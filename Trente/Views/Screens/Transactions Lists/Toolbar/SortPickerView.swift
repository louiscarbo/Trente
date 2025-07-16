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
            Image(systemName: "arrow.up.arrow.down")
        }
    }
}

enum SortOption: CaseIterable {
    case dateAsc, dateDesc
    case amountAsc, amountDesc
    case titleAsc, titleDesc

    var label: String {
        switch self {
        case .dateAsc:    return String(localized: "Date ↑")
        case .dateDesc:   return String(localized: "Date ↓")
        case .amountAsc:  return String(localized: "Montant ↑")
        case .amountDesc: return String(localized: "Montant ↓")
        case .titleAsc:   return String(localized: "Titre A→Z")
        case .titleDesc:  return String(localized: "Titre Z→A")
        }
    }
}
