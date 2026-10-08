import SwiftUI
import UIKit

/// Paged full-screen photo viewer with zoom and a thumbnail strip.
@MainActor
public struct PreviewImagesView: View {
    private enum ImageSource {
        case loaded([UIImage])
        case lazy(count: Int, imageAt: @MainActor (Int) async throws -> UIImage)
    }

    private let source: ImageSource
    private let onDismiss: () -> Void
    private let downloadAction: ((UIImage) -> Void)?
    private let shareAction: ((UIImage) -> Void)?

    @State private var currentImageIndex: Int
    @State private var loadedImages: [Int: UIImage] = [:]
    @State private var failedImages: Set<Int> = []
    @State private var attempts: [Int: Int] = [:]
    @State private var showToolbar = true

    private var imageCount: Int {
        switch source {
        case .loaded(let images): images.count
        case .lazy(let count, _): count
        }
    }

    public init(
        images: [UIImage],
        initialImageIndex: Int = 0,
        onDismiss: @escaping () -> Void,
        downloadAction: ((UIImage) -> Void)? = nil,
        shareAction: ((UIImage) -> Void)? = nil
    ) {
        precondition(!images.isEmpty, "Image viewer requires at least one image")
        let safeIndex = min(max(initialImageIndex, 0), images.count - 1)
        self.source = .loaded(images)
        self.onDismiss = onDismiss
        self.downloadAction = downloadAction
        self.shareAction = shareAction
        _currentImageIndex = State(initialValue: safeIndex)
        _loadedImages = State(initialValue: Dictionary(uniqueKeysWithValues: images.enumerated().map { ($0.offset, $0.element) }))
    }

    /// Creates a viewer that fetches only the current image and adjacent pages.
    /// The loader is retried when the user taps a failed page.
    public init(
        imageCount: Int,
        initialImageIndex: Int = 0,
        imageAt: @escaping @MainActor (Int) async throws -> UIImage,
        onDismiss: @escaping () -> Void,
        downloadAction: ((UIImage) -> Void)? = nil,
        shareAction: ((UIImage) -> Void)? = nil
    ) {
        precondition(imageCount > 0, "Image viewer requires at least one image")
        let safeIndex = min(max(initialImageIndex, 0), imageCount - 1)
        self.source = .lazy(count: imageCount, imageAt: imageAt)
        self.onDismiss = onDismiss
        self.downloadAction = downloadAction
        self.shareAction = shareAction
        _currentImageIndex = State(initialValue: safeIndex)
    }

    public var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black.ignoresSafeArea()

                TabView(selection: $currentImageIndex) {
                    ForEach(0..<imageCount, id: \.self) { index in
                        imagePage(index)
                            .ignoresSafeArea()
                            .tag(index)
                    }
                }
                .frame(maxHeight: .infinity)
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.default, value: currentImageIndex)

                if showToolbar {
                    VStack(spacing: 0) {
                        ImagePreviewToolbar(
                            onDismiss: onDismiss,
                            downloadAction: currentImageDownload,
                            shareAction: currentImageShare
                        )
                        .overlay(alignment: .trailing) {
                            Text("\(currentImageIndex + 1) of \(imageCount)")
                                .font(.subheadline.monospacedDigit())
                                .foregroundStyle(.white)
                                .accessibilityIdentifier("image-viewer-position")
                                .padding(.trailing, 4)
                        }
                        .padding(.top, geometry.safeAreaInsets.top + 4)
                        .padding(.horizontal, 16)
                        Spacer()
                        ThumbnailPickerView(
                            imageCount: imageCount,
                            imageAtIndex: { loadedImages[$0] },
                            imageHeight: 40,
                            currentImageIndex: $currentImageIndex
                        )
                        .frame(height: 56)
                        .padding(.bottom, geometry.safeAreaInsets.bottom + 4)
                    }
                    .transition(.opacity)
                }
            }
            .background(.black)
            .animation(.easeInOut(duration: 0.2), value: showToolbar)
        }
        .ignoresSafeArea()
        .task(id: "\(currentImageIndex)-\(attempts[currentImageIndex, default: 0])") {
            guard case .lazy(let count, let imageAt) = source else { return }
            let visible = [currentImageIndex, currentImageIndex - 1, currentImageIndex + 1]
                .filter { (0..<count).contains($0) }
            let visibleSet = Set(visible)
            loadedImages = loadedImages.filter { visibleSet.contains($0.key) }
            failedImages = failedImages.intersection(visibleSet)
            for index in visible where loadedImages[index] == nil && !failedImages.contains(index) {
                do {
                    let image = try await imageAt(index)
                    try Task.checkCancellation()
                    loadedImages[index] = image
                } catch is CancellationError {
                    return
                } catch {
                    if !Task.isCancelled { failedImages.insert(index) }
                }
            }
        }
    }

    private var currentImage: UIImage? { loadedImages[currentImageIndex] }

    private var currentImageDownload: (() -> Void)? {
        guard let image = currentImage, let downloadAction else { return nil }
        return { downloadAction(image) }
    }

    private var currentImageShare: (() -> Void)? {
        guard let image = currentImage, let shareAction else { return nil }
        return { shareAction(image) }
    }

    @ViewBuilder
    private func imagePage(_ index: Int) -> some View {
        if let image = loadedImages[index] {
            ZoomableImage(
                image: image,
                resetBehavior: .onPageChange(currentPageIndex: $currentImageIndex, pageIndex: index)
            )
            .onZoomStarted { setToolbarVisible(false) }
            .onZoomEnded { scale in if scale == 1 { setToolbarVisible(true) } }
            .onSingleTap { setToolbarVisible(!showToolbar) }
            .accessibilityLabel("Photo \(index + 1) of \(imageCount)")
        } else if failedImages.contains(index) {
            Button {
                failedImages.remove(index)
                attempts[index, default: 0] += 1
            } label: {
                ContentUnavailableView("Couldn't load photo", systemImage: "arrow.clockwise", description: Text("Tap to retry"))
                    .foregroundStyle(.white)
            }
            .accessibilityIdentifier("image-viewer-retry-\(index)")
        } else {
            ProgressView("Loading photo")
                .tint(.white)
                .foregroundStyle(.white)
                .accessibilityIdentifier("image-viewer-loading-\(index)")
        }
    }

    private func setToolbarVisible(_ visible: Bool) {
        withAnimation { showToolbar = visible }
    }
}
