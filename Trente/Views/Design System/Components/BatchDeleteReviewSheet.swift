//
//  BatchDeleteReviewSheet.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 03/11/2026.
//

import SwiftUI

struct BatchDeleteReviewSheet: View {
    @Environment(\.dismiss) private var dismiss

    let deleteTitle: String
    let sections: [Section]
    let onConfirm: () -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: .medium) {
                    ForEach(sections, id: \.title, content: sectionBox)
                    Text("This action cannot be undone.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .padding()
            }
            .safeAreaBar(edge: .bottom) {
                Button(role: .destructive, action: onConfirm) {
                    Label(deleteTitle, systemImage: "trash.fill")
                        .font(.headline)
                }
                .buttonStyle(TrentePrimaryButtonStyle())
                .padding()
            }
            .navigationTitle("Review")
            .inlineNavigationBarTitleDisplayMode()
            .toolbar {
                CancelToolbarItem { dismiss() }
            }
        }
        #if os(macOS)
        .frame(minWidth: 420, minHeight: 480)
        #endif
    }

    private func sectionBox(_ section: Section) -> some View {
        GroupBox(label: Label(section.title, systemImage: section.systemImage)) {
            VStack(alignment: .leading, spacing: .small) {
                ForEach(section.rows.indices, id: \.self) { index in
                    rowView(section.rows[index])
                }
                if let note = section.note {
                    Text(note)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .groupBoxStyle(TrenteGroupBoxStyle())
    }

    private func rowView(_ row: Row) -> some View {
        HStack {
            Text(row.title)
            Spacer()
            if let detail = row.detail {
                Text(detail)
                    .foregroundStyle(.secondary)
            }
        }
        .accessibilityElement(children: .combine)
    }
}

extension BatchDeleteReviewSheet {
    struct Section: Equatable {
        let title: String
        let systemImage: String
        let rows: [Row]
        var note: String?
    }

    struct Row: Equatable {
        let title: String
        var detail: String?
    }
}

extension BatchDeleteReviewSheet.Section {
    static func willBeDeleted(_ rows: [BatchDeleteReviewSheet.Row], note: String? = nil) -> Self {
        Self(title: String(localized: "Will be deleted"), systemImage: "trash.fill", rows: rows, note: note)
    }

    static func stays(_ rows: [BatchDeleteReviewSheet.Row], note: String? = nil) -> Self {
        Self(title: String(localized: "Stays"), systemImage: "checkmark.circle.fill", rows: rows, note: note)
    }
}

extension BatchDeleteReviewSheet.Row {
    init(title: String, transactionCount: Int) {
        let detail = AttributedString(localized: "^[\(transactionCount) transaction](inflect: true)")
        self.init(title: title, detail: String(detail.characters))
    }
}

#Preview {
    BatchDeleteReviewSheet(
        deleteTitle: "Delete 2 Months",
        sections: [
            .willBeDeleted(
                [.init(title: "June 2026", transactionCount: 19), .init(title: "May 2026", transactionCount: 1)],
                note: "Their notes and images go too."
            ),
            .stays([.init(title: "Other months", detail: "4")])
        ]
    ) {}
}
