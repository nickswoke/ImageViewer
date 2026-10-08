# ImageViewer
An Image Viewer component created for iOS in SwiftUI and UIKit.
Referenced in my Medium article [here](https://medium.com/@lukaszima41/building-a-polished-image-viewer-for-ios-8e2f935222a6).

This repository is maintained by `nickswoke` as a Swift package for use in Kin, with permission from the original author. The viewer source is based on [Silenterc/ImageViewer](https://github.com/Silenterc/ImageViewer), Copyright © 2025 Lukas Zima. The original author retains copyright to their work. This repository does not grant rights beyond the permission provided directly by the author.

## Swift Package Manager

Add `https://github.com/nickswoke/ImageViewer` to Xcode as a package dependency and link the `ImageViewer` product.

## Lazy image loading

The original `[UIImage]` initializer remains available. For private or remote images, use the lazy initializer so the current photo and its neighbors load as the user browses:

```swift
PreviewImagesView(
    imageCount: photoCount,
    initialImageIndex: selectedIndex,
    imageAt: { index in try await loadImage(at: index) },
    onDismiss: { dismiss() }
)
```

<img width="1400" height="1400" alt="medium" src="https://github.com/user-attachments/assets/d95dcc8b-8a4d-40d0-a536-e0441378cce2" />
