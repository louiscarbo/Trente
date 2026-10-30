//
//  BudgetRingsCard+Rings.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 29/10/2026.
//

import SwiftUI

extension BudgetRingsCard {
    struct Rings: View {
        let segments: [BudgetRings.Slice]
        let plan: [BudgetRings.Slice]
        let centerShare: Double?
        let centerCaption: String
        let isOverspent: Bool
        var showsCaptionAsAlert = false
        var maximumDiameter: CGFloat = 280

        private static let designDiameter = 220.0
        private static let planInnerRatio = 208 / designDiameter
        private static let segmentInnerRatio = 112 / designDiameter
        private static let segmentOuterRatio = 192 / designDiameter
        private static let labelRatio = 152 / designDiameter
        private static let minimumLabelledShare = 0.072

        var body: some View {
            GeometryReader { proxy in
                let diameter = min(proxy.size.width, proxy.size.height)
                chart(diameter: diameter)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .aspectRatio(1, contentMode: .fit)
            .frame(maxWidth: maximumDiameter, maxHeight: maximumDiameter)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text(verbatim: accessibilitySummary))
        }

        private func chart(diameter: CGFloat) -> some View {
            let scale = diameter / Self.designDiameter
            return ZStack {
                ring(
                    of: plan,
                    innerRatio: Self.planInnerRatio,
                    outerRatio: 1,
                    gap: 4 * scale,
                    cornerRadius: 3 * scale,
                    isPlan: true
                )
                ring(
                    of: segments,
                    innerRatio: Self.segmentInnerRatio,
                    outerRatio: Self.segmentOuterRatio,
                    gap: 4 * scale,
                    cornerRadius: 10 * scale,
                    isPlan: false
                )
                shareLabels(diameter: diameter)
                centerLabel(diameter: diameter)
            }
            .frame(width: diameter, height: diameter)
        }

        private func arcs(of slices: [BudgetRings.Slice]) -> [Arc] {
            var cursor = -90.0
            return slices.map { slice in
                let start = cursor
                cursor += slice.share * 360
                return Arc(slice: slice, startDegrees: start, endDegrees: cursor)
            }
        }

        @ViewBuilder
        private func ring(
            of slices: [BudgetRings.Slice],
            innerRatio: Double,
            outerRatio: Double,
            gap: Double,
            cornerRadius: Double,
            isPlan: Bool
        ) -> some View {
            if slices.allSatisfy({ $0.share == 0 }) {
                let track = RingSegment(startDegrees: 0, endDegrees: 360, innerRatio: innerRatio, outerRatio: outerRatio)
                track.fill(Color.gray)
                    .overlay { track.strokeBorder(Color.gray.darken(0.1), lineWidth: isPlan ? 0 : 3) }
                    .compositingGroup()
                    .opacity(0.18)
            } else {
                ZStack {
                    ForEach(arcs(of: slices)) { arc in
                        let shape = RingSegment(
                            startDegrees: arc.startDegrees,
                            endDegrees: arc.endDegrees,
                            innerRatio: innerRatio,
                            outerRatio: outerRatio,
                            gap: gap,
                            cornerRadius: cornerRadius
                        )
                        let style = SliceStyle(kind: arc.slice.kind, isPlan: isPlan)
                        shape.fill(style.fill)
                            .overlay {
                                if let border = style.border {
                                    shape.strokeBorder(border, lineWidth: 3)
                                }
                            }
                            .compositingGroup()
                            .opacity(style.opacity)
                    }
                }
            }
        }

        private func shareLabels(diameter: CGFloat) -> some View {
            let radius = diameter / 2 * Self.labelRatio
            return ZStack {
                ForEach(arcs(of: segments).filter { $0.slice.share >= Self.minimumLabelledShare && $0.slice.share < 0.995 }) { arc in
                    Text(arc.slice.share, format: .percent.precision(.fractionLength(0)))
                        .font(.footnote.weight(.semibold))
                        .monospacedDigit()
                        .foregroundStyle(SliceStyle(kind: arc.slice.kind, isPlan: false).label)
                        .contentTransition(.numericText(value: arc.slice.share))
                        .offset(x: radius * cos(arc.middleRadians), y: radius * sin(arc.middleRadians))
                }
            }
        }

        private func centerLabel(diameter: CGFloat) -> some View {
            VStack(spacing: 0) {
                Group {
                    if let centerShare {
                        Text(centerShare, format: .percent.precision(.fractionLength(0)))
                            .contentTransition(.numericText(value: centerShare))
                    } else {
                        Text(verbatim: "–")
                    }
                }
                .font(.title.bold())
                .monospacedDigit()
                .foregroundStyle(isOverspent ? .red : .primary)

                Text(centerCaption)
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(showsCaptionAsAlert ? .red : .secondary)
                    .contentTransition(.opacity)
            }
            .lineLimit(1)
            .minimumScaleFactor(0.6)
            .frame(maxWidth: diameter * Self.segmentInnerRatio * 0.9)
        }

        private var accessibilitySummary: String {
            let percent = FloatingPointFormatStyle<Double>.Percent().precision(.fractionLength(0))
            let center = centerShare.map { "\($0.formatted(percent)) \(centerCaption)" } ?? centerCaption
            let parts = segments
                .filter { $0.share > 0 }
                .map { "\(SliceStyle.name(of: $0.kind)) \($0.share.formatted(percent))" }
            return ([center] + parts).joined(separator: ", ")
        }
    }

    private struct Arc: Identifiable {
        let slice: BudgetRings.Slice
        let startDegrees: Double
        let endDegrees: Double

        var id: BudgetRings.SliceKind { slice.kind }
        var middleRadians: Double { (startDegrees + endDegrees) / 2 * .pi / 180 }
    }
}
