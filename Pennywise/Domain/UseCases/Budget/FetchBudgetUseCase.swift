//
//  FetchBudgetUseCase.swift
//  Pennywise
//
//  Use Case - Domain Layer
//

import Foundation

/// Use case for fetching budget and calculating spending
@MainActor
public final class FetchBudgetUseCase {
    private let budgetRepository: BudgetRepository
    private let transactionRepository: TransactionRepository
    
    public init(
        budgetRepository: BudgetRepository,
        transactionRepository: TransactionRepository
    ) {
        self.budgetRepository = budgetRepository
        self.transactionRepository = transactionRepository
    }
    
    public func execute() async throws -> BudgetSummary {
        // Repositories are @MainActor, so these calls serialize on the main
        // actor regardless; await them sequentially rather than via `async let`
        // (which would send non-Sendable `self` into a child task).
        let budgetCategories = try await budgetRepository.fetchBudgetCategories()

        // Use a rolling 30-day window for "spent" rather than the current
        // calendar month. Calendar-month spend reads ~0 right after a month
        // rollover (e.g. on the 1st), which makes budgets look empty even when
        // there's recent activity.
        let allTransactions = try await transactionRepository.fetchTransactions()
        let windowStart = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        let currentTransactions = allTransactions.filter { $0.date >= windowStart }

        // Calculate spending for each category
        var categorySpending: [String: Double] = [:]
        for category in budgetCategories {
            let spending = budgetRepository.calculateCategorySpending(
                categoryName: category.name,
                transactions: currentTransactions
            )
            // Key by category id (matches BudgetViewModel and UI lookups)
            categorySpending[category.id] = spending
        }
        
        // Calculate totals
        let totalBudget = budgetCategories.reduce(0) { $0 + $1.amount }
        let totalSpent = currentTransactions
            .filter { $0.isExpense }
            .reduce(0) { $0 + $1.amount }
        
        let status = BudgetStatus.calculate(spent: totalSpent, budgeted: totalBudget)
        
        return BudgetSummary(
            categories: budgetCategories,
            categorySpending: categorySpending,
            totalBudget: totalBudget,
            totalSpent: totalSpent,
            status: status
        )
    }
}

/// Budget summary result
public struct BudgetSummary {
    public let categories: [BudgetCategory]
    public let categorySpending: [String: Double]
    public let totalBudget: Double
    public let totalSpent: Double
    public let status: BudgetStatus
    
    public var remainingBudget: Double {
        max(totalBudget - totalSpent, 0)
    }
    
    public var spendingPercentage: Double {
        guard totalBudget > 0 else { return 0 }
        return min(totalSpent / totalBudget, 1.0)
    }
}

