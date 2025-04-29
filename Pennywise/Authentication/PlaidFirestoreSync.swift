//
//  PlaidFirestoreSync.swift
//  Pennywise
//
//  Created by Arnav Varyani on 4/24/25.
//

import Foundation
import Combine
import Firebase
import FirebaseAuth

/// Manages synchronization between Plaid API data and Firestore
class PlaidFirestoreSync: ObservableObject {
    static let shared = PlaidFirestoreSync()
    
    // References to other services
    private let plaidManager = PlaidManager.shared
    private let firestoreManager = FirestoreManager.shared
    private let authService = AuthenticationService.shared
    
    // Sync status
    @Published var isSyncing = false
    @Published var lastSyncTime: Date?
    @Published var syncError: Error?
    @Published var syncProgress: Float = 0
    
    // Sync configuration
    private let minSyncInterval: TimeInterval = 3600 // 1 hour between syncs
    private var syncTimer: Timer?
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        // Set up auth state observer
        authService.$isAuthenticated
            .sink { [weak self] isAuthenticated in
                if isAuthenticated {
                    self?.startSyncTimer()
                } else {
                    self?.stopSyncTimer()
                }
            }
            .store(in: &cancellables)
        
        // Set up observer for new Plaid accounts
        plaidManager.$accounts
            .dropFirst() // Skip initial empty value
            .sink { [weak self] accounts in
                if !accounts.isEmpty {
                    self?.syncAccountsToFirestore()
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Sync Timer Management
    
    /// Starts a timer for regular syncing
    func startSyncTimer() {
        stopSyncTimer() // Ensure no duplicate timers
        
        // Run an initial sync
        performFullSync()
        
        // Set up timer for regular syncs
        syncTimer = Timer.scheduledTimer(withTimeInterval: minSyncInterval, repeats: true) { [weak self] _ in
            self?.performFullSync()
        }
    }
    
    /// Stops the sync timer
    func stopSyncTimer() {
        syncTimer?.invalidate()
        syncTimer = nil
    }
     
    
    // MARK: - Sync Operations
    
    /// Performs a complete sync of all Plaid data to Firestore
    func performFullSync(completion: ((Bool) -> Void)? = nil) {
        guard !isSyncing, authService.isAuthenticated else {
            completion?(false)
            return
        }
        
        guard shouldSync() else {
            print("Skipping sync: Last sync was too recent")
            completion?(false)
            return
        }
        
        isSyncing = true
        syncProgress = 0
        syncError = nil
        
        // Update progress for UI
        syncProgress = 0.1
        
        // First, sync accounts
        syncAccountsToFirestore { [weak self] accountSuccess in
            guard let self = self else {
                completion?(false)
                return
            }
            
            if !accountSuccess {
                self.handleSyncFailure(error: NSError(domain: "PlaidFirestoreSync", code: 1,
                                                    userInfo: [NSLocalizedDescriptionKey: "Failed to sync accounts"]))
                completion?(false)
                return
            }
            
            // Update progress
            self.syncProgress = 0.3
            
            // Next, sync transactions
            self.syncTransactionsToFirestore { transactionSuccess in
                if !transactionSuccess {
                    self.handleSyncFailure(error: NSError(domain: "PlaidFirestoreSync", code: 2,
                                                        userInfo: [NSLocalizedDescriptionKey: "Failed to sync transactions"]))
                    completion?(false)
                    return
                }
                
                // Update progress
                self.syncProgress = 0.7
                
                // Finally, update budget data
                self.syncBudgetData { budgetSuccess in
                    // Complete the sync
                    self.syncProgress = 1.0
                    self.isSyncing = false
                    self.lastSyncTime = Date()
                    
                    if !budgetSuccess {
                        self.syncError = NSError(domain: "PlaidFirestoreSync", code: 3,
                                                userInfo: [NSLocalizedDescriptionKey: "Failed to sync budget data"])
                    }
                    
                    // Save last sync time
                    UserDefaults.standard.set(self.lastSyncTime?.timeIntervalSince1970, forKey: "lastPlaidSyncTime")
                    
                    completion?(budgetSuccess)
                }
            }
        }
    }
    
    /// Syncs account data to Firestore
    func syncAccountsToFirestore(completion: ((Bool) -> Void)? = nil) {
        // If no accounts, fetch them first
        if plaidManager.accounts.isEmpty {
            plaidManager.prepareLinkController()
            
            // Give some time for accounts to be fetched, then sync
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
                guard let self = self else {
                    completion?(false)
                    return
                }
                
                // If we have accounts now, sync them
                if !self.plaidManager.accounts.isEmpty {
                    self.firestoreManager.syncAccounts(self.plaidManager.accounts, completion: completion ?? { _ in })
                } else {
                    completion?(false)
                }
            }
        } else {
            // Use existing accounts
            firestoreManager.syncAccounts(plaidManager.accounts, completion: completion ?? { _ in })
        }
    }
    
    /// Syncs transaction data to Firestore
        func syncTransactionsToFirestore(completion: ((Bool) -> Void)? = nil) {
            guard let userId = Auth.auth().currentUser?.uid else {
                print("Error: User not logged in")
                completion?(false)
                return
            }
            
            // Get all transactions from PlaidManager
            let transactions = plaidManager.transactions
            
            if transactions.isEmpty {
                print("No transactions to sync")
                completion?(true)
                return
            }
            
            print("Syncing \(transactions.count) transactions to Firestore")
            
            // Create batches of transactions (max 500 operations per batch in Firestore)
            let batchSize = 450 // Leaving room for other operations
            let batches = stride(from: 0, to: transactions.count, by: batchSize).map {
                Array(transactions[$0..<min($0 + batchSize, transactions.count)])
            }
            
            // Process each batch
            processBatches(batches, userId: userId, index: 0) { [weak self] success in
                if success {
                    print("Successfully synced all transaction batches")
                    
                    // Update monthly summaries
                    self?.firestoreManager.updateMonthlySummaries(from: transactions) { summariesSuccess in
                        if summariesSuccess {
                            print("Successfully updated monthly summaries")
                        } else {
                            print("Failed to update monthly summaries")
                        }
                        
                        // Update budget categories
                        self?.firestoreManager.updateBudgetUsage { budgetSuccess in
                            print("Budget usage update: \(budgetSuccess)")
                            completion?(true)
                        }
                    }
                } else {
                    print("Failed to sync all transaction batches")
                    completion?(false)
                }
            }
        }
    
    /// Processes batches of transactions recursively
    private func processBatches(_ batches: [[PlaidTransaction]], userId: String, index: Int, completion: @escaping (Bool) -> Void) {
        // Base case: if we've processed all batches, we're done
        if index >= batches.count {
            completion(true)
            return
        }
        
        let currentBatch = batches[index]
        print("Processing transaction batch \(index + 1)/\(batches.count) with \(currentBatch.count) transactions")
        
        // Create a new batch write
        let batch = Firestore.firestore().batch()
        
        // Reference to the transactions collection
        let transactionsRef = Firestore.firestore().collection("users").document(userId).collection("transactions")
        
        // Add each transaction to the batch
        for transaction in currentBatch {
            let docRef = transactionsRef.document(transaction.id)
            
            // Convert transaction to dictionary manually
            let transactionData: [String: Any] = [
                "id": transaction.id,
                "accountId": transaction.accountId,
                "name": transaction.name,
                "amount": transaction.amount,
                "date": transaction.date,
                "category": transaction.category,
                "merchantName": transaction.merchantName,
                "pending": transaction.pending,
                "lastUpdated": FieldValue.serverTimestamp()
            ]
            
            // Add a set operation to the batch
            batch.setData(transactionData, forDocument: docRef, merge: true)
        }
        
        // Commit the batch
        batch.commit { [weak self] error in
            if let error = error {
                print("Error writing transaction batch \(index): \(error.localizedDescription)")
                completion(false)
                return
            }
            
            // Update progress if needed
            let progressPerBatch = 0.4 / Float(batches.count)
            self?.syncProgress = 0.3 + (Float(index + 1) * progressPerBatch)
            
            // Process the next batch
            self?.processBatches(batches, userId: userId, index: index + 1, completion: completion)
        }
    }
    
    
    /// Syncs budget data to Firestore
    func syncBudgetData(completion: @escaping ((Bool) -> Void)) {
        // Get budget categories from Plaid Manager with proper mappings
        let categories = plaidManager.getBudgetCategories()
        
        // Sync each category with Firestore
        let group = DispatchGroup()
        var overallSuccess = true
        
        // Check existing categories to avoid duplicates
        guard let userId = Auth.auth().currentUser?.uid else {
            completion(false)
            return
        }
        
        let db = Firestore.firestore()
        
        // First, get existing categories
        db.collection("users/\(userId)/budgetCategories").getDocuments { [weak self] snapshot, error in
            guard let self = self else {
                completion(false)
                return
            }
            
            if let error = error {
                print("Error fetching categories: \(error.localizedDescription)")
                completion(false)
                return
            }
            
            // Create a map of existing categories by name
            var existingCategoriesByName: [String: String] = [:]
            
            if let documents = snapshot?.documents {
                for document in documents {
                    if let name = document.data()["name"] as? String {
                        existingCategoriesByName[name.lowercased()] = document.documentID
                    }
                }
            }
            
            // Process each category - update existing or create new
            for category in categories {
                group.enter()
                
                // Check if category already exists
                if let docId = existingCategoriesByName[category.name.lowercased()] {
                    // Update existing category
                    self.firestoreManager.updateBudgetCategory(
                        docId: docId,
                        category: category
                    ) { success in
                        if !success {
                            overallSuccess = false
                        }
                        group.leave()
                    }
                } else {
                    // Create new category
                    self.firestoreManager.saveBudgetCategory(category) { success in
                        if !success {
                            overallSuccess = false
                        }
                        group.leave()
                    }
                }
            }
            
            // Update budget usage
            group.enter()
            self.firestoreManager.updateBudgetUsage { success in
                if !success {
                    overallSuccess = false
                }
                group.leave()
            }
            
            // When all operations complete
            group.notify(queue: .main) {
                completion(overallSuccess)
            }
        }
    }
    
    // MARK: - Helper Methods
    
    /// Determines if enough time has passed since the last sync
    private func shouldSync() -> Bool {
        if let lastSyncTimeInterval = UserDefaults.standard.double(forKey: "lastPlaidSyncTime") as TimeInterval?,
           lastSyncTimeInterval > 0 {
            let lastSync = Date(timeIntervalSince1970: lastSyncTimeInterval)
            let timeSinceLastSync = Date().timeIntervalSince(lastSync)
            
            // Skip if synced recently, unless it's a force sync
            return timeSinceLastSync >= minSyncInterval
        }
        
        // No previous sync, should sync
        return true
    }
    
    /// Handles a sync failure
    private func handleSyncFailure(error: Error) {
        isSyncing = false
        syncError = error
        syncProgress = 0
        
        // Log the error
        print("Sync error: \(error.localizedDescription)")
    }
    
    // MARK: - Public Methods
    
    /// Forces an immediate data sync
    func forceSyncNow(completion: ((Bool) -> Void)? = nil) {
        // Cancel any ongoing sync
        isSyncing = false
        
        // Start a new sync
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.performFullSync(completion: completion)
        }
    }
    
    /// Updates a specific transaction's notes, tags or hidden status
    func updateTransactionDetails(transaction: PlaidTransaction, notes: String? = nil,
                                tags: [String]? = nil, isHidden: Bool? = nil,
                                completion: @escaping (Bool) -> Void) {
        firestoreManager.updateTransactionDetails(
            transactionId: transaction.id,
            notes: notes,
            tags: tags,
            isHidden: isHidden,
            completion: completion
        )
    }
    
    /// Updates a transaction's category
    func updateTransactionCategory(transaction: PlaidTransaction, newCategory: String, completion: @escaping (Bool) -> Void) {
        firestoreManager.updateTransactionCategory(
            transactionId: transaction.id,
            category: newCategory,
            completion: completion
        )
    }
}
