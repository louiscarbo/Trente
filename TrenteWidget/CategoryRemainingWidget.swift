//
//  CategoryRemainingWidget.swift
//  TrenteWidgetExtension
//
//  Created by Louis Carbo Estaque on 24/04/2025.
//

import WidgetKit
import SwiftUI

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
        .description(
            String(localized: """
                See your remaining budget for the current month in a specific category, or for all categories in the medium widget.
                
                To select a category, hold the widget.
                """
            )
        )
        #if os(iOS)
        .supportedFamilies([.systemMedium, .systemSmall, .accessoryCircular])
        #elseif os(macOS)
        .supportedFamilies([.systemMedium, .systemSmall])
        #endif
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
            let month = entry.month ?? .sample
            let category = entry.category.budgetCategory
            BudgetGaugeView(
                figures: month.figures(for: category),
                category: category,
                currencyCode: month.currencyCode
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
        var month: WidgetMonth?
        var category: BudgetCategory
        
        var body: some View {
            ZStack(alignment: .bottom) {
                let month = month ?? .sample
                BudgetGaugeView(
                    figures: month.figures(for: category),
                    category: category,
                    currencyCode: month.currencyCode,
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
            let figures = currentMonth.figures(for: category)
            Gauge(value: figures.remaining, in: 0...figures.income) {
                Text(currentMonth.display(figures.remaining))
                    .privacySensitive()
            }
            .gaugeStyle(AccessoryCircularGaugeStyle())
        } else {
            Image(systemName: "xmark")
        }
    }
}

struct CategoryTimeline: AppIntentTimelineProvider {
    func timeline(for configuration: SelectCategoryIntent, in context: Context) async -> Timeline<CategoryEntry> {
        do {
            let month = try getCurrentMonth()
            let entry = CategoryEntry(
                date: Date(),
                month: month,
                category: configuration.category ?? .needs
            )
            return Timeline(entries: [entry], policy: .never)
        } catch {
            // If fetching the current month fails, return an empty timeline
            return Timeline(entries: [], policy: .never)
        }
    }
    
    func snapshot(for configuration: SelectCategoryIntent, in context: Context) async -> CategoryEntry {
        CategoryEntry(
            date: Date(),
            month: .sample,
            category: WidgetBudgetCategory.needs
        )
    }
    
    func placeholder(in context: Context) -> CategoryEntry {
        CategoryEntry(
            date: Date(),
            month: .sample,
            category: WidgetBudgetCategory.needs
        )
    }
}

struct CategoryEntry: TimelineEntry {
    let date: Date
    let month: WidgetMonth?
    let category: WidgetBudgetCategory
}

#Preview(as: .systemSmall) {
    CategoryRemainingWidget()
} timeline: {
    CategoryEntry(date: Date(), month: .sample, category: .needs)
}
