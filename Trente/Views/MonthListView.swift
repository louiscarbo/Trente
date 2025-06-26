//
//  MonthListView.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 22/04/2025.
//

import SwiftUI
import SwiftData

struct MonthListView: View {
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
                LazyVStack(alignment: .leading) {
                    if let currentMonth = months.first {
                        Text("CURRENT MONTH")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal)
                        
                        CurrentMonthRowView(currentMonth: currentMonth, selectedMonth: $selection)
                    }
                    
                    // New Month Button
                    NewMonthButtonView()
                        .padding(.vertical)
                    
                    if months.count > 1 {
                        Text("ARCHIVED MONTHS")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal)
                        ArchivedMonthsList(selectedMonth: $selection, archivedMonths: months.dropFirst())
                    }
                    
                    Spacer()
                    
                }
                .navigationTitle("All Months")
                #if os(iOS)
                .toolbarTitleDisplayMode(.large)
                #elseif os(macOS)
                .frame(minWidth: 200, idealWidth: 300, maxWidth: 400)
                #endif
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
        .onAppear {
            selection = months.first
        }
    }
}

#Preview {
    MonthListView()
}

struct ArchivedMonthsList: View {
    @Binding var selectedMonth: Month?
    var archivedMonths: ArraySlice<Month>
    
    @Environment(\.colorScheme) var colorScheme
    private var lightMode: Bool { colorScheme == .light }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(archivedMonths) { month in
                MonthRowView(month: month, archivedMonths: archivedMonths, selectedMonth: $selectedMonth)
            }
        }
        .background(
            TrenteListBackgroundView()
        )
   }
}

private struct MonthRowView: View {
    var month: Month
    var archivedMonths: ArraySlice<Month>
    @Binding var selectedMonth: Month?
    
    var isSelected: Bool {
        selectedMonth == month
    }
    @State var isPressed: Bool = false
    
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
            ZStack {
                if isSelected {
                    if month != archivedMonths.last && month != archivedMonths.first {
                        Rectangle()
                            .stroke(lightMode ? Color.black : Color.white, lineWidth: 3)
                    } else if month == archivedMonths.first {
                        UnevenRoundedRectangle(
                            topLeadingRadius: 26,
                            bottomLeadingRadius: 0,
                            bottomTrailingRadius: 0,
                            topTrailingRadius: 26
                        )
                        .stroke(lightMode ? Color.black : Color.white, lineWidth: 3)
                    } else {
                        UnevenRoundedRectangle(
                            topLeadingRadius: 0,
                            bottomLeadingRadius: 26,
                            bottomTrailingRadius: 26,
                            topTrailingRadius: 0
                        )
                        .stroke(lightMode ? Color.black : Color.white, lineWidth: 3)
                    }
                }
                if isPressed {
                    if month != archivedMonths.last && month != archivedMonths.first {
                        Rectangle()
                            .fill(lightMode ? Color.black.opacity(0.1) : Color.white.opacity(0.1))
                    } else if month == archivedMonths.first {
                        UnevenRoundedRectangle(
                            topLeadingRadius: 26,
                            bottomLeadingRadius: 0,
                            bottomTrailingRadius: 0,
                            topTrailingRadius: 26
                        )
                        .fill(lightMode ? Color.black.opacity(0.1) : Color.white.opacity(0.1))
                    } else {
                        UnevenRoundedRectangle(
                            topLeadingRadius: 0,
                            bottomLeadingRadius: 26,
                            bottomTrailingRadius: 26,
                            topTrailingRadius: 0
                        )
                        .fill(lightMode ? Color.black.opacity(0.1) : Color.white.opacity(0.1))
                    }
                }
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            toggleSelection()
        }
        .onLongPressGesture(
            minimumDuration: 0,
            pressing: { inProgress in
                withAnimation(.easeOut) {
                    isPressed = inProgress
                }
            },
            perform: { }
        )
        
        if month != archivedMonths.last {
            Divider()
        }
    }
    
    func toggleSelection() {
        withAnimation {
            selectedMonth = month
        }
    }
}

private struct NewMonthButtonView: View {
    var body: some View {
        Button {
            
        } label: {
            Label("Start a New Month", systemImage: "calendar.badge.plus")
        }
        .buttonStyle(TrenteSecondaryButtonStyle())
    }
}

struct TrenteListBackgroundView: View {
    @Environment(\.colorScheme) var colorScheme
    private var lightMode: Bool { colorScheme == .light }
    
    var body: some View {
        RoundedRectangle(cornerRadius: 26)
            .foregroundStyle(.regularMaterial)
            .overlay(
                RoundedRectangle(cornerRadius: 26)
                    .stroke(
                        lightMode ? Color.black.opacity(0.2) : Color.white.opacity(0.2), lineWidth: 3)
            )
    }
}
