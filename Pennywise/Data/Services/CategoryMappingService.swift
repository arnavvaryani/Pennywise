import Foundation

/// Pure mapping from Plaid category strings to the app's budget category names.
/// Keep this in the Data layer (no SwiftUI/Firebase) so ingestion and math stay consistent.
public enum CategoryMappingService {
    private enum Storage {
        static let overridesKey = "category_mapping_overrides_v1"
    }
    
    private static let defaultMappings: [String: String] = [
        // Food
        "Food and Drink": "Dining Out",
        "Restaurant": "Dining Out",
        "Restaurants": "Dining Out",
        "Dining": "Dining Out",
        "Coffee": "Dining Out",
        "Fast Food": "Dining Out",
        
        // Groceries
        "Groceries": "Groceries",
        "Supermarket": "Groceries",
        "Supermarkets": "Groceries",
        
        // Transportation
        "Travel": "Transportation",
        "Taxi": "Transportation",
        "Uber": "Transportation",
        "Lyft": "Transportation",
        "Gas": "Transportation",
        "Fuel": "Transportation",
        "Automotive": "Transportation",
        "Public Transportation": "Transportation",
        "Transit": "Transportation",
        
        // Utilities
        "Utilities": "Utilities",
        "Electric": "Utilities",
        "Water": "Utilities",
        "Internet": "Utilities",
        "Cable": "Utilities",
        "Phone": "Utilities",
        "Bills": "Utilities",
        
        // Housing
        "Rent": "Housing",
        "Mortgage": "Housing",
        
        // Entertainment
        "Entertainment": "Entertainment",
        "Movies": "Entertainment",
        "Music": "Entertainment",
        "Games": "Entertainment",
        
        // Shopping
        "Shopping": "Shopping",
        "Clothing": "Shopping",
        "Electronics": "Shopping",
        "General Merchandise": "Shopping",
        "Home Improvement": "Shopping",
        
        // Healthcare
        "Health": "Healthcare",
        "Medical": "Healthcare",
        "Pharmacy": "Healthcare",
        "Fitness": "Healthcare",
        
        // Subscriptions
        "Subscription": "Subscriptions",
        "Streaming": "Subscriptions",
        "Software": "Subscriptions",
        
        // Savings / Debt
        "Transfer": "Savings",
        "Investment": "Savings",
        "Loan": "Debt Repayment",
        "Credit Card": "Debt Repayment",
        
        // Income
        "Income": "Income",
        "Deposit": "Income",
        "Payroll": "Income"
    ]
    
    public static func mapPlaidCategoryToBudget(_ plaidCategory: String) -> String {
        if let override = overrides()[plaidCategory] {
            return override
        }
        if let direct = defaultMappings[plaidCategory] {
            return direct
        }
        let lower = plaidCategory.lowercased()
        
        // If user overrides exist, allow partial match against those keys too.
        for (k, v) in overrides() {
            if lower.contains(k.lowercased()) {
                return v
            }
        }
        for (k, v) in defaultMappings {
            if lower.contains(k.lowercased()) {
                return v
            }
        }
        return "Other"
    }
    
    /// Replace all overrides for a given budget category with the provided Plaid categories.
    /// This is used by the mapping editor so user choices affect ingestion + calculations.
    public static func updateOverrides(forBudgetCategory budgetCategory: String, plaidCategories: [String]) {
        var map = overrides()
        map = map.filter { $0.value != budgetCategory }
        for plaidCategory in plaidCategories {
            map[plaidCategory] = budgetCategory
        }
        saveOverrides(map)
    }
    
    public static func clearAllOverrides() {
        UserDefaults.standard.removeObject(forKey: Storage.overridesKey)
    }
    
    private static func overrides() -> [String: String] {
        guard let data = UserDefaults.standard.data(forKey: Storage.overridesKey) else { return [:] }
        do {
            return try JSONDecoder().decode([String: String].self, from: data)
        } catch {
            print("CategoryMappingService: failed to decode overrides: \(error)")
            return [:]
        }
    }

    private static func saveOverrides(_ map: [String: String]) {
        do {
            let data = try JSONEncoder().encode(map)
            UserDefaults.standard.set(data, forKey: Storage.overridesKey)
        } catch {
            print("CategoryMappingService: failed to encode overrides: \(error)")
        }
    }
}

