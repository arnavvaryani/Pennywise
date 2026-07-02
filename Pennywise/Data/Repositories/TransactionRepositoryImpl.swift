//
//  TransactionRepositoryImpl.swift
//  Pennywise
//
//  Repository Implementation - Data Layer
//

import Foundation
import Combine

/// Implementation of TransactionRepository
@MainActor
public final class TransactionRepositoryImpl: TransactionRepository {
    private let plaidService: PlaidAPIService
    private let firestoreService: FirestoreService
    
    // In-memory cache of the latest transactions (source for local mutations).
    private let transactionsSubject = CurrentValueSubject<[Transaction], Never>([])

    public init(plaidService: PlaidAPIService, firestoreService: FirestoreService) {
        self.plaidService = plaidService
        self.firestoreService = firestoreService
    }
    
    public func clearLocalCache() {
        transactionsSubject.send([])
    }
    
    public func fetchTransactions() async throws -> [Transaction] {
        // Single source of truth per data type:
        //  • Plaid is authoritative for bank transactions (fetched live, NEVER
        //    written back to Firestore — that write-back was the root cause of the
        //    duplicate/accumulation bugs).
        //  • Firestore is authoritative for user-authored (manual) transactions.
        // The view is the union of the two (their IDs are disjoint).
        let manual = (try? await firestoreService.fetchManualTransactions()) ?? []

        do {
            let plaidDTOs = try await plaidService.fetchTransactions()
            let plaid = TransactionMapper.toDomainArray(plaidDTOs)
            let merged = plaid + manual
            transactionsSubject.send(merged)
            return merged
        } catch {
            // Plaid unavailable: show the user's own manual transactions only.
            // (No bank-transaction cache exists by design.)
            transactionsSubject.send(manual)
            return manual
        }
    }
    
    public func fetchTransactions(for accountId: String) async throws -> [Transaction] {
        let allTransactions = try await fetchTransactions()
        return allTransactions.filter { $0.accountId == accountId }
    }
    
    public func fetchCurrentMonthTransactions() async throws -> [Transaction] {
        let allTransactions = try await fetchTransactions()
        return allTransactions.filter { $0.isInCurrentMonth }
    }
    
    public func addTransaction(_ transaction: Transaction) async throws {
        try await firestoreService.saveTransaction(transaction)
        
        // Update local cache
        var current = transactionsSubject.value
        current.insert(transaction, at: 0)
        transactionsSubject.send(current)
    }
    
    public func updateTransaction(_ transaction: Transaction) async throws {
        try await firestoreService.updateTransaction(transaction)
        
        // Update local cache
        var current = transactionsSubject.value
        if let index = current.firstIndex(where: { $0.id == transaction.id }) {
            current[index] = transaction
            transactionsSubject.send(current)
        }
    }
    
    public func deleteTransaction(id: String) async throws {
        try await firestoreService.deleteTransaction(id: id)
        
        // Update local cache
        var current = transactionsSubject.value
        current.removeAll { $0.id == id }
        transactionsSubject.send(current)
    }
    
    public func updateTransactionCategory(transactionId: String, category: String) async throws {
        // Fetch current transaction
        let current = transactionsSubject.value
        guard var transaction = current.first(where: { $0.id == transactionId }) else {
            throw TransactionError.notFound
        }
        
        // Update category
        transaction = Transaction(
            id: transaction.id,
            name: transaction.name,
            amount: transaction.amount,
            date: transaction.date,
            category: category,
            merchantName: transaction.merchantName,
            accountId: transaction.accountId,
            isPending: transaction.isPending,
            isManual: transaction.isManual
        )
        
        try await updateTransaction(transaction)
    }
    
    public func syncTransactions() async throws {
        _ = try await fetchTransactions()
    }

    public func resetSync() async throws {
        // Drop stale in-memory data and remove any legacy Plaid/sample rows that
        // older builds wrote into Firestore. Only user-authored (manual)
        // transactions should live in Firestore now.
        clearLocalCache()
        try? await firestoreService.purgeNonManualTransactions()
        _ = try await fetchTransactions()
    }
}

