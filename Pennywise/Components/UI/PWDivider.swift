import SwiftUI

struct PWDivider: View {
    var inset: CGFloat = 0
    var opacity: Double = 1.0

    var body: some View {
        Divider()
            .background(AppTheme.cardStroke.opacity(opacity))
            .padding(.leading, inset)
    }
}

