//
//  Account.swift
//  Pennywise
//
//  Domain Entity - Pure Swift, no framework dependencies
//

import Foundation

/// Domain entity representing a financial account
public struct Account: Identifiable, Codable, Equatable, Hashable, Sendable {
    public let id: String
    public let name: String
    public let type: String
    public let balance: Double
    public let institutionName: String
    public let institutionLogo: Data?
    public let isPlaceholder: Bool
    
    public init(
        id: String,
        name: String,
        type: String,
        balance: Double,
        institutionName: String,
        institutionLogo: Data? = nil,
        isPlaceholder: Bool = false
    ) {
        self.id = id
        self.name = name
        self.type = type
        self.balance = balance
        self.institutionName = institutionName
        self.institutionLogo = institutionLogo
        self.isPlaceholder = isPlaceholder
    }
}

// MARK: - Business Logic

extension Account {
    /// Check if balance is positive
    public var isPositive: Bool {
        balance >= 0
    }
    
    /// Formatted balance string
    public var formattedBalance: String {
        CurrencyFormatter.format(balance)
    }
    
    /// Account number last 4 digits
    public var maskedAccountNumber: String {
        "****\(id.suffix(4))"
    }
}

