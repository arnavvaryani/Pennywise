//
//  BudgetRepository.swift
//  Pennywise
//
//  Repository Protocol - Domain Layer
//

import Foundation

/// Repository protocol for budget operations
@MainActor
public protocol BudgetRepository {
    /// Fetch all budget categories
    func fetchBudgetCategories() async throws -> [BudgetCategory]
    
    /// Add a new budget category
    func addBudgetCategory(_ category: BudgetCategory) async throws
    
    /// Update a budget category
    func updateBudgetCategory(_ category: BudgetCategory) async throws
    
    /// Update category amount
    func updateCategoryAmount(categoryId: String, amount: Double) async throws
    
    /// Delete a budget category
    func deleteBudgetCategory(id: String) async throws
    
    /// Calculate spending for category
    func calculateCategorySpending(categoryName: String, transactions: [Transaction]) -> Double
    
    /// Update budget usage
    func updateBudgetUsage() async throws
    
    /// Get monthly financial data
    func getMonthlyFinancialData(transactions: [Transaction]) -> [MonthlyFinancialData]
}

/// Errors related to budget operations
public enum BudgetError: LocalizedError {
    case invalidName
    case invalidAmount
    case categoryExists
    case notFound
    
    public var errorDescription: String? {
        switch self {
        case .invalidName:
            return "Category name cannot be empty"
        case .invalidAmount:
            return "Amount must be greater than zero"
        case .categoryExists:
            return "A category with this name already exists"
        case .notFound:
            return "Category not found"
        }
    }
}

