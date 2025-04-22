//
//  FiltersView.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 20/04/2025.
//

import SwiftUI

import SwiftUI

struct FiltersView: View {
    @Binding var lowerBound: Date
    @Binding var upperBound: Date
    let availableCategories: Set<String>
    @Binding var selectedCategories: Set<String>
    @Binding var sortOption: SortOption

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Date range pickers
            HStack {
                DatePicker(
                    "De",
                    selection: $lowerBound,
                    displayedComponents: .date
                )
                DatePicker(
                    "À",
                    selection: $upperBound,
                    displayedComponents: .date
                )
            }

            // Category filter buttons
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    ForEach(Array(availableCategories), id: \.self) { cat in
                        Button(cat) {
                            if selectedCategories.contains(cat) {
                                selectedCategories.remove(cat)
                            } else {
                                selectedCategories.insert(cat)
                            }
                        }
                        .padding(6)
                        .background(
                            selectedCategories.contains(cat)
                                ? Color.accentColor.opacity(0.2)
                                : Color.clear
                        )
                        .cornerRadius(6)
                    }
                }
            }

            // Sort picker
            Picker("Trier par", selection: $sortOption) {
                ForEach(SortOption.allCases, id: \.self) { opt in
                    Text(opt.label).tag(opt)
                }
            }
            .pickerStyle(.segmented)
        }
    }
}

// MARK: - SortOption



#Preview {
    @Previewable @State var lowerBound = Calendar.current.date(byAdding: .month, value: -1, to: Date())!
    @Previewable @State var upperBound = Date()
    @Previewable @State var selectedCategories: Set<String> = ["Food", "Rent"]
    @Previewable @State var sortOption: SortOption = .dateDesc

    FiltersView(
        lowerBound: $lowerBound,
        upperBound: $upperBound,
        availableCategories: ["Food", "Rent", "Salary", "Shopping"],
        selectedCategories: $selectedCategories,
        sortOption: $sortOption
    )
}
