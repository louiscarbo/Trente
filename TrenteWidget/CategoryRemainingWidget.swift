//
//  CategoryRemainingWidget.swift
//  TrenteWidgetExtension
//
//  Created by Louis Carbo Estaque on 24/04/2025.
//

import WidgetKit
import SwiftUI
import SwiftData

struct CategoryRemainingWidget: Widget {
    let kind: String = "CategoryRemainingWidget"
    @Environment(\.widgetFamily) var family
    
    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: kind,
            intent: SelectCategoryIntent.self,
            provider: CategoryTimeline()
        ) { entry in
            CategoryRemainingWidgetView(entry: entry)
                .containerBackground(for: .widget) {
                    EmptyView()
                }
        }
        .configurationDisplayName(String(localized: "Category Recap"))
        .description(String(localized: "See your remaining budget for the current month in a specific category, or for all categories in the medium widget.\n\nTo select a category, hold the widget."))
        .supportedFamilies([.systemMedium, .systemSmall, .accessoryCircular])
    }
}

struct CategoryRemainingWidgetView: View {
    var entry: CategoryTimeline.Entry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .systemSmall:
            SmallMediumCategoryRemainingWidgetView(entry: entry)
        case .systemMedium:
            MediumCategoryRemainingWidgetView(entry: entry)
        case .accessoryCircular:
            AccessoryCircularCategoryRemainingWidgetView(entry: entry)
        default:
            Text("Not Implemented Yet.")
        }
    }
}

struct SmallMediumCategoryRemainingWidgetView: View {
    var entry: CategoryTimeline.Entry
    
    var body: some View {
        ZStack(alignment: .bottom) {
            CategoryRemainingGaugeView(
                month: entry.month ?? Month.getSampleMonthWithTransactions(),
                category: entry.category.budgetCategory
            )
            
            Text(entry.category.budgetCategory.shortName)
                .lineLimit(1)
                .font(.subheadline)
                .bold()
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background {
                    Capsule()
                        .fill(.thinMaterial)
                        .padding(2)
                }
                .offset(y: 13)
        }
        
    }
}

struct MediumCategoryRemainingWidgetView: View {
    var entry: CategoryTimeline.Entry
    
    var body: some View {
        HStack(spacing: 25) {
            OneGaugeView(month: entry.month, category: .needs)
            OneGaugeView(month: entry.month, category: .wants)
            OneGaugeView(month: entry.month, category: .savingsAndDebts)
        }
    }
    
    private struct OneGaugeView: View {
        var month: Month?
        var category: BudgetCategory
        
        var body: some View {
            ZStack(alignment: .bottom) {
                CategoryRemainingGaugeView(
                    month: month ?? Month.getSampleMonthWithTransactions(),
                    category: category,
                    size: 80
                )
                
                Text(category.shortName)
                    .lineLimit(1)
                    .font(.subheadline)
                    .bold()
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    .background {
                        Capsule()
                            .fill(.thinMaterial)
                            .padding(2)
                    }
                    .offset(y: 13)
            }
            .aspectRatio(CGSize(width: 1, height: 2), contentMode: .fit)
        }
    }
}


struct AccessoryCircularCategoryRemainingWidgetView: View {
    var entry: CategoryTimeline.Entry
    
    var body: some View {
        let category = entry.category.budgetCategory
        
        if let currentMonth = entry.month {
            Gauge(
                value: currentMonth.remainingAmount(for: category),
                in:
                    0
                        ...
                    currentMonth.incomeAmount(for: category)
            ) {
                Text(currentMonth.remainingAmountDisplay(for: category))
                    .privacySensitive()
            }
            .gaugeStyle(AccessoryCircularGaugeStyle())
        } else {
            Image(systemName: "xmark")
        }
    }
}

struct CategoryTimeline: AppIntentTimelineProvider {
    @MainActor
    func timeline(for configuration: SelectCategoryIntent, in context: Context) async -> Timeline<CategoryEntry> {
        Timeline(
            entries: [
                CategoryEntry(
                    date: Date(),
                    month: getCurrentMonth(),
                    category: configuration.category ?? .needs
                )
            ],
            policy: .never
        )
    }
    
    func snapshot(for configuration: SelectCategoryIntent, in context: Context) async -> CategoryEntry {
        CategoryEntry(
            date: Date(),
            month: Month.getSampleMonthWithTransactions(),
            category: WidgetBudgetCategory.needs
        )
    }
    
    func placeholder(in context: Context) -> CategoryEntry {
        CategoryEntry(
            date: Date(),
            month: Month.getSampleMonthWithTransactions(),
            category: WidgetBudgetCategory.needs
        )
    }
}

struct CategoryEntry: TimelineEntry {
    let date: Date
    let month: Month?
    let category: WidgetBudgetCategory
}

#Preview(as: .systemSmall) {
    CategoryRemainingWidget()
} timeline: {
    CategoryEntry(date: Date(), month: Month.getSampleMonthWithTransactions(), category: .needs)
}
