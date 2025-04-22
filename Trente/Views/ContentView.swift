//
//  ContentView.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 16/04/2025.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        MonthListViewVariation()
            .modelContainer(SampleDataProvider.shared.modelContainer)
    }
}

#Preview {
    ContentView()
        .modelContainer(SampleDataProvider.shared.modelContainer)
}
