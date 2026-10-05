//
//  TrenteGaugeStyle.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 24/04/2025.
//

import SwiftUI

// MARK: TrenteGaugeStyle
struct TrenteGaugeStyle: GaugeStyle {
    var color: Color
    var diameter: CGFloat = 100
    var highlightsRemaining = false

    var gradient: Gradient {
        Gradient(colors: [adjustHue(of: color, by: -20), color])
    }

    func makeBody(configuration: Configuration) -> some View {
        let strokeWidth = diameter / 6
        let splitPoint = 0.75 * configuration.value
        let roundStroke = StrokeStyle(lineWidth: strokeWidth, lineCap: .round)
        
        ZStack {
                Circle()
                    .trim(from: 0, to: 0.75)
                    .stroke(gradient.opacity(0.3), style: roundStroke)
                    .rotationEffect(.degrees(135))
                
                Circle()
                    .trim(from: 0, to: splitPoint)
                    .stroke(gradient, style: roundStroke)
                    .rotationEffect(.degrees(135))
                    .opacity(highlightsRemaining ? 0 : 1)
                
                Circle()
                    .trim(from: 0, to: 0.75)
                    .stroke(gradient, style: roundStroke)
                    .rotationEffect(.degrees(135))
                    .mask {
                        Rectangle()
                            .padding(-strokeWidth)
                            .overlay {
                                Circle()
                                    .trim(from: 0, to: splitPoint)
                                    .stroke(.black, style: roundStroke)
                                    .rotationEffect(.degrees(135))
                                    .frame(width: diameter, height: diameter)
                                    .blendMode(.destinationOut)
                            }
                            .compositingGroup()
                    }
                    .opacity(highlightsRemaining ? 1 : 0)
                
                Circle()
                    .fill(Color.white)
                    .frame(width: 0.6*strokeWidth.rounded(), height: 0.6*strokeWidth.rounded())
                    .offset(y: -1 * diameter / 2)
                    .rotationEffect(.degrees(225 + 270 * configuration.value))
                
            VStack(spacing: 0) {
                configuration.currentValueLabel
                    .font(.headline)
                Divider()
                    .frame(width: diameter / 2, height: 1)
                    .padding(2)
                configuration.maximumValueLabel
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: diameter, height: diameter)
    }
    
    func adjustHue(of color: Color, by degrees: Double) -> Color {
        #if os(iOS)
        let uiColor = UIColor(color)
        var hue: CGFloat = 0
        var saturation: CGFloat = 0
        var brightness: CGFloat = 0
        var alpha: CGFloat = 0

        uiColor.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)
        hue = CGFloat((Double(hue) + degrees / 360).truncatingRemainder(dividingBy: 1))
        if hue < 0 { hue += 1 }

        return Color(hue: Double(hue), saturation: Double(saturation), brightness: Double(brightness) - 0.1, opacity: Double(alpha))
        #else
        return color
        #endif
    }
}
