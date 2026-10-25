//
//  AboutDeveloperView.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 24/10/2026.
//

import SwiftUI

struct AboutDeveloperView: View {
    let profile: DeveloperProfile
    let contactURL: URL?
    let contactAddress: String

    var body: some View {
        ScrollView {
            VStack(spacing: .large) {
                portrait

                VStack(spacing: .small) {
                    Text(profile.greeting)
                        .font(.largeTitle.bold())
                        .accessibilityAddTraits(.isHeader)
                    Text(profile.bio)
                        .foregroundStyle(.secondary)
                }
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

                ContactButton(url: contactURL, address: contactAddress) {
                    Text("Send Me an Email")
                }
                .buttonStyle(TrentePrimaryButtonStyle())

                links
            }
            .padding()
            .frame(maxWidth: 520)
            .frame(maxWidth: .infinity)
        }
        .navigationTitle("About the Developer")
        .inlineNavigationBarTitleDisplayMode()
    }

    private var portrait: some View {
        Image(profile.photoName)
            .resizable()
            .aspectRatio(contentMode: .fill)
            .frame(width: 140, height: 140)
            .clipShape(Circle())
            .overlay(alignment: .bottomTrailing) {
                StickerView(imageName: "Trente Pig Sticker")
                    .frame(width: 64)
                    .offset(x: 18, y: 6)
            }
            .padding(.top)
            .accessibilityLabel(Text(profile.name))
    }

    private var links: some View {
        GroupBox(label: Label("Find Me Online", systemImage: "link")) {
            VStack(spacing: 0) {
                ForEach(profile.links) { link in
                    ProfileLinkRow(
                        title: link.title,
                        systemImage: link.systemImage,
                        url: link.url
                    )
                    if link.id != profile.links.last?.id {
                        Divider()
                    }
                }
            }
        }
        .groupBoxStyle(TrenteGroupBoxStyle())
    }
}

struct ProfileLinkRow: View {
    let title: LocalizedStringResource
    let systemImage: String
    let url: URL

    var body: some View {
        Link(destination: url) {
            ExternalLinkLabel(title: title, systemImage: systemImage)
                .padding(.vertical, DesignSystem.Spacing.medium.rawValue)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    NavigationStack {
        AboutDeveloperView(
            profile: .louis,
            contactURL: nil,
            contactAddress: SupportMail.address
        )
    }
}
