//
//  MonthCurrencyPicker.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 23/10/2026.
//

import SwiftUI

struct MonthCurrencyPicker: View {
    @Binding var currency: Currency

    var body: some View {
        LabeledPicker(
            title: "Currency",
            selection: $currency,
            options: Currencies.availableCurrencies.sorted(by: { $0.displayName.localizedStandardCompare($1.displayName) == .orderedAscending })
        ) { currency in
            Label(currency.displayName, systemImage: currency.sfSymbolName ?? "xmark")
        }
    }
}

#Preview {
    @Previewable @State var currency: Currency = Currencies.currency(for: "EUR")!

    MonthCurrencyPicker(currency: $currency)
        .padding()
}
