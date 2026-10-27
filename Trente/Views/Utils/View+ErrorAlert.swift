//
//  View+ErrorAlert.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 27/10/2026.
//

import SwiftUI

extension View {
    func errorAlert(_ title: LocalizedStringKey = "An error occurred", message: Binding<String?>) -> some View {
        alert(title, isPresented: message.isPresent(), presenting: message.wrappedValue) { _ in
        } message: { message in
            Text(message)
        }
    }
}
