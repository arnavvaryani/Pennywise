import SwiftUI

struct HomeActivityRow: View {
    let transaction: Transaction

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.18))
                    .frame(width: 44, height: 44)

                Image(systemName: iconName)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(iconColor)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(transaction.merchantName.isEmpty ? transaction.name : transaction.merchantName)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(AppTheme.textColor)
                    .lineLimit(1)

                Text(transaction.category)
                    .font(.caption)
                    .foregroundColor(AppTheme.textColor.opacity(0.6))
                    .lineLimit(1)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                let isIncome = transaction.amount < 0
                Text(isIncome ? "+\(CurrencyFormatter.format(abs(transaction.amount)))" : "-\(CurrencyFormatter.format(abs(transaction.amount)))")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(isIncome ? AppTheme.primaryGreen : AppTheme.expenseColor)
                    .monospacedDigit()

                Text(shortDate(transaction.date))
                    .font(.caption)
                    .foregroundColor(AppTheme.textColor.opacity(0.6))
            }
        }
        .padding(.vertical, 12)
        .contentShape(Rectangle())
    }

    private var iconName: String {
        let c = transaction.category.lowercased()
        if c.contains("entertain") { return "play.tv" }
        if c.contains("shop") { return "cart" }
        if c.contains("transfer") || c.contains("income") { return "arrow.down.circle" }
        if c.contains("cash") || c.contains("atm") { return "banknote" }
        if c.contains("food") { return "fork.knife" }
        return "dollarsign.circle"
    }

    private var iconColor: Color {
        let c = transaction.category.lowercased()
        if c.contains("entertain") { return AppTheme.accentPurple }
        if c.contains("shop") { return AppTheme.accentBlue }
        if c.contains("transfer") || c.contains("income") { return AppTheme.primaryGreen }
        if c.contains("cash") || c.contains("atm") { return AppTheme.alertOrange }
        if c.contains("food") { return AppTheme.primaryGreen }
        return AppTheme.accentBlue
    }

    private func shortDate(_ date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) { return "Today" }
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }
}

