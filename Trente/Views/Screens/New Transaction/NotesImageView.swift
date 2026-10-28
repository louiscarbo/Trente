//
//  NotesImageView.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 12/07/2025.
//

import SwiftUI
import PhotosUI

// TODO: Refactor/Simplify/Split into smaller views
struct NotesImageView: View {
    // Transaction Data
    let imageData: Data?
    let isLoadingImage: Bool
    @Binding var notes: String

    // View State
    @Binding var showKeyboardDismissButton: Bool
    @Binding var imageLoadingError: String?
    let onPickImage: (PhotosPickerItem) -> Void
    @State private var userSubscriptionIsActive: Bool = true
    @State private var photosPickerItem: PhotosPickerItem?
    @State private var showImageSubscriptionSheet: Bool = false
    @State private var showFullScreen = false
    @State private var image: Image?
    @FocusState private var notesFocused: Bool
    
    var body: some View {
        ZStack {
            // Content
            ScrollView {
                VStack(spacing: 20) {
                    if imageData == nil && !isLoadingImage {
                        PhotosPicker(selection: $photosPickerItem) {
                            Label("Add Image", systemImage: "photo.badge.plus")
                        }
                        .buttonStyle(TrenteSecondaryButtonStyle())
                    } else {
                        if let selectedImage = image {
                            Group {
                                #if os(iOS)
                                Button {
                                    showFullScreen = true
                                } label: {
                                    thumbnail(selectedImage)
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel(Text("Show Image"))
                                #else
                                thumbnail(selectedImage)
                                #endif
                            }
                            .padding(.bottom, 30)
                            .overlay(alignment: .bottom) {
                                PhotosPicker(selection: $photosPickerItem) {
                                    Label("Change Image", systemImage: "photo.badge.plus")
                                        .font(.headline)
                                        .padding(.horizontal)
                                }
                                .buttonStyle(TrenteSecondaryButtonStyle())
                                .fixedSize()
                                .padding(.top, 30)
                            }
                            .modify { view in
                                #if os(iOS)
                                    view.fullScreenCover(isPresented: $showFullScreen) {
                                        ZoomableImageView(image: selectedImage)
                                    }
                                #else
                                    view
                                #endif
                            }
                        } else {
                            ProgressView()
                                .frame(height: 200)
                        }
                    }
                    
                    GroupBox(label: Label("Transaction Notes", systemImage: "note.text")) {
                        TextField(
                            "",
                            text: $notes,
                            prompt: Text("Add your notes here."),
                            axis: .vertical
                        )
                        .focused($notesFocused)
                        .lineLimit(5, reservesSpace: true)
                        .fixedSize(horizontal: false, vertical: true)
                        .textFieldStyle(.plain)
                        .onChange(of: notesFocused) { _, newValue in
                            if newValue == true {
                                showKeyboardDismissButton = true
                            } else {
                                showKeyboardDismissButton = false
                            }
                        }
                    }
                    .groupBoxStyle(TrenteGroupBoxStyle())
                }
                .padding()
                .padding(.top, 30)
            }
            .subscriptionAccessible(subscribed: userSubscriptionIsActive)
            .onChange(of: photosPickerItem) { _, item in
                guard let item else { return }
                onPickImage(item)
                photosPickerItem = nil
            }
            .task(id: imageData) {
                image = imageData.flatMap(createImage)
            }
            
            if !userSubscriptionIsActive {
                GroupBox(label: Label("Add Notes and Images", systemImage: "sparkle")) {
                    Text("With Trente+, you can add images and notes to your transactions. Try it now!")
                        .padding(.bottom)
                    
                    Button {
                        showImageSubscriptionSheet = true
                    } label: {
                        Text("Discover Trente+")
                            .font(.title3)
                    }
                    .buttonStyle(TrentePrimaryButtonStyle())
                    .sheet(isPresented: $showImageSubscriptionSheet) {
                        SubscriptionView()
                    }
                }
                .groupBoxStyle(TrenteGroupBoxStyle())
                .padding()
            }
        }
        .errorAlert("Error Loading Image", message: $imageLoadingError)
    }

    private func thumbnail(_ image: Image) -> some View {
        image
            .resizable()
            .scaledToFit()
            .clipShape(
                RoundedRectangle(cornerRadius: .large)
            )
            .overlay {
                RoundedRectangle(cornerRadius: .large)
                    .strokeBorder(Color.white, lineWidth: 10)
            }
            .glassEffect(.regular.interactive(true), in: RoundedRectangle(cornerRadius: .large))
            .frame(height: 200)
            .shadow(radius: DesignSystem.Radius.large.rawValue, y: 10)
    }
}
