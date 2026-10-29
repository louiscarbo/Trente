//
//  SortPickerView.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 25/06/2025.
//

import SwiftUI

struct SortPickerView: View {
    @Binding var sortOption: SortOption
    
    var body: some View {
        Menu {
            Section {
                Text("Sort by")
                    .font(.headline)
            }
            // Date
            Button {
                if sortOption == .dateAsc {
                    sortOption = .dateDesc
                } else {
                    sortOption = .dateAsc
                }
            } label: {
                HStack {
                    Text("Date")
                    if sortOption == .dateAsc || sortOption == .dateDesc {
                        Image(systemName: sortOption == .dateAsc ? "chevron.up" : "chevron.down")
                    }
                }
            }
            
            // Montant
            Button {
                if sortOption == .amountAsc {
                    sortOption = .amountDesc
                } else {
                    sortOption = .amountAsc
                }
            } label: {
                HStack {
                    Text("Amount")
                    if sortOption == .amountAsc || sortOption == .amountDesc {
                        Image(systemName: sortOption == .amountAsc ? "chevron.up" : "chevron.down")
                    }
                }
            }
            
            // Titre
            Button {
                if sortOption == .titleAsc {
                    sortOption = .titleDesc
                } else {
                    sortOption = .titleAsc
                }
            } label: {
                HStack {
                    Text("Title")
                    if sortOption == .titleAsc || sortOption == .titleDesc {
                        Image(systemName: sortOption == .titleAsc ? "chevron.up" : "chevron.down")
                    }
                }
            }
        } label: {
            Label("Sort", systemImage: "arrow.up.arrow.down")
        }
        .accessibilityValue(sortOption.accessibilityDescription)
    }
}

enum SortOption: CaseIterable {
    case dateAsc, dateDesc
    case amountAsc, amountDesc
    case titleAsc, titleDesc

    var accessibilityDescription: String {
        switch self {
        case .dateAsc: String(localized: "Date, oldest first")
        case .dateDesc: String(localized: "Date, newest first")
        case .amountAsc: String(localized: "Amount, lowest first")
        case .amountDesc: String(localized: "Amount, highest first")
        case .titleAsc: String(localized: "Title, A to Z")
        case .titleDesc: String(localized: "Title, Z to A")
        }
    }
}
