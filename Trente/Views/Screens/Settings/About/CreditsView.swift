//
//  CreditsView.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 24/10/2026.
//

import SwiftUI

struct CreditsView: View {
    let sections: [CreditSection]

    var body: some View {
        Form {
            ForEach(sections) { section in
                Section {
                    ForEach(section.credits) { credit in
                        CreditRow(credit: credit)
                    }
                } header: {
                    Text(section.title)
                }
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Credits")
    }
}

struct CreditRow: View {
    let credit: Credit

    var body: some View {
        if let url = credit.url {
            Link(destination: url) {
                content
            }
        } else {
            content
        }
    }

    private var content: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(credit.title)
                    .foregroundStyle(.primary)
                Text(credit.detail)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            if credit.url != nil {
                Image(systemName: "arrow.up.right")
                    .foregroundStyle(.secondary)
                    .accessibilityHidden(true)
            }
        }
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    NavigationStack {
        CreditsView(sections: CreditSection.all)
    }
}
