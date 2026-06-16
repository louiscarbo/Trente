//
//  ZoomableImageView.swift
//  Trente
//
//  Created by Louis Carbo Estaque on 26/04/2025.
//

import SwiftUI
#if canImport(UIKit)
import UIKit

struct ZoomableImageView: View {
    let image: Image
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Color.black.ignoresSafeArea()

            ZoomableUIKitContainer(
                image: image,
                onDismiss: { dismiss() }
            )
            .ignoresSafeArea()

            // Dismiss button
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.title2)
                    .padding(4)
            }
            .padding(.top, 12)
            .padding(.trailing, 12)
            .accessibilityLabel(Text("Close"))
            .buttonBorderShape(.circle)
            .buttonStyle(.glass)
        }
    }
}

// MARK: - UIKit bridge

private struct ZoomableUIKitContainer: UIViewRepresentable {
    let image: Image
    let onDismiss: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onDismiss: onDismiss)
    }

    func makeUIView(context: Context) -> UIScrollView {
        let scrollView = UIScrollView()
        scrollView.backgroundColor = .clear
        scrollView.delegate = context.coordinator
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.bouncesZoom = true
        scrollView.bounces = true
        scrollView.decelerationRate = .fast
        scrollView.minimumZoomScale = 1.0
        scrollView.maximumZoomScale = 5.0
        scrollView.zoomScale = 1.0
        scrollView.clipsToBounds = false

        // Host SwiftUI Image inside UIScrollView
        let hosting = UIHostingController(
            rootView: image
                .resizable()
                .scaledToFit()
                .background(Color.clear)
        )
        hosting.view.backgroundColor = .clear
        hosting.view.translatesAutoresizingMaskIntoConstraints = false

        scrollView.addSubview(hosting.view)

        // Pin hosted view to scrollView’s content layout guides
        NSLayoutConstraint.activate([
            hosting.view.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            hosting.view.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            hosting.view.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            hosting.view.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),

            // At base (fit) scale, hosted view matches the visible frame size.
            hosting.view.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),
            hosting.view.heightAnchor.constraint(equalTo: scrollView.frameLayoutGuide.heightAnchor)
        ])

        // Store non-generic references to avoid 'some View' opaque type mismatch
        context.coordinator.scrollView = scrollView
        context.coordinator.hostingVC = hosting          // strong retain of the controller
        context.coordinator.contentView = hosting.view   // the zoomable UIView

        // Gesture: Double-tap to zoom in/out at the tap location
        let doubleTap = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleDoubleTap(_:)))
        doubleTap.numberOfTapsRequired = 2
        doubleTap.delaysTouchesBegan = false
        doubleTap.cancelsTouchesInView = false
        doubleTap.delegate = context.coordinator
        scrollView.addGestureRecognizer(doubleTap)

        // Gesture: Swipe-down to dismiss (only at base scale)
        let panToDismiss = UIPanGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handlePanToDismiss(_:)))
        panToDismiss.maximumNumberOfTouches = 1
        panToDismiss.cancelsTouchesInView = false
        panToDismiss.delegate = context.coordinator
        scrollView.addGestureRecognizer(panToDismiss)

        // Accessibility shortcuts
        context.coordinator.installAccessibilityActions()

        return scrollView
    }

    func updateUIView(_ scrollView: UIScrollView, context: Context) {
        // Keep zoom within limits.
        let minZ = scrollView.minimumZoomScale
        let maxZ = scrollView.maximumZoomScale
        if scrollView.zoomScale < minZ {
            scrollView.setZoomScale(minZ, animated: false)
        } else if scrollView.zoomScale > maxZ {
            scrollView.setZoomScale(maxZ, animated: false)
        }
        // Recalculate insets to keep content centered.
        context.coordinator.updateContentInsets()
    }

    // MARK: - Coordinator

    final class Coordinator: NSObject, UIScrollViewDelegate, UIGestureRecognizerDelegate {
        weak var scrollView: UIScrollView?
        // Non-generic storage avoids opaque type clashes
        var hostingVC: UIViewController?
        var contentView: UIView?
        private let onDismiss: () -> Void

        // Tuning
        private let doubleTapTargetZoom: CGFloat = 2.5
        private let dismissTranslationThreshold: CGFloat = 120.0
        private let dismissVelocityThreshold: CGFloat = 950.0 // points/s

        init(onDismiss: @escaping () -> Void) {
            self.onDismiss = onDismiss
        }

        // MARK: UIScrollViewDelegate

        func viewForZooming(in scrollView: UIScrollView) -> UIView? {
            return contentView
        }

        func scrollViewDidZoom(_ scrollView: UIScrollView) {
            updateContentInsets()
        }

        func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
            // Clamp and re-center after gesture ends
            let clamped = min(max(scale, scrollView.minimumZoomScale), scrollView.maximumZoomScale)
            if clamped != scale {
                scrollView.setZoomScale(clamped, animated: true)
            }
            updateContentInsets()
        }

        func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
            if !decelerate { centerContentIfSmaller() }
        }

        func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
            centerContentIfSmaller()
        }

        // MARK: Centering / Insets

        func updateContentInsets() {
            guard let scroll = scrollView,
                  let content = contentView else { return }

            // Ensure layout is up to date
            scroll.layoutIfNeeded()
            content.layoutIfNeeded()

            let boundsSize = scroll.bounds.size
            let contentSize = content.frame.size

            let horizontalInset = max((boundsSize.width - contentSize.width) * 0.5, 0)
            let verticalInset = max((boundsSize.height - contentSize.height) * 0.5, 0)

            scroll.contentInset = UIEdgeInsets(top: verticalInset,
                                               left: horizontalInset,
                                               bottom: verticalInset,
                                               right: horizontalInset)
        }

        func centerContentIfSmaller() {
            updateContentInsets()
        }

        // MARK: Double-tap zoom

        @objc func handleDoubleTap(_ recognizer: UITapGestureRecognizer) {
            guard let scroll = scrollView,
                  let contentView = contentView else { return }

            let minZ = scroll.minimumZoomScale
            let maxZ = scroll.maximumZoomScale
            let current = scroll.zoomScale

            let target: CGFloat
            if abs(current - minZ) < 0.01 {
                target = min(maxZ, max(minZ, doubleTapTargetZoom))
            } else {
                target = minZ
            }

            // Tap location in content coordinates
            let pointInContent = recognizer.location(in: contentView)
            let zoomRect = zoomRectForScale(target, center: pointInContent, in: scroll)
            scroll.zoom(to: zoomRect, animated: true)
        }

        private func zoomRectForScale(_ scale: CGFloat, center: CGPoint, in scrollView: UIScrollView) -> CGRect {
            var zoomRect = CGRect.zero
            zoomRect.size.width  = scrollView.bounds.size.width / scale
            zoomRect.size.height = scrollView.bounds.size.height / scale
            zoomRect.origin.x = center.x - (zoomRect.size.width / 2.0)
            zoomRect.origin.y = center.y - (zoomRect.size.height / 2.0)
            return zoomRect
        }

        // MARK: Swipe-down to dismiss

        @objc func handlePanToDismiss(_ recognizer: UIPanGestureRecognizer) {
            guard let scroll = scrollView else { return }

            // Only when at base scale (fit)
            let isAtBase = abs(scroll.zoomScale - scroll.minimumZoomScale) < 0.01
            if !isAtBase { return }

            let velocity = recognizer.velocity(in: scroll)
            let translation = recognizer.translation(in: scroll)

            switch recognizer.state {
            case .ended:
                let isDownward = velocity.y > dismissVelocityThreshold || translation.y > dismissTranslationThreshold
                let isMostlyVertical = abs(translation.y) > abs(translation.x)
                if isDownward && isMostlyVertical {
                    onDismiss()
                }
            default:
                break
            }
        }

        // MARK: Accessibility

        func installAccessibilityActions() {
            guard let view = contentView else { return }
            view.isAccessibilityElement = true
            view.accessibilityLabel = "Photo"
            view.accessibilityTraits = [.image, .allowsDirectInteraction]

            let zoomIn = UIAccessibilityCustomAction(name: "Zoom in") { [weak self] _ in
                guard let self, let scroll = self.scrollView else { return false }
                let target = min(scroll.zoomScale * 1.5, scroll.maximumZoomScale)
                scroll.setZoomScale(target, animated: true)
                return true
            }
            let zoomOut = UIAccessibilityCustomAction(name: "Zoom out") { [weak self] _ in
                guard let self, let scroll = self.scrollView else { return false }
                let target = max(scroll.zoomScale / 1.5, scroll.minimumZoomScale)
                scroll.setZoomScale(target, animated: true)
                return true
            }
            view.accessibilityCustomActions = [zoomIn, zoomOut]
        }

        // MARK: Gesture delegate

        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
            // Allow simultaneous recognition with the scroll view’s internal pan/pinch.
            return true
        }
    }
}
#endif
