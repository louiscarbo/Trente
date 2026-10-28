//
//  DetailEditScaffold.swift
//  Trente
//

import SwiftUI

struct DetailEditScaffold<Content: View>: View {
    @Environment(\.dismiss) private var dismiss

    var title: String
    var editingTitle: String = String(localized: "Editing")
    var cancelSystemImage: String = "arrow.uturn.backward"
    @Binding var isEditing: Bool
    @Binding var validationErrors: [String]
    @Binding var deleteError: String?

    var deleteSectionTitle: String? = nil
    var isDoneDisabled: Bool = false
    var keyboardDismissVisible: Bool
    var onDismissKeyboard: () -> Void

    var onBeginEdit: () -> Void
    var onCancel: () -> Void
    var onDone: () -> Void
    var onDelete: (() -> Void)? = nil

    @ViewBuilder var content: () -> Content

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: .medium) {
                    content()
                    if isEditing, let deleteSectionTitle, let onDelete {
                        DeleteSectionBox(title: deleteSectionTitle, onDelete: onDelete)
                    }
                }
                .padding()
            }
            .scrollDismissesKeyboard(.interactively)
            .interactiveDismissDisabled(isEditing)
            .keyboardDismissButton(isVisible: keyboardDismissVisible, action: onDismissKeyboard)
            .navigationTitle(isEditing ? editingTitle : title)
            .inlineNavigationBarTitleDisplayMode()
            .toolbar { toolbarContent }
            .alert(String(localized: "Cannot Save"), isPresented: Binding(
                get: { !validationErrors.isEmpty && isEditing },
                set: { if !$0 { validationErrors = [] } }
            )) {
                Button("OK") { validationErrors = [] }
            } message: {
                Text(validationErrors.joined(separator: "\n"))
            }
            .errorAlert("Delete Failed", message: $deleteError)
        }
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        if isEditing {
            CancelToolbarItem(systemImage: cancelSystemImage, action: onCancel)
            ConfirmToolbarItem(isDisabled: isDoneDisabled, action: onDone)
        } else {
            EditToolbarItem(action: onBeginEdit)
            CloseToolbarItem { dismiss() }
        }
    }
}
