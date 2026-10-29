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

            let edgeInset = gap / 2 + insetAmount
            let start = startDegrees * .pi / 180
            let end = endDegrees * .pi / 180
            let outerStart = start + edgeInset / outer
            let outerEnd = end - edgeInset / outer
            let innerStart = start + edgeInset / inner
            let innerEnd = end - edgeInset / inner
            guard innerEnd > innerStart else { return Path() }

            let corner = max(0, min(cornerRadius - insetAmount, (outer - inner) / 2, (innerEnd - innerStart) * inner / 2))
            let point = { (distance: Double, angle: Double) in
                CGPoint(x: center.x + distance * cos(angle), y: center.y + distance * sin(angle))
            }
            let along = { (origin: CGPoint, angle: Double, length: Double) in
                CGPoint(x: origin.x - length * sin(angle), y: origin.y + length * cos(angle))
            }
            let outerStartPoint = point(outer, outerStart)
            let outerEndPoint = point(outer, outerEnd)
            let innerStartPoint = point(inner, innerStart)
            let innerEndPoint = point(inner, innerEnd)

            var path = Path()
            path.move(to: CGPoint(
                x: (outerStartPoint.x + innerStartPoint.x) / 2,
                y: (outerStartPoint.y + innerStartPoint.y) / 2
            ))
            path.addArc(tangent1End: outerStartPoint, tangent2End: along(outerStartPoint, outerStart, 2 * corner + 1), radius: corner)
            path.addArc(
                center: center,
                radius: outer,
                startAngle: .radians(outerStart + corner / outer),
                endAngle: .radians(outerEnd - corner / outer),
                clockwise: false
            )
            path.addArc(tangent1End: outerEndPoint, tangent2End: innerEndPoint, radius: corner)
            path.addArc(tangent1End: innerEndPoint, tangent2End: along(innerEndPoint, innerEnd, -2 * corner - 1), radius: corner)
            path.addArc(
                center: center,
                radius: inner,
                startAngle: .radians(innerEnd - corner / inner),
                endAngle: .radians(innerStart + corner / inner),
                clockwise: true
            )
            path.addArc(tangent1End: innerStartPoint, tangent2End: outerStartPoint, radius: corner)
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
