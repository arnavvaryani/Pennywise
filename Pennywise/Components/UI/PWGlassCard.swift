import SwiftUI

struct PWGlassCard<Content: View>: View {
    private let cornerRadius: CGFloat
    private let content: Content

    init(cornerRadius: CGFloat = 22, @ViewBuilder content: () -> Content) {
        self.cornerRadius = cornerRadius
        self.content = content()
    }

    var body: some View {
        content
            .padding(16)
            // Liquid Glass (iOS 26). Replaces the previous faux-glass fill,
            // stroke, and shadow with the real material.
            .glassEffect(.regular, in: .rect(cornerRadius: cornerRadius, style: .continuous))
    }
}

