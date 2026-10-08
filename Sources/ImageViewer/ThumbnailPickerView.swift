import SwiftUI
import UIKit

/// Selects an image page from the viewer's thumbnail strip.
@MainActor
public struct ThumbnailPickerView: View {
    private let imageCount: Int
    private let imageAtIndex: (Int) -> UIImage?
    private let imageHeight: CGFloat
    @Binding private var currentImageIndex: Int

    private let animation: Animation = .interpolatingSpring(stiffness: 500, damping: 50)
    private let biggerPadding: CGFloat = 10
    private let smallerPadding: CGFloat = 4
    private let cornerRadius: CGFloat = 4

    public init(
        imageCount: Int,
        imageAtIndex: @escaping (Int) -> UIImage?,
        imageHeight: CGFloat,
        currentImageIndex: Binding<Int>
    ) {
        self.imageCount = imageCount
        self.imageAtIndex = imageAtIndex
        self.imageHeight = imageHeight
        self._currentImageIndex = currentImageIndex
    }

    public init(images: [UIImage], imageHeight: CGFloat, currentImageIndex: Binding<Int>) {
        self.init(
            imageCount: images.count,
            imageAtIndex: { images.indices.contains($0) ? images[$0] : nil },
            imageHeight: imageHeight,
            currentImageIndex: currentImageIndex
        )
    }

    public var body: some View {
        GeometryReader { geometry in
            ScrollViewReader { scrollProxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 0) {
                        ForEach(0..<imageCount, id: \.self) { index in
                            let isSelected = currentImageIndex == index
                            let thumbnailWidth = isSelected ? imageHeight : imageHeight / 1.5
                            Button {
                                currentImageIndex = index
                            } label: {
                                Group {
                                    if let image = imageAtIndex(index) {
                                        Image(uiImage: image)
                                            .resizable()
                                            .scaledToFill()
                                    } else {
                                        Rectangle()
                                            .fill(.white.opacity(0.16))
                                            .overlay {
                                                ProgressView().tint(.white)
                                            }
                                    }
                                }
                                .frame(width: thumbnailWidth, height: imageHeight)
                                .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
                                .padding(.horizontal, isSelected ? biggerPadding : smallerPadding)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Photo \(index + 1) of \(imageCount)")
                            .accessibilityAddTraits(isSelected ? .isSelected : [])
                            .accessibilityIdentifier("image-viewer-thumbnail-\(index)")
                            .id(index)
                        }
                    }
                    .padding(.horizontal, max(0, (geometry.size.width - imageHeight) / 2))
                }
                .onChange(of: currentImageIndex) { _, newValue in
                    withAnimation(animation) { scrollProxy.scrollTo(newValue, anchor: .center) }
                }
                .onAppear { scrollProxy.scrollTo(currentImageIndex, anchor: .center) }
            }
        }
        .frame(height: imageHeight + biggerPadding * 2)
    }
}
