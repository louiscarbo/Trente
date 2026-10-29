//
//  TrenteHelpCommands.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 24/10/2026.
//

#if os(macOS)
import SwiftUI

struct TrenteHelpCommands: Commands {
    @Environment(\.openWindow) private var openWindow

    var body: some Commands {
        CommandGroup(replacing: .help) {
            Button("Trente Help") {
                openWindow(id: WindowIdentifiers.help)
            }
            .keyboardShortcut("?", modifiers: .command)
        }
    }
}
#endif
