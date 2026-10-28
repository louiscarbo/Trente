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
            ForEach(Array(pages.enumerated()), id: \.element) { index, page in
                let isCurrent = page == (currentPage ?? pages.first)
                Button {
                    withAnimation { currentPage = page }
                } label: {
                    Circle()
                        .fill(isCurrent ? Color.primary : Color.secondary.opacity(0.3))
                        .frame(width: 6, height: 6)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text("Page \(index + 1) of \(pages.count)"))
                .accessibilityAddTraits(isCurrent ? .isSelected : [])
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
