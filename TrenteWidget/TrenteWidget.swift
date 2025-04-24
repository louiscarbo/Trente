//
//  TrenteWidget.swift
//  TrenteWidget
//
//  Created by Louis Carbo Estaque on 23/04/2025.
//

import WidgetKit
import SwiftUI
import SwiftData

struct TrenteWidget: Widget {
    let kind: String = "TrenteWidget"
    @Environment(\.widgetFamily) var family
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            TrenteWidgetView(entry: entry)
                .containerBackground(for: .widget) {
                    EmptyView()
                }
        }
        .configurationDisplayName("Current Month")
        .description("See your current month, as well as your latest transactions in larger widgets.")
    }
}

struct TrenteWidgetView: View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .systemMedium:
            HomescreenTrenteWidgetView(entry: entry)
        case .systemLarge:
            HomescreenTrenteWidgetView(entry: entry)
        case .systemSmall:
            HomescreenTrenteWidgetView(entry: entry)
        default:
            Text("Not Implemented Yet.")
        }
    }
}

struct HomescreenTrenteWidgetView : View {
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
                    
                    if family != .systemSmall {
                        Link(destination: URL(string: "trente://newtransaction/" + currentMonth.id.uuidString)!) {
                            Button { } label: {
                                Label("New Transaction", systemImage: "plus")
                                    .foregroundStyle(.primary)
                                    .font(.subheadline)
                            }
                            .buttonStyle(TrenteButtonStyle(narrow: true))
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
                }
            }
        } else {
            Text("No current month")
        }
    }
}

struct Provider: @preconcurrency TimelineProvider {
    @MainActor
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), month: getCurrentMonth(inPreview: true))
    }

    @MainActor
    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let entry = SimpleEntry(date: Date(), month: getCurrentMonth())
        completion(entry)
    }

    @MainActor
    func getTimeline(in context: Context, completion: @escaping (Timeline<SimpleEntry>) -> ()) {
        
        var entries: [SimpleEntry] = []
        // MARK: TODO: Change this in the release version
        let entry = SimpleEntry(date: Date(), month: getCurrentMonth(inPreview: true))
        entries.append(entry)

        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let month: Month?
}

@MainActor
private func getCurrentMonth(inPreview: Bool = false) -> Month? {
    do {
        var modelContainer = SampleDataProvider.shared.modelContainer
        if !inPreview {
            modelContainer = try ModelContainer(for: Month.self)
        }
        let descriptor = FetchDescriptor<Month>(sortBy: [SortDescriptor(\Month.startDate, order: .forward)])
        if let month = try modelContainer.mainContext.fetch(descriptor).last {
            return month.detachedCopy()
        }
    } catch {
        print("Error fetching month budgets: \(error)")
    }
    return nil
}

#Preview(as: .systemLarge) {
    TrenteWidget()
} timeline: {
    SimpleEntry(date: Date(), month: getCurrentMonth(inPreview: true))
}
