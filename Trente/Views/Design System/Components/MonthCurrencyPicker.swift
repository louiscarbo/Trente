//
//  MonthCurrencyPicker.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 23/10/2026.
//

import SwiftUI

struct MonthCurrencyPicker: View {
    @Binding var currency: Currency

    @State private var isShowingCurrencies = false

    var body: some View {
        LabeledContent("Currency") {
            Button {
                isShowingCurrencies = true
            } label: {
                Label(currency.displayName, systemImage: currency.sfSymbolName ?? "banknote")
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .buttonStyle(.bordered)
            .tint(.secondary)
        }
        .sheet(isPresented: $isShowingCurrencies) {
            CurrencyPickerSheet(selection: $currency)
        }
    }
}

#Preview {
    @Previewable @State var currency: Currency = Currencies.currency(for: "EUR")!

    MonthCurrencyPicker(currency: $currency)
        .padding()
}
