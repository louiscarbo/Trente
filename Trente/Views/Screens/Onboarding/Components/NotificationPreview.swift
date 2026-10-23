//
//  NotificationPreview.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 23/10/2026.
//

import SwiftUI

struct NotificationPreview: View {
    let title: String
    let message: String

    private let cardShape = RoundedRectangle(cornerRadius: 24)

    var body: some View {
        card
            .background {
                cardBackground
                    .padding(.horizontal, 15)
                    .offset(y: 12)
                    .opacity(0.7)
            }
            .padding(.bottom, 12)
            .accessibilityElement(children: .combine)
    }

    private var card: some View {
        HStack(spacing: 10) {
            AppIconImage()
                .frame(width: 38, height: 38)
                #if os(iOS)
                .clipShape(RoundedRectangle(cornerRadius: 9))
                #endif
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 1) {
                HStack(alignment: .firstTextBaseline) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .lineLimit(1)
                    Spacer()
                    Text("now")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                Text(message)
                    .font(.subheadline)
                    .lineLimit(2)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background { cardBackground }
    }

    private var cardBackground: some View {
        cardShape
            .fill(.background.secondary)
            .overlay {
                cardShape.strokeBorder(.primary.opacity(0.06))
            }
            .shadow(color: .black.opacity(0.12), radius: 12, y: 8)
    }
}

#Preview {
    NotificationPreview(title: "€4.50 - Boulangerie", message: "Tap here to log it in Trente")
        .padding()
        .frame(maxWidth: 420)
}
