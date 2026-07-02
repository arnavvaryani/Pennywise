//
//  Budget.swift
//  Pennywise
//
//  Domain Entity - Pure Swift, no framework dependencies
//

import Foundation

/// Domain entity representing a budget category
public struct BudgetCategory: Identifiable, Codable, Equatable, Hashable, Sendable {
    public let id: String
    public let name: String
    public var amount: Double
    public let icon: String
    public let colorHex: String
    public let isEssential: Bool
    
    public init(
        id: String = UUID().uuidString,
        name: String,
        amount: Double,
        icon: String,
        colorHex: String,
        isEssential: Bool = false
    ) {
        self.id = id
        self.name = name
        self.amount = amount
        self.icon = icon
        self.colorHex = colorHex
        self.isEssential = isEssential
    }
}

// MARK: - Business Logic

extension BudgetCategory {
    /// Calculate spending percentage
    public func spendingPercentage(spent: Double) -> Double {
        guard amount > 0 else { return 0 }
        return min(spent / amount, 1.0)
    }
    
    /// Check if over budget
    public func isOverBudget(spent: Double) -> Bool {
        spent > amount
    }
    
    /// Check if approaching limit (>90%)
    public func isApproachingLimit(spent: Double) -> Bool {
        spendingPercentage(spent: spent) > 0.9
    }
    
    /// Remaining budget amount
    public func remainingBudget(spent: Double) -> Double {
        max(amount - spent, 0)
    }
}

/// Budget status enumeration
public enum BudgetStatus: String, Codable {
    case overBudget
    case warning
    case onTrack
    case underBudget
    
    public static func calculate(spent: Double, budgeted: Double) -> BudgetStatus {
        guard budgeted > 0 else { return .underBudget }
        let ratio = spent / budgeted
        
        if ratio > 1.0 {
            return .overBudget
        } else if ratio > 0.9 {
            return .warning
        } else if ratio > 0.1 {
            return .onTrack
        } else {
            return .underBudget
        }
    }
}

/// Monthly financial data summary
public struct MonthlyFinancialData: Identifiable, Equatable, Hashable, Codable {
    public let id: String
    public let month: String
    public let income: Double
    public let expenses: Double
    
    public init(id: String = UUID().uuidString, month: String, income: Double, expenses: Double) {
        self.id = id
        self.month = month
        self.income = income
        self.expenses = expenses
    }
    
    public var netSavings: Double {
        income - expenses
    }
    
    public var savingsRate: Double {
        guard income > 0 else { return 0 }
        return (netSavings / income) * 100
    }
}

