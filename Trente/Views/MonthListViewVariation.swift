//
//  MonthListViewVariation.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 22/04/2025.
//

import SwiftUI
import SwiftData

struct MonthListViewVariation: View {
    @Query(
        sort: \Month.startDate,
        order: .reverse,
        animation: .default
    ) var months: [Month]
        
    @State private var selection: Month?
    @State private var isShowingNewMonth = false
    
    @Environment(\.colorScheme) var colorScheme
    private var lightMode: Bool { colorScheme == .light }

    var body: some View {
        NavigationSplitView {
            ScrollView {
                VStack(alignment: .leading) {
                    if let currentMonth = months.first {
                        Text("CURRENT MONTH")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal)
                        
                        CurrentMonthRowViewVariation(currentMonth: currentMonth, selectedMonth: $selection)
                    }
                    
                    // New Month Button
                    NewMonthButtonViewVariation()
                        .padding(.vertical)
                    
                    if months.count > 1 {
                        Text("ARCHIVED MONTHS")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal)
                        ArchivedMonthsListVariation(selectedMonth: $selection, archivedMonths: months.dropFirst())
                    }
                    
                    Spacer()
                    
                }
                .navigationTitle("All Months")
                .toolbarTitleDisplayMode(.large)
                .padding()
            }
            .navigationDestination(item: $selection) { month in
                MonthView(month: month)
                    .id(month)
            }
        } detail: {
            if months.isEmpty {
                ContentUnavailableView {
                    Label("No months available", systemImage: "calendar")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                }
            } else {
                if let selected = selection {
                    MonthView(month: selected)
                        .id(selected)
                } else {
                    Text("Select a month")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

struct TrenteButton: ButtonStyle {
    @Environment(\.colorScheme) var colorScheme
    private var lightMode: Bool { colorScheme == .light }

    func makeBody(configuration: Configuration) -> some View {
        ZStack {
            Capsule()
                .fill(.regularMaterial)
                .overlay(
                    ZStack {
                        Capsule()
                            .stroke(
                                lightMode ? Color.black.opacity(configuration.isPressed ? 0.1 : 0.2) :
                                    Color.white.opacity(configuration.isPressed ? 0.1 : 0.2),
                                lineWidth: 3
                            )
                        if configuration.isPressed {
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: lightMode ?
                                        [.black.opacity(0.05), .black.opacity(0.1)] :
                                            [.white.opacity(0.05), .white.opacity(0.2)],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                        }
                    }
                )
            configuration.label
                .font(.title2)
                .bold()
                .tint(.primary)
                .padding(.vertical)
        }
        .scaleEffect(configuration.isPressed ? 0.95 : 1)
    }
}

extension Color {
    /// Create a Color from a 24‑bit hex code (e.g. 0xFAF6F1) plus optional opacity.
    init(hex: Int, opacity: Double = 1) {
        let red   = Double((hex >> 16) & 0xFF) / 255
        let green = Double((hex >> 8)  & 0xFF) / 255
        let blue  = Double(hex         & 0xFF) / 255
        self.init(.sRGB, red: red, green: green, blue: blue, opacity: opacity)
    }
}

#Preview {
    MonthListViewVariation()
        .modelContainer(SampleDataProvider.shared.modelContainer)
}

struct CurrentMonthRowViewVariation: View {
    var currentMonth: Month
    @Binding var selectedMonth: Month?
    
    @Environment(\.colorScheme) var colorScheme
    private var lightMode: Bool { colorScheme == .light }

    private var isSelected : Bool { selectedMonth == currentMonth }
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text("\(currentMonth.name)")
                    .font(.headline)
                Spacer()
                Text(currentMonth.overSpent ? "Over Budget" : "Under Budget")
            }
            
            Divider()
            
            remainingSpentView
        }
        .padding()
        .background(
            backgroundView
        )
        .onTapGesture {
            withAnimation(.easeOut) {
                if selectedMonth == currentMonth {
                    selectedMonth = nil
                } else {
                    selectedMonth = currentMonth
                }
            }
        }
    }
    
    var remainingSpentView: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("Remaining")
                    .font(.subheadline)
                Text(currentMonth.remainingAmountDisplay)
                    .font(.title)
                    .foregroundColor(.green)
            }
            
            Spacer()
            
            VStack(alignment: .trailing) {
                Text("Spent")
                    .font(.subheadline)
                Text(currentMonth.spentAmountDisplay)
                    .font(.title)
                    .foregroundColor(.red)
            }
        }
    }
    
    var backgroundView: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .foregroundStyle(
                    LinearGradient(
                        colors: [.green.opacity(0.4), .red.opacity(0.4)],
                        startPoint: .bottomLeading,
                        endPoint: .bottomTrailing
                    )
                )
            RoundedRectangle(cornerRadius: 20)
                .foregroundStyle(
                    RadialGradient(
                        colors: [lightMode ? .white : .black, .clear],
                        center: .top,
                        startRadius: 0,
                        endRadius: 500
                    )
                )
            RoundedRectangle(cornerRadius: 20)
                .foregroundStyle(.regularMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(isSelected ? Color.primary :
                                    (lightMode ? Color.black.opacity(0.2) : Color.white.opacity(0.2)), lineWidth: 3)
                )
        }
    }
}

struct ArchivedMonthsListVariation: View {
    @Binding var selectedMonth: Month?
    var archivedMonths: ArraySlice<Month>
    
    @Environment(\.colorScheme) var colorScheme
    private var lightMode: Bool { colorScheme == .light }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(archivedMonths) { month in
                MonthRowViewVariation(month: month, archivedMonths: archivedMonths, selectedMonth: $selectedMonth)
            }
        }
        .background(
            // 4) Rounded rectangle with gradient fill + border
            RoundedRectangle(cornerRadius: 20)
                .foregroundStyle(.thickMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            lightMode ? Color.black.opacity(0.2) : Color.white.opacity(0.2), lineWidth: 3)
                )
        )
   }
}

private struct MonthRowViewVariation: View {
    var month: Month
    var archivedMonths: ArraySlice<Month>
    @Binding var selectedMonth: Month?
    
    var isSelected: Bool {
        selectedMonth == month
    }
    
    @Environment(\.colorScheme) var colorScheme
    private var lightMode: Bool { colorScheme == .light }
    
    var body: some View {
        
        HStack {
            Text(month.name)
            Spacer()
            Text(month.overSpent ? "Over Budget" : "Under Budget")
            Image(systemName: "chevron.right")
                .foregroundStyle(Color.secondary)
        }
        .padding()
        .overlay {
            if isSelected {
                if month != archivedMonths.last && month != archivedMonths.first {
                    Rectangle()
                        .stroke(lightMode ? Color.black : Color.white, lineWidth: 3)
                } else if month == archivedMonths.first {
                    UnevenRoundedRectangle(
                        topLeadingRadius: 20,
                        bottomLeadingRadius: 0,
                        bottomTrailingRadius: 0,
                        topTrailingRadius: 20
                    )
                    .stroke(lightMode ? Color.black : Color.white, lineWidth: 3)
                } else {
                    UnevenRoundedRectangle(
                        topLeadingRadius: 0,
                        bottomLeadingRadius: 20,
                        bottomTrailingRadius: 20,
                        topTrailingRadius: 0
                    )
                    .stroke(lightMode ? Color.black : Color.white, lineWidth: 3)
                }
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            toggleSelection()
        }
        
        if month != archivedMonths.last {
            Divider()
        }
    }
    
    func toggleSelection() {
        withAnimation {
            if selectedMonth == month {
                selectedMonth = nil
            } else {
                selectedMonth = month
            }
        }
    }
}

private struct NewMonthButtonViewVariation: View {
    var body: some View {
        Button {
            
        } label: {
            Label("Start a New Month", systemImage: "calendar.badge.plus")
        }
        .buttonStyle(TrenteButton())
    }
}
