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
        VStack(spacing: 4) {
            CurrencyTextField(
                amountCents: $amountCents,
                currency: currency
            )
            .focused(isFocused)
            .font(.title)
            .bold()
            .multilineTextAlignment(.center)

            Text("After taxes, before rent and bills.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }
}

#Preview {
    @Previewable @State var amountCents: Int = 2000_00
    @Previewable @FocusState var isFocused: Bool

    IdealBudgetField(amountCents: $amountCents, currency: Currencies.currency(for: "EUR")!, isFocused: $isFocused)
        .padding()
}
