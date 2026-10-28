//
//  FAQView+Answer.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 24/10/2026.
//

import SwiftUI

extension FAQView {
    struct Answer: View {
        let text: LocalizedStringResource

        var body: some View {
            Text(text)
                .foregroundStyle(.secondary)
                .textSelection(.enabled)
        }
    }
}
