//
//  AddBudgetCategoryUseCase.swift
//  Pennywise
//
//  Use Case - Domain Layer
//

import Foundation

/// Use case for adding a budget category
@MainActor
public final class AddBudgetCategoryUseCase {
    private let budgetRepository: BudgetRepository
    
    public init(budgetRepository: BudgetRepository) {
        self.budgetRepository = budgetRepository
    }
    
    public func execute(
        name: String,
        amount: Double,
        icon: String,
        colorHex: String,
        isEssential: Bool = false
    ) async throws -> BudgetCategory {
        // Business validation
        guard !name.trimmingCharacters(in: .whitespaces).isEmpty else {
            throw BudgetError.invalidName
        }
        
        guard amount > 0 else {
            throw BudgetError.invalidAmount
        }
        
        // Create category
        let category = BudgetCategory(
            id: UUID().uuidString,
            name: name.trimmingCharacters(in: .whitespaces),
            amount: amount,
            icon: icon,
            colorHex: colorHex,
            isEssential: isEssential
        )
        
        // Save via repository
        try await budgetRepository.addBudgetCategory(category)
        
        return category
    }
}
