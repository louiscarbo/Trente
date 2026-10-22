//
//  PageIndicator.swift
//  Trente
//

import SwiftUI

struct PageIndicator<Page: Hashable>: View {
    let pages: [Page]
    @Binding var currentPage: Page?

    var body: some View {
        HStack(spacing: 6) {
            ForEach(pages, id: \.self) { page in
                Button {
                    withAnimation { currentPage = page }
                } label: {
                    Circle()
                        .fill(page == (currentPage ?? pages.first) ? Color.primary : Color.secondary.opacity(0.3))
                        .frame(width: 6, height: 6)
                }
                .buttonStyle(.plain)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: currentPage)
    }
}

extension PageIndicator where Page: CaseIterable {
    init(currentPage: Binding<Page?>) {
        self.init(pages: Array(Page.allCases), currentPage: currentPage)
    }
}

private enum PreviewPage: Int, CaseIterable { case a, b, c, d, e }

#Preview {
    VStack(spacing: .large) {
        PageIndicator(currentPage: .constant(PreviewPage.c))
        PageIndicator(pages: [PreviewPage.a, .c, .e], currentPage: .constant(.c))
    }
    .padding()
}
