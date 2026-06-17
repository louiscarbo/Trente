//
//  EditableTitleField.swift
//  Trente
//

import SwiftUI

struct EditableTitleField: View {
    @Binding var text: String
    var isEditing: Bool
    var placeholder: String
    var focus: FocusState<Bool>.Binding

    var body: some View {
        TextField(placeholder, text: $text, axis: .vertical)
            .focused(focus)
            .disabled(!isEditing)
            .frame(maxWidth: .infinity, alignment: .leading)
            .font(.title)
            .padding(isEditing ? 8 : 0)
            .background {
                if isEditing {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.gray.opacity(0.2))
                }
            }
    }
}
