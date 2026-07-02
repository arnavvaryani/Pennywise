import SwiftUI

struct PWSectionHeader: View {
    let title: String
    var subtitle: String? = nil
    var trailing: AnyView? = nil

    init(_ title: String, subtitle: String? = nil, trailing: AnyView? = nil) {
        self.title = title
        self.subtitle = subtitle
        self.trailing = trailing
    }

    var body: some View {
        HStack(alignment: subtitle == nil ? .center : .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(AppTheme.headlineFont())
                    .foregroundColor(AppTheme.textColor)

                if let subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(AppTheme.textColor.opacity(0.65))
                }
            }

            Spacer()

            if let trailing {
                trailing
            }
        }
    }
}

