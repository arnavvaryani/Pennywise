//
//  CategoryMappingSystem.swift
//  Pennywise
//
//  Created by Arnav Varyani on 4/25/25.
//


import SwiftUI
import FirebaseFirestore
import FirebaseAuth

/// Manages the mapping between Plaid transaction categories and user-defined budget categories
@MainActor
class CategoryMappingSystem {
    static let shared = CategoryMappingSystem()
    
    // Essential categories that are typically necessary expenses
    static let essentialCategories = [
        "Groceries", "Rent", "Utilities", "Healthcare", 
        "Insurance", "Transportation", "Mortgage", "Bills"
    ]
    
    // Default predefined categories for users to choose from
    static let defaultCategories: [PredefinedCategory] = [
        // Needs (Essential)
        PredefinedCategory(name: "Housing", icon: "house.fill", color: Color(hex: "#4CAF50"), isEssential: true),
        PredefinedCategory(name: "Groceries", icon: "cart.fill", color: Color(hex: "#2196F3"), isEssential: true),
        PredefinedCategory(name: "Utilities", icon: "bolt.fill", color: Color(hex: "#9370DB"), isEssential: true),
        PredefinedCategory(name: "Transportation", icon: "car.fill", color: Color(hex: "#BA55D3"), isEssential: true),
        PredefinedCategory(name: "Healthcare", icon: "heart.fill", color: Color(hex: "#FF5757"), isEssential: true),
        PredefinedCategory(name: "Insurance", icon: "shield.fill", color: Color(hex: "#20B2AA"), isEssential: true),
        
        // Wants (Non-essential)
        PredefinedCategory(name: "Dining Out", icon: "fork.knife", color: Color(hex: "#FF8C00"), isEssential: false),
        PredefinedCategory(name: "Entertainment", icon: "play.tv", color: Color(hex: "#FFD700"), isEssential: false),
        PredefinedCategory(name: "Shopping", icon: "bag.fill", color: Color(hex: "#FF69B4"), isEssential: false),
        PredefinedCategory(name: "Subscriptions", icon: "repeat", color: Color(hex: "#BA55D3"), isEssential: false),
        PredefinedCategory(name: "Personal Care", icon: "person.fill", color: Color(hex: "#FF7F50"), isEssential: false),
        PredefinedCategory(name: "Travel", icon: "airplane", color: Color(hex: "#87CEEB"), isEssential: false),
        
        // Savings & Debt
        PredefinedCategory(name: "Savings", icon: "banknote.fill", color: Color(hex: "#4CAF50"), isEssential: false),
        PredefinedCategory(name: "Debt Repayment", icon: "creditcard.fill", color: Color(hex: "#20B2AA"), isEssential: false)
    ]
    
    // Dictionary mapping Plaid categories to user budget categories
    private var categoryMappings: [String: String] = [:]
    
    // Default mappings for common Plaid categories to typical budget categories
    private let defaultMappings: [String: String] = [
        // Food & Dining
        "Food and Drink": "Food",
        "Restaurants": "Food",
        "Dining": "Food",
        "Coffee Shop": "Food",
        "Fast Food": "Food",
        
        // Groceries
        "Groceries": "Groceries",
        "Supermarkets": "Groceries",
        
        // Transportation
        "Travel": "Transportation",
        "Taxi": "Transportation",
        "Uber": "Transportation",
        "Lyft": "Transportation",
        "Gas": "Transportation",
        "Automotive": "Transportation",
        "Public Transportation": "Transportation",
        
        // Shopping
        "Shopping": "Shopping",
        "Clothing": "Shopping",
        "Electronics": "Shopping",
        "Home Improvement": "Shopping",
        
        // Entertainment
        "Entertainment": "Entertainment",
        "Movies": "Entertainment",
        "Music": "Entertainment",
        "Games": "Entertainment",
        
        // Health
        "Health": "Healthcare",
        "Medical": "Healthcare",
        "Pharmacy": "Healthcare",
        "Fitness": "Healthcare",
        
        // Housing & Utilities
        "Rent": "Housing",
        "Mortgage": "Housing",
        "Utilities": "Utilities",
        "Electric": "Utilities",
        "Water": "Utilities",
        "Internet": "Utilities",
        "Cable": "Utilities",
        
        // Personal Care
        "Personal Care": "Personal Care",
        "Beauty": "Personal Care",
        
        // Subscriptions
        "Subscription": "Subscriptions",
        "Streaming": "Subscriptions",
        "Software": "Subscriptions",
        
        // Income
        "Income": "Income",
        "Deposit": "Income",
        "Payroll": "Income",
        
        // Debt
        "Credit Card": "Debt Repayment",
        "Loan": "Debt Repayment",
        "Student Loan": "Debt Repayment",
        
        // Savings
        "Transfer": "Savings",
        "Investment": "Savings"
    ]
    
    private init() {
        // Initialize with default mappings
        categoryMappings = defaultMappings
        // Load any custom mappings from Firestore
        loadCustomMappings()
    }
    
    // MARK: - Public Methods
    
    /// Maps a Plaid transaction category to a budget category
    func mapCategory(_ plaidCategory: String) -> String {
        // First check if there's a direct mapping
        if let budgetCategory = categoryMappings[plaidCategory] {
            return budgetCategory
        }
        
        // If no direct mapping, check for partial matches
        for (plaidKey, budgetValue) in categoryMappings {
            if plaidCategory.lowercased().contains(plaidKey.lowercased()) {
                return budgetValue
            }
        }
        
        // If still no match, check if any budget category name is contained in the Plaid category
        for (_, budgetValue) in categoryMappings {
            if plaidCategory.lowercased().contains(budgetValue.lowercased()) {
                return budgetValue
            }
        }
        
        // Default to "Other" if no mapping found
        return "Other"
    }
    
    /// Create a custom mapping between a Plaid category and a budget category
    func createMapping(plaidCategory: String, budgetCategory: String) {
        categoryMappings[plaidCategory] = budgetCategory
        saveCustomMapping(plaidCategory: plaidCategory, budgetCategory: budgetCategory)
    }
    
    /// Get all available budget categories based on current mappings
    func getAvailableBudgetCategories() -> [String] {
        return Array(Set(categoryMappings.values)).sorted()
    }
    
    /// Get Plaid categories mapped to a specific budget category
    func getMappings(for budgetCategory: String) -> [String] {
        return categoryMappings.filter { $1 == budgetCategory }.map { $0.key }
    }
    
    /// Update mappings for a budget category
    func updateMappings(for budgetCategory: String, plaidCategories: [String]) {
        // Remove old mappings for this budget category
        let categoriesToRemove = categoryMappings.filter { $1 == budgetCategory }.map { $0.key }
        for category in categoriesToRemove {
            categoryMappings.removeValue(forKey: category)
        }
        
        // Add new mappings
        for category in plaidCategories {
            categoryMappings[category] = budgetCategory
            saveCustomMapping(plaidCategory: category, budgetCategory: budgetCategory)
        }
    }
    
    /// Get all potential Plaid categories (currently just all keys in mappings + some defaults)
    func getAllPotentialPlaidCategories() -> [String] {
        return Array(categoryMappings.keys).sorted()
    }
    
    /// Calculate spending by budget category from Plaid transactions
    func calculateSpendingByBudgetCategory(transactions: [PlaidTransaction]) -> [String: Double] {
        var spending: [String: Double] = [:]
        
        for transaction in transactions {
            let budgetCategory = mapCategory(transaction.category)
            
            // Only add positive amounts (expenses)
            if transaction.amount > 0 {
                spending[budgetCategory, default: 0] += transaction.amount
            }
        }
        
        return spending
    }
    
    /// Generate budget categories from Plaid transaction history with auto-allocation
    func generateBudgetCategories(from transactions: [PlaidTransaction], 
                                  monthlyIncome: Double) -> [BudgetCategory] {
        // Calculate total spending by budget category
        let spendingByCategory = calculateSpendingByBudgetCategory(transactions: transactions)
        
        // Create budget categories with recommended amounts
        var budgetCategories: [BudgetCategory] = []
        
        // Standard category icons and colors
        let categoryIcons: [String: String] = [
            "Food": "fork.knife",
            "Groceries": "cart.fill",
            "Transportation": "car.fill",
            "Entertainment": "play.tv",
            "Healthcare": "heart.fill",
            "Housing": "house.fill",
            "Utilities": "bolt.fill",
            "Shopping": "bag.fill",
            "Personal Care": "person.fill",
            "Subscriptions": "repeat",
            "Debt Repayment": "creditcard.fill",
            "Savings": "banknote.fill",
            "Income": "arrow.down.circle.fill",
            "Other": "ellipsis.circle.fill"
        ]
        
        let categoryColors: [String: Color] = [
            "Food": AppTheme.primaryGreen,
            "Groceries": AppTheme.accentBlue,
            "Transportation": AppTheme.accentPurple,
            "Entertainment": Color(hex: "#FFD700"),
            "Healthcare": Color(hex: "#FF5757"),
            "Housing": AppTheme.primaryGreen,
            "Utilities": Color(hex: "#9370DB"),
            "Shopping": Color(hex: "#FF69B4"),
            "Personal Care": Color(hex: "#FF7F50"),
            "Subscriptions": Color(hex: "#BA55D3"),
            "Debt Repayment": Color(hex: "#20B2AA"),
            "Savings": AppTheme.primaryGreen,
            "Income": AppTheme.primaryGreen,
            "Other": Color.gray
        ]
        
        // Create budget categories based on spending
        for (category, spent) in spendingByCategory {
            // Calculate recommended budget based on past spending + buffer
            let recommendedAmount = spent * 1.1 // 10% buffer
            
            // Create the budget category
            let icon = categoryIcons[category] ?? "questionmark.circle.fill"
            let color = categoryColors[category] ?? Color.gray
            
            let budgetCategory = BudgetCategory(
                id: UUID().uuidString,
                name: category,
                amount: recommendedAmount,
                icon: icon,
                colorHex: color.hexString,
                isEssential: CategoryMappingSystem.essentialCategories.contains(category)
            )
            
            budgetCategories.append(budgetCategory)
        }
        
        // Ensure savings category exists
        if !budgetCategories.contains(where: { $0.name == "Savings" }) {
            // Calculate recommended savings (15% of income if none exists)
            let recommendedSavings = monthlyIncome * 0.15
            
            let savingsCategory = BudgetCategory(
                id: UUID().uuidString,
                name: "Savings",
                amount: recommendedSavings,
                icon: "banknote.fill",
                colorHex: AppTheme.primaryGreen.hexString,
                isEssential: true
            )
            
            budgetCategories.append(savingsCategory)
        }
        
        return budgetCategories
    }
    
    // MARK: - Private Methods
    
    private func loadCustomMappings() {
        guard let userId = Auth.auth().currentUser?.uid else {
            return
        }
        
        let db = Firestore.firestore()
        db.collection("users/\(userId)/categoryMappings").getDocuments { [weak self] snapshot, error in
            guard error == nil else {
                print("Error loading category mappings: \(error?.localizedDescription ?? "Unknown error")")
                return
            }

            // Build a plain (Sendable) dictionary inside the Firestore callback,
            // then hop to the main actor to mutate the isolated state.
            var loaded: [String: String] = [:]
            for document in snapshot?.documents ?? [] {
                if let plaidCategory = document.data()["plaidCategory"] as? String,
                   let budgetCategory = document.data()["budgetCategory"] as? String {
                    loaded[plaidCategory] = budgetCategory
                }
            }

            Task { @MainActor in
                self?.categoryMappings.merge(loaded) { _, new in new }
            }
        }
    }
    
    private func saveCustomMapping(plaidCategory: String, budgetCategory: String) {
        guard let userId = Auth.auth().currentUser?.uid else {
            return
        }
        
        let db = Firestore.firestore()
        let mappingRef = db.collection("users/\(userId)/categoryMappings").document(plaidCategory)
        
        let data: [String: Any] = [
            "plaidCategory": plaidCategory,
            "budgetCategory": budgetCategory,
            "updatedAt": FieldValue.serverTimestamp()
        ]
        
        mappingRef.setData(data, merge: true) { error in
            if let error = error {
                print("Error saving category mapping: \(error.localizedDescription)")
            }
        }
    }
}
