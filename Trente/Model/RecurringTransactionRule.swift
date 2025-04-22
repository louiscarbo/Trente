//
//  RecurringTransactionRule.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 16/04/2025.
//

import Foundation
import SwiftData

@Model
class RecurringTransactionRule {
    var title: String
    var amountCents: Int
    var category: BudgetCategory
    var frequency: RecurrenceFrequency
    var startDate: Date
    var endDate: Date? = nil
    var autoConfirm: Bool = false
    
    @Relationship(deleteRule: .cascade, inverse: \RecurringTransactionInstance.rule)
    var instances: [RecurringTransactionInstance] = []

    var isDeleted: Bool = false
    
    init(title: String, amountCents: Int, category: BudgetCategory, frequency: RecurrenceFrequency, startDate: Date) {
        self.title = title
        self.amountCents = amountCents
        self.category = category
        self.frequency = frequency
        self.startDate = startDate
    }
}

enum RecurrenceFrequency: String, Codable, CaseIterable {
    case weekly, monthly, yearly
    
    var displayName: String {
        switch self {
        case .weekly:
            return String(localized: "Weekly")
        case .monthly:
            return String(localized: "Monthly")
        case .yearly:
            return String(localized: "Yearly")
        }
    }
}

extension RecurringTransactionRule {
    var frequencyDescription: String {
        switch frequency {
        case .weekly:
            return String(localized: "Every \(startDate.formatted(.dateTime.weekday(.wide)))")
        case .monthly:
            let day = Calendar.current.component(.day, from: startDate)
            let ordinalDay = day.ordinalString 
            return "\(ordinalDay) of every month"
        case .yearly:
            return String(localized: "Every \(startDate.formatted(.dateTime.month(.wide))) \(startDate.formatted(.dateTime.day(.ordinalOfDayInMonth)))")
        }
    }
}

extension Int {
    /// “1st”, “2nd”, “3rd”, “4th”, … localized
    var ordinalString: String {
        let fmt = NumberFormatter()
        fmt.numberStyle = .ordinal
        return fmt.string(from: NSNumber(value: self)) ?? "\(self)"
    }
}

extension RecurringTransactionRule {
    /// Returns the recurring transaction instances for the given month,
    /// based on the rule's start/end dates and its frequency.
    func createRecurringInstances(for month: Month) -> [RecurringTransactionInstance] {
        var instances: [RecurringTransactionInstance] = []
        let calendar = Calendar.current
        
        // 1. Compute month bounds
        let startOfMonth = month.startDate
        let endOfMonth = month.endDate()
        
        // 2. Clip rule’s date window to this month
        let windowStart = max(self.startDate, startOfMonth)

        let windowEnd = {
            if let ruleEnd = self.endDate {
                return min(ruleEnd, endOfMonth)
            } else {
                return endOfMonth
            }
        }()
        guard windowStart <= windowEnd else {
            // No overlap between rule and this month
            return []
        }
        
        switch frequency {
        case .weekly:
            // 3a. Weekly: same weekday as rule.startDate
            let weekday = calendar.component(.weekday, from: self.startDate)
            
            // Find first occurrence on/after windowStart
            var candidate = calendar.nextDate(
                after: windowStart.addingTimeInterval(-1),
                matching: DateComponents(weekday: weekday),
                matchingPolicy: .nextTime
            )!
            
            // Step by 1 week until we exceed windowEnd
            while candidate <= windowEnd {
                instances.append(
                    RecurringTransactionInstance(
                        date:     candidate,
                        rule:     self,
                        month:    month,
                        confirmed: false
                    )
                )
                candidate = calendar.date(
                    byAdding: .weekOfYear,
                    value: 1,
                    to: candidate
                )!
            }
            
        case .monthly:
            // 1) normalize windowStart to midnight for date‐only compare
            let dayWindowStart = calendar.startOfDay(for: windowStart)
            let day = calendar.component(.day, from: self.startDate)

            // 2) We’ll test two calendar‐months: the one containing month.startDate, and the next one
            for offset in 0...1 {
                // anchor to month.startDate + offset months
                guard let monthAnchor = calendar.date(
                    byAdding: .month,
                    value: offset,
                    to: month.startDate
                ) else { continue }

                // build year/month from that anchor
                var comps = calendar.dateComponents([.year, .month], from: monthAnchor)
                comps.day = day

                // try to form the candidate
                guard let candidate = calendar.date(from: comps) else { continue }

                // 3) only accept if it lands in our valid window
                if candidate >= dayWindowStart && candidate <= windowEnd {
                    instances.append(
                        RecurringTransactionInstance(
                            date:      candidate,
                            rule:      self,
                            month:     month,
                            confirmed: false
                        )
                    )
                }
            }
            
        case .yearly:
            // 3c. Yearly: same month/day as rule.startDate, but only if it falls in this month
            let ruleMonth = calendar.component(.month, from: self.startDate)
            let targetMonth = calendar.component(.month, from: month.startDate)
            
            guard ruleMonth == targetMonth else {
                // Different month, so no yearly hit
                break
            }
            
            let day = calendar.component(.day, from: self.startDate)
            var comps = calendar.dateComponents([.year], from: windowStart)
            comps.month = targetMonth
            comps.day   = day
            
            if let candidate = calendar.date(from: comps),
               candidate >= windowStart,
               candidate <= windowEnd {
                
                print("Adding yearly instance: \(title), \(candidate)")

                instances.append(
                    RecurringTransactionInstance(
                        date:     candidate,
                        rule:     self,
                        month:    month,
                        confirmed: false
                    )
                )
            }
        }
        
        return instances
    }
}

// MARK: - Sample Data
extension RecurringTransactionRule {
    /// A few sample recurring rules so that month1, month2 & month3
    /// each get at least two instances when you call `generateInstances(...)`
    static let sampleData: [RecurringTransactionRule] = {
        // Start all rules two months ago, so they fire in month3, month2 & month1
        let start = Month.month3.startDate
        
        // 1) Monthly salary income
        let salary = RecurringTransactionRule(
            title: "Salary",
            amountCents: 1600_00,
            category: .needs,
            frequency: .monthly,
            startDate: start.addingTimeInterval(-15 * 24 * 60 * 60) // One day earlier
        )
        salary.autoConfirm = true
        
        // 2) Monthly rent expense
        let rent = RecurringTransactionRule(
            title: "Rent",
            amountCents: -800_00,
            category: .needs,
            frequency: .monthly,
            startDate: start.addingTimeInterval(-1 * 24 * 60 * 60) // One day earlier
        )
        rent.autoConfirm = true
        
        // 3) Weekly coffee expense
        let coffee = RecurringTransactionRule(
            title: "Coffee",
            amountCents: -300,
            category: .wants,
            frequency: .weekly,
            startDate: start
        )
        coffee.autoConfirm = true
        
        return [salary, rent, coffee]
    }()
}
