import SwiftUI

@MainActor
public struct ImagePreviewToolbar: View {
    private let onDismiss: () -> Void
    private let downloadAction: (() -> Void)?
    private let shareAction: (() -> Void)?

    public init(onDismiss: @escaping () -> Void, downloadAction: (() -> Void)? = nil, shareAction: (() -> Void)? = nil) {
        self.onDismiss = onDismiss
        self.downloadAction = downloadAction
        self.shareAction = shareAction
    }
    
    public var body: some View {
        HStack {
            ImageToolbarButton(
                icon: Image(systemName: "xmark"),
                accessibilityLabel: "Close photo viewer",
                action: onDismiss
            )
            
            Spacer()
            
            if let downloadAction {
                ImageToolbarButton(icon: Image(systemName: "arrow.down"), accessibilityLabel: "Download photo", action: downloadAction)
            }
            if let shareAction {
                ImageToolbarButton(icon: Image(systemName: "square.and.arrow.up"), accessibilityLabel: "Share photo", action: shareAction)
            }
        }
        .foregroundStyle(.white)
    }
}

/// A reusable button component for the toolbar.
private struct ImageToolbarButton: View {
    let icon: Image
    let accessibilityLabel: String
    let action: () -> Void
    
    private let buttonWidth: CGFloat = 24
    private let buttonHeight: CGFloat = 24
    private let buttonPadding: CGFloat = 8
    
    var body: some View {
        Button(action: action) {
            icon
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: buttonWidth, height: buttonHeight)
                .padding(buttonPadding)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel)
        .frame(minWidth: 44, minHeight: 44)
    }
}
