//
//  ExportButton+ShareSheet.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 23/10/2026.
//

import SwiftUI

#if os(iOS)
extension ExportButton {
    struct ShareSheet: UIViewControllerRepresentable {
        let url: URL
        let onComplete: () -> Void

        func makeUIViewController(context: Context) -> UIActivityViewController {
            let controller = UIActivityViewController(activityItems: [url], applicationActivities: nil)
            controller.completionWithItemsHandler = { _, _, _, _ in onComplete() }
            return controller
        }

        func updateUIViewController(_ controller: UIActivityViewController, context: Context) {}
    }
}
#endif
