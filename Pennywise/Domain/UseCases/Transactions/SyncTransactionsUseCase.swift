//
//  SyncTransactionsUseCase.swift
//  Pennywise
//
//  Use Case - Domain Layer
//

import Foundation

/// Use case for syncing transactions with remote source
@MainActor
public final class SyncTransactionsUseCase {
    private let transactionRepository: TransactionRepository
    private let accountRepository: AccountRepository
    
    public init(
        transactionRepository: TransactionRepository,
        accountRepository: AccountRepository
    ) {
        self.transactionRepository = transactionRepository
        self.accountRepository = accountRepository
    }
    
    public func execute() async throws {
        // Sync both accounts and transactions
        try await accountRepository.syncAccounts()
        try await transactionRepository.syncTransactions()
    }
}

