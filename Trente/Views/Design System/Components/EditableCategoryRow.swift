//
//  EditableCategoryRow.swift
//  Trente
//

import SwiftUI

struct EditableCategoryRow: View {
    var isEditing: Bool
    @Binding var category: BudgetCategory?

    @Namespace private var animation

    var body: some View {
        if isEditing {
            picker
                .matchedGeometryEffect(id: "category", in: animation, properties: .position)
        } else {
            tag
                .matchedGeometryEffect(id: "category", in: animation, properties: .position)
        }
    }

    @ViewBuilder
    private var picker: some View {
        if category == nil {
            addCategoryMenu
        } else {
            categoryPicker
        }
    }

    private var addCategoryMenu: some View {
        Menu {
            ForEach(BudgetCategory.allCases) { option in
                Button(option.name) { category = option }
            }
        } label: {
            Label("Add category", systemImage: "plus")
                .padding(.vertical, 6)
                .padding(.horizontal, 12)
                .frame(maxHeight: .infinity)
        }
        .background {
            RoundedRectangle(cornerRadius: 10)
                .fill(.gray.opacity(0.2))
        }
    }

    private var categoryPicker: some View {
        Picker("Category", selection: $category) {
            ForEach(BudgetCategory.allCases) { category in
                Text(category.name)
                    .tag(category as BudgetCategory?)
            }
        }
        .frame(maxHeight: .infinity)
        .pickerStyle(.menu)
        .background {
            RoundedRectangle(cornerRadius: 10)
                .fill(.gray.opacity(0.2))
        }
    }

    @ViewBuilder
    private var tag: some View {
        if let category {
            HStack {
                Circle()
                    .fill(category.color)
                    .frame(width: 10, height: 10)
                Text(category.name)
                    .multilineTextAlignment(.leading)
                    .font(.subheadline)
                    .foregroundStyle(category.color.darken(0.6))
            }
            .padding(.vertical, 4)
            .padding(.horizontal, 8)
            .background {
                Capsule()
                    .fill(category.color.lighten(0.45))
                    .stroke(category.color.darken(0.3).opacity(0.2))
            }
            .offset(x: -2)
        }
    }
}
