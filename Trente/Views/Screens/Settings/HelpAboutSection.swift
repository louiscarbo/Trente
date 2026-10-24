//
//  HelpAboutSection.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 24/10/2026.
//

import SwiftUI

struct HelpAboutSection: View {
    let faqItems: [FAQItem]
    let contactURL: URL?
    let contactAddress: String
    let reviewURL: URL
    let profile: DeveloperProfile
    let credits: [CreditSection]
    let versionDescription: String

    var body: some View {
        Section {
            NavigationLink {
                FAQView(items: faqItems)
            } label: {
                Label("Frequently Asked Questions", systemImage: "questionmark.circle")
            }

            ContactButton(url: contactURL, address: contactAddress) {
                ExternalLinkLabel(
                    title: "Email the Developer",
                    detail: "Opens Mail with your app version",
                    systemImage: "envelope"
                )
            }

            Link(destination: reviewURL) {
                ExternalLinkLabel(
                    title: "Rate on the App Store",
                    detail: "Opens Trente's App Store page",
                    systemImage: "star"
                )
            }

            NavigationLink {
                AboutDeveloperView(
                    profile: profile,
                    contactURL: contactURL,
                    contactAddress: contactAddress
                )
            } label: {
                Label("About the Developer", systemImage: "person.crop.circle")
            }

            NavigationLink {
                CreditsView(sections: credits)
            } label: {
                Label("Credits", systemImage: "heart")
            }
        } header: {
            Text("Help & About")
        } footer: {
            AppVersionFooter(versionDescription: versionDescription)
                .padding(.top, DesignSystem.Spacing.large.rawValue)
        }
    }
}

#Preview {
    NavigationStack {
        Form {
            HelpAboutSection(
                faqItems: FAQItem.all,
                contactURL: nil,
                contactAddress: SupportMail.address,
                reviewURL: ExternalLinks.writeReview,
                profile: .louis,
                credits: CreditSection.all,
                versionDescription: "1.0 (1)"
            )
        }
        .formStyle(.grouped)
    }
}
