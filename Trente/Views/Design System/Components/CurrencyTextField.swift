//
//  CurrencyTextField.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 02/08/2025.
//

import SwiftUI

struct CurrencyTextField: View {
    @Binding var amountCents: Int
    let currency: Currency
    
    @State private var amountText: String = ""
    
    var body: some View {
        TextField(
            "",
            text: $amountText,
            prompt: Text(0, format: .currency(code: currency.isoCode))
        )
        #if os(iOS)
        .keyboardType(.decimalPad)
        #endif
        .onChange(of: amountText) { oldValue, newValue in
            processAmountTextChange(newValue: newValue, oldValue: oldValue)
        }
        .onAppear {
            updateText(from: amountCents)
        }
        .onChange(of: amountCents) { _, newAmount in
            let expectedText = createText(from: newAmount)
            if amountText != expectedText {
                amountText = expectedText
            }
        }
    }
    
    /// Creates the correct string representation (with sign) from a cents value.
    private func createText(from cents: Int) -> String {
        guard cents != 0 else { return "" }
        
        let isNegative = cents < 0
        let absoluteValue = Double(abs(cents)) / 100.0
        
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.locale = Locale.current
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 2
        formatter.groupingSeparator = ""
        
        let unsignedText = formatter.string(from: NSNumber(value: absoluteValue)) ?? ""
        
        return isNegative ? "-" + unsignedText : unsignedText
    }
    
    /// A convenience wrapper for `createText` to update the state.
    private func updateText(from cents: Int) {
        amountText = createText(from: cents)
    }
    
    /// Converts a string (ignoring signs) from the text field into an integer of absolute cents.
    private func textToAbsCents(_ text: String) -> Int {
        let unsignedText = text.trimmingCharacters(in: .init(charactersIn: "+-"))
        let formatter = NumberFormatter()
        formatter.locale = .current
        formatter.numberStyle = .decimal
        guard let number = formatter.number(from: unsignedText) else { return 0 }

        let decimalAmount = number.decimalValue
        var cents = decimalAmount * 100
        
        var roundedCents = Decimal()
        NSDecimalRound(&roundedCents, &cents, 0, .plain)
        
        return NSDecimalNumber(decimal: roundedCents).intValue
    }
    
    /// Validates user input and updates the `amountCents` binding.
    private func processAmountTextChange(newValue: String, oldValue: String) {
        let unsignedText = newValue.trimmingCharacters(in: .init(charactersIn: "+-"))
        let decimalSep = Locale.current.decimalSeparator ?? "."
        
        // Validation: prevent more than one decimal separator.
        if unsignedText.filter({ String($0) == decimalSep }).count > 1 {
            amountText = oldValue
            return
        }
        
        // Validation: enforce max two decimal places.
        if let sepIndex = unsignedText.firstIndex(of: Character(decimalSep)) {
            let fraction = unsignedText[unsignedText.index(after: sepIndex)...]
            if fraction.count > 2 {
                amountText = oldValue
                return
            }
        }
        
        // Calculate the new absolute value in cents.
        let absCents = textToAbsCents(newValue)
        
        // Update the binding, preserving the original sign.
        if amountCents < 0 {
            amountCents = -absCents
        } else {
            amountCents = absCents
        }
    }
}

#Preview {
    @Previewable @State var amount: Int = -12345 // Initial value: -123.45 EUR
    
    let euro = Currencies.availableCurrencies.first { $0.isoCode == "EUR" }!
    
    VStack(spacing: 20) {
        Text("Bound Value: \(amount)")
            .font(.headline)
        
        CurrencyTextField(amountCents: $amount, currency: euro)
            .font(.system(size: 60, weight: .bold))
            .multilineTextAlignment(.center)
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(10)
        
        HStack {
            Button("Set to 50.00") { amount = 5000 }
            Button("Set to -25.50") { amount = -2550 }
            Button("Set to 0") { amount = 0 }
        }
        .buttonStyle(.bordered)
    }
    .padding()
}
