//
//  WidthThresholdReader.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 22/04/2025.
//

import SwiftUI

/**
 A view useful for determining if a child view should act like it is horizontally compressed.
 
 Several elements are used to decide if a view is compressed:
 - Width
 - Horizontal size class (on iOS)
 */
struct WidthThresholdReader<Content: View>: View {
    var widthThreshold: Double = 400
    @ViewBuilder var content: (WidthThresholdProxy) -> Content
    
    #if os(iOS)
    @Environment(\.horizontalSizeClass) private var sizeClass
    #endif
    
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

private struct CompactIndicator: View {
    let proxy: WidthThresholdProxy

    var body: some View {
        if proxy.isCompact {
            Image(systemName: "arrowtriangle.right.and.line.vertical.and.arrowtriangle.left.fill")
                .foregroundStyle(.red)
        } else {
            Image(systemName: "checkmark.circle")
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    VStack(spacing: 40) {
        WidthThresholdReader { proxy in
            Label {
                Text("Standard")
            } icon: {
                CompactIndicator(proxy: proxy)
            }
        }
        .border(.quaternary)

        WidthThresholdReader { proxy in
            Label {
                Text("200 Wide")
            } icon: {
                CompactIndicator(proxy: proxy)
            }
        }
        .frame(width: 200)
        .border(.quaternary)

        #if os(iOS)
        WidthThresholdReader { proxy in
            Label {
                Text("Manually Compact Size Class")
            } icon: {
                CompactIndicator(proxy: proxy)
            }
        }
        .border(.quaternary)
        .environment(\.horizontalSizeClass, .compact)
        #endif
    }
}
