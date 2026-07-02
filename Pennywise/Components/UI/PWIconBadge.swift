import SwiftUI

struct PWIconBadge: View {
    let systemImage: String
    var tint: Color = AppTheme.accentBlue
    var size: CGFloat = 40

    var body: some View {
        ZStack {
            Circle()
                .fill(tint.opacity(0.18))
                .frame(width: size, height: size)

            Image(systemName: systemImage)
                .font(.system(size: size * 0.42, weight: .semibold))
                .foregroundColor(tint.opacity(0.95))
        }
    }
}

