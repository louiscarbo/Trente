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
                        Row(credit: credit)
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

#Preview {
    NavigationStack {
        CreditsView(sections: CreditSection.all)
    }
}
