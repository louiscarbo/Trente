//
//  TestSupport.swift
//  TrenteTests
//
//  Created by Louis Carbo Estaque on 08/10/2026.
//

import SwiftData
import Foundation
import UserNotifications
@testable import Trente

func makeContext() throws -> ModelContext {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try ModelContainer(for: .trente, migrationPlan: TrenteMigrationPlan.self, configurations: config)
    return ModelContext(container)
}

@discardableResult
func insertMonth(year: Int, month: Int, in context: ModelContext) -> Month {
    let eur = Currencies.currency(for: "EUR")!
    let month = Month(
        startDate: Calendar.current.date(from: DateComponents(year: year, month: month, day: 1))!,
        currency: eur,
        idealBudgetCents: 2000_00,
        idealRepartition: [.needs: 50, .wants: 30, .savingsAndDebts: 20]
    )
    context.insert(month)
    return month
}

func csvRecords(_ csv: String, separator: Character = ",") -> [[String]] {
    let characters = Array(csv)
    var records: [[String]] = []
    var record: [String] = []
    var field = ""
    var isQuoted = false
    var index = 0
    while index < characters.count {
        let character = characters[index]
        if isQuoted {
            if character != "\"" {
                field.append(character)
            } else if index + 1 < characters.count, characters[index + 1] == "\"" {
                field.append("\"")
                index += 1
            } else {
                isQuoted = false
            }
        } else if character == "\"" {
            isQuoted = true
        } else if character == separator {
            record.append(field)
            field = ""
        } else if character == "\r\n" {
            record.append(field)
            records.append(record)
            record = []
            field = ""
        } else {
            field.append(character)
        }
        index += 1
    }
    if !field.isEmpty || !record.isEmpty {
        record.append(field)
        records.append(record)
    }
    return records
}

actor FakeNotificationCenter: NotificationAuthorizing {
    let status: UNAuthorizationStatus
    let grants: Bool
    private(set) var requestCount = 0

    init(status: UNAuthorizationStatus, grants: Bool) {
        self.status = status
        self.grants = grants
    }

    func currentAuthorizationStatus() async -> UNAuthorizationStatus {
        status
    }

    func requestAuthorization(options: UNAuthorizationOptions) async throws -> Bool {
        requestCount += 1
        return grants
    }
}
