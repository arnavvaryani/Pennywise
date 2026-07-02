//
//  UpdateBudgetCategoryUseCase.swift
//  Pennywise
//
//  Use Case - Domain Layer
//

import Foundation

/// Use case for updating a budget category
@MainActor
public final class UpdateBudgetCategoryUseCase {
    private let budgetRepository: BudgetRepository
    
    public init(budgetRepository: BudgetRepository) {
        self.budgetRepository = budgetRepository
    }
    
    public func execute(_ category: BudgetCategory) async throws {
        // Business validation
        guard !category.name.trimmingCharacters(in: .whitespaces).isEmpty else {
            throw BudgetError.invalidName
        }
        
        guard category.amount > 0 else {
            throw BudgetError.invalidAmount
        }
        
        // Update via repository
        try await budgetRepository.updateBudgetCategory(category)
    }
    
    public func updateAmount(categoryId: String, amount: Double) async throws {
        guard amount > 0 else {
            throw BudgetError.invalidAmount
        }
        
        try await budgetRepository.updateCategoryAmount(categoryId: categoryId, amount: amount)
    }
}

