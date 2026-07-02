//
//  AccountRepository.swift
//  Pennywise
//
//  Repository Protocol - Domain Layer
//

import Foundation

/// Repository protocol for account data access
@MainActor
public protocol AccountRepository {
    /// Fetch all accounts
    func fetchAccounts() async throws -> [Account]
    
    /// Fetch a specific account by ID
    func fetchAccount(id: String) async throws -> Account?
    
    /// Sync accounts with remote source
    func syncAccounts() async throws
    
    /// Disconnect an account
    func disconnectAccount(id: String) async throws
    
    /// Disconnect all accounts
    func disconnectAllAccounts() async throws
}

