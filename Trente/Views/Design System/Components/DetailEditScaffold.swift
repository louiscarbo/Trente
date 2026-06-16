//
//  DetailEditScaffold.swift
//  Trente
//

import SwiftUI

struct DetailEditScaffold<Content: View>: View {
    @Environment(\.dismiss) private var dismiss

    var title: String
    @Binding var isEditing: Bool
    @Binding var validationErrors: [String]
    @Binding var deleteError: String?

    var deleteSectionTitle: String
    var keyboardDismissVisible: Bool
    var onDismissKeyboard: () -> Void

    var onBeginEdit: () -> Void
    var onCancel: () -> Void
    var onDone: () -> Void
    var onDelete: () -> Void

    @ViewBuilder var content: () -> Content

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: .medium) {
                    content()
                    if isEditing {
                        DeleteSectionBox(title: deleteSectionTitle, onDelete: onDelete)
                    }
                }
                .padding()
            }
            .scrollDismissesKeyboard(.interactively)
            .interactiveDismissDisabled(isEditing)
            .keyboardDismissButton(isVisible: keyboardDismissVisible, action: onDismissKeyboard)
            .navigationTitle(isEditing ? String(localized: "Editing") : title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbarContent }
            .alert(String(localized: "Cannot Save"), isPresented: Binding(
                get: { !validationErrors.isEmpty && isEditing },
                set: { if !$0 { validationErrors = [] } }
            )) {
                Button("OK") { validationErrors = [] }
            } message: {
                Text(validationErrors.joined(separator: "\n"))
            }
            .alert(String(localized: "Delete Failed"), isPresented: Binding(
                get: { deleteError != nil },
                set: { if !$0 { deleteError = nil } }
            )) {
                Button("OK", role: .cancel) { deleteError = nil }
            } message: {
                Text(deleteError ?? "")
            }
        }
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        if isEditing {
            ToolbarItem(placement: .cancellationAction) {
                Button(role: .cancel, action: onCancel) {
                    Label("Cancel", systemImage: "arrow.uturn.backward")
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button(action: onDone) {
                    Label("Done", systemImage: "checkmark")
                }
            }
        } else {
            ToolbarItem(placement: .primaryAction) {
                Button(action: onBeginEdit) {
                    Label("Edit", systemImage: "pencil")
                }
            }
            ToolbarItem(placement: .topBarLeading) {
                Button { dismiss() } label: {
                    Label("Close", systemImage: "chevron.down")
                }
            }
        }
    }
}
