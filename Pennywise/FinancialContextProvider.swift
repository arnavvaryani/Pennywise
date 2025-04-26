//
//  FinancialContextProvider.swift
//  Pennywise
//
//  Created by Arnav Varyani on 4/25/25.
//

import Foundation
import Combine

/// Provides financial context from app data for the Gemini AI assistant
class FinancialContextProvider {
    // MARK: - Singleton
    static let shared = FinancialContextProvider()
    
    // MARK: - Properties
    private let plaidManager = PlaidManager.shared
    private let authService = AuthenticationService.shared
    
    // MARK: - Initialization
    private init() {}
    
    // MARK: - Public Methods
    
    /// Gathers current financial context from the app's data sources
    /// - Parameter completion: Callback with the constructed financial context
    func getCurrentContext(completion: @escaping (FinancialContext) -> Void) {
        var context = FinancialContext()
        
        // 1. Add account information
        context.accounts = plaidManager.accounts
        
        // 2. Calculate total balance
        context.totalBalance = plaidManager.accounts.reduce(0) { $0 + $1.balance }
        
        // 3. Add budget categories and spending
        context.budgetCategories = plaidManager.getBudgetCategories()
        context.categorySpending = calculateCategorySpending()
        
        // 4. Add recent transactions
        context.recentTransactions = getRecentTransactions()
        
        // 5. Calculate monthly income and expenses
        let (income, expenses) = calculateMonthlyIncomeAndExpenses()
        context.monthlyIncome = income
        context.monthlyExpenses = expenses
        
        // 6. Determine top spending category
        context.topSpendingCategory = findTopSpendingCategory()
        
        // Return the completed context
        completion(context)
    }
    
    // MARK: - Private Methods
    
    /// Calculates spending by category for the current month
    private func calculateCategorySpending() -> [String: Double] {
        let calendar = Calendar.current
        let now = Date()
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!
        
        var categorySpending: [String: Double] = [:]
        
        // Get transactions for the current month
        let monthTransactions = plaidManager.transactions.filter { transaction in
            transaction.date >= startOfMonth && transaction.date <= now && transaction.amount > 0
        }
        
        // Group by category and sum amounts
        for transaction in monthTransactions {
            categorySpending[transaction.category, default: 0] += transaction.amount
        }
        
        return categorySpending
    }
    
    /// Gets the most recent transactions, up to a limit
    private func getRecentTransactions(limit: Int = 30) -> [PlaidTransaction] {
        return Array(plaidManager.transactions
            .sorted(by: { $0.date > $1.date })
            .prefix(limit))
    }
    
    /// Calculates monthly income and expenses
    private func calculateMonthlyIncomeAndExpenses() -> (income: Double, expenses: Double) {
        let calendar = Calendar.current
        let now = Date()
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!
        
        let monthTransactions = plaidManager.transactions.filter { transaction in
            transaction.date >= startOfMonth && transaction.date <= now
        }
        
        let incomeTransactions = monthTransactions.filter { $0.amount < 0 }
        let expenseTransactions = monthTransactions.filter { $0.amount > 0 }
        
        let income = abs(incomeTransactions.reduce(0) { $0 + $1.amount })
        let expenses = expenseTransactions.reduce(0) { $0 + $1.amount }
        
        return (income, expenses)
    }
    
    /// Finds the category with the highest spending
    private func findTopSpendingCategory() -> (name: String, amount: Double) {
        let spending = calculateCategorySpending()
        
        if let topCategory = spending.max(by: { $0.value < $1.value }) {
            return (topCategory.key, topCategory.value)
        }
        
        return ("None", 0)
    }
}
