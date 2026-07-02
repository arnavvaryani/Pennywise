//
//  AddTransactionUseCase.swift
//  Pennywise
//
//  Use Case - Domain Layer
//

import Foundation

/// Use case for adding a new transaction
@MainActor
public final class AddTransactionUseCase {
    private let transactionRepository: TransactionRepository
    
    public init(transactionRepository: TransactionRepository) {
        self.transactionRepository = transactionRepository
    }
    
    public func execute(
        name: String,
        amount: Double,
        date: Date,
        category: String,
        merchantName: String,
        accountId: String
    ) async throws -> Transaction {
        // Business validation
        guard !name.trimmingCharacters(in: .whitespaces).isEmpty else {
            throw TransactionError.invalidName
        }
        
        guard amount != 0 else {
            throw TransactionError.invalidAmount
        }
        
        guard !category.isEmpty else {
            throw TransactionError.invalidCategory
        }
        
        // Create transaction
        let transaction = Transaction(
            id: UUID().uuidString,
            name: name,
            amount: amount,
            date: date,
            category: category,
            merchantName: merchantName,
            accountId: accountId,
            isPending: false,
            isManual: true
        )
        
        // Save via repository
        try await transactionRepository.addTransaction(transaction)
        
        return transaction
    }
}

/// Transaction errors
public enum TransactionError: LocalizedError {
    case invalidName
    case invalidAmount
    case invalidCategory
    case notFound
    
    public var errorDescription: String? {
        switch self {
        case .invalidName:
            return "Transaction name cannot be empty"
        case .invalidAmount:
            return "Transaction amount must be non-zero"
        case .invalidCategory:
            return "Invalid transaction category"
        case .notFound:
            return "Transaction not found"
        }
    }
}

