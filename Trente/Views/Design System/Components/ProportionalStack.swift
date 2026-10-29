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
    var minimumLength: CGFloat = 0

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        CGSize(width: finiteLength(proposal.width), height: finiteLength(proposal.height))
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let weights = subviews.map { $0[LayoutWeight.self] }
        guard weights.reduce(0, +) > 0 else { return }

        let totalSpacing = spacing * CGFloat(max(subviews.count - 1, 0))
        let availableLength = max((axis == .vertical ? bounds.height : bounds.width) - totalSpacing, 0)
        var offset = axis == .vertical ? bounds.minY : bounds.minX

        for (subview, length) in zip(subviews, lengths(for: weights, availableLength: availableLength)) {
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

    func lengths(for weights: [CGFloat], availableLength: CGFloat) -> [CGFloat] {
        let totalWeight = weights.reduce(0, +)
        let weightedLengths = weights.map { weight in availableLength * weight / totalWeight }
        let isRaised = weightedLengths.map { length in length < minimumLength }
        let raisedCount = isRaised.filter { $0 }.count
        let otherWeight = zip(weights, isRaised).reduce(0) { total, pair in pair.1 ? total : total + pair.0 }
        guard raisedCount > 0, otherWeight > 0 else { return weightedLengths }

        let otherLength = max(availableLength - minimumLength * CGFloat(raisedCount), 0)
        return zip(weights, isRaised).map { weight, raised in
            raised ? minimumLength : otherLength * weight / otherWeight
        }
    }

    private func finiteLength(_ length: CGFloat?) -> CGFloat {
        guard let length, length.isFinite else { return 0 }
        return length
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
    VStack(spacing: 20) {
        ProportionalStack {
            Color.blue.layoutWeight(5)
            Color.yellow.layoutWeight(3)
            Color.green.layoutWeight(2)
        }
        ProportionalStack(axis: .horizontal, spacing: 3, minimumLength: 3) {
            Color.blue.layoutWeight(0.98)
            Color.yellow.layoutWeight(0.01)
            Color.green.layoutWeight(0.01)
        }
        .frame(height: 10)
    }
    .padding()
}
