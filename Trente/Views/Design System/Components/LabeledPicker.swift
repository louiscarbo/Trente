//
//  LabeledPicker.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 02/08/2025.
//

import SwiftUI

/// A reusable view that presents a labeled picker, suitable for use in a `Form`.
struct LabeledPicker<SelectionValue: Identifiable & Hashable, Content: View>: View {
    let title: String
    @Binding var selection: SelectionValue
    let options: [SelectionValue]
    @ViewBuilder let content: (SelectionValue) -> Content
    
    @Environment(\.sizeCategory) private var sizeCategory

    var body: some View {
        let titleText = Text(title)
            .accessibilityHidden(true)
            .fixedSize(horizontal: true, vertical: false)
        
        let picker = Picker(title, selection: $selection) {
            ForEach(options) { option in
                content(option)
                    .tag(option)
            }
        }
        .pickerStyle(.automatic)
        .tint(.primary)
        
        if sizeCategory.isAccessibilityCategory {
            VStack {
                titleText
                picker
            }
        } else {
            HStack {
                #if os(iOS)
                titleText
                Spacer()
                    .frame(minWidth: 0)
                #endif
                picker
                    .fixedSize(horizontal: true, vertical: false)
            }
        }
    }
}

#Preview {
    @Previewable @State var frequency: RecurrenceFrequency = .weekly
    @Previewable @State var currency: Currency = Currencies.availableCurrencies[0]
    
    NavigationStack {
        ScrollView {
            GroupBox {
                LabeledPicker(
                    title: "Frequency",
                    selection: $frequency,
                    options: RecurrenceFrequency.allCases
                ) { frequency in
                    Text(frequency.displayName)
                }
                
                LabeledPicker(
                    title: "Currency",
                    selection: $currency,
                    options: Currencies.availableCurrencies
                ) { currency in
                    Label(currency.localizedName, systemImage: currency.sfSymbolName ?? "xmark")
                }
            }
            .groupBoxStyle(TrenteGroupBoxStyle())
            .padding()
        }
        .navigationTitle("LabeledPicker")
    }
}
