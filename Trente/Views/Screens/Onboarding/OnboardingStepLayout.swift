//
//  OnboardingStepLayout.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 23/10/2026.
//

import SwiftUI

enum OnboardingCompactArrangement {
    case secondaryFills
    case secondaryAbove
    case secondaryBelow
}

struct OnboardingStepLayout<Primary: View, Secondary: View, Actions: View>: View {
    var compactArrangement: OnboardingCompactArrangement = .secondaryFills
    var isEditing = false
    @ViewBuilder let primary: () -> Primary
    @ViewBuilder let secondary: () -> Secondary
    @ViewBuilder let actions: () -> Actions

    #if os(iOS)
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    #endif
    @State private var containerSize: CGSize = .zero
    @State private var compactViewportHeight: CGFloat = 0
    @State private var compactScrollPosition = ScrollPosition(edge: .top)

    private static var regularMinimumWidth: CGFloat { 1000 }
    private static var primaryColumnWidth: ClosedRange<CGFloat> { 340...420 }

    private var isRegular: Bool {
        guard containerSize.width > containerSize.height else { return false }
        #if os(iOS)
        return horizontalSizeClass == .regular
        #else
        return containerSize.width >= Self.regularMinimumWidth
        #endif
    }

    var body: some View {
        Group {
            if isRegular {
                regularLayout
            } else {
                compactLayout
            }
        }
        .environment(\.isOnboardingLayoutRegular, isRegular)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onGeometryChange(for: CGSize.self) { proxy in
            proxy.size
        } action: { newSize in
            containerSize = newSize
        }
    }

    private var compactLayout: some View {
        ScrollView {
            compactContent
                .frame(minHeight: isEditing ? nil : compactViewportHeight)
        }
        .scrollBounceBehavior(.basedOnSize)
        .scrollPosition($compactScrollPosition)
        .onScrollGeometryChange(for: CGFloat.self) { geometry in
            geometry.containerSize.height
        } action: { _, height in
            compactViewportHeight = height
        }
        .onChange(of: isEditing) { _, isEditing in
            withAnimation {
                compactScrollPosition.scrollTo(edge: isEditing ? .bottom : .top)
            }
        }
        .safeAreaInset(edge: .bottom) {
            if !isEditing {
                VStack(spacing: .small) {
                    actions()
                }
                .padding([.horizontal, .bottom])
            }
        }
    }

    private var compactContent: some View {
        VStack(spacing: .large) {
            switch compactArrangement {
            case .secondaryFills:
                primary()
                secondary()
                    .frame(maxHeight: .infinity)
            case .secondaryAbove:
                secondary()
                primary()
            case .secondaryBelow:
                primary()
                secondary()
            }
        }
        .padding(.horizontal)
    }

    private var regularLayout: some View {
        HStack(spacing: 48) {
            VStack(alignment: .leading, spacing: .large) {
                primary()
                VStack(spacing: .small) {
                    actions()
                }
            }
            .frame(
                minWidth: Self.primaryColumnWidth.lowerBound,
                maxWidth: Self.primaryColumnWidth.upperBound
            )

            secondary()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .padding(48)
    }
}

extension EnvironmentValues {
    @Entry var isOnboardingLayoutRegular = false
}

#Preview {
    OnboardingStepLayout {
        VStack(alignment: .leading, spacing: .small) {
            Text("Primary title")
                .font(.largeTitle)
                .bold()
            Text("A subtitle explaining the step.")
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    } secondary: {
        RoundedRectangle(cornerRadius: .large)
            .fill(.blue.gradient)
    } actions: {
        Button("Continue") {}
            .buttonStyle(TrentePrimaryButtonStyle())
    }
}
