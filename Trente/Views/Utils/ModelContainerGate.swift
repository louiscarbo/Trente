//
//  ModelContainerGate.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 22/10/2026.
//

import SwiftUI
import SwiftData

struct ModelContainerGate<Content: View>: View {
    let container: Result<ModelContainer, any Error>
    @ViewBuilder let content: () -> Content

    var body: some View {
        switch container {
        case .success(let container):
            content()
                .modelContainer(container)
        case .failure(let error):
            StoreUnavailableView(errorDetails: String(describing: error))
        }
    }
}
