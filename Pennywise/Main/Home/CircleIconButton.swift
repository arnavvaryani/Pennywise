import SwiftUI

struct CircleIconButton: View {
    let systemImage: String

    var body: some View {
        ZStack {
            Circle()
                .fill(AppTheme.cardBackground.opacity(0.9))
                .frame(width: 42, height: 42)
                .overlay(Circle().stroke(AppTheme.cardStroke, lineWidth: 1))

            Image(systemName: systemImage)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(AppTheme.textColor.opacity(0.85))
        }
    }
}

