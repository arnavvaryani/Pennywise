//
//  BudgetCategorySystem.swift
//  Pennywise
//
//  Created by Arnav Varyani on 4/25/25.
//


import SwiftUI
import FirebaseFirestore

// MARK: - Budget Category System
class BudgetCategorySystem {
    static let shared = BudgetCategorySystem()
    
    let predefinedCategories: [PredefinedCategory] = [
        PredefinedCategory(
            name: "Housing", 
            icon: "house.fill", 
            color: Color(hex: "#4CAF50"), 
            isEssential: true,
            plaidCategories: ["Mortgage", "Rent", "Real Estate", "Home Insurance", "Property Tax"]
        ),
        PredefinedCategory(
            name: "Groceries", 
            icon: "cart.fill", 
            color: Color(hex: "#2196F3"), 
            isEssential: true,
            plaidCategories: ["Groceries", "Supermarkets", "Food and Drink"]
        ),
        PredefinedCategory(
            name: "Utilities", 
            icon: "bolt.fill", 
            color: Color(hex: "#9C27B0"), 
            isEssential: true,
            plaidCategories: ["Utilities", "Electric", "Gas", "Water", "Internet", "Cable TV"]
        ),
        PredefinedCategory(
            name: "Transportation", 
            icon: "car.fill", 
            color: Color(hex: "#03A9F4"), 
            isEssential: true,
            plaidCategories: ["Gas", "Public Transportation", "Parking", "Car Service", "Taxi", "Uber", "Lyft"]
        ),
        PredefinedCategory(
            name: "Healthcare", 
            icon: "heart.fill", 
            color: Color(hex: "#E91E63"), 
            isEssential: true,
            plaidCategories: ["Healthcare", "Medical", "Pharmacy", "Doctor", "Hospital", "Health Insurance"]
        ),
        
        // Discretionary spending
        PredefinedCategory(
            name: "Dining Out", 
            icon: "fork.knife", 
            color: Color(hex: "#FF9800"), 
            isEssential: false,
            plaidCategories: ["Restaurants", "Fast Food", "Coffee Shop", "Bar", "Food Delivery"]
        ),
        PredefinedCategory(
            name: "Entertainment", 
            icon: "play.tv.fill", 
            color: Color(hex: "#FFC107"), 
            isEssential: false,
            plaidCategories: ["Entertainment", "Movies", "Music", "Games", "Concerts", "Sports"]
        ),
        PredefinedCategory(
            name: "Shopping", 
            icon: "bag.fill", 
            color: Color(hex: "#F44336"), 
            isEssential: false,
            plaidCategories: ["Shopping", "Clothing", "Electronics", "Retail", "Department Stores"]
        ),
        PredefinedCategory(
            name: "Personal Care", 
            icon: "person.fill", 
            color: Color(hex: "#FF5722"), 
            isEssential: false,
            plaidCategories: ["Personal Care", "Hair", "Spa", "Gym", "Fitness"]
        ),
        PredefinedCategory(
            name: "Subscriptions", 
            icon: "repeat", 
            color: Color(hex: "#673AB7"), 
            isEssential: false,
            plaidCategories: ["Subscription", "Streaming", "Software", "Music", "Netflix", "Spotify", "Amazon Prime"]
        ),
        
        // Savings/Debt
        PredefinedCategory(
            name: "Savings", 
            icon: "banknote.fill", 
            color: Color(hex: "#4CAF50"), 
            isEssential: true,
            plaidCategories: ["Transfer", "Deposit", "Savings"]
        ),
        PredefinedCategory(
            name: "Debt Payment", 
            icon: "creditcard.fill", 
            color: Color(hex: "#00BCD4"), 
            isEssential: true,
            plaidCategories: ["Credit Card Payment", "Loan Payment", "Student Loan", "Mortgage Payment"]
        ),
        
        // Income
        PredefinedCategory(
            name: "Income", 
            icon: "arrow.down.circle.fill", 
            color: Color(hex: "#4CAF50"), 
            isEssential: false,
            plaidCategories: ["Payroll", "Deposit", "Income", "Transfer", "Interest Income"]
        ),
        
        // Catch-all
        PredefinedCategory(
            name: "Other", 
            icon: "ellipsis.circle.fill", 
            color: Color(hex: "#9E9E9E"), 
            isEssential: false,
            plaidCategories: []
        )
    ]
    
    // MARK: - Public Methods
    
    // Get a predefined category by name
    func getPredefinedCategory(name: String) -> PredefinedCategory? {
        return predefinedCategories.first(where: { $0.name == name })
    }
    
    // Convert predefined category to budget category
    func convertToBudgetCategory(predefined: PredefinedCategory, amount: Double = 0) -> BudgetCategory {
        return BudgetCategory(
            name: predefined.name,
            amount: amount,
            icon: predefined.icon,
            color: predefined.color
        )
    }
    
    // Map a Plaid transaction category to the best matching predefined category
    func mapPlaidCategoryToPredefined(plaidCategory: String) -> PredefinedCategory {
        // First check for exact matches in the predefined Plaid categories
        for predefined in predefinedCategories {
            if predefined.plaidCategories.contains(plaidCategory) {
                return predefined
            }
            
            // Check for partial matches (case insensitive)
            for predefinedPlaidCategory in predefined.plaidCategories {
                if plaidCategory.lowercased().contains(predefinedPlaidCategory.lowercased()) || 
                   predefinedPlaidCategory.lowercased().contains(plaidCategory.lowercased()) {
                    return predefined
                }
            }
        }
        
        // If no match found, return "Other"
        return predefinedCategories.last ?? predefinedCategories[0]
    }
    
    // Calculate spending by budget category from Plaid transactions
    func calculateSpendingByBudgetCategory(transactions: [PlaidTransaction]) -> [String: Double] {
        var spending: [String: Double] = [:]
        
        for transaction in transactions {
            // Skip negative amounts (income)
            if transaction.amount <= 0 {
                continue
            }
            
            // Map the transaction to a predefined category
            let predefinedCategory = mapPlaidCategoryToPredefined(plaidCategory: transaction.category)
            
            // Add the amount to the appropriate category
            spending[predefinedCategory.name, default: 0] += transaction.amount
        }
        
        return spending
    }
    
    func generateRecommendedBudgets(monthlyIncome: Double, transactions: [PlaidTransaction]) -> [BudgetCategory] {
        // Calculate current spending patterns
        let spending = calculateSpendingByBudgetCategory(transactions: transactions)
        
        var budgetCategories: [BudgetCategory] = []
        
        // Create budget for each predefined category
        for predefined in predefinedCategories {
            // Skip 'Income' category for budgeting
            if predefined.name == "Income" {
                continue
            }
            
            // Calculate recommended amount based on spending or standard percentages
            var recommendedAmount: Double
            
            if let spent = spending[predefined.name], spent > 0 {
                // If we have spending data, use it with a 10% buffer
                recommendedAmount = spent * 1.1
            } else {
                // Otherwise, use standard percentage allocations based on category type
                if predefined.name == "Housing" {
                    recommendedAmount = monthlyIncome * 0.3 // 30% for housing
                } else if predefined.name == "Groceries" {
                    recommendedAmount = monthlyIncome * 0.1 // 10% for groceries
                } else if predefined.name == "Utilities" {
                    recommendedAmount = monthlyIncome * 0.05 // 5% for utilities
                } else if predefined.name == "Transportation" {
                    recommendedAmount = monthlyIncome * 0.05 // 5% for transportation
                } else if predefined.name == "Healthcare" {
                    recommendedAmount = monthlyIncome * 0.05 // 5% for healthcare
                } else if predefined.name == "Savings" {
                    recommendedAmount = monthlyIncome * 0.15 // 15% for savings
                } else if predefined.name == "Debt Payment" {
                    recommendedAmount = monthlyIncome * 0.05 // 5% for debt
                } else if predefined.isEssential {
                    recommendedAmount = monthlyIncome * 0.03 // 3% for other essentials
                } else {
                    recommendedAmount = monthlyIncome * 0.02 // 2% for discretionary categories
                }
            }
            
            // Create budget category with recommended amount
            let budgetCategory = convertToBudgetCategory(
                predefined: predefined,
                amount: recommendedAmount
            )
            
            budgetCategories.append(budgetCategory)
        }
        
        return budgetCategories
    }
}

// MARK: - Predefined Category Model
struct PredefinedCategory: Identifiable {
    var id: String { name }
    let name: String
    let icon: String
    let color: Color
    let isEssential: Bool
    let plaidCategories: [String]
    
    // For custom categories
    static func custom(name: String) -> PredefinedCategory {
        return PredefinedCategory(
            name: name,
            icon: "tag.fill",
            color: Color(hex: "#607D8B"),
            isEssential: false,
            plaidCategories: [name]
        )
    }
}
