//
//  TrenteApp.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 16/04/2025.
//

import SwiftUI
import SwiftData

@main
struct TrenteApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
//                .modelContainer(for: [
//                    Month.self
//                ])
                .modelContainer(DataProvider.shared.modelContainer)
        }
    }
}
