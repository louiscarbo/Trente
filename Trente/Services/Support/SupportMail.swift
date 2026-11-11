//
//  SupportMail.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 24/10/2026.
//

import Foundation

enum SupportMail {
    static let address = "louis@trente.app"

    private static let queryValueAllowed = CharacterSet.urlQueryAllowed.subtracting(CharacterSet(charactersIn: "&=+?#"))

    static func url(to address: String, subject: String, body: String) -> URL? {
        guard
            let encodedSubject = subject.addingPercentEncoding(withAllowedCharacters: queryValueAllowed),
            let encodedBody = body.addingPercentEncoding(withAllowedCharacters: queryValueAllowed)
        else { return nil }
        return URL(string: "mailto:\(address)?subject=\(encodedSubject)&body=\(encodedBody)")
    }

    static func feedbackBody(appInfo: AppInfo) -> String {
        "\n\n\n—\nTrente \(appInfo.versionDescription) · \(appInfo.systemDescription)"
    }

    static func feedbackURL(appInfo: AppInfo) -> URL? {
        url(
            to: address,
            subject: String(localized: "Trente Feedback"),
            body: feedbackBody(appInfo: appInfo)
        )
    }
}
