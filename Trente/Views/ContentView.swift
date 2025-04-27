//
//  ContentView.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 16/04/2025.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        MonthListView()
            .modelContainer(DataProvider.shared.modelContainer)
    }
}

#Preview {
    ContentView()
        .modelContainer(DataProvider.shared.modelContainer)
}
