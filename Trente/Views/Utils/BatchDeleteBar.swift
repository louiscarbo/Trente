//
//  BatchDeleteBar.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 04/11/2026.
//

import SwiftUI

private struct BatchDeleteBarModifier: ViewModifier {
    let isShown: Bool
    let selectedCount: Int
    let deleteTitle: String
    let reviewSections: () -> [BatchDeleteReviewSheet.Section]
    let onDelete: () -> Void

    @State private var isReviewing = false
    @State private var isDeleteConfirmed = false

    func body(content: Content) -> some View {
        content
            .safeAreaBar(edge: .bottom) {
                if isShown {
                    SelectionBar(selectedCount: selectedCount, deleteTitle: deleteTitle) {
                        isReviewing = true
                    }
                }
            }
            .sheet(isPresented: $isReviewing, onDismiss: deleteIfConfirmed) {
                BatchDeleteReviewSheet(deleteTitle: deleteTitle, sections: reviewSections()) {
                    isDeleteConfirmed = true
                    isReviewing = false
                }
            }
    }

    private func deleteIfConfirmed() {
        guard isDeleteConfirmed else { return }
        isDeleteConfirmed = false
        onDelete()
    }
}

extension View {
    func batchDeleteBar(
        isShown: Bool,
        selectedCount: Int,
        deleteTitle: String,
        reviewSections: @escaping () -> [BatchDeleteReviewSheet.Section],
        onDelete: @escaping () -> Void
    ) -> some View {
        modifier(
            BatchDeleteBarModifier(
                isShown: isShown,
                selectedCount: selectedCount,
                deleteTitle: deleteTitle,
                reviewSections: reviewSections,
                onDelete: onDelete
            )
        )
    }
}
