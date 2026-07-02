//
//  BudgetRepositoryImpl.swift
//  Pennywise
//
//  Repository Implementation - Data Layer
//

import Foundation

/// Implementation of BudgetRepository
@MainActor
public final class BudgetRepositoryImpl: BudgetRepository {
    private let firestoreService: FirestoreService
    
    public init(firestoreService: FirestoreService) {
        self.firestoreService = firestoreService
    }
    
    public func fetchBudgetCategories() async throws -> [BudgetCategory] {
        return try await firestoreService.fetchBudgetCategories()
    }
    
    public func addBudgetCategory(_ category: BudgetCategory) async throws {
        try await firestoreService.saveBudgetCategory(category)
    }
    
    public func updateBudgetCategory(_ category: BudgetCategory) async throws {
        try await firestoreService.saveBudgetCategory(category)
    }
    
    public func updateCategoryAmount(categoryId: String, amount: Double) async throws {
        // Fetch all categories, find the one, update it
        let categories = try await fetchBudgetCategories()
        guard var category = categories.first(where: { $0.id == categoryId }) else {
            throw BudgetError.notFound
        }
        
        category = BudgetCategory(
            id: category.id,
            name: category.name,
            amount: amount,
            icon: category.icon,
            colorHex: category.colorHex,
            isEssential: category.isEssential
        )
        
        try await updateBudgetCategory(category)
    }
    
    public func deleteBudgetCategory(id: String) async throws {
        try await firestoreService.deleteBudgetCategory(id: id)
    }
    
    public func calculateCategorySpending(categoryName: String, transactions: [Transaction]) -> Double {
        let categoryTransactions = transactions.filter { transaction in
            transaction.category.lowercased() == categoryName.lowercased() && transaction.isExpense
        }
        
        return categoryTransactions.reduce(0) { $0 + $1.amount }
    }
    
    public func updateBudgetUsage() async throws {
        // This is typically called after syncing transactions
        // No direct action needed as spending is calculated on-demand
    }
    
    public func getMonthlyFinancialData(transactions: [Transaction]) -> [MonthlyFinancialData] {
        let calendar = Calendar.current
        let now = Date()
        var data: [MonthlyFinancialData] = []
        
        for offset in 0..<6 {
            guard let monthStart = calendar.date(byAdding: .month, value: -offset, to: now) else { continue }
            
            let monthName = calendar.monthSymbols[calendar.component(.month, from: monthStart) - 1]
            let monthShort = String(monthName.prefix(3))
            
            let monthTransactions = transactions.filter { transaction in
                calendar.isDate(transaction.date, equalTo: monthStart, toGranularity: .month)
            }
            
            let income = monthTransactions
                .filter { $0.isIncome }
                .reduce(0) { $0 + $1.absoluteAmount }
            
            let expenses = monthTransactions
                .filter { $0.isExpense }
                .reduce(0) { $0 + $1.amount }
            
            data.append(MonthlyFinancialData(month: monthShort, income: income, expenses: expenses))
        }
        
        return data.reversed()
    }
}

