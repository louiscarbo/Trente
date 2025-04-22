//
//  MonthListView.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 16/04/2025.
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
            
    var body: some View {
        NavigationSplitView {
            List(selection: $selection) {
                NewMonthButtonView()
                
                if let currentMonth = months.first {
                    Section(header: Text("Current Month")) {
                        CurrentMonthRowView(currentMonth: currentMonth)
                            .tag(currentMonth)
                    }
                }
                
                if months.count > 1 {
                    Section(header: Text("Archived Months")) {
                        ForEach(months.dropFirst()) { month in
                            MonthRowView(month: month)
                                .tag(month)
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background {
                ListBackgroundView(month: months.first)
            }
            .navigationBarHidden(true)
            .navigationTitle("Months")
        } detail : {
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
//        .onAppear {
//            selection = months.first
//        }
    }
}

#Preview {
    MonthListView()
        .modelContainer(SampleDataProvider.shared.modelContainer)
}

// MARK: - MonthRowView
struct MonthRowView: View {
    var month: Month
    
    var body: some View {
        HStack {
            Image(systemName: month.overSpent ? "xmark.circle.fill" : "checkmark.circle.fill")
                .foregroundColor(month.overSpent ? . red : .green)
            
            VStack(alignment: .leading) {
                Text(month.name)
                    .font(.headline)
                Text(month.overSpent ? "Over Spent" : "Under Budget")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    
            }
            
            Image(systemName: "chevron.right")
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
    }
}

// MARK: - Remaining/Spent View
struct RemainingSpentView: View {
    @State var month: Month
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("Remaining")
                    .font(.subheadline)
                Text("\(month.remainingAmount.formatted(.currency(code: month.currency.isoCode)))")
                    .font(.title2)
                    .foregroundStyle(month.overSpent ? .red : .green)
            }
            
            Spacer()
            
            VStack(alignment: .trailing) {
                Text("Spent")
                    .font(.subheadline)
                Text("\(month.negativeSpentAmount.formatted(.currency(code: month.currency.isoCode)))")
                    .font(.title2)
                    .foregroundStyle(.red)
            }
        }
    }
}

// MARK: - Current Month Row View
struct CurrentMonthRowView: View {
    @State var currentMonth: Month
    
    var body: some View {
        VStack(alignment: .leading) {
            MonthRowView(month: currentMonth)
            RemainingSpentView(month: currentMonth)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(.ultraThinMaterial)
                )
        }
        .padding(16)
        .listRowInsets(.init(top: 0, leading: 0, bottom: 0, trailing: 0))
    }
}

// MARK: - New Month Button View
struct NewMonthButtonView: View {
    var body: some View {
        Button {
            
        } label: {
            Label("New Month", systemImage: "calendar.badge.plus")
                .tint(.white)
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .listRowInsets(.init(top: 0, leading: 0, bottom: 0, trailing: 0))
    }
}

// MARK: - List Background View
struct ListBackgroundView: View {
    var month: Month?
    
    @Environment(\.colorScheme) var colorScheme
    var opacity: Double {
        if colorScheme == .dark {
            0.4
        } else {
            0.2
        }
    }
    
    var gradient: LinearGradient {
        if let month = month {
            if month.overSpent {
                return LinearGradient(
                    colors: [
                        .red.opacity(opacity),
                        .purple.opacity(opacity/2),
                        .clear
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            } else {
                return LinearGradient(
                    colors: [
                        .green.opacity(opacity),
                        .blue.opacity(opacity/2),
                        .clear
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
        } else {
            return LinearGradient(
                colors: [
                    Color.clear,
                    Color.clear
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }
    
    var body: some View {
        Rectangle()
            .fill(gradient)
            .ignoresSafeArea()
    }
}
