//
//  ViewUtils.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 22/04/2025.
//

import Foundation
import SwiftUI

extension Color {
    /// Create a Color from a 24‑bit hex code (e.g. 0xFAF6F1) plus optional opacity.
    init(hex: Int, opacity: Double = 1) {
        let red   = Double((hex >> 16) & 0xFF) / 255
        let green = Double((hex >> 8)  & 0xFF) / 255
        let blue  = Double(hex         & 0xFF) / 255
        self.init(.sRGB, red: red, green: green, blue: blue, opacity: opacity)
    }
}
