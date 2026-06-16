//
//  EditableAmountRow.swift
//  Trente
//

import SwiftUI

struct EditableAmountRow: View {
    var isEditing: Bool
    @Binding var amountCents: Int
    var currency: Currency
    var focus: FocusState<Bool>.Binding

    @Namespace private var animation

    var body: some View {
        if isEditing {
            CurrencyTextField(amountCents: $amountCents, currency: currency)
                .focused(focus)
                .matchedGeometryEffect(id: "amount", in: animation, anchor: .leading)
                .padding(8)
                .background {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(.gray.opacity(0.2))
                }
        } else {
            Text(currency.roundFormatter.string(from: NSNumber(value: Double(amountCents) / 100.0)) ?? "")
                .font(.subheadline)
                .padding(.vertical, 4)
                .padding(.horizontal, 8)
                .background {
                    Capsule()
                        .fill(.gray.opacity(0.2))
                        .stroke(.primary.opacity(0.2))
                }
                .matchedGeometryEffect(id: "amount", in: animation, anchor: .leading)
        }
    }
}
