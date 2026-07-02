import SwiftUI

struct PWPill: View {
    let title: String
    var systemImage: String? = nil
    var tint: Color = AppTheme.accentBlue
    var isSelected: Bool = false

    var body: some View {
        HStack(spacing: 6) {
            if let systemImage {
                Image(systemName: systemImage)
                    .font(.caption.weight(.semibold))
            }

            Text(title)
                .font(.caption.weight(.semibold))
        }
        .foregroundColor(isSelected ? .white : AppTheme.textColor.opacity(0.8))
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        // Liquid Glass capsule; tinted with the pill's color when selected.
        .glassEffect(isSelected ? .regular.tint(tint) : .regular, in: .capsule)
    }
}

