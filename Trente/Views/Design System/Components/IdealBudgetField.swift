//
//  IdealBudgetField.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 23/10/2026.
//

import SwiftUI

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
    @Previewable @State var amountCents: Int = 2000_00
    @Previewable @FocusState var isFocused: Bool

    IdealBudgetField(amountCents: $amountCents, currency: Currencies.currency(for: "EUR")!, isFocused: $isFocused)
        .padding()
}
