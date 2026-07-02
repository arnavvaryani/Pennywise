//
//  PlaidAccount.swift
//  Pennywise
//
//  Created for Plaid SDK compatibility
//

import Foundation

// MARK: - PlaidAccount
/// Represents a Plaid account (used by PlaidSandboxManager)
public struct PlaidAccount: Identifiable, Codable {
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

