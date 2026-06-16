//
//  ViewUtils.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 22/04/2025.
//

import SwiftUI

// MARK: WidthThresholdReader
/**
 A view useful for determining if a child view should act like it is horizontally compressed.
 
 Several elements are used to decide if a view is compressed:
 - Width
 - Dynamic Type size
 - Horizontal size class (on iOS)
 */
struct WidthThresholdReader<Content: View>: View {
    var widthThreshold: Double = 400
    @ViewBuilder var content: (WidthThresholdProxy) -> Content
    
    #if os(iOS)
    @Environment(\.horizontalSizeClass) private var sizeClass
    #endif
    @Environment(\.dynamicTypeSize) private var dynamicType
    
    var body: some View {
        GeometryReader { geometryProxy in
            let compressionProxy = WidthThresholdProxy(
                width: geometryProxy.size.width,
                isCompact: isCompact(width: geometryProxy.size.width)
            )
            content(compressionProxy)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
                
    func isCompact(width: Double) -> Bool {
        #if os(iOS)
        if sizeClass == .compact {
            return true
        }
        #endif
        if width < widthThreshold {
            return true
        }
        return false
    }
}

struct WidthThresholdProxy: Equatable {
    var width: Double
    var isCompact: Bool
}

struct WidthThresholdReader_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 40) {
            WidthThresholdReader { proxy in
                Label {
                    Text("Standard")
                } icon: {
                    compactIndicator(proxy: proxy)
                }
            }
            .border(.quaternary)
            
            WidthThresholdReader { proxy in
                Label {
                    Text("200 Wide")
                } icon: {
                    compactIndicator(proxy: proxy)
                }
            }
            .frame(width: 200)
            .border(.quaternary)
            
            WidthThresholdReader { proxy in
                Label {
                    Text("X Large Type")
                } icon: {
                    compactIndicator(proxy: proxy)
                }
            }
            .dynamicTypeSize(.xxxLarge)
            .border(.quaternary)
        
            #if os(iOS)
            WidthThresholdReader { proxy in
                Label {
                    Text("Manually Compact Size Class")
                } icon: {
                    compactIndicator(proxy: proxy)
                }
            }
            .border(.quaternary)
            .environment(\.horizontalSizeClass, .regular)
            #endif
        }
    }
    
    @ViewBuilder
    static func compactIndicator(proxy: WidthThresholdProxy) -> some View {
        if proxy.isCompact {
            Image(systemName: "arrowtriangle.right.and.line.vertical.and.arrowtriangle.left.fill")
                .foregroundStyle(.red)
        } else {
            Image(systemName: "checkmark.circle")
                .foregroundStyle(.secondary)
        }
    }
}

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
    func modify<T: View>(_ transform: (Self) -> T) -> some View {
        transform(self)
    }
}
