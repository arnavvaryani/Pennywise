//
//  PlaidCategoryMapper.swift
//  Pennywise
//

import SwiftUI

@MainActor
class PlaidCategoryMapper {
    static let shared = PlaidCategoryMapper()
    
    private var categoryMappings: [String: String] = [
        "Food and Drink": "Food & Dining",
        "Restaurants": "Food & Dining",
        "Coffee Shop": "Food & Dining",
        "Shopping": "Shopping",
        "General Merchandise": "Shopping",
        "Travel": "Transportation",
        "Taxi": "Transportation",
        "Public Transportation": "Transportation",
        "Utilities": "Bills & Utilities",
        "Rent": "Housing",
        "Mortgage": "Housing",
        "Entertainment": "Entertainment",
        "Movies": "Entertainment",
        "Music": "Entertainment",
        "Healthcare": "Health & Fitness",
        "Pharmacy": "Health & Fitness",
        "Transfer": "Savings",
        "Investment": "Investments",
        "Deposit": "Income",
        "Payroll": "Income"
    ]
    
    func getBudgetCategory(for plaidCategory: String) -> String {
        if let budgetCategory = categoryMappings[plaidCategory] {
            return budgetCategory
        }
        for (plaidKey, budgetValue) in categoryMappings {
            if plaidCategory.lowercased().contains(plaidKey.lowercased()) {
                return budgetValue
            }
        }
        return "Other"
    }
    
    func getIconForCategory(_ category: String) -> String {
        let c = category.lowercased()
        if c.contains("food") || c.contains("dining") { return "fork.knife" }
        else if c.contains("shop") { return "cart.fill" }
        else if c.contains("transport") { return "car.fill" }
        else if c.contains("bill") || c.contains("utilities") { return "bolt.fill" }
        else if c.contains("entertain") { return "play.tv" }
        else if c.contains("health") { return "heart.fill" }
        else if c.contains("housing") || c.contains("rent") { return "house.fill" }
        else if c.contains("income") { return "arrow.down.circle.fill" }
        else if c.contains("saving") { return "banknote.fill" }
        else if c.contains("investment") { return "chart.line.uptrend.xyaxis" }
        return "tag.fill"
    }
    
    func getColorForCategory(_ category: String) -> Color {
        let c = category.lowercased()
        if c.contains("food") || c.contains("dining") { return AppTheme.primaryGreen }
        else if c.contains("shop") { return AppTheme.accentBlue }
        else if c.contains("transport") { return AppTheme.accentPurple }
        else if c.contains("bill") || c.contains("utilities") { return Color(hex: "#9370DB") }
        else if c.contains("entertain") { return Color(hex: "#FFD700") }
        else if c.contains("health") { return Color(hex: "#FF5757") }
        else if c.contains("housing") || c.contains("rent") { return Color(hex: "#CD853F") }
        else if c.contains("income") { return AppTheme.primaryGreen }
        else if c.contains("saving") { return Color(hex: "#50C878") }
        else if c.contains("investment") { return Color(hex: "#4682B4") }
        let hash = category.hashValue
        return Color(
            hue: Double(abs(hash % 256)) / 256.0,
            saturation: 0.7,
            brightness: 0.9
        )
    }
    
    static func isEssentialCategory(_ category: String) -> Bool {
        CategoryMappingSystem.essentialCategories.contains { essential in
            category.lowercased().contains(essential.lowercased())
        }
    }
}
