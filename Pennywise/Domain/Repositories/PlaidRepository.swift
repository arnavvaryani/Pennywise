//
//  PlaidRepository.swift
//  Pennywise
//
//  Repository Protocol - Domain Layer
//

import Foundation

/// Repository protocol for Plaid integration
@MainActor
public protocol PlaidRepository {
    /// Prepare Plaid Link for presentation
    func preparePlaidLink() async throws
    
    /// Present Plaid Link
    func presentPlaidLink() async throws
    
    /// Exchange public token for access token
    func exchangePublicToken(_ publicToken: String) async throws
    
    /// Check if Plaid is linked
    var isPlaidLinked: Bool { get }
}

