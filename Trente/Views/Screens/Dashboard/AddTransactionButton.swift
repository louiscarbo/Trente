//
//  AddTransactionButton.swift
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

struct AddTransactionButton: View {
    let context: NewTransactionContext
    var wide: Bool = false
    
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
        }
        .buttonStyle(TrentePrimaryButtonStyle())
        .padding(.horizontal)
        .padding(.top)
        .frame(width: wide ? 400 : nil)
        #if os(macOS)
        .padding(.bottom)
        #else
        .sheet(isPresented: $isShowingNewTransactionSheet) {
            NewTransactionView(context: context)
        }
        #endif
    }
}
