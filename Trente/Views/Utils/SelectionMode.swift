//
//  SelectionMode.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 30/10/2026.
//

import SwiftUI

extension View {
    func selectionMode<ID: Hashable>(
        _ selection: Binding<RowSelection<ID>>,
        visibleIDs: [ID],
        isAvailable: Bool = true,
        deleteTitle: String,
        reviewSections: @escaping () -> [BatchDeleteReviewSheet.Section],
        onDelete: @escaping () -> Void
    ) -> some View {
        let isActive = selection.wrappedValue.isActive
        let areAllSelected = selection.wrappedValue.areAllSelected(visibleIDs)
        return navigationBarBackButtonHidden(isActive)
            #if os(iOS)
            .environment(\.editMode, .constant(isActive ? .active : .inactive))
            #endif
            .toolbar {
                if isActive {
                    ToolbarItem(placement: .cancellationAction) {
                        Button(areAllSelected ? "Deselect All" : "Select All") {
                            selection.wrappedValue.toggleAll(visibleIDs)
                        }
                    }
                    ConfirmToolbarItem {
                        withAnimation {
                            selection.wrappedValue.end()
                        }
                    }
                } else if isAvailable {
                    ToolbarItem(placement: .primaryAction) {
                        Button("Select") {
                            withAnimation {
                                selection.wrappedValue.begin()
                            }
                        }
                        .disabled(visibleIDs.isEmpty)
                    }
                }
            }
            .batchDeleteBar(
                isShown: isActive,
                selectedCount: selection.wrappedValue.selectedCount(in: visibleIDs),
                deleteTitle: deleteTitle,
                reviewSections: reviewSections,
                onDelete: onDelete
            )
    }
}
