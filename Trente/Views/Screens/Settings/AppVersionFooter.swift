//
//  AppVersionFooter.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 24/10/2026.
//

import SwiftUI

struct AppVersionFooter: View {
    let versionDescription: String

    var body: some View {
        Text("Trente \(versionDescription)")
            .font(.footnote)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
    }
}

#Preview {
    AppVersionFooter(versionDescription: "1.0 (1)")
}
