//
//  TrentePlusSection+SignedNote.swift
//  Trente
//

import SwiftUI

extension TrentePlusSection {
    struct SignedNote: View {
        let message: LocalizedStringResource
        let signature: String
        let portraitName: String

        @ScaledMetric(relativeTo: .footnote) private var portraitSize = 32.0

        var body: some View {
            VStack(alignment: .leading, spacing: 6) {
                Text(message)
                    .font(.subheadline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                HStack(spacing: 6) {
                    Image(portraitName)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: portraitSize, height: portraitSize)
                        .clipShape(.circle)
                        .accessibilityHidden(true)
                    Text(verbatim: signature)
                        .font(.footnote)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                }
            }
            .accessibilityElement(children: .combine)
            .padding([.horizontal, .top])
        }
    }
}

#Preview {
    Form {
        Section {
            TrentePlusSection.SignedNote(
                message: "I make Trente on my own, in my spare time, without ads or collecting your data. Trente+ helps me keep going, and gives you a few extras.",
                signature: "Louis",
                portraitName: DeveloperProfile.louis.photoName
            )
            .padding(.bottom)
            .listRowInsets(EdgeInsets())
        }
    }
    .formStyle(.grouped)
}
