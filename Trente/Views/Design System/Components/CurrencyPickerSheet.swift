//
//  CurrencyPickerSheet.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 02/11/2026.
//

import SwiftUI

struct CurrencyPickerSheet: View {
    @Binding var selection: Currency

    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""

    private var currencies: [Currency] {
        Currencies.matching(searchText)
    }

    var body: some View {
        NavigationStack {
            List(currencies) { currency in
                Button {
                    selection = currency
                    dismiss()
                } label: {
                    row(for: currency)
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(currency.isoCode == selection.isoCode ? .isSelected : [])
            }
            .overlay {
                if currencies.isEmpty {
                    ContentUnavailableView.search(text: searchText)
                }
            }
            .searchable(text: $searchText, prompt: "Search currencies")
            .navigationTitle("Currency")
            .inlineNavigationBarTitleDisplayMode()
            .toolbar {
                CloseToolbarItem { dismiss() }
            }
        }
        #if os(macOS)
        .frame(minHeight: 480)
        #endif
    }

    private func row(for currency: Currency) -> some View {
        HStack {
            Label(currency.displayName, systemImage: currency.sfSymbolName ?? "banknote")
            Spacer()
            if currency.isoCode == selection.isoCode {
                Image(systemName: "checkmark")
                    .foregroundStyle(.tint)
                    .accessibilityHidden(true)
            }
        }
        .contentShape(.rect)
    }
}

#Preview {
    @Previewable @State var currency: Currency = Currencies.currency(for: "EUR")!

    CurrencyPickerSheet(selection: $currency)
}
