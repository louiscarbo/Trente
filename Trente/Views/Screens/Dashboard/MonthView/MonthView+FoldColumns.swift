//
//  MonthView+FoldColumns.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 31/10/2026.
//

import CoreGraphics

extension MonthView {
    struct FoldColumns: Equatable {
        static let leadingMargin: CGFloat = 20
        static let trailingMargin: CGFloat = 16
        static let minimumWidth: CGFloat = 300

        let leadingWidth: CGFloat
        let trailingWidth: CGFloat
        let spacing: CGFloat

        static func around(fold: CGRect, containerWidth: CGFloat) -> FoldColumns? {
            guard fold.height > fold.width else { return nil }
            let leadingWidth = fold.minX - leadingMargin
            let trailingWidth = containerWidth - fold.maxX - trailingMargin
            guard min(leadingWidth, trailingWidth) >= minimumWidth else { return nil }
            return FoldColumns(leadingWidth: leadingWidth, trailingWidth: trailingWidth, spacing: fold.width)
        }
    }
}
