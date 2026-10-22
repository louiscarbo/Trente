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

    var body: some View {
        HStack(alignment: .center, spacing: DesignSystem.Spacing.medium.rawValue) {
            Image("Trente Pig Sticker")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .padding(4)
                .frame(width: 38, height: 38)
                .background(.background, in: RoundedRectangle(cornerRadius: 9))
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(verbatim: "Trente")
                        .font(.subheadline)
                        .bold()
                    Spacer()
                    Text("now")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                Text(title)
                    .font(.subheadline)
                    .bold()
                    .lineLimit(1)
                Text(message)
                    .font(.subheadline)
                    .lineLimit(2)
            }
        }
        .padding(14)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: .large))
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    VStack {
        NotificationPreview(title: "€4.20 - Café Kitsuné", message: "Tap here to log it in Trente")
        NotificationPreview(title: "€850 - Rent", message: "Due tomorrow")
    }
    .padding()
    .frame(maxWidth: 420)
    .background(.blue.gradient)
}
