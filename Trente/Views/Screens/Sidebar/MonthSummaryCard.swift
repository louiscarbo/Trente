//
//  MonthSummaryCard.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 23/04/2025.
//

import SwiftUI

struct MonthSummaryCard: View {
    let name: String
    let remaining: Double
    let spent: Double
    let currencyCode: String
    let isOverspent: Bool
    var isSelected = false
    var onSelect: (() -> Void)?

    @Environment(\.colorScheme) private var colorScheme
    private var lightMode: Bool { colorScheme == .light }

    var body: some View {
        if let onSelect {
            Button(action: onSelect) {
                content
            }
            .buttonStyle(
                SidebarRowButtonStyle(
                    pressedShape: RoundedRectangle(cornerRadius: .large),
                    drawsBehindContent: true
                )
            )
            .background(backgroundView)
            .accessibilityAddTraits(isSelected ? .isSelected : [])
        } else {
            content
                .background(backgroundView)
                .accessibilityElement(children: .combine)
        }
    }

    private var content: some View {
        VStack(alignment: .leading) {
            HStack {
                Text(name)
                    .font(.headline)
                Spacer()
                Text(isOverspent ? "Over Budget" : "Under Budget")
            }

            Divider()

            remainingSpentView
        }
        .padding()
    }

    private var remainingSpentView: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("Remaining")
                    .font(.subheadline)
                Text(remaining, format: .budget(currencyCode))
                    .font(.title)
                    .foregroundStyle(isOverspent ? .red : .green)
            }

            Spacer()

            VStack(alignment: .trailing) {
                Text("Spent")
                    .font(.subheadline)
                Text(spent.isZero ? 0 : -spent, format: .budget(currencyCode))
                    .font(.title)
                    .foregroundStyle(.red)
            }
        }
    }

    private var backgroundView: some View {
        ZStack {
            RoundedRectangle(cornerRadius: DesignSystem.Radius.large.rawValue)
                .foregroundStyle(
                    LinearGradient(
                        colors: [isOverspent ? .red.opacity(0.6) : .green.opacity(0.6), .red.opacity(0.6)],
                        startPoint: .bottomLeading,
                        endPoint: .bottomTrailing
                    )
                )
            RoundedRectangle(cornerRadius: DesignSystem.Radius.large.rawValue)
                .foregroundStyle(
                    RadialGradient(
                        colors: [lightMode ? .white : .black, .clear],
                        center: .top,
                        startRadius: 0,
                        endRadius: 500
                    )
                )
            RoundedRectangle(cornerRadius: DesignSystem.Radius.large.rawValue)
                .foregroundStyle(.regularMaterial)
                .overlay {
                    RoundedRectangle(cornerRadius: DesignSystem.Radius.large.rawValue)
                        .stroke(.primary.opacity(isSelected ? 0.5 : 0.2), lineWidth: 3)
                }
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        MonthSummaryCard(
            name: "October 2026",
            remaining: 1_240,
            spent: 760,
            currencyCode: "EUR",
            isOverspent: false
        )
        MonthSummaryCard(
            name: "October 2026",
            remaining: 0,
            spent: 0,
            currencyCode: "EUR",
            isOverspent: false,
            isSelected: true
        ) {}
        MonthSummaryCard(
            name: "October 2026",
            remaining: -120,
            spent: 2_120,
            currencyCode: "EUR",
            isOverspent: true
        ) {}
    }
    .padding()
}
