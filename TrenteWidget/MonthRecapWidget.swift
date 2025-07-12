//
//  MonthRecapWidget.swift
//  MonthRecapWidget
//
//  Created by Louis Carbo Estaque on 23/04/2025.
//

import WidgetKit
import SwiftUI
import SwiftData

struct MonthRecapWidget: Widget {
    let kind: String = "MonthRecapWidget"
    @Environment(\.widgetFamily) var family
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            MonthRecapWidgetView(entry: entry)
                .containerBackground(for: .widget) {
                    EmptyView()
                }
        }
        .configurationDisplayName(String(localized: "Month Recap"))
        .description(
            String(localized: """
            See your remaining budget for the current month, as well as your spending on larger widgets.
            Quickly see how you're doing, and easily log new transactions.

            See examples below.
            """
            )
        )
        #if os(iOS)
        .supportedFamilies([.systemMedium, .systemLarge, .systemSmall, .accessoryCircular, .accessoryInline, .accessoryRectangular])
        #elseif os(macOS)
        .supportedFamilies([.systemMedium, .systemLarge, .systemSmall])
        #endif
    }
}

struct MonthRecapWidgetView: View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .systemMedium:
            HomescreenMonthRecapWidgetView(entry: entry)
        case .systemLarge:
            HomescreenMonthRecapWidgetView(entry: entry)
        case .systemSmall:
            HomescreenMonthRecapWidgetView(entry: entry)
        case .accessoryCircular:
            AccessoryCircularMonthRecapWidgetView(entry: entry)
        case .accessoryInline:
            AccessoryInlineMonthRecapWidgetView(entry: entry)
        case .accessoryRectangular:
            AccessoryRectangularMonthRecapWidgetView(entry: entry)
        default:
            Text("Not Implemented Yet.")
        }
    }
}

struct HomescreenMonthRecapWidgetView: View {
    var entry: Provider.Entry
    
    @Environment(\.widgetFamily) var family

    var body: some View {
        if let currentMonth = entry.month {
            VStack(spacing: family == .systemMedium ? 6 : 12) {
                HStack {
                    Text(currentMonth.name)
                        .font(.headline)
                    Spacer()
                    if family != .systemSmall {
                        Text("Trente")
                            .foregroundStyle(.secondary)
                    }
                }
                if family != .systemSmall {
                    Divider()
                }
                HStack {
                    VStack(alignment: .leading) {
                        Text("Remaining")
                            .font(.subheadline)
                        Text(currentMonth.remainingAmountDisplay)
                            .font(.title)
                            .foregroundStyle(currentMonth.overSpent ? .red : .green)
                            .privacySensitive()
                    }
                    
                    Spacer()
                    
                    if family != .systemSmall {
                        VStack(alignment: .trailing) {
                            Text("Spent")
                                .font(.subheadline)
                            Text(currentMonth.spentAmountDisplay)
                                .font(.title)
                                .foregroundStyle(.red)
                                .privacySensitive()
                        }
                    }
                }
                
                HStack {
                    VStack(alignment: .leading) {
                        Text(entry.date.formatted(.dateTime.day().month(.wide).year()))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Text(entry.date.formatted(.dateTime.hour().minute()))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    if family != .systemSmall {
                        Link(destination: URL(string: "trente://newtransaction/" + currentMonth.id.uuidString)!) {
                            Button { } label: {
                                Label("New Transaction", systemImage: "plus")
                                    .foregroundStyle(.primary)
                                    .font(.subheadline)
                                    .padding(.horizontal)
                            }
                            .buttonStyle(TrentePrimaryButtonStyle(narrow: true))
                            .scaledToFit()
                            .padding(.leading)
                            .padding(.trailing, -3)
                        }
                    } else {
                        Spacer()
                    }
                }
                
                if family == .systemLarge {
                    Divider()
                    ForEach(currentMonth.latestTransactions.prefix(3)) { transactionGroup in
                        TransactionGroupRowView(transactionGroup: transactionGroup)
                            .privacySensitive()
                    }
                    
                    if currentMonth.latestTransactions.isEmpty {
                        Spacer()
                        Text("Add your first transactions by tapping 'New Transaction'.")
                            .foregroundStyle(.secondary)
                            .padding()
                        Spacer()
                    } else if currentMonth.latestTransactions.count < 3 {
                        Spacer()
                    }
                }
            }
        } else {
            if family == .systemLarge {
                ContentUnavailableView(
                    "No month yet",
                    systemImage: "calendar",
                    description:
                        Text("""
                            You haven't started tracking your budget yet. Start tracking your budget with Trente by opening the app!
                        """)
                )
            } else {
                Text("Start tracking your budget with Trente by opening the app!")
                    .multilineTextAlignment(.center)
            }
        }
    }
}

struct AccessoryCircularMonthRecapWidgetView: View {
    var entry: Provider.Entry
    
    var body: some View {
        if let currentMonth = entry.month {
            Gauge(value: currentMonth.remainingAmount, in: 0...currentMonth.incomeAmount) {
                Text(currentMonth.remainingAmountDisplay)
                    .privacySensitive()
            }
            .gaugeStyle(AccessoryCircularGaugeStyle())
        } else {
            Image(systemName: "xmark")
        }
    }
}

struct AccessoryInlineMonthRecapWidgetView: View {
    var entry: Provider.Entry
    
    var body: some View {
        if let currentMonth = entry.month {
            Text("- \(currentMonth.remainingAmountDisplay) Remaining")
                .privacySensitive()
                .font(.headline)
                .foregroundStyle(currentMonth.overSpent ? .red : .green)
        } else {
            Image(systemName: "xmark")
        }
    }
}

struct AccessoryRectangularMonthRecapWidgetView: View {
    var entry: Provider.Entry
    
    var body: some View {
        if let currentMonth = entry.month {
            VStack {
                Text("\(currentMonth.remainingAmountDisplay) Remaining")
                    .privacySensitive()
                Gauge(value: currentMonth.remainingAmount, in: 0...currentMonth.incomeAmount) {
                }
                .gaugeStyle(AccessoryLinearGaugeStyle())
            }
        } else {
            Label("Start tracking your budget.", systemImage: "xmark")
        }
    }
}

struct Provider: @preconcurrency TimelineProvider {
    @MainActor
    func placeholder(in context: Context) -> MonthRecapEntry {
        MonthRecapEntry(date: Date(), month: Month.getSampleMonthWithTransactions())
    }

    @MainActor
    func getSnapshot(in context: Context, completion: @escaping (MonthRecapEntry) -> Void) {
        let entry = MonthRecapEntry(date: Date(), month: Month.getSampleMonthWithTransactions())
        completion(entry)
    }

    @MainActor
    func getTimeline(in context: Context, completion: @escaping (Timeline<MonthRecapEntry>) -> Void) {
        
        var entries: [MonthRecapEntry] = []
        // TODO: Change this in the release version
        let entry = MonthRecapEntry(date: Date(), month: getCurrentMonth(inPreview: true))
        entries.append(entry)

        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }
}

struct MonthRecapEntry: TimelineEntry {
    let date: Date
    let month: Month?
}

#if os(iOS)
#Preview(as: .accessoryRectangular) {
    MonthRecapWidget()
} timeline: {
    MonthRecapEntry(date: Date(), month: getCurrentMonth(inPreview: true))
}
#endif
