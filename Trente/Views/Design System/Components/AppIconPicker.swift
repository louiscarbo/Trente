//
//  AppIconPicker.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 29/10/2026.
//

import SwiftUI

struct AppIconPicker: View {
    @Binding var selection: AppIcon

    private let rows = Array(
        repeating: GridItem(.fixed(90), spacing: DesignSystem.Spacing.medium.rawValue),
        count: 2
    )

    var body: some View {
        ScrollView(.horizontal) {
            LazyHGrid(rows: rows, spacing: DesignSystem.Spacing.medium.rawValue) {
                ForEach(AppIcon.allCases) { icon in
                    Button {
                        selection = icon
                    } label: {
                        tile(for: icon, isSelected: icon == selection)
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(icon == selection ? .isSelected : [])
                }
            }
            .padding(.vertical, DesignSystem.Spacing.medium.rawValue)
        }
        .scrollIndicators(.hidden)
        .contentMargins(.horizontal, DesignSystem.Spacing.medium.rawValue, for: .scrollContent)
    }

    private func tile(for icon: AppIcon, isSelected: Bool) -> some View {
        VStack(spacing: .small) {
            Image(icon.previewImageName)
                .resizable()
                .scaledToFit()
                .frame(width: 60, height: 60)
                .overlay(alignment: .bottomTrailing) {
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title3)
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(.white, .tint)
                            .offset(x: 6, y: 6)
                    }
                }
                .accessibilityHidden(true)
            Text(icon.title)
                .font(.caption)
                .foregroundStyle(isSelected ? .primary : .secondary)
        }
        .frame(width: 76)
        .contentShape(.rect)
    }
}

#Preview {
    @Previewable @State var selection = AppIcon.green

    Form {
        Section {
            AppIconPicker(selection: $selection)
        }
    }
    .formStyle(.grouped)
}
