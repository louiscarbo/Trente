//
//  EditableTransactionHeader.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 07/10/2026.
//

import SwiftUI
import PhotosUI

struct EditableTransactionHeader: View {
    var isEditing: Bool
    var currency: Currency
    var showsExpenseRow: Bool

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
    @State private var imageLoader = ImageAttachmentLoader()
    @State private var image: Image?

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
                    if isEditing {
                        noteEditor
                            .requiresTrentePlus()
                    } else {
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
                if let image {
                    tappableImage(image)
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
                                photosPickerItem = nil
                            }
                        }
                        Button("Cancel", role: .cancel) { }
                    } message: {
                        Text("This action cannot be undone.")
                    }
                } else if imageLoader.isLoading {
                    ProgressView()
                        .padding()
                } else {
                    PhotosPicker(selection: $photosPickerItem) {
                        Label("Add Image", systemImage: "photo.badge.plus")
                    }
                    .buttonStyle(TrenteSecondaryButtonStyle())
                    .requiresTrentePlus()
                    .padding()
                }
            } else {
                if let image {
                    tappableImage(image)
                }
            }
        }
        .onChange(of: photosPickerItem) { _, item in
            guard let item else { return }
            imageLoader.load({ try await item.loadTransferable(type: Data.self) }) { preparedData in
                imageData = preparedData
            }
            photosPickerItem = nil
        }
        .task(id: imageData) {
            image = imageData.flatMap(createImage)
        }
        .errorAlert("Error Loading Image", message: $imageLoader.error)
    }

    private func tappableImage(_ image: Image) -> some View {
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
