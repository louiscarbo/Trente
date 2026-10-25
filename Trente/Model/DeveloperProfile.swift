//
//  DeveloperProfile.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 24/10/2026.
//

import Foundation

struct DeveloperProfile {
    let name: String
    let greeting: LocalizedStringResource
    let bio: LocalizedStringResource
    let photoName: String
    let links: [ProfileLink]

    static let louis = DeveloperProfile(
        name: "Louis Carbo Estaque",
        greeting: "Hi, I'm Louis 👋",
        bio: """
            I'm a French 🇫🇷 developer who loves building apps. Trente is the app I wished I had to follow the 50/30/20 rule. \
            Every suggestion helps, so feel free to write to me!
            """,
        photoName: "placeholder",
        links: [
            ProfileLink(
                id: "website",
                title: "Website",
                systemImage: "globe",
                url: ExternalLinks.developerWebsite
            ),
            ProfileLink(
                id: "linkedIn",
                title: "LinkedIn",
                systemImage: "person.crop.rectangle",
                url: ExternalLinks.developerLinkedIn
            ),
            ProfileLink(
                id: "gitHub",
                title: "GitHub",
                systemImage: "chevron.left.forwardslash.chevron.right",
                url: ExternalLinks.developerGitHub
            )
        ]
    )
}

struct ProfileLink: Identifiable {
    let id: String
    let title: LocalizedStringResource
    let systemImage: String
    let url: URL
}
