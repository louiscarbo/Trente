//
//  RequiresTrentePlus.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 26/04/2025.
//

import SwiftUI

enum TrentePlusLockStyle {
    case inline
    case section(prompt: LocalizedStringKey)
}

struct RequiresTrentePlus: ViewModifier {
    let style: TrentePlusLockStyle
    @Environment(\.isTrentePlusSubscribed) private var isSubscribed
    @State private var isShowingPaywall = false

    private var isLocked: Bool { !isSubscribed }

    private var isSection: Bool {
        if case .section = style { true } else { false }
    }

    func body(content: Content) -> some View {
        content
            .disabled(isLocked)
            .opacity(isLocked ? (isSection ? 0.8 : 0.4) : 1)
            .blur(radius: isLocked && isSection ? 3 : 0)
            .accessibilityHidden(isLocked && isSection)
            .overlay(alignment: isSection ? .center : .trailing) {
                if isLocked {
                    lock
                }
            }
            .sheet(isPresented: $isShowingPaywall) {
                SubscriptionView()
            }
    }

    @ViewBuilder
    private var lock: some View {
        switch style {
        case .inline:
            Button {
                isShowingPaywall = true
            } label: {
                Label("Trente+", systemImage: "lock.fill")
                    .font(.caption.bold())
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(.regularMaterial, in: .capsule)
                    .overlay(
                        Capsule()
                            .inset(by: 1)
                            .stroke(.primary.opacity(0.2), lineWidth: 2)
                    )
                    .padding(.trailing, DesignSystem.Spacing.medium.rawValue)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
                    .contentShape(.rect)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Requires Trente+")
        case .section(let prompt):
            Button {
                isShowingPaywall = true
            } label: {
                HStack {
                    Image(systemName: "lock.fill")
                        .padding(.trailing, 4)
                    Text(prompt)
                }
                .font(.title3)
            }
            .buttonStyle(TrentePrimaryButtonStyle())
            .padding(.horizontal, 24)
        }
    }
}

extension View {
    func requiresTrentePlus(_ style: TrentePlusLockStyle = .inline) -> some View {
        modifier(RequiresTrentePlus(style: style))
    }
}

#Preview("Inline") {
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

#Preview("Section") {
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
        .requiresTrentePlus(.section(prompt: "Add notes and images with Trente+"))
    }
    .padding()
    .environment(\.isTrentePlusSubscribed, isSubscribed)
}
