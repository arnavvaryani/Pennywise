import SwiftUI

struct PWProgressBar: View {
    var progress: Double
    var height: CGFloat = 10
    var gradient: LinearGradient = LinearGradient(
        colors: [AppTheme.accentBlue.opacity(0.95), AppTheme.accentPurple.opacity(0.9)],
        startPoint: .leading,
        endPoint: .trailing
    )

    var body: some View {
        GeometryReader { geo in
            let clamped = min(max(progress, 0), 1)
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(AppTheme.cardStroke.opacity(0.45))
                    .frame(height: height)

                Capsule()
                    .fill(gradient)
                    .frame(width: max(height, geo.size.width * clamped), height: height)
            }
        }
        .frame(height: height)
    }
}

