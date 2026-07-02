//
//  TransactionRepository.swift
//  Pennywise
//
//  Repository Protocol - Domain Layer
//

import Foundation

/// Repository protocol for transaction data access
/// Defined in Domain layer, implemented in Data layer
@MainActor
public protocol TransactionRepository {
    /// Fetch all transactions
    func fetchTransactions() async throws -> [Transaction]
    
    /// Fetch transactions for a specific account
    func fetchTransactions(for accountId: String) async throws -> [Transaction]
    
    /// Fetch transactions for current month
    func fetchCurrentMonthTransactions() async throws -> [Transaction]
    
    /// Add a new transaction
    func addTransaction(_ transaction: Transaction) async throws
    
    /// Update an existing transaction
    func updateTransaction(_ transaction: Transaction) async throws
    
    /// Delete a transaction
    func deleteTransaction(id: String) async throws
    
    /// Update transaction category
    func updateTransactionCategory(transactionId: String, category: String) async throws
    
    /// Sync transactions with remote source
    func syncTransactions() async throws

    /// Reset the sync: clears the local cache, purges accumulated sandbox/sample
    /// data from the remote cache, and re-fetches a fresh set.
    func resetSync() async throws
}

