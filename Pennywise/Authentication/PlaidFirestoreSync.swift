//
//  PlaidFirestoreSync.swift
//  Pennywise
//
//  Created by Arnav Varyani on 4/24/25.
//

import Foundation
import Combine
import Firebase

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
            // We can't directly access the token, so we'll have to rely on the
            // PlaidManager's internal implementation to load accounts
            
            // Just call prepareLinkController to ensure accounts are loaded if possible
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
        // If no transactions, fetch them first
        if plaidManager.transactions.isEmpty {
            plaidManager.fetchTransactions { [weak self] success in
                guard let self = self else {
                    completion?(false)
                    return
                }
                
                if success {
                    self.firestoreManager.syncTransactions(self.plaidManager.transactions, completion: completion ?? { _ in })
                } else {
                    completion?(false)
                }
            }
        } else {
            // Use existing transactions
            firestoreManager.syncTransactions(plaidManager.transactions, completion: completion ?? { _ in })
        }
    }
    
    /// Syncs budget data to Firestore
    func syncBudgetData(completion: ((Bool) -> Void)? = nil) {
        // Get budget categories from Plaid Manager
        let categories = plaidManager.getBudgetCategories()
        
        // Sync each category
        let group = DispatchGroup()
        var overallSuccess = true
        
        for category in categories {
            group.enter()
            
            firestoreManager.saveBudgetCategory(category) { success in
                if !success {
                    overallSuccess = false
                }
                group.leave()
            }
        }
        
        // Update budget usage
        group.enter()
        firestoreManager.updateBudgetUsage { success in
            if !success {
                overallSuccess = false
            }
            group.leave()
        }
        
        // When all operations complete
        group.notify(queue: .main) {
            completion?(overallSuccess)
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
