//
//  TransactionHeaderBox.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 07/10/2026.
//

import SwiftUI
import PhotosUI

struct TransactionHeaderBox: View {
    var isEditing: Bool
    var currency: Currency
    var showsExpenseRow: Bool
    var showsNotes: Bool

    @Binding var title: String
    @Binding var category: BudgetCategory?
    @Binding var amountCents: Int
    @Binding var note: String
    @Binding var imageData: Data?

    var titleFocus: FocusState<Bool>.Binding
    var notesFocus: FocusState<Bool>.Binding
    var amountFocus: FocusState<Bool>.Binding

    @State private var showFullScreen = false
    @State private var photosPickerItem: PhotosPickerItem?
    @State private var showDeleteConfirmation = false

    var body: some View {
        GroupBox {
            VStack(spacing: 0) {
                imageSection
                VStack(alignment: .leading, spacing: .small) {
                    EditableTitleField(
                        text: $title,
                        isEditing: isEditing,
                        placeholder: String(localized: "Transaction title"),
                        focus: titleFocus
                    )
                    .padding(.top, 12)
                    if showsExpenseRow {
                        EditableExpenseRow(
                            isEditing: isEditing,
                            category: $category,
                            amountCents: $amountCents,
                            currency: currency,
                            focus: amountFocus
                        )
                    }
                    if showsNotes {
                        noteEditor
                    }
                }
                .padding([.bottom, .horizontal])
            }
        }
        .groupBoxStyle(TrenteGroupBoxStyle(withPadding: false))
    }

    // MARK: - Image

    private var imageSection: some View {
        ZStack(alignment: .bottomTrailing) {
            if isEditing {
                if let imageData {
                    tappableImage(from: imageData)
                }
                if imageData != nil {
                    Button(role: .destructive) {
                        showDeleteConfirmation = true
                    } label: {
                        Label("Delete Image", systemImage: "trash")
                    }
                    .padding([.bottom, .trailing])
                    .buttonStyle(.glassProminent)
                    .tint(.red)
                    .alert("Are you sure?", isPresented: $showDeleteConfirmation) {
                        Button("Delete", role: .destructive) {
                            withAnimation {
                                imageData = nil
                            }
                        }
                        Button("Cancel", role: .cancel) { }
                    } message: {
                        Text("This action cannot be undone.")
                    }
                } else {
                    PhotosPicker(selection: $photosPickerItem) {
                        Label("Add Image", systemImage: "photo.badge.plus")
                    }
                    .buttonStyle(TrenteSecondaryButtonStyle())
                    .padding()
                }
            } else {
                if let imageData {
                    tappableImage(from: imageData)
                }
            }
        }
        .task(id: photosPickerItem) {
            guard let item = photosPickerItem else {
                imageData = nil
                return
            }
            do {
                imageData = try await item.loadTransferable(type: Data.self)
            } catch {
                imageData = nil
            }
        }
    }

    @ViewBuilder
    private func tappableImage(from imageData: Data) -> some View {
        if let image = createImage(imageData) {
            Button {
                showFullScreen = true
            } label: {
                image
                    .resizable()
                    .scaledToFill()
                    .frame(height: 200)
                    .clipShape(
                        UnevenRoundedRectangle(
                            topLeadingRadius: DesignSystem.Radius.large.rawValue,
                            topTrailingRadius: DesignSystem.Radius.large.rawValue
                        )
                    )
            }
            .buttonStyle(.plain)
            .modify { view in
#if os(iOS)
                view.fullScreenCover(isPresented: $showFullScreen) {
                    ZoomableImageView(image: image)
                }
#else
                view
#endif
            }
        }
    }

    // MARK: - Notes

    private var noteEditor: some View {
        TextField(
            "",
            text: $note,
            prompt: Text("Add your notes here."),
            axis: .vertical
        )
        .focused(notesFocus)
        .lineLimit(5)
        .padding(isEditing ? 8 : 0)
        .background {
            if isEditing {
                RoundedRectangle(cornerRadius: 10)
                    .fill(.gray.opacity(0.2))
            }
        }
        .disabled(!isEditing)
    }
}
