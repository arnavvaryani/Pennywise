//
//  AccountRepositoryImpl.swift
//  Pennywise
//
//  Repository Implementation - Data Layer
//

import Foundation
import Combine
import FirebaseAuth

/// Implementation of AccountRepository
@MainActor
public final class AccountRepositoryImpl: AccountRepository {
    private let plaidService: PlaidAPIService
    private let firestoreService: FirestoreService
    private let transactionRepository: TransactionRepository?
    
    // In-memory cache of the latest accounts (source for local mutations).
    private let accountsSubject = CurrentValueSubject<[Account], Never>([])

    public init(plaidService: PlaidAPIService, firestoreService: FirestoreService, transactionRepository: TransactionRepository? = nil) {
        self.plaidService = plaidService
        self.firestoreService = firestoreService
        self.transactionRepository = transactionRepository
    }
    
    public func fetchAccounts() async throws -> [Account] {
        // Plaid is the single source of truth for accounts (fetched live, not
        // persisted to Firestore — there is no "manual account" concept, so the
        // old Firestore write-back/fallback was a pure cache and a second source
        // of truth we no longer want).
        do {
            let plaidDTOs = try await plaidService.fetchAccounts()
            let accounts = AccountMapper.toDomainArray(plaidDTOs)
            accountsSubject.send(accounts)
            return accounts
        } catch {
            // Plaid unavailable: return the last known in-memory accounts.
            return accountsSubject.value
        }
    }
    
    public func fetchAccount(id: String) async throws -> Account? {
        let accounts = try await fetchAccounts()
        return accounts.first { $0.id == id }
    }
    
    public func syncAccounts() async throws {
        _ = try await fetchAccounts()
    }
    
    public func disconnectAccount(id: String) async throws {
        // Remove from Firestore
        try await firestoreService.deleteAccount(id: id)
        
        // Update local cache
        var current = accountsSubject.value
        current.removeAll { $0.id == id }
        accountsSubject.send(current)
    }
    
    public func disconnectAllAccounts() async throws {
        if let userId = Auth.auth().currentUser?.uid {
            // Purge cached data so UI doesn't keep showing "disconnected" transactions.
            try? await firestoreService.deleteAllTransactions(userId: userId)
        }
        try await firestoreService.deleteAllAccounts()
        try await plaidService.disconnect()
        accountsSubject.send([])
        
        // Best-effort clear local transaction publisher if the implementation is available.
        if let impl = transactionRepository as? TransactionRepositoryImpl {
            impl.clearLocalCache()
        }
    }
}

