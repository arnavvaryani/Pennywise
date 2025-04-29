//
//  CategoryMappingSystem.swift
//  Pennywise
//
//  Created by Arnav Varyani on 4/25/25.
//


import SwiftUI
import FirebaseFirestore
import FirebaseAuth

// MARK: - CategoryMappingSystem
/// Manages the mapping between Plaid transaction categories and user-defined budget categories
class CategoryMappingSystem {
    static let shared = CategoryMappingSystem()
    
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
        
        // Calculate total spent
        let totalSpent = spendingByCategory.values.reduce(0, +)
        
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
                name: category,
                amount: recommendedAmount,
                icon: icon,
                color: color
            )
            
            budgetCategories.append(budgetCategory)
        }
        
        // Ensure savings category exists
        if !budgetCategories.contains(where: { $0.name == "Savings" }) {
            // Calculate recommended savings (15% of income if none exists)
            let recommendedSavings = monthlyIncome * 0.15
            
            let savingsCategory = BudgetCategory(
                name: "Savings",
                amount: recommendedSavings,
                icon: "banknote.fill",
                color: AppTheme.primaryGreen
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
            guard let self = self, error == nil else {
                print("Error loading category mappings: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            
            if let documents = snapshot?.documents {
                for document in documents {
                    if let plaidCategory = document.data()["plaidCategory"] as? String,
                       let budgetCategory = document.data()["budgetCategory"] as? String {
                        self.categoryMappings[plaidCategory] = budgetCategory
                    }
                }
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

import SwiftUI

struct CategoryMappingEditorView: View {
    let budgetCategory: String
    @Binding var associatedCategories: [String]
    let potentialCategories: [String]
    let onSave: () -> Void
    
    @Environment(\.presentationMode) var presentationMode
    @State private var searchText = ""
    @State private var selectedCategories: [String] = []
    
    var filteredCategories: [String] {
        if searchText.isEmpty {
            return potentialCategories
        } else {
            return potentialCategories.filter { $0.lowercased().contains(searchText.lowercased()) }
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                AppTheme.backgroundGradient
                    .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    // Header explanation
                    VStack(spacing: 12) {
                        Image(systemName: "arrow.triangle.swap")
                            .font(.system(size: 40))
                            .foregroundColor(AppTheme.accentBlue)
                            .padding(.top, 20)
                        
                        Text("Map Plaid Categories")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(AppTheme.textColor)
                        
                        Text("Select Plaid transaction categories to map to your \"\(budgetCategory)\" budget category")
                            .font(.subheadline)
                            .multilineTextAlignment(.center)
                            .foregroundColor(AppTheme.textColor.opacity(0.7))
                            .padding(.horizontal, 20)
                    }
                    
                    // Search bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(AppTheme.textColor.opacity(0.7))
                            .padding(.leading, 12)
                        
                        TextField("Search categories", text: $searchText)
                            .foregroundColor(AppTheme.textColor)
                            .padding(.vertical, 10)
                        
                        if !searchText.isEmpty {
                            Button(action: {
                                searchText = ""
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(AppTheme.textColor.opacity(0.7))
                            }
                            .padding(.trailing, 12)
                        }
                    }
                    .background(AppTheme.cardBackground)
                    .cornerRadius(10)
                    .padding(.horizontal, 20)
                    
                    // Currently selected categories
                    if !selectedCategories.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Selected Categories")
                                .font(.headline)
                                .foregroundColor(AppTheme.textColor)
                                .padding(.leading, 20)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(selectedCategories, id: \.self) { category in
                                        HStack(spacing: 5) {
                                            Text(category)
                                                .font(.caption)
                                                .foregroundColor(AppTheme.textColor)
                                                .lineLimit(1)
                                            
                                            Button(action: {
                                                removeSelectedCategory(category)
                                            }) {
                                                Image(systemName: "xmark.circle.fill")
                                                    .foregroundColor(AppTheme.textColor.opacity(0.6))
                                                    .font(.system(size: 14))
                                            }
                                        }
                                        .padding(.vertical, 6)
                                        .padding(.horizontal, 10)
                                        .background(AppTheme.primaryGreen.opacity(0.2))
                                        .cornerRadius(15)
                                    }
                                }
                                .padding(.horizontal, 20)
                            }
                        }
                    }
                    
                    // Categories list
                    List {
                        ForEach(filteredCategories, id: \.self) { category in
                            HStack {
                                Text(category)
                                    .foregroundColor(AppTheme.textColor)
                                
                                Spacer()
                                
                                if selectedCategories.contains(category) || associatedCategories.contains(category) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(AppTheme.primaryGreen)
                                }
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                toggleCategory(category)
                            }
                            .listRowBackground(AppTheme.cardBackground)
                        }
                    }
                    .listStyle(PlainListStyle())
                    .environment(\.defaultMinListRowHeight, 44)
                    
                    // Info text
                    Text("Mapping Plaid categories to your budget categories ensures that transactions are correctly categorized in your budget reports.")
                        .font(.caption)
                        .foregroundColor(AppTheme.textColor.opacity(0.6))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                }
            }
            .navigationTitle("Map Categories")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveChanges()
                    }
                    .foregroundColor(AppTheme.primaryGreen)
                    .fontWeight(.semibold)
                }
            }
            .onAppear {
                // Initialize selected categories with already associated ones
                selectedCategories = associatedCategories
            }
        }
    }
    
    // MARK: - Actions
    
    private func toggleCategory(_ category: String) {
        if selectedCategories.contains(category) {
            removeSelectedCategory(category)
        } else {
            selectedCategories.append(category)
        }
    }
    
    private func removeSelectedCategory(_ category: String) {
        selectedCategories.removeAll { $0 == category }
    }
    
    private func saveChanges() {
        // Update the associated categories
        associatedCategories = selectedCategories
        
        // Call the save handler
        onSave()
        
        // Dismiss the sheet
        presentationMode.wrappedValue.dismiss()
    }
}

class PlaidCategoryMapper {
    static let shared = PlaidCategoryMapper()
    
    // Map of Plaid categories to your budget categories
    private var categoryMappings: [String: String] = [
        // Food & Dining
        "Food and Drink": "Food & Dining",
        "Restaurants": "Food & Dining",
        "Coffee Shop": "Food & Dining",
        
        // Shopping
        "Shopping": "Shopping",
        "General Merchandise": "Shopping",
        
        // Transportation
        "Travel": "Transportation",
        "Taxi": "Transportation",
        "Public Transportation": "Transportation",
        
        // Bills & Utilities
        "Utilities": "Bills & Utilities",
        "Rent": "Housing",
        "Mortgage": "Housing",
        
        // Entertainment
        "Entertainment": "Entertainment",
        "Movies": "Entertainment",
        "Music": "Entertainment",
        
        // Health & Fitness
        "Healthcare": "Health & Fitness",
        "Pharmacy": "Health & Fitness",
        
        // Savings & Investment
        "Transfer": "Savings",
        "Investment": "Investments",
        
        // Income categories
        "Deposit": "Income",
        "Payroll": "Income"
    ]
    
    // Get budget category for a Plaid category
    func getBudgetCategory(for plaidCategory: String) -> String {
        // First check for direct mapping
        if let budgetCategory = categoryMappings[plaidCategory] {
            return budgetCategory
        }
        
        // Check for partial matches
        for (plaidKey, budgetValue) in categoryMappings {
            if plaidCategory.lowercased().contains(plaidKey.lowercased()) {
                return budgetValue
            }
        }
        
        // Default fallback
        return "Other"
    }
    
    // Get icon for a budget category
    func getIconForCategory(_ category: String) -> String {
        let c = category.lowercased()
        
        if c.contains("food") || c.contains("dining") {
            return "fork.knife"
        } else if c.contains("shop") {
            return "cart.fill"
        } else if c.contains("transport") {
            return "car.fill"
        } else if c.contains("bill") || c.contains("utilities") {
            return "bolt.fill"
        } else if c.contains("entertain") {
            return "play.tv"
        } else if c.contains("health") {
            return "heart.fill"
        } else if c.contains("housing") || c.contains("rent") {
            return "house.fill"
        } else if c.contains("income") {
            return "arrow.down.circle.fill"
        } else if c.contains("saving") {
            return "banknote.fill"
        } else if c.contains("investment") {
            return "chart.line.uptrend.xyaxis"
        }
        
        return "tag.fill" // Default
    }
    
    // Get color for a budget category
    func getColorForCategory(_ category: String) -> Color {
        let c = category.lowercased()
        
        if c.contains("food") || c.contains("dining") {
            return AppTheme.primaryGreen
        } else if c.contains("shop") {
            return AppTheme.accentBlue
        } else if c.contains("transport") {
            return AppTheme.accentPurple
        } else if c.contains("bill") || c.contains("utilities") {
            return Color(hex: "#9370DB")
        } else if c.contains("entertain") {
            return Color(hex: "#FFD700")
        } else if c.contains("health") {
            return Color(hex: "#FF5757")
        } else if c.contains("housing") || c.contains("rent") {
            return Color(hex: "#CD853F")
        } else if c.contains("income") {
            return AppTheme.primaryGreen
        } else if c.contains("saving") {
            return Color(hex: "#50C878")
        } else if c.contains("investment") {
            return Color(hex: "#4682B4")
        }
        
        // Generate a consistent color based on the category name
        let hash = category.hashValue
        return Color(
            hue: Double(abs(hash % 256)) / 256.0,
            saturation: 0.7,
            brightness: 0.9
        )
    }
}
