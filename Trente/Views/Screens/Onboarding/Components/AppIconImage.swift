//
//  AppIconImage.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 23/10/2026.
//

import SwiftUI

struct AppIconImage: View {
    var body: some View {
        if let icon = Self.icon {
            icon
                .resizable()
                .aspectRatio(contentMode: .fit)
        }
    }

    private static var icon: Image? {
        #if os(macOS)
        Image(nsImage: NSApplication.shared.applicationIconImage)
        #else
        guard
            let icons = Bundle.main.object(forInfoDictionaryKey: "CFBundleIcons") as? [String: Any],
            let primaryIcon = icons["CFBundlePrimaryIcon"] as? [String: Any],
            let iconFiles = primaryIcon["CFBundleIconFiles"] as? [String],
            let iconName = iconFiles.last,
            let image = UIImage(named: iconName)
        else { return nil }
        return Image(uiImage: image)
        #endif
    }
}

#Preview {
    AppIconImage()
        .frame(width: 120, height: 120)
}
