//
//  PlaidDTO.swift
//  Pennywise
//
//  Data Transfer Objects for Plaid API
//

import Foundation

/// DTO for Plaid transaction
public struct PlaidTransactionDTO: Codable, Sendable {
    public let id: String
    public let name: String
    public let amount: Double
    public let date: Date
    public let category: String
    public let merchantName: String
    public let accountId: String
    public let pending: Bool
    
    public init(
        id: String,
        name: String,
        amount: Double,
        date: Date,
        category: String,
        merchantName: String,
        accountId: String,
        pending: Bool
    ) {
        self.id = id
        self.name = name
        self.amount = amount
        self.date = date
        self.category = category
        self.merchantName = merchantName
        self.accountId = accountId
        self.pending = pending
    }
}

/// DTO for Plaid account
public struct PlaidAccountDTO: Codable, Sendable {
    public let id: String
    public let name: String
    public let type: String
    public let balance: Double
    public let institutionName: String
    public let institutionLogo: Data?
    
    public init(
        id: String,
        name: String,
        type: String,
        balance: Double,
        institutionName: String,
        institutionLogo: Data? = nil
    ) {
        self.id = id
        self.name = name
        self.type = type
        self.balance = balance
        self.institutionName = institutionName
        self.institutionLogo = institutionLogo
    }
}

