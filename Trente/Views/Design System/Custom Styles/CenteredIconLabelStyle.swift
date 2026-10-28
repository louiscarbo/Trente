//
//  CenteredIconLabelStyle.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 28/10/2026.
//

import SwiftUI

struct CenteredIconLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(alignment: .center) {
            configuration.icon
            configuration.title
        }
    }
}

extension LabelStyle where Self == CenteredIconLabelStyle {
    static var centeredIcon: Self { CenteredIconLabelStyle() }
}
