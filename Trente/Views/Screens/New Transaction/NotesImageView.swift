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
    @Binding var imageData: Data?
    @Binding var notes: String
            
    // View State
    @Binding var nextButtonDisabled: Bool
    @Binding var showKeyboardDismissButton: Bool
    @State private var userSubscriptionIsActive: Bool = true
    @State private var photosPickerItem: PhotosPickerItem?
    @State private var showImageSubscriptionSheet: Bool = false
    @State private var showFullScreen = false
    @State private var errorWrapper: ErrorWrapper?
    @State private var showErrorAlert = false
    @FocusState private var notesFocused: Bool
    
    private var image: Image? {
        guard let data = imageData else { return nil }
        #if canImport(UIKit)
        guard let uiImage = UIImage(data: data) else { return nil }
        return Image(uiImage: uiImage)
        #elseif canImport(AppKit)
        guard let nsImage = NSImage(data: data) else { return nil }
        return Image(nsImage: nsImage)
        #endif
    }
    
    var body: some View {
        ZStack {
            // Content
            ScrollView {
                VStack(spacing: 20) {
                    if photosPickerItem == nil {
                        PhotosPicker(selection: $photosPickerItem) {
                            Label("Add Image", systemImage: "photo.badge.plus")
                        }
                        .buttonStyle(TrenteSecondaryButtonStyle())
                    } else {
                        if let selectedImage = image {
                            selectedImage
                                .resizable()
                                .scaledToFit()
                                .clipShape(
                                    RoundedRectangle(cornerRadius: DesignSystem.Radius.large.rawValue)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: DesignSystem.Radius.large.rawValue)
                                        .stroke(Color.white, lineWidth: 10)
                                )
                                .frame(height: 200)
                                .shadow(radius: DesignSystem.Radius.large.rawValue, y: 10)
                                .padding(.bottom, 30)
                                .overlay(alignment: .bottom) {
                                    PhotosPicker(selection: $photosPickerItem) {
                                        Label("Change Image", systemImage: "photo.badge.plus")
                                            .font(.headline)
                                            .padding(.horizontal)
                                    }
                                    .buttonStyle(TrenteSecondaryButtonStyle())
                                    .fixedSize()
                                }
                                .onTapGesture {
                                    showFullScreen = true
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
                                .frame(height: 400)
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
            .onChange(of: photosPickerItem) { _, newItem in
                Task {
                    guard let item = newItem else {
                        imageData = nil
                        return
                    }
                    do {
                        imageData = try await item.loadTransferable(type: Data.self)
                    } catch {
                        errorWrapper = ErrorWrapper(error: error, guidance: "The image could not be loaded. Please try again.")
                        showErrorAlert = true
                        imageData = nil
                    }
                }
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
        .alert("Error Loading Image", isPresented: $showErrorAlert, presenting: errorWrapper) { _ in
            Button("OK") {}
        } message: { wrapper in
            Text(wrapper.guidance)
        }
        .onAppear {
            nextButtonDisabled = false
        }
    }
}
