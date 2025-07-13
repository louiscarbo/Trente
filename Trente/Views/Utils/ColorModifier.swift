//
//  ColorModifier.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 13/07/2025.
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

// MARK: - Color + Darken
public extension Color {
    // MARK: Darken
    /// Returns a copy of the color with *brightness* lowered and *saturation* increased.
    ///
    /// - Parameters:
    ///   - brightnessDrop: How much to subtract from the original brightness.
    ///     Supply a value in **0…1** (default `0.15`).
    ///   - saturationBoost: How much to add to the original saturation.
    ///     Supply a value in **0…1** (default `0.10`).
    ///
    /// If the color cannot be converted to HSB/HSV (rare, but possible with
    /// certain system colors), the original color is returned unchanged.
    func darken(
        brightnessDrop: CGFloat = 0.15,
        saturationBoost: CGFloat = 0.10
    ) -> Color {
        #if canImport(UIKit)
        guard let uiColor = UIColor(self).hsbAdjusted(
            brightnessDrop: brightnessDrop,
            saturationBoost: saturationBoost
        ) else { return self }
        return Color(uiColor)
        
        #elseif canImport(AppKit)
        guard let nsColor = NSColor(self).hsbAdjusted(
            brightnessDrop: brightnessDrop,
            saturationBoost: saturationBoost
        ) else { return self }
        return Color(nsColor)
        
        #else
        // watchOS/tvOS fall-back via CGColor
        guard
            let cgColor   = self.cgColor,
            let adjusted  = cgColor.hsbAdjusted(
                brightnessDrop: brightnessDrop,
                saturationBoost: saturationBoost
            )
        else { return self }
        return Color(adjusted)
        #endif
    }
    
    // MARK: Lighten
    /// Returns a copy of the color with *brightness* increased and *saturation* reduced.
    ///
    /// - Parameters:
    ///   - brightnessBoost: How much to add to the original brightness.
    ///     Supply a value in **0…1** (default `0.15`).
    ///   - saturationDrop: How much to subtract from the original saturation.
    ///     Supply a value in **0…1** (default `0.10`).
    ///
    /// If the color cannot be converted to HSB/HSV (rare, but possible with
    /// certain system colors), the original color is returned unchanged.
    func lighten(
        brightnessBoost: CGFloat = 0.15,
        saturationDrop: CGFloat = 0.10
    ) -> Color {
        
        // We can reuse the existing hsbAdjusted helper by passing
        // negative values (adding brightness, reducing saturation).
        return self.darken(
            brightnessDrop: -brightnessBoost,
            saturationBoost: -saturationDrop
        )
    }
    
    // MARK: Scalar convenience overloads
    /// Darkens the color by a single scalar `amount` between 0 and 1.
    /// Internally this lowers brightness and raises saturation by `amount`.
    /// Passing 0 leaves the color unchanged; passing 1 applies the maximum tweak.
    func darken(_ amount: CGFloat) -> Color {
        let clamped = max(0, min(amount, 1))
        return darken(brightnessDrop: clamped, saturationBoost: clamped)
    }
    
    /// Lightens the color by a single scalar `amount` between 0 and 1.
    /// Internally this raises brightness and lowers saturation by `amount`.
    /// Passing 0 leaves the color unchanged; passing 1 applies the maximum tweak.
    func lighten(_ amount: CGFloat) -> Color {
        let clamped = max(0, min(amount, 1))
        return darken(brightnessDrop: -clamped, saturationBoost: -clamped * 1)
    }
}

// MARK: - Platform helpers
#if canImport(UIKit)
private extension UIColor {
    func hsbAdjusted(brightnessDrop: CGFloat,
                     saturationBoost: CGFloat) -> UIColor? {
        var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        guard getHue(&h, saturation: &s, brightness: &b, alpha: &a) else { return nil }
        return UIColor(
            hue: h,
            saturation: min(s + saturationBoost, 1),
            brightness: max(b - brightnessDrop, 0),
            alpha: a
        )
    }
}
#elseif canImport(AppKit)
private extension NSColor {
    func hsbAdjusted(brightnessDrop: CGFloat,
                     saturationBoost: CGFloat) -> NSColor? {
        guard let conv = usingColorSpace(.deviceRGB) else { return nil }
        var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        guard conv.getHue(&h, saturation: &s, brightness: &b, alpha: &a) else { return nil }
        return NSColor(
            hue: h,
            saturation: min(s + saturationBoost, 1),
            brightness: max(b - brightnessDrop, 0),
            alpha: a
        )
    }
}
#endif

private extension CGColor {
    /// Minimal HSB adjustment using Core Graphics (for tvOS/watchOS fallback).
    func hsbAdjusted(brightnessDrop: CGFloat,
                     saturationBoost: CGFloat) -> CGColor? {
        guard
            let comps = components,
            comps.count >= 3
        else { return nil }
        // naïve RGB→HSB conversion
        let r = comps[0], g = comps[1], b = comps[2]
        let maxVal = max(r, g, b), minVal = min(r, g, b)
        var h: CGFloat = 0, s: CGFloat = 0, v: CGFloat = maxVal
        let delta = maxVal - minVal

        if maxVal != 0 { s = delta / maxVal }
        if delta != 0 {
            if maxVal == r {
                h = (g - b) / delta + (g < b ? 6 : 0)
            } else if maxVal == g {
                h = (b - r) / delta + 2
            } else {
                h = (r - g) / delta + 4
            }
            h /= 6
        }

        // adjust
        s = min(s + saturationBoost, 1)
        v = max(v - brightnessDrop, 0)

        // convert back HSB→RGB
        let i = floor(h * 6)
        let f = h * 6 - i
        let p = v * (1 - s)
        let q = v * (1 - f * s)
        let t = v * (1 - (1 - f) * s)
        let (nr, ng, nb): (CGFloat, CGFloat, CGFloat)
        switch Int(i) % 6 {
        case 0: (nr, ng, nb) = (v, t, p)
        case 1: (nr, ng, nb) = (q, v, p)
        case 2: (nr, ng, nb) = (p, v, t)
        case 3: (nr, ng, nb) = (p, q, v)
        case 4: (nr, ng, nb) = (t, p, v)
        default:(nr, ng, nb) = (v, p, q)
        }
        return CGColor(red: nr, green: ng, blue: nb, alpha: comps.count == 4 ? comps[3] : 1)
    }
}

#Preview {
    VStack(spacing: 0) {
        let color = Color.pink
        Rectangle()
            .foregroundStyle(color.lighten(0.3))
        
        Rectangle()
            .foregroundStyle(color)
        
        Rectangle()
            .foregroundStyle(color.darken(0.05))
    }
    .ignoresSafeArea()
}
