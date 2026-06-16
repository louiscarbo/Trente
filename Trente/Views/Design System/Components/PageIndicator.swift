//
//  PageIndicator.swift
//  Trente
//

import SwiftUI

struct PageIndicator<Page: CaseIterable & Hashable>: View where Page.AllCases: RandomAccessCollection {
    @Binding var currentPage: Page?

    var body: some View {
        HStack(spacing: 6) {
            ForEach(Page.allCases, id: \.self) { page in
                Button {
                    withAnimation { currentPage = page }
                } label: {
                    Circle()
                        .fill(page == (currentPage ?? Page.allCases.first) ? Color.primary : Color.secondary.opacity(0.3))
                        .frame(width: 6, height: 6)
                }
                .buttonStyle(.plain)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: currentPage)
    }
}

private enum PreviewPage: Int, CaseIterable { case a, b, c, d, e }

#Preview {
    PageIndicator(currentPage: .constant(PreviewPage.c))
        .padding()
}
