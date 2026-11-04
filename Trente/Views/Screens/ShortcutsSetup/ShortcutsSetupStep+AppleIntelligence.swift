//
//  ShortcutsSetupStep+AppleIntelligence.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 03/11/2026.
//

import FoundationModels

extension ShortcutsSetupStep {
    // With Apple Intelligence ready, a new shortcut opens on "Describe a shortcut" and Edit leads to the editor.
    // While the model is still downloading, it opens straight in the editor.
    static func opensOnDescribeScreen(_ availability: SystemLanguageModel.Availability) -> Bool {
        switch availability {
        case .available:
            true
        case .unavailable:
            false
        }
    }
}
