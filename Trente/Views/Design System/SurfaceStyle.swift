//
//  SurfaceStyle.swift
//  Trente
//
//  Prototype only: claude/materials-preview is not meant to be merged.
//

import SwiftUI

enum SurfaceStyle: String {
    case current
    case solid = "A"
    case solidGreyPage = "A-grey-page"
    case tinted = "B"
    case outline = "C"

    static let active = SurfaceStyle(rawValue: UserDefaults.standard.string(forKey: "surfaceStyle") ?? "") ?? .current

    static var isCurrent: Bool { active == .current }

    static var pageColor: Color {
        switch active {
        case .solidGreyPage:
            #if os(iOS)
            Color(uiColor: .systemGroupedBackground)
            #else
            Color(nsColor: .windowBackgroundColor)
            #endif
        default:
            #if os(iOS)
            Color(uiColor: .systemBackground)
            #else
            Color(nsColor: .textBackgroundColor)
            #endif
        }
    }

    static var cardColor: Color {
        switch active {
        case .solidGreyPage:
            #if os(iOS)
            Color(uiColor: .secondarySystemGroupedBackground)
            #else
            Color(nsColor: .textBackgroundColor)
            #endif
        case .outline:
            .clear
        default:
            #if os(iOS)
            Color(uiColor: .secondarySystemBackground)
            #else
            Color(nsColor: .windowBackgroundColor)
            #endif
        }
    }

    static func cardFill(tint: Color?) -> AnyShapeStyle {
        switch active {
        case .current:
            AnyShapeStyle(.regularMaterial)
        case .tinted:
            AnyShapeStyle(
                LinearGradient(
                    colors: [cardColor.mix(with: tint ?? cardColor, by: 0.22), cardColor],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
        default:
            AnyShapeStyle(cardColor)
        }
    }

    static var barFill: AnyShapeStyle {
        switch active {
        case .current:
            AnyShapeStyle(.regularMaterial)
        case .outline:
            AnyShapeStyle(pageColor)
        default:
            AnyShapeStyle(cardColor)
        }
    }

    static var secondaryButtonFill: AnyShapeStyle {
        switch active {
        case .current:
            AnyShapeStyle(.regularMaterial)
        case .outline:
            AnyShapeStyle(Color.clear)
        default:
            AnyShapeStyle(cardColor)
        }
    }

    static var heroCardOverlayOpacity: Double {
        switch active {
        case .current: 1
        case .solid, .solidGreyPage: 0.75
        case .tinted: 0.5
        case .outline: 0
        }
    }

    static var previewScreen: String? {
        UserDefaults.standard.string(forKey: "previewScreen")
    }
}

extension EnvironmentValues {
    @Entry var surfaceTint: Color?
}

extension View {
    @ViewBuilder
    func surfacePageBackground() -> some View {
        if SurfaceStyle.isCurrent {
            self
        } else {
            self
                .scrollContentBackground(.hidden)
                .background(SurfaceStyle.pageColor)
                #if os(iOS)
                .containerBackground(SurfaceStyle.pageColor, for: .navigation)
                #endif
        }
    }
}

