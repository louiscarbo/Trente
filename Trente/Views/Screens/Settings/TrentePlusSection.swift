//
//  TrentePlusSection.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 24/10/2026.
//

import SwiftUI

struct TrentePlusSection: View {
    let isSubscribed: Bool
    let onDiscover: () -> Void
    let onManage: () -> Void

    var body: some View {
        Section {
            VStack(alignment: .leading, spacing: 0) {
                if isSubscribed {
                    Text("You have everything in the Trente+ column.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .padding([.horizontal, .top])
                        .padding(.bottom, 4)
                }
                ComparisonTable(comparisons: TrentePlusBenefit.comparisons)
                Group {
                    if isSubscribed {
                        Button("Manage Subscription", action: onManage)
                            .buttonStyle(TrenteSecondaryButtonStyle())
                    } else {
                        Button("See Plans", action: onDiscover)
                            .buttonStyle(TrentePrimaryButtonStyle())
                    }
                }
                .padding()
            }
            .listRowInsets(EdgeInsets())
        } header: {
            Text("Trente+")
        }
    }
}

#Preview {
    Form {
        TrentePlusSection(isSubscribed: false, onDiscover: {}, onManage: {})
        TrentePlusSection(isSubscribed: true, onDiscover: {}, onManage: {})
    }
    .formStyle(.grouped)
}
