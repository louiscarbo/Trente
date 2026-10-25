//
//  Pasteboard.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 24/10/2026.
//

#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

enum Pasteboard {
    @MainActor
    static func copy(_ string: String) {
        #if os(iOS)
        UIPasteboard.general.string = string
        #elseif os(macOS)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(string, forType: .string)
        #endif
    }
}
