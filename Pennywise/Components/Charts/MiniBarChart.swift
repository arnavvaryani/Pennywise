import SwiftUI

struct MiniBarChart: View {
    struct Bar: Identifiable {
        let id = UUID()
        let value: Double
        let label: String
    }

    let bars: [Bar]
    var accent: Color = Color.pink

    var body: some View {
        GeometryReader { geo in
            let maxV = max(bars.map(\.value).max() ?? 1, 0.0001)
            HStack(alignment: .bottom, spacing: 6) {
                ForEach(bars) { bar in
                    VStack(spacing: 6) {
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(accent.opacity(0.85))
                            .frame(height: max(6, geo.size.height * CGFloat(bar.value / maxV)))

                        Text(bar.label)
                            .font(.caption2)
                            .foregroundColor(AppTheme.textColor.opacity(0.55))
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .frame(height: 92)
    }
}

