//
//  FetchInsightsUseCase.swift
//  Pennywise
//
//  Use Case - Domain Layer
//
//  Single source of truth for the Insights screen's aggregations. All finance
//  math that used to live in InsightsView now lives here, so the view only
//  renders a prepared InsightsSummary.
//

import Foundation

/// A named monetary total (e.g. a category or vendor).
public struct NamedAmount: Identifiable {
    public let name: String
    public let amount: Double
    public var id: String { name }
    public init(name: String, amount: Double) {
        self.name = name
        self.amount = amount
    }
}

/// A labelled value for a simple bar chart (domain-level; the view maps this
/// onto its own chart type).
public struct SpendingBar: Identifiable {
    public let label: String
    public let value: Double
    public var id: String { label }
    public init(label: String, value: Double) {
        self.label = label
        self.value = value
    }
}

/// Prepared, ready-to-render result for the Insights screen.
public struct InsightsSummary {
    public let timeframe: TimeFrame
    public let totalSpending: Double
    public let totalIncome: Double
    public let last30DaysSpending: Double
    public let allTimeSpending: Double
    public let categoryBreakdown: [NamedAmount]
    public let topVendors: [NamedAmount]
    public let incomeSources: [NamedAmount]
    public let bars: [SpendingBar]
    public let monthlyData: [MonthlyFinancialData]
    /// Timeframe-filtered transactions, for the view's recent-activity lists.
    public let expenseTransactions: [Transaction]
    public let incomeTransactions: [Transaction]
    /// Whether the timeframe contains no transactions at all (for empty state).
    public let isEmpty: Bool

    public var netCashflow: Double { totalIncome - totalSpending }

    public var spendingVsIncomePercent: Int {
        guard totalIncome > 0 else { return 0 }
        return Int(min(max(totalSpending / totalIncome, 0), 1) * 100)
    }

    public var totalSavings: Double {
        monthlyData.reduce(0) { $0 + $1.netSavings }
    }
}

/// Computes the Insights screen summary for a given timeframe.
@MainActor
public final class FetchInsightsUseCase {
    private let transactionRepository: TransactionRepository
    private let budgetRepository: BudgetRepository

    public init(
        transactionRepository: TransactionRepository,
        budgetRepository: BudgetRepository
    ) {
        self.transactionRepository = transactionRepository
        self.budgetRepository = budgetRepository
    }

    public func execute(timeframe: TimeFrame) async throws -> InsightsSummary {
        let all = try await transactionRepository.fetchTransactions()
        let calendar = Calendar.current
        let now = Date()

        // Rolling window for the timeframe (matches the intended Insights behavior:
        // rolling, not calendar-to-date, so it survives month/year rollovers).
        let startDate: Date
        switch timeframe {
        case .week:
            startDate = calendar.date(byAdding: .day, value: -7, to: now) ?? now
        case .month:
            startDate = calendar.date(byAdding: .month, value: -1, to: now) ?? now
        case .year:
            startDate = calendar.date(byAdding: .year, value: -1, to: now) ?? now
        }

        let inTimeframe = all.filter { $0.date >= startDate && $0.date <= now }
        let expenses = inTimeframe.filter { $0.isExpense }
        let income = inTimeframe.filter { $0.isIncome }

        let totalSpending = expenses.reduce(0) { $0 + $1.amount }
        let totalIncome = abs(income.reduce(0) { $0 + $1.amount })

        // Category breakdown (expenses grouped by category, desc).
        var categories: [String: Double] = [:]
        for tx in expenses {
            categories[tx.category, default: 0] += tx.amount
        }
        let categoryBreakdown = categories
            .map { NamedAmount(name: $0.key, amount: $0.value) }
            .sorted { $0.amount > $1.amount }

        // Top vendors (expenses grouped by merchant, desc, top 5).
        var vendors: [String: Double] = [:]
        for tx in expenses {
            let merchant = tx.merchantName.isEmpty ? "Unknown Vendor" : tx.merchantName
            vendors[merchant, default: 0] += tx.amount
        }
        let topVendors = vendors
            .map { NamedAmount(name: $0.key, amount: $0.value) }
            .sorted { $0.amount > $1.amount }
            .prefix(5)
            .map { $0 }

        // Income sources (income grouped by merchant, desc).
        var sources: [String: Double] = [:]
        for tx in income {
            let source = tx.merchantName.isEmpty ? "Primary Income" : tx.merchantName
            sources[source, default: 0] += abs(tx.amount)
        }
        let incomeSources = sources
            .map { NamedAmount(name: $0.key, amount: $0.value) }
            .sorted { $0.amount > $1.amount }

        // Last-30-days and all-time spending (over ALL transactions).
        let thirtyStart = calendar.date(byAdding: .day, value: -30, to: now) ?? now
        let last30DaysSpending = all
            .filter { $0.date >= thirtyStart && $0.date <= now && $0.isExpense }
            .reduce(0) { $0 + $1.amount }
        let allTimeSpending = all.filter { $0.isExpense }.reduce(0) { $0 + $1.amount }

        let bars = spendingBars(for: timeframe, transactions: all, calendar: calendar, now: now)
        let monthlyData = budgetRepository.getMonthlyFinancialData(transactions: all)

        return InsightsSummary(
            timeframe: timeframe,
            totalSpending: totalSpending,
            totalIncome: totalIncome,
            last30DaysSpending: last30DaysSpending,
            allTimeSpending: allTimeSpending,
            categoryBreakdown: categoryBreakdown,
            topVendors: topVendors,
            incomeSources: incomeSources,
            bars: bars,
            monthlyData: monthlyData,
            expenseTransactions: expenses,
            incomeTransactions: income,
            isEmpty: inTimeframe.isEmpty
        )
    }

    // MARK: - Chart bins (7 days / 8 months / 12 months of expense sums)

    private func spendingBars(
        for timeframe: TimeFrame,
        transactions: [Transaction],
        calendar: Calendar,
        now: Date
    ) -> [SpendingBar] {
        switch timeframe {
        case .week:
            let labelFormatter = DateFormatter()
            labelFormatter.dateFormat = "EEE"
            let days: [Date] = (0..<7).compactMap {
                calendar.date(byAdding: .day, value: -(6 - $0), to: now)
            }
            return days.map { day in
                let start = calendar.startOfDay(for: day)
                let end = calendar.date(byAdding: .day, value: 1, to: start) ?? start
                let sum = transactions
                    .filter { $0.date >= start && $0.date < end && $0.isExpense }
                    .reduce(0) { $0 + $1.amount }
                return SpendingBar(label: labelFormatter.string(from: start), value: sum)
            }
        case .month:
            return monthlyBars(count: 8, transactions: transactions, calendar: calendar, now: now)
        case .year:
            return monthlyBars(count: 12, transactions: transactions, calendar: calendar, now: now)
        }
    }

    private func monthlyBars(
        count: Int,
        transactions: [Transaction],
        calendar: Calendar,
        now: Date
    ) -> [SpendingBar] {
        let labelFormatter = DateFormatter()
        labelFormatter.dateFormat = "MMM"
        let months: [Date] = (0..<count).compactMap {
            calendar.date(byAdding: .month, value: -((count - 1) - $0), to: now)
        }
        return months.map { monthDate in
            let comps = calendar.dateComponents([.year, .month], from: monthDate)
            let start = calendar.date(from: comps) ?? monthDate
            let end = calendar.date(byAdding: .month, value: 1, to: start) ?? start
            let sum = transactions
                .filter { $0.date >= start && $0.date < end && $0.isExpense }
                .reduce(0) { $0 + $1.amount }
            return SpendingBar(label: labelFormatter.string(from: start), value: sum)
        }
    }
}
