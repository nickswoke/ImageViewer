import SwiftUI
import UIKit

/// A behavior that determines when the zoom level should be reset.
public enum ZoomResetBehavior {
    case automatic
    case onPageChange(currentPageIndex: Binding<Int>, pageIndex: Int)
}

/// A UIKit scroll view that supports pinch and double-tap zoom.
@MainActor
public struct ZoomableImage: UIViewRepresentable {
    let image: UIImage
    var resetBehavior: ZoomResetBehavior
    var onZoomStarted: (() -> Void)?
    var onZoomEnded: ((CGFloat) -> Void)?
    var onSingleTap: (() -> Void)?

    public init(image: UIImage, resetBehavior: ZoomResetBehavior = .automatic) {
        self.image = image
        self.resetBehavior = resetBehavior
    }

    public func makeUIView(context: Context) -> UIScrollView {
        let scrollView = UIScrollView()
        scrollView.delegate = context.coordinator
        scrollView.maximumZoomScale = 5
        scrollView.minimumZoomScale = 1
        scrollView.bouncesZoom = true
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false

        let imageView = UIImageView(image: image)
        imageView.contentMode = .scaleAspectFit
        imageView.tag = 1
        imageView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(imageView)
        NSLayoutConstraint.activate([
            imageView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            imageView.heightAnchor.constraint(equalTo: scrollView.heightAnchor),
            imageView.centerXAnchor.constraint(equalTo: scrollView.centerXAnchor),
            imageView.centerYAnchor.constraint(equalTo: scrollView.centerYAnchor)
        ])

        let doubleTap = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleDoubleTap(recognizer:)))
        doubleTap.numberOfTapsRequired = 2
        scrollView.addGestureRecognizer(doubleTap)
        let singleTap = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleSingleTap(recognizer:)))
        singleTap.require(toFail: doubleTap)
        scrollView.addGestureRecognizer(singleTap)
        return scrollView
    }

    public func updateUIView(_ scrollView: UIScrollView, context: Context) {
        context.coordinator.onZoomStarted = onZoomStarted
        context.coordinator.onZoomEnded = onZoomEnded
        context.coordinator.onSingleTap = onSingleTap
        if let imageView = scrollView.viewWithTag(1) as? UIImageView, imageView.image !== image {
            imageView.image = image
        }
        if case let .onPageChange(currentPageIndex, pageIndex) = resetBehavior,
           currentPageIndex.wrappedValue != pageIndex {
            DispatchQueue.main.async {
                scrollView.setZoomScale(scrollView.minimumZoomScale, animated: true)
            }
        }
    }

    public func makeCoordinator() -> Coordinator { Coordinator() }

    public final class Coordinator: NSObject, UIScrollViewDelegate {
        var onZoomStarted: (() -> Void)?
        var onZoomEnded: ((CGFloat) -> Void)?
        var onSingleTap: (() -> Void)?

        public func viewForZooming(in scrollView: UIScrollView) -> UIView? {
            scrollView.viewWithTag(1)
        }

        public func scrollViewWillBeginZooming(_ scrollView: UIScrollView, with view: UIView?) {
            onZoomStarted?()
        }

        public func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
            onZoomEnded?(scale)
        }

        @objc func handleDoubleTap(recognizer: UITapGestureRecognizer) {
            guard let scrollView = recognizer.view as? UIScrollView else { return }
            let targetScale = scrollView.zoomScale > scrollView.minimumZoomScale ? scrollView.minimumZoomScale : 2
            scrollView.setZoomScale(targetScale, animated: true)
        }

        @objc func handleSingleTap(recognizer: UITapGestureRecognizer) {
            onSingleTap?()
        }
    }
}

public extension ZoomableImage {
    func onZoomStarted(perform action: @escaping () -> Void) -> Self {
        var view = self
        view.onZoomStarted = action
        return view
    }

    func onZoomEnded(perform action: @escaping (CGFloat) -> Void) -> Self {
        var view = self
        view.onZoomEnded = action
        return view
    }

    func onSingleTap(perform action: @escaping () -> Void) -> Self {
        var view = self
        view.onSingleTap = action
        return view
    }
}
