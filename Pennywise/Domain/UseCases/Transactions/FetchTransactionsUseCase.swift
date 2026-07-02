//
//  FetchTransactionsUseCase.swift
//  Pennywise
//
//  Use Case - Domain Layer
//

import Foundation

/// Use case for fetching transactions and calculating financial summaries
@MainActor
public final class FetchTransactionsUseCase {
    private let transactionRepository: TransactionRepository
    private let accountRepository: AccountRepository
    
    public init(
        transactionRepository: TransactionRepository,
        accountRepository: AccountRepository
    ) {
        self.transactionRepository = transactionRepository
        self.accountRepository = accountRepository
    }
    
    public func execute() async throws -> FinancialSummary {
        // Repositories are @MainActor, so these calls serialize on the main
        // actor regardless; await them sequentially rather than via `async let`
        // (which would send non-Sendable `self` into a child task).
        let fetchedTransactions = try await transactionRepository.fetchTransactions()
        let fetchedAccounts = try await accountRepository.fetchAccounts()

        // Calculate totals
        let totalBalance = fetchedAccounts.reduce(0) { $0 + $1.balance }
        let currentMonthTransactions = filterCurrentMonth(fetchedTransactions)
        let income = calculateIncome(from: currentMonthTransactions)
        let expenses = calculateExpenses(from: currentMonthTransactions)

        return FinancialSummary(
            transactions: fetchedTransactions,
            accounts: fetchedAccounts,
            totalBalance: totalBalance,
            monthlyIncome: income,
            monthlyExpenses: expenses,
            monthlyExpenseBars: monthlyExpenseBars(from: fetchedTransactions),
            totalDebt: total(fetchedTransactions, categoryContains: "debt"),
            totalInvestments: total(fetchedTransactions, categoryContains: "investment")
        )
    }

    // MARK: - Business Logic

    private func filterCurrentMonth(_ transactions: [Transaction]) -> [Transaction] {
        transactions.filter { $0.isInCurrentMonth }
    }

    private func calculateIncome(from transactions: [Transaction]) -> Double {
        transactions
            .filter { $0.isIncome }
            .reduce(0) { $0 + $1.absoluteAmount }
    }

    private func calculateExpenses(from transactions: [Transaction]) -> Double {
        transactions
            .filter { $0.isExpense }
            .reduce(0) { $0 + $1.amount }
    }

    /// Sum of the absolute amounts of transactions whose category contains the
    /// given keyword (e.g. "debt", "investment").
    private func total(_ transactions: [Transaction], categoryContains keyword: String) -> Double {
        transactions
            .filter { $0.category.lowercased().contains(keyword) }
            .reduce(0) { $0 + abs($1.amount) }
    }

    /// Last 8 months of expense totals, oldest→newest.
    private func monthlyExpenseBars(from transactions: [Transaction]) -> [SpendingBar] {
        let calendar = Calendar.current
        let now = Date()
        let labelFormatter = DateFormatter()
        labelFormatter.dateFormat = "MMM"
        let months: [Date] = (0..<8).compactMap {
            calendar.date(byAdding: .month, value: -(7 - $0), to: now)
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

/// Financial summary result
public struct FinancialSummary {
    public let transactions: [Transaction]
    public let accounts: [Account]
    public let totalBalance: Double
    public let monthlyIncome: Double
    public let monthlyExpenses: Double
    public let monthlyExpenseBars: [SpendingBar]
    public let totalDebt: Double
    public let totalInvestments: Double

    public var netSavings: Double {
        monthlyIncome - monthlyExpenses
    }
    
    public var savingsRate: Double {
        guard monthlyIncome > 0 else { return 0 }
        return (netSavings / monthlyIncome) * 100
    }
}

