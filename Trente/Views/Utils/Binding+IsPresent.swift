//
//  Binding+IsPresent.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 27/10/2026.
//

import SwiftUI

extension Binding {
    func isPresent<Wrapped>() -> Binding<Bool> where Value == Wrapped? {
        Binding<Bool>(
            get: { wrappedValue != nil },
            set: { isPresented in
                if !isPresented { wrappedValue = nil }
            }
        )
    }
}
