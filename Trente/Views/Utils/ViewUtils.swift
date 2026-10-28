//
//  ViewUtils.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 22/04/2025.
//

import SwiftUI

func createImage(_ value: Data) -> Image? {
    #if canImport(UIKit)
    guard let uiImage: UIImage = UIImage(data: value) else { return nil }
    return Image(uiImage: uiImage)
    #elseif canImport(AppKit)
    guard let uiImage: NSImage = NSImage(data: value) else { return nil }
    return Image(nsImage: uiImage)
    #else
    return nil
    #endif
}

#if canImport(AppKit)
extension NSImage {
    func pngData() -> Data? {
        guard let tiffData = tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData) else { return nil }
        return bitmap.representation(using: .png, properties: [:])
    }
}
#endif

func imageData(named name: String) -> Data? {
    #if canImport(UIKit)
    return UIImage(named: name)?.pngData()
    #elseif canImport(AppKit)
    return NSImage(named: name)?.pngData()
    #else
    return nil
    #endif
}

extension ToolbarItemPlacement {
    /// Leading "close sheet" button placement: `.topBarLeading` on iOS, `.cancellationAction` on macOS.
    static var closeButtonPlacement: ToolbarItemPlacement {
        #if os(iOS)
        .topBarLeading
        #else
        .cancellationAction
        #endif
    }
}

extension View {
    /// Applies `.navigationBarTitleDisplayMode(.inline)` on iOS; no-op on macOS, which has no equivalent.
    @ViewBuilder
    func inlineNavigationBarTitleDisplayMode() -> some View {
        #if os(iOS)
        self.navigationBarTitleDisplayMode(.inline)
        #else
        self
        #endif
    }
}

// MARK: View Extensions
extension View {
    @ViewBuilder
    func modify<T: View>(@ViewBuilder _ transform: (Self) -> T) -> some View {
        transform(self)
    }

    /// Standard destructive-delete confirmation dialog with a "cannot be undone" warning.
    func deleteConfirmation(
        isPresented: Binding<Bool>,
        message: String = String(localized: "This action cannot be undone."),
        onDelete: @escaping () -> Void
    ) -> some View {
        confirmationDialog(
            String(localized: "Are you sure?"),
            isPresented: isPresented,
            titleVisibility: .visible
        ) {
            Button(String(localized: "Delete"), role: .destructive, action: onDelete)
            Button(String(localized: "Cancel"), role: .cancel) {}
        } message: {
            Text(message)
        }
    }
}
