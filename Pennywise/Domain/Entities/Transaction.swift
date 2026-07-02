//
//  Transaction.swift
//  Pennywise
//
//  Domain Entity - Pure Swift, no framework dependencies
//

import Foundation

/// Domain entity representing a financial transaction
public struct Transaction: Identifiable, Equatable, Hashable, Codable, Sendable {
    public let id: String
    public let name: String
    public let amount: Double
    public let date: Date
    public let category: String
    public let merchantName: String
    public let accountId: String
    public let isPending: Bool
    public let isManual: Bool
    
    public init(
        id: String,
        name: String,
        amount: Double,
        date: Date,
        category: String,
        merchantName: String,
        accountId: String,
        isPending: Bool = false,
        isManual: Bool = false
    ) {
        self.id = id
        self.name = name
        self.amount = amount
        self.date = date
        self.category = category
        self.merchantName = merchantName
        self.accountId = accountId
        self.isPending = isPending
        self.isManual = isManual
    }
    
    /// Formatted amount string
    public var formattedAmount: String {
        CurrencyFormatter.format(absoluteAmount)
    }
}

// MARK: - Business Logic Extensions

extension Transaction {
    /// Transaction is income if amount is negative
    public var isIncome: Bool {
        amount < 0
    }
    
    /// Transaction is expense if amount is positive
    public var isExpense: Bool {
        amount > 0
    }
    
    /// Absolute value of amount
    public var absoluteAmount: Double {
        abs(amount)
    }
    
    /// Check if transaction is in a specific month
    public func isInMonth(_ date: Date) -> Bool {
        Calendar.current.isDate(self.date, equalTo: date, toGranularity: .month)
    }
    
    /// Check if transaction is in current month
    public var isInCurrentMonth: Bool {
        isInMonth(Date())
    }
    
    /// Check if transaction is cash/manual
    public var isCash: Bool {
        accountId == "cash" || isManual
    }
}

