//
//  FAQView.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 24/10/2026.
//

import SwiftUI

struct FAQView: View {
    let items: [FAQItem]

    var body: some View {
        Form {
            Section {
                ForEach(items) { item in
                    FAQRow(item: item)
                }
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Frequently Asked Questions")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }
}

struct FAQRow: View {
    let item: FAQItem

    @State private var isExpanded = false

    var body: some View {
        DisclosureGroup(isExpanded: $isExpanded) {
            Text(item.answer)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .textSelection(.enabled)
        } label: {
            Text(item.question)
                .fontWeight(.semibold)
        }
    }
}

#Preview {
    NavigationStack {
        FAQView(items: FAQItem.all)
    }
}
