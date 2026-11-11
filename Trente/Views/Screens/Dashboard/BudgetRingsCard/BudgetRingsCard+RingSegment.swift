//
//  BudgetRingsCard+RingSegment.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 29/10/2026.
//

import SwiftUI

extension BudgetRingsCard {
    struct RingSegment: InsettableShape {
        var startDegrees: Double
        var endDegrees: Double
        var innerRatio: Double
        var outerRatio: Double = 1
        var gap: Double = 0
        var cornerRadius: Double = 0
        var insetAmount: Double = 0

        private static let cornerHandleRatio = 0.5523

        var animatableData: AnimatablePair<Double, Double> {
            get { AnimatablePair(startDegrees, endDegrees) }
            set {
                startDegrees = newValue.first
                endDegrees = newValue.second
            }
        }

        func inset(by amount: CGFloat) -> RingSegment {
            var segment = self
            segment.insetAmount += amount
            return segment
        }

        func path(in rect: CGRect) -> Path {
            let center = CGPoint(x: rect.midX, y: rect.midY)
            let radius = min(rect.width, rect.height) / 2
            let outer = radius * outerRatio - insetAmount
            let inner = radius * innerRatio + insetAmount
            guard outer > inner, endDegrees > startDegrees else { return Path() }

            if endDegrees - startDegrees >= 359.99 {
                return fullRing(center: center, outer: outer, inner: inner)
            }

            let edgeAngle = gap / (radius * (outerRatio + innerRatio))
            let start = startDegrees * .pi / 180 + edgeAngle
            let end = endDegrees * .pi / 180 - edgeAngle
            let outerStart = start + insetAmount / outer
            let outerEnd = end - insetAmount / outer
            let innerStart = start + insetAmount / inner
            let innerEnd = end - insetAmount / inner
            guard innerEnd > innerStart else { return Path() }

            let corner = max(0, min(cornerRadius - insetAmount, (outer - inner) / 2, (innerEnd - innerStart) * inner / 2))
            let handle = corner * Self.cornerHandleRatio
            let point = { (distance: Double, angle: Double) in
                CGPoint(x: center.x + distance * cos(angle), y: center.y + distance * sin(angle))
            }
            let along = { (origin: CGPoint, angle: Double, length: Double) in
                CGPoint(x: origin.x - length * sin(angle), y: origin.y + length * cos(angle))
            }
            let outward = { (origin: CGPoint, angle: Double, length: Double) in
                CGPoint(x: origin.x + length * cos(angle), y: origin.y + length * sin(angle))
            }
            let outerArcStart = outerStart + corner / outer
            let outerArcEnd = outerEnd - corner / outer
            let innerArcStart = innerStart + corner / inner
            let innerArcEnd = innerEnd - corner / inner
            let startEdgeOuter = outward(point(outer, outerStart), start, -corner)
            let endEdgeOuter = outward(point(outer, outerEnd), end, -corner)
            let endEdgeInner = outward(point(inner, innerEnd), end, corner)
            let startEdgeInner = outward(point(inner, innerStart), start, corner)
            let outerArcStartPoint = point(outer, outerArcStart)
            let outerArcEndPoint = point(outer, outerArcEnd)
            let innerArcStartPoint = point(inner, innerArcStart)
            let innerArcEndPoint = point(inner, innerArcEnd)

            var path = Path()
            path.move(to: startEdgeOuter)
            path.addCurve(
                to: outerArcStartPoint,
                control1: outward(startEdgeOuter, start, handle),
                control2: along(outerArcStartPoint, outerArcStart, -handle)
            )
            path.addArc(
                center: center,
                radius: outer,
                startAngle: .radians(outerArcStart),
                endAngle: .radians(outerArcEnd),
                clockwise: false
            )
            path.addCurve(
                to: endEdgeOuter,
                control1: along(outerArcEndPoint, outerArcEnd, handle),
                control2: outward(endEdgeOuter, end, handle)
            )
            path.addLine(to: endEdgeInner)
            path.addCurve(
                to: innerArcEndPoint,
                control1: outward(endEdgeInner, end, -handle),
                control2: along(innerArcEndPoint, innerArcEnd, handle)
            )
            path.addArc(
                center: center,
                radius: inner,
                startAngle: .radians(innerArcEnd),
                endAngle: .radians(innerArcStart),
                clockwise: true
            )
            path.addCurve(
                to: startEdgeInner,
                control1: along(innerArcStartPoint, innerArcStart, -handle),
                control2: outward(startEdgeInner, start, -handle)
            )
            path.closeSubpath()
            return path
        }

        private func fullRing(center: CGPoint, outer: Double, inner: Double) -> Path {
            var path = Path()
            path.addArc(center: center, radius: outer, startAngle: .zero, endAngle: .degrees(360), clockwise: false)
            path.closeSubpath()
            path.addArc(center: center, radius: inner, startAngle: .degrees(360), endAngle: .zero, clockwise: true)
            path.closeSubpath()
            return path
        }
    }
}
