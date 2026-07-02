//
//  CreateAutoBudgetUseCase.swift
//  Pennywise
//
//  Use Case for generating auto-budget based on monthly income
//

import Foundation

@MainActor
public final class CreateAutoBudgetUseCase {
    private let budgetRepository: BudgetRepository
    private let userRepository: UserRepository
    
    public init(budgetRepository: BudgetRepository, userRepository: UserRepository) {
        self.budgetRepository = budgetRepository
        self.userRepository = userRepository
    }
    
    public func execute() async throws -> [BudgetCategory] {
        let income = try await userRepository.getMonthlyIncome()
        
        guard income > 0 else {
            throw BudgetError.invalidAmount
        }
        
        // 50/30/20 Rule
        // 50% Needs: Housing, Utilities, Groceries, Transport, Insurance
        // 30% Wants: Dining, Entertainment, Shopping, Health
        // 20% Savings/Debt: Savings, Investments, Debt Repayment
        
        let needsAllocation = income * 0.5
        let wantsAllocation = income * 0.3
        let savingsAllocation = income * 0.2
        
        let categories = [
            // Needs (50%)
            BudgetCategory(id: UUID().uuidString, name: "Housing", amount: needsAllocation * 0.5, icon: "house.fill", colorHex: "#4A90E2", isEssential: true),
            BudgetCategory(id: UUID().uuidString, name: "Groceries", amount: needsAllocation * 0.2, icon: "cart.fill", colorHex: "#7ED321", isEssential: true),
            BudgetCategory(id: UUID().uuidString, name: "Utilities", amount: needsAllocation * 0.15, icon: "lightbulb.fill", colorHex: "#F5A623", isEssential: true),
            BudgetCategory(id: UUID().uuidString, name: "Transport", amount: needsAllocation * 0.15, icon: "car.fill", colorHex: "#9B9B9B", isEssential: true),
            
            // Wants (30%)
            BudgetCategory(id: UUID().uuidString, name: "Dining", amount: wantsAllocation * 0.4, icon: "fork.knife", colorHex: "#D0021B", isEssential: false),
            BudgetCategory(id: UUID().uuidString, name: "Entertainment", amount: wantsAllocation * 0.3, icon: "play.tv.fill", colorHex: "#BD10E0", isEssential: false),
            BudgetCategory(id: UUID().uuidString, name: "Shopping", amount: wantsAllocation * 0.3, icon: "bag.fill", colorHex: "#F8E71C", isEssential: false),
            
            // Savings (20%)
            BudgetCategory(id: UUID().uuidString, name: "Savings", amount: savingsAllocation, icon: "leaf.fill", colorHex: "#50E3C2", isEssential: false)
        ]
        
        // In a real app, we might want to check if categories already exist
        // For simplicity, we'll add these.
        for category in categories {
            try await budgetRepository.addBudgetCategory(category)
        }
        
        return categories
    }
}
