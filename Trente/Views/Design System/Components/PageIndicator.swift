//
//  PageIndicator.swift
//  Trente
//

import SwiftUI

struct PageIndicator<Page: Hashable>: View {
    let pages: [Page]
    @Binding var currentPage: Page?

    @State private var scrubOrigin: Int?

    private let dotSize: CGFloat = 6
    private let dotSpacing: CGFloat = 6
    private let scrubDistancePerPage: CGFloat = 20
    private let scrubPressDuration: TimeInterval = 0.3
    private let capsuleInset: CGFloat = 7

    private var isScrubbing: Bool { scrubOrigin != nil }

    private var currentIndex: Int {
        currentPage.flatMap { pages.firstIndex(of: $0) } ?? 0
    }

    var body: some View {
        HStack(spacing: dotSpacing) {
            ForEach(Array(pages.enumerated()), id: \.element) { index, page in
                let isCurrent = page == (currentPage ?? pages.first)
                Circle()
                    .fill(isCurrent ? Color.primary : Color.secondary.opacity(0.3))
                    .frame(width: dotSize, height: dotSize)
                    .accessibilityRepresentation {
                        Button {
                            withAnimation { currentPage = page }
                        } label: {
                            Text("Page \(index + 1) of \(pages.count)")
                        }
                        .accessibilityAddTraits(isCurrent ? .isSelected : [])
                    }
            }
        }
        .background {
            Capsule()
                .inset(by: -capsuleInset)
                .fill(.fill.secondary)
                .opacity(isScrubbing ? 1 : 0)
        }
        .contentShape(Capsule().inset(by: -capsuleInset))
        .onTapGesture(coordinateSpace: .local) { location in
            let nearestIndex = ((location.x - dotSize / 2) / (dotSize + dotSpacing)).rounded()
            select(index: Int(nearestIndex))
        }
        .gesture(scrubGesture)
        .sensoryFeedback(.impact(weight: .light), trigger: isScrubbing) { _, isNowScrubbing in isNowScrubbing }
        .sensoryFeedback(.selection, trigger: currentPage) { _, _ in isScrubbing }
        .animation(.easeInOut(duration: 0.2), value: currentPage)
        .animation(.easeInOut(duration: 0.2), value: isScrubbing)
    }

    #if os(iOS)
    private var scrubGesture: some UIGestureRecognizerRepresentable {
        LongPressDragGesture(
            minimumDuration: scrubPressDuration,
            onBegan: beginScrub,
            onChanged: scrub(by:),
            onEnded: endScrub
        )
    }
    #else
    private var scrubGesture: some Gesture {
        LongPressGesture(minimumDuration: scrubPressDuration)
            .sequenced(before: DragGesture(minimumDistance: 0))
            .onChanged { value in
                guard case .second(true, let drag) = value else { return }
                if !isScrubbing { beginScrub() }
                scrub(by: drag?.translation.width ?? 0)
            }
            .onEnded { _ in endScrub() }
    }
    #endif

    private func beginScrub() {
        scrubOrigin = currentIndex
    }

    private func scrub(by translation: CGFloat) {
        guard let scrubOrigin else { return }
        let steps = Int((translation / scrubDistancePerPage).rounded(.towardZero))
        select(index: scrubOrigin + steps)
    }

    private func endScrub() {
        scrubOrigin = nil
    }

    private func select(index: Int) {
        guard !pages.isEmpty else { return }
        let page = pages[min(max(index, 0), pages.count - 1)]
        if page != (currentPage ?? pages.first) {
            withAnimation { currentPage = page }
        }
    }
}

extension PageIndicator where Page: CaseIterable {
    init(currentPage: Binding<Page?>) {
        self.init(pages: Array(Page.allCases), currentPage: currentPage)
    }
}

#if os(iOS)
private struct LongPressDragGesture: UIGestureRecognizerRepresentable {
    let minimumDuration: TimeInterval
    let onBegan: () -> Void
    let onChanged: (CGFloat) -> Void
    let onEnded: () -> Void

    final class Coordinator {
        var startX: CGFloat = 0
    }

    func makeCoordinator(converter: CoordinateSpaceConverter) -> Coordinator {
        Coordinator()
    }

    func makeUIGestureRecognizer(context: Context) -> UILongPressGestureRecognizer {
        let recognizer = UILongPressGestureRecognizer()
        recognizer.minimumPressDuration = minimumDuration
        return recognizer
    }

    func handleUIGestureRecognizerAction(_ recognizer: UILongPressGestureRecognizer, context: Context) {
        let locationX = context.converter.localLocation.x
        switch recognizer.state {
        case .began:
            context.coordinator.startX = locationX
            onBegan()
        case .changed:
            onChanged(locationX - context.coordinator.startX)
        case .ended, .cancelled, .failed:
            onEnded()
        default:
            break
        }
    }
}
#endif

private enum PreviewPage: Int, CaseIterable { case a, b, c, d, e }

#Preview {
    @Previewable @State var currentPage: PreviewPage? = .c

    VStack(spacing: .large) {
        PageIndicator(currentPage: $currentPage)
        PageIndicator(pages: [PreviewPage.a, .c, .e], currentPage: .constant(.c))
    }
    .padding()
}
