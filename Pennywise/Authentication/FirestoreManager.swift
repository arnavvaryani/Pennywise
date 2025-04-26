//
//  FirestoreManager.swift
//  Pennywise
//
//  Created by Arnav Varyani on 4/24/25.
//

import Foundation
import Firebase
import FirebaseFirestore
import Combine
import FirebaseAuth
import SwiftUI

/// Manager class for handling Firestore database operations
class FirestoreManager: ObservableObject {
    static let shared = FirestoreManager()
    
    // Firestore database reference
    private let db = Firestore.firestore()
    
    // Current user ID
    private var userId: String? {
        Auth.auth().currentUser?.uid
    }
    
    // Publishers for reactive updates
    @Published var accounts: [PlaidAccount] = []
    @Published var transactions: [PlaidTransaction] = []
    @Published var budgetCategories: [BudgetCategory] = []
    @Published var monthlyBudgets: [String: MonthlyBudget] = [:]
    @Published var insights: [String: MonthlySummary] = [:]
    
    // Error state
    @Published var error: Error?
    
    // Private initializer for singleton
    private init() {
        // Configure Firestore settings
        let settings = FirestoreSettings()
        settings.isPersistenceEnabled = true
        db.settings = settings
    }
    
    // MARK: - Plaid Data Synchronization
    
    /// Syncs all Plaid accounts to Firestore
    func syncAccounts(_ accounts: [PlaidAccount], completion: @escaping (Bool) -> Void) {
        guard let userId = userId else {
            error = NSError(domain: "FirestoreManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "User not signed in"])
            completion(false)
            return
        }
        
        let batch = db.batch()
        
        for account in accounts {
            let accountRef = db.collection("users").document(userId).collection("accounts").document(account.id)
            
            batch.setData([
                "name": account.name,
                "type": account.type,
                "balance": account.balance,
                "institutionName": account.institutionName,
                "mask": account.id.suffix(4),
                "lastUpdated": FieldValue.serverTimestamp()
            ], forDocument: accountRef, merge: true)
        }
        
        batch.commit { [weak self] error in
            if let error = error {
                self?.error = error
                completion(false)
            } else {
                completion(true)
            }
        }
    }
    
    /// Syncs all Plaid transactions to Firestore
    func syncTransactions(_ transactions: [PlaidTransaction], completion: @escaping (Bool) -> Void) {
        guard let userId = userId else {
            error = NSError(domain: "FirestoreManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "User not signed in"])
            completion(false)
            return
        }
        
        // Create transaction batches (max 500 operations per batch)
        let batchSize = 450 // Leaving room for other batch operations
        let batches = stride(from: 0, to: transactions.count, by: batchSize).map {
            Array(transactions[$0..<min($0 + batchSize, transactions.count)])
        }
        
        // Process batches sequentially
        processBatches(batches, index: 0) { [weak self] success in
            if success {
                // After syncing all transactions, update monthly summaries
                self?.updateMonthlySummaries(from: transactions) { success in
                    completion(success)
                }
            } else {
                completion(false)
            }
        }
    }
    
    /// Process transaction batches sequentially
    private func processBatches(_ batches: [[PlaidTransaction]], index: Int, completion: @escaping (Bool) -> Void) {
        guard index < batches.count else {
            // All batches processed
            completion(true)
            return
        }
        
        let batch = batches[index]
        uploadTransactionBatch(batch) { [weak self] success in
            if success {
                // Process next batch
                self?.processBatches(batches, index: index + 1, completion: completion)
            } else {
                completion(false)
            }
        }
    }
    
    /// Upload a batch of transactions to Firestore
    private func uploadTransactionBatch(_ transactions: [PlaidTransaction], completion: @escaping (Bool) -> Void) {
        guard let userId = userId else {
            error = NSError(domain: "FirestoreManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "User not signed in"])
            completion(false)
            return
        }
        
        let batch = db.batch()
        
        for transaction in transactions {
            let transactionRef = db.collection("users").document(userId).collection("transactions").document(transaction.id)
            
            // Convert Date to Timestamp
            let timestamp = Timestamp(date: transaction.date)
            
            batch.setData([
                "name": transaction.name,
                "amount": transaction.amount,
                "date": timestamp,
                "category": transaction.category,
                "merchantName": transaction.merchantName,
                "accountId": transaction.accountId,
                "pending": transaction.pending,
                "createdAt": FieldValue.serverTimestamp(),
                "updatedAt": FieldValue.serverTimestamp()
            ], forDocument: transactionRef, merge: true)
        }
        
        batch.commit { [weak self] error in
            if let error = error {
                self?.error = error
                completion(false)
            } else {
                completion(true)
            }
        }
    }
    
    // MARK: - Budget Categories
    
    /// Saves a budget category to Firestore
    func saveBudgetCategory(_ category: BudgetCategory, completion: @escaping (Bool) -> Void) {
        guard let userId = userId else {
            error = NSError(domain: "FirestoreManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "User not signed in"])
            completion(false)
            return
        }
        
        // Create a document ID if needed
        let categoryId = category.id
        let categoryRef = db.collection("users").document(userId).collection("budgetCategories").document(categoryId)
        
        // Convert Color to hex string
        let colorHex = category.color.hexString
        
        let data: [String: Any] = [
            "name": category.name,
            "amount": category.amount,
            "icon": category.icon,
            "color": colorHex,
            "isEssential": isEssentialCategory(category.name),
            "updatedAt": FieldValue.serverTimestamp()
        ]
        
        categoryRef.setData(data, merge: true) { [weak self] error in
            if let error = error {
                self?.error = error
                completion(false)
            } else {
                completion(true)
            }
        }
    }
    
    // Helper function to determine if a category is essential
    private func isEssentialCategory(_ name: String) -> Bool {
        let essentialCategories = ["Groceries", "Rent", "Utilities", "Transportation",
                                 "Healthcare", "Insurance", "Housing", "Bills", "Medical"]
        
        return essentialCategories.contains { essential in
            name.lowercased().contains(essential.lowercased())
        }
    }
    
    /// Loads all budget categories from Firestore
    func loadBudgetCategories(completion: @escaping ([BudgetCategory]) -> Void) {
        guard let userId = userId else {
            error = NSError(domain: "FirestoreManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "User not signed in"])
            completion([])
            return
        }
        
        db.collection("users").document(userId).collection("budgetCategories").getDocuments { [weak self] snapshot, error in
            if let error = error {
                self?.error = error
                completion([])
                return
            }
            
            guard let documents = snapshot?.documents else {
                completion([])
                return
            }
            
            let categories = documents.compactMap { document -> BudgetCategory? in
                guard
                    let name = document.data()["name"] as? String,
                    let amount = document.data()["amount"] as? Double,
                    let icon = document.data()["icon"] as? String,
                    let colorHex = document.data()["color"] as? String
                else {
                    return nil
                }
                
                let color = Color(hex: colorHex)
                return BudgetCategory(
                    name: name,
                    amount: amount,
                    icon: icon,
                    color: color
                )
            }
            
            self?.budgetCategories = categories
            completion(categories)
        }
    }
    
    /// Deletes a budget category from Firestore
    func deleteBudgetCategory(_ categoryId: String, completion: @escaping (Bool) -> Void) {
        guard let userId = userId else {
            error = NSError(domain: "FirestoreManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "User not signed in"])
            completion(false)
            return
        }
        
        let categoryRef = db.collection("users/\(userId)/budgetCategories").document(categoryId)
        
        categoryRef.delete { [weak self] error in
            if let error = error {
                self?.error = error
                completion(false)
            } else {
                completion(true)
            }
        }
    }
    
    // MARK: - Transaction Notes and Tags
    
    /// Updates transaction notes or tags
    func updateTransactionDetails(transactionId: String, notes: String? = nil, tags: [String]? = nil, isHidden: Bool? = nil, completion: @escaping (Bool) -> Void) {
        guard let userId = userId else {
            error = NSError(domain: "FirestoreManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "User not signed in"])
            completion(false)
            return
        }
        
        let transactionRef = db.collection("users/\(userId)/transactions").document(transactionId)
        
        var data: [String: Any] = [
            "updatedAt": FieldValue.serverTimestamp()
        ]
        
        if let notes = notes {
            data["notes"] = notes
        }
        
        if let tags = tags {
            data["tags"] = tags
        }
        
        if let isHidden = isHidden {
            data["isHidden"] = isHidden
        }
        
        transactionRef.updateData(data) { [weak self] error in
            if let error = error {
                self?.error = error
                completion(false)
            } else {
                completion(true)
            }
        }
    }
    
    /// Updates transaction category
    func updateTransactionCategory(transactionId: String, category: String, completion: @escaping (Bool) -> Void) {
        guard let userId = userId else {
            error = NSError(domain: "FirestoreManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "User not signed in"])
            completion(false)
            return
        }
        
        let transactionRef = db.collection("users/\(userId)/transactions").document(transactionId)
        
        let data: [String: Any] = [
            "category": category,
            "updatedAt": FieldValue.serverTimestamp()
        ]
        
        transactionRef.updateData(data) { [weak self] error in
            if let error = error {
                self?.error = error
                completion(false)
            } else {
                // After updating the category, recalculate budget usage
                self?.updateBudgetUsage { success in
                    completion(success)
                }
            }
        }
    }
    
    // MARK: - Monthly Budgets
    
    /// Updates monthly budget settings
    func saveBudgetSettings(startDay: Int, savingsGoalPercentage: Double, notifications: Bool, completion: @escaping (Bool) -> Void) {
        guard let userId = userId else {
            error = NSError(domain: "FirestoreManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "User not signed in"])
            completion(false)
            return
        }
        
        let settingsRef = db.collection("users/\(userId)/budget").document("settings")
        
        let data: [String: Any] = [
            "startDay": startDay,
            "savingsGoalPercentage": savingsGoalPercentage,
            "notifications": notifications,
            "updatedAt": FieldValue.serverTimestamp()
        ]
        
        settingsRef.setData(data, merge: true) { [weak self] error in
            if let error = error {
                self?.error = error
                completion(false)
            } else {
                completion(true)
            }
        }
    }
    
    /// Updates budget usage based on transactions
    func updateBudgetUsage(completion: @escaping (Bool) -> Void) {
        guard let userId = userId else {
            error = NSError(domain: "FirestoreManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "User not signed in"])
            completion(false)
            return
        }
        
        // Get current month and year
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM"
        let currentYearMonth = dateFormatter.string(from: Date())
        
        // Load budget categories
        loadBudgetCategories { [weak self] categories in
            guard let self = self else { return }
            
            // Load transactions for current month
            let calendar = Calendar.current
            let components = calendar.dateComponents([.year, .month], from: Date())
            let startOfMonth = calendar.date(from: components)!
            let nextMonth = calendar.date(byAdding: .month, value: 1, to: startOfMonth)!
            let startOfNextMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: nextMonth))!
            
            // Query transactions for the current month
            self.db.collection("users/\(userId)/transactions")
                .whereField("date", isGreaterThanOrEqualTo: Timestamp(date: startOfMonth))
                .whereField("date", isLessThan: Timestamp(date: startOfNextMonth))
                .whereField("amount", isGreaterThan: 0) // Only expenses (positive amounts)
                .getDocuments { snapshot, error in
                    if let error = error {
                        self.error = error
                        completion(false)
                        return
                    }
                    
                    guard let documents = snapshot?.documents else {
                        completion(false)
                        return
                    }
                    
                    // Calculate spent amount per category
                    var categorySpending: [String: Double] = [:]
                    var totalSpent: Double = 0
                    
                    for document in documents {
                        if let category = document.data()["category"] as? String,
                           let amount = document.data()["amount"] as? Double {
                            categorySpending[category, default: 0] += amount
                            totalSpent += amount
                        }
                    }
                    
                    // Create monthly budget data
                    var categoryData: [String: [String: Double]] = [:]
                    var totalBudget: Double = 0
                    
                    for category in categories {
                        let spent = categorySpending[category.name] ?? 0
                        categoryData[category.id] = [
                            "budget": category.amount,
                            "spent": spent
                        ]
                        totalBudget += category.amount
                    }
                    
                    // Save to Firestore
                    let monthlyBudgetRef = self.db.collection("users").document(userId).collection("budget").document(currentYearMonth)
                    
                    let data: [String: Any] = [
                        "totalBudget": totalBudget,
                        "totalSpent": totalSpent,
                        "categories": categoryData,
                        "updatedAt": FieldValue.serverTimestamp()
                    ]
                    
                    monthlyBudgetRef.setData(data, merge: true) { error in
                        if let error = error {
                            self.error = error
                            completion(false)
                        } else {
                            completion(true)
                        }
                    }
                }
        }
    }
    
    // MARK: - Financial Insights
    
    /// Updates monthly financial summaries for insights
    func updateMonthlySummaries(from transactions: [PlaidTransaction], completion: @escaping (Bool) -> Void) {
        guard let userId = userId else {
            error = NSError(domain: "FirestoreManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "User not signed in"])
            completion(false)
            return
        }
        
        // Group transactions by month
        let calendar = Calendar.current
        var transactionsByMonth: [String: [PlaidTransaction]] = [:]
        
        for transaction in transactions {
            let components = calendar.dateComponents([.year, .month], from: transaction.date)
            guard let year = components.year, let month = components.month else { continue }
            
            let yearMonth = String(format: "%04d-%02d", year, month)
            if transactionsByMonth[yearMonth] == nil {
                transactionsByMonth[yearMonth] = []
            }
            transactionsByMonth[yearMonth]?.append(transaction)
        }
        
        // Process each month
        let group = DispatchGroup()
        var overallSuccess = true
        
        for (yearMonth, monthTransactions) in transactionsByMonth {
            group.enter()
            
            // Calculate monthly metrics
            let incomeTransactions = monthTransactions.filter { $0.amount < 0 }
            let expenseTransactions = monthTransactions.filter { $0.amount > 0 }
            
            let income = abs(incomeTransactions.reduce(0) { $0 + $1.amount })
            let expenses = expenseTransactions.reduce(0) { $0 + $1.amount }
            
            // Calculate savings rate
            let savingsRate = income > 0 ? ((income - expenses) / income) * 100 : 0
            
            // Top spending categories
            var categorySpending: [String: Double] = [:]
            for transaction in expenseTransactions {
                categorySpending[transaction.category, default: 0] += transaction.amount
            }
            
            let topCategories = categorySpending.map { (category: String, amount: Double) -> [String: Any] in
                return ["category": category, "amount": amount]
            }.sorted { a, b in
                (a["amount"] as! Double) > (b["amount"] as! Double)
            }.prefix(5)
            
            // Get previous month data to calculate change
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM"
            guard let date = dateFormatter.date(from: yearMonth) else {
                group.leave()
                continue
            }
            
            let previousMonth = calendar.date(byAdding: .month, value: -1, to: date)!
            let previousYearMonth = dateFormatter.string(from: previousMonth)
            
            // Query previous month summary
            let monthlyBudgetsRef = db
                .collection("users")
                .document(userId)
                .collection("budget")
                .document(previousYearMonth)
      

            let previousSummaryRef = db
                .collection("users")
                .document(userId)
                .collection("monthlySummaries")
                
            
            previousSummaryRef.document(previousYearMonth).getDocument { [weak self] document, error in
                guard let self = self else {
                    group.leave()
                    return
                }
                
                var monthlyChange: Double = 0
                
                if let document = document, document.exists,
                   let previousExpenses = document.data()?["expenses"] as? Double {
                    // Calculate percentage change in spending
                    monthlyChange = previousExpenses > 0 ? ((expenses - previousExpenses) / previousExpenses) * 100 : 0
                }
                
                // Save current month summary
                let summaryRef = previousSummaryRef.document(yearMonth)
                
                let data: [String: Any] = [
                    "income": income,
                    "expenses": expenses,
                    "savingsRate": savingsRate,
                    "topCategories": topCategories,
                    "monthlyChange": monthlyChange,
                    "updatedAt": FieldValue.serverTimestamp()
                ]
                
                summaryRef.setData(data, merge: true) { error in
                    if let error = error {
                        self.error = error
                        overallSuccess = false
                    }
                    
                    // If this is the current month, also generate savings tips
                    let currentDateFormatter = DateFormatter()
                    currentDateFormatter.dateFormat = "yyyy-MM"
                    let currentYearMonth = currentDateFormatter.string(from: Date())
                    
                    if yearMonth == currentYearMonth {
                        self.generateSavingsTips(from: monthTransactions) { _ in
                            group.leave()
                        }
                    } else {
                        group.leave()
                    }
                }
            }
        }
        
        // When all months are processed
        group.notify(queue: .main) {
            completion(overallSuccess)
        }
    }
    
    /// Generates and stores personalized savings tips based on transaction patterns
    func generateSavingsTips(from transactions: [PlaidTransaction], completion: @escaping (Bool) -> Void) {
        guard let userId = userId else {
            error = NSError(domain: "FirestoreManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "User not signed in"])
            completion(false)
            return
        }
        
        // Analyze spending patterns
        var categorySpending: [String: Double] = [:]
        for transaction in transactions where transaction.amount > 0 {
            categorySpending[transaction.category, default: 0] += transaction.amount
        }
        
        // Sort categories by spending amount
        let sortedCategories = categorySpending.sorted { $0.value > $1.value }
        
        // Generate tips based on top spending categories
        var tips: [[String: Any]] = []
        
        // Tip 1: Highest spending category
        if let topCategory = sortedCategories.first {
            let potentialSavings = topCategory.value * 0.15 // Suggest 15% reduction
            tips.append([
                "title": "Reduce \(topCategory.key) expenses",
                "description": "You've spent $\(String(format: "%.2f", topCategory.value)) on \(topCategory.key) this month. Try reducing this by 15% to save $\(String(format: "%.2f", potentialSavings)).",
                "category": topCategory.key,
                "potentialSavings": potentialSavings,
                "createdAt": FieldValue.serverTimestamp()
            ])
        }
        
        // Tip 2: Frequency pattern (if dining out multiple times per week)
        let diningTransactions = transactions.filter {
            $0.category.lowercased().contains("food") ||
            $0.category.lowercased().contains("restaurant") ||
            $0.category.lowercased().contains("dining")
        }
        
        if diningTransactions.count > 5 {
            let diningTotal = diningTransactions.reduce(0) { $0 + abs($1.amount) }
            let potentialSavings = diningTotal * 0.2 // Suggest 20% reduction
            tips.append([
                "title": "Cook more meals at home",
                "description": "You dined out \(diningTransactions.count) times this month. Cooking at home 2 more times per week could save you about $\(String(format: "%.2f", potentialSavings)) monthly.",
                "category": "Food & Dining",
                "potentialSavings": potentialSavings,
                "createdAt": FieldValue.serverTimestamp()
            ])
        }
        
        // Tip 3: Subscription analysis
        let smallRecurringTransactions = findPotentialSubscriptions(in: transactions)
        if !smallRecurringTransactions.isEmpty {
            let totalSubscriptionCost = smallRecurringTransactions.reduce(0) { $0 + $1.amount }
            tips.append([
                "title": "Review your subscriptions",
                "description": "You may have \(smallRecurringTransactions.count) active subscriptions totaling $\(String(format: "%.2f", totalSubscriptionCost)) monthly. Consider reviewing these services to see if you're still using all of them.",
                "category": "Subscriptions",
                "potentialSavings": totalSubscriptionCost * 0.3, // Assume 30% could be cut
                "createdAt": FieldValue.serverTimestamp()
            ])
        }
        
        // Save tips to Firestore
        let batch = db.batch()
        
        // First, delete existing tips
        db.collection("users/\(userId)/insights/savingsTips").getDocuments { [weak self] snapshot, error in
            guard let self = self else {
                completion(false)
                return
            }
            
            if let error = error {
                self.error = error
                completion(false)
                return
            }
            
            let batch = db.batch()
            
            // Delete existing tips
            if let documents = snapshot?.documents {
                for document in documents {
                    batch.deleteDocument(document.reference)
                }
            }
            
            // Add new tips
            for tip in tips {
                let tipRef = self.db.collection("users/\(userId)/insights/savingsTips").document()
                batch.setData(tip, forDocument: tipRef)
            }
            
            // Commit the batch
            batch.commit { error in
                if let error = error {
                    self.error = error
                    completion(false)
                } else {
                    completion(true)
                }
            }
        }
    }
    
    /// Helper function to find potential subscriptions in transactions
    private func findPotentialSubscriptions(in transactions: [PlaidTransaction]) -> [PlaidTransaction] {
        // Look for transactions with similar amounts (between $5 and $50)
        let potentialSubscriptions = transactions.filter {
            $0.amount >= 5 && $0.amount <= 50 &&
            (
                $0.category.lowercased().contains("subscription") ||
                $0.merchantName.lowercased().contains("netflix") ||
                $0.merchantName.lowercased().contains("spotify") ||
                $0.merchantName.lowercased().contains("hulu") ||
                $0.merchantName.lowercased().contains("disney") ||
                $0.merchantName.lowercased().contains("apple") ||
                $0.merchantName.lowercased().contains("amazon") ||
                $0.merchantName.lowercased().contains("prime")
            )
        }
        
        return potentialSubscriptions
    }
    
    // MARK: - Data Models
    
    // These would normally be in separate files, but included here for completeness
    
    struct MonthlyBudget: Codable, Identifiable {
        var id: String // YYYY-MM format
        var totalBudget: Double
        var totalSpent: Double
        var categories: [String: CategoryBudget] // Dictionary of category ID to budget/spent data
        var updatedAt: Date
        
        struct CategoryBudget: Codable {
            var budget: Double
            var spent: Double
        }
    }
    
    struct MonthlySummary: Codable, Identifiable {
        var id: String // YYYY-MM format
        var income: Double
        var expenses: Double
        var savingsRate: Double
        var topCategories: [CategorySpending]
        var monthlyChange: Double
        var updatedAt: Date
        
        struct CategorySpending: Codable {
            var category: String
            var amount: Double
        }
    }
    
    struct SavingsTip: Codable, Identifiable {
        var id: String
        var title: String
        var description: String
        var category: String
        var potentialSavings: Double
        var createdAt: Date
    }
}

