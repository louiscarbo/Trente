//
//  ProportionalStack.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 23/10/2026.
//

import SwiftUI

struct ProportionalStack: Layout {
    var axis: Axis = .vertical
    var spacing: CGFloat = DesignSystem.Spacing.small.rawValue

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        proposal.replacingUnspecifiedDimensions()
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let weights = subviews.map { $0[LayoutWeight.self] }
        let totalWeight = weights.reduce(0, +)
        guard totalWeight > 0 else { return }

        let totalSpacing = spacing * CGFloat(max(subviews.count - 1, 0))
        let availableLength = max((axis == .vertical ? bounds.height : bounds.width) - totalSpacing, 0)
        var offset = axis == .vertical ? bounds.minY : bounds.minX

        for (subview, weight) in zip(subviews, weights) {
            let length = availableLength * weight / totalWeight
            let origin = axis == .vertical
                ? CGPoint(x: bounds.minX, y: offset)
                : CGPoint(x: offset, y: bounds.minY)
            let size = axis == .vertical
                ? CGSize(width: bounds.width, height: length)
                : CGSize(width: length, height: bounds.height)
            subview.place(at: origin, anchor: .topLeading, proposal: ProposedViewSize(size))
            offset += length + spacing
        }
    }
}

private struct LayoutWeight: LayoutValueKey {
    static let defaultValue: CGFloat = 1
}

extension View {
    func layoutWeight(_ weight: CGFloat) -> some View {
        layoutValue(key: LayoutWeight.self, value: weight)
    }
}

#Preview {
    ProportionalStack {
        Color.blue.layoutWeight(5)
        Color.yellow.layoutWeight(3)
        Color.green.layoutWeight(2)
    }
    .padding()
}
