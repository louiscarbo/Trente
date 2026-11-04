//
//  RowActions.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 04/11/2026.
//

import SwiftUI

struct RowAction {
    let title: String
    let systemImage: String
    let tint: Color
    var isDestructive = false
    let action: () -> Void

    fileprivate var swipeButton: some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
        }
        .tint(tint)
    }

    fileprivate var menuButton: some View {
        Button(role: isDestructive ? .destructive : nil, action: action) {
            Label(title, systemImage: systemImage)
        }
    }
}

extension View {
    func rowActions(leading: RowAction, trailing: RowAction) -> some View {
        self
            .swipeActions(edge: .leading) {
                leading.swipeButton
            }
            .swipeActions(edge: .trailing) {
                trailing.swipeButton
            }
            .contextMenu {
                leading.menuButton
                trailing.menuButton
            }
            .clipShape(Rectangle().inset(by: -3))
    }
}
