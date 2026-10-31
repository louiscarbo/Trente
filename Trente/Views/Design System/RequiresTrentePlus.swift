//
//  RequiresTrentePlus.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 26/04/2025.
//

import SwiftUI

struct RequiresTrentePlus: ViewModifier {
    let message: LocalizedStringKey?
    let isRequired: Bool
    @Environment(\.isTrentePlusSubscribed) private var isSubscribed
    @State private var isShowingPaywall = false

    private let tagShape = RoundedRectangle(cornerRadius: .large)

    private var isLocked: Bool { isRequired && !isSubscribed }

    func body(content: Content) -> some View {
        content
            .disabled(isLocked)
            .opacity(isLocked ? 0.4 : 1)
            .overlay {
                if isLocked {
                    lock
                }
            }
            .sheet(isPresented: $isShowingPaywall) {
                SubscriptionView()
            }
    }

    private var lock: some View {
        Button {
            isShowingPaywall = true
        } label: {
            tag
                .padding(.horizontal, DesignSystem.Spacing.medium.rawValue)
                .frame(
                    maxWidth: .infinity,
                    maxHeight: .infinity,
                    alignment: message == nil ? .trailing : .center
                )
                .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(message ?? "Requires Trente+")
    }

    private var tag: some View {
        HStack(spacing: 6) {
            Image(systemName: "lock.fill")
            Text(message ?? "Trente+")
        }
        .font(.caption.bold())
        .foregroundStyle(.primary)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(.regularMaterial, in: tagShape)
        .overlay {
            tagShape
                .inset(by: 1)
                .stroke(.primary.opacity(0.2), lineWidth: 2)
        }
        .fixedSize(horizontal: false, vertical: true)
    }
}

extension View {
    func requiresTrentePlus(message: LocalizedStringKey? = nil, isRequired: Bool = true) -> some View {
        modifier(RequiresTrentePlus(message: message, isRequired: isRequired))
    }
}

#Preview("Without message") {
    @Previewable @State var isSubscribed = false
    @Previewable @State var note = ""

    VStack(spacing: 20) {
        Toggle("Subscribed", isOn: $isSubscribed)

        Button("Add Image", systemImage: "photo.badge.plus") {}
            .buttonStyle(TrenteSecondaryButtonStyle())
            .requiresTrentePlus()

        TextField("", text: $note, prompt: Text("Add your notes here."), axis: .vertical)
            .padding(8)
            .background(.gray.opacity(0.2), in: .rect(cornerRadius: 10))
            .requiresTrentePlus()
    }
    .padding()
    .environment(\.isTrentePlusSubscribed, isSubscribed)
}

#Preview("With message") {
    @Previewable @State var isSubscribed = false

    VStack(spacing: 20) {
        Toggle("Subscribed", isOn: $isSubscribed)

        VStack {
            Button("Add Image", systemImage: "photo.badge.plus") {}
                .buttonStyle(TrenteSecondaryButtonStyle())
            Text("Notes")
                .frame(maxWidth: .infinity, minHeight: 120)
                .background(.gray.opacity(0.2), in: .rect(cornerRadius: 10))
        }
        .requiresTrentePlus(message: "Add notes and images with Trente+")
    }
    .padding()
    .environment(\.isTrentePlusSubscribed, isSubscribed)
}
