//
//  MonthView+AddTransactionButton.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 27/10/2026.
//

import SwiftUI
import SwiftData

extension Month {
    var newTransactionContext: NewTransactionContext {
        NewTransactionContext(currency: currency, monthID: persistentModelID)
    }
}

extension MonthView {
    struct AddTransactionButton: View {
        let context: NewTransactionContext
        var slotWidth: CGFloat?

        @State private var isShowingNewTransactionSheet: Bool = false
        @Environment(\.openWindow) private var openWindow

        var body: some View {
            Button {
                #if os(iOS)
                isShowingNewTransactionSheet = true
                #else
                openWindow(id: WindowIdentifiers.newTransaction, value: context)
                #endif
            } label: {
                Label("Add Transaction", systemImage: "plus")
                    .font(.title)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .padding(.horizontal, 12)
            }
            .buttonStyle(TrentePrimaryButtonStyle())
            .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
            .padding(.horizontal)
            .padding(.top)
            .frame(width: slotWidth)
            #if os(macOS)
            .padding(.bottom)
            #else
            .sheet(isPresented: $isShowingNewTransactionSheet) {
                NewTransactionView(context: context)
            }
            #endif
        }
    }
}
