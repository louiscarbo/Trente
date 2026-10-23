//
//  MonthDetailsFields.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 23/10/2026.
//

import SwiftUI

struct MonthStartDatePicker: View {
    @Binding var startDate: Date

    var body: some View {
        DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
            .datePickerStyle(.compact)
    }
}

struct MonthCurrencyPicker: View {
    @Binding var currency: Currency

    var body: some View {
        LabeledPicker(
            title: "Currency",
            selection: $currency,
            options: Currencies.availableCurrencies.sorted(by: { $0.localizedName < $1.localizedName })
        ) { currency in
            Label(currency.localizedName, systemImage: currency.sfSymbolName ?? "xmark")
        }
    }
}

struct IdealBudgetField: View {
    @Binding var amountCents: Int
    let currency: Currency
    var isFocused: FocusState<Bool>.Binding

    var body: some View {
        CurrencyTextField(
            amountCents: $amountCents,
            currency: currency
        )
        .focused(isFocused)
        .font(.title)
        .bold()
        .multilineTextAlignment(.center)
    }
}

#Preview {
    @Previewable @State var startDate: Date = .now
    @Previewable @State var currency: Currency = Currencies.currency(for: "EUR")!
    @Previewable @State var amountCents: Int = 2000_00
    @Previewable @FocusState var isFocused: Bool

    VStack(spacing: .medium) {
        MonthStartDatePicker(startDate: $startDate)
        MonthCurrencyPicker(currency: $currency)
        IdealBudgetField(amountCents: $amountCents, currency: currency, isFocused: $isFocused)
    }
    .padding()
}
