//
//  PlaidAPIService.swift
//  Pennywise
//
//  Service for Plaid API operations
//

import Foundation
import LinkKit
import Security

/// Service for Plaid API interactions
@MainActor
public final class PlaidAPIService {
    private let keychainServiceName = "com.pennywise.plaid"
    private let keychainAccessTokenKey = "plaid_access_token"
    
    private(set) var linkController: (any Handler)?
    
    public init() {}
    
    // MARK: - Access Token Management
    
    private var accessToken: String? {
        get {
            var item: CFTypeRef?
            let query: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: keychainServiceName,
                kSecAttrAccount as String: keychainAccessTokenKey,
                kSecReturnData as String: true
            ]
            let status = SecItemCopyMatching(query as CFDictionary, &item)
            guard status == errSecSuccess,
                  let data = item as? Data,
                  let token = String(data: data, encoding: .utf8)
            else { return nil }
            return token
        }
        set {
            let deleteQuery: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: keychainServiceName,
                kSecAttrAccount as String: keychainAccessTokenKey
            ]
            SecItemDelete(deleteQuery as CFDictionary)
            
            if let newValue = newValue, let valueData = newValue.data(using: .utf8) {
                let addQuery: [String: Any] = [
                    kSecClass as String: kSecClassGenericPassword,
                    kSecAttrService as String: keychainServiceName,
                    kSecAttrAccount as String: keychainAccessTokenKey,
                    kSecValueData as String: valueData
                ]
                SecItemAdd(addQuery as CFDictionary, nil)
            }
        }
    }
    
    // MARK: - Public Methods
    
    public func exchangePublicToken(_ publicToken: String) async throws -> String {
        // Call your backend to exchange the token
        // For now, using the existing sandbox manager
        let token = try await PlaidSandboxManager.shared.exchangePublicToken(publicToken)
        self.accessToken = token
        NotificationCenter.default.post(name: PlaidNotifications.linkedStateChanged, object: nil)
        return token
    }
    
    public func fetchAccounts() async throws -> [PlaidAccountDTO] {
        guard let token = accessToken else {
            throw NSError(domain: "PlaidAPIService", code: -1, userInfo: [NSLocalizedDescriptionKey: "No access token"])
        }
        
        let accounts = try await PlaidSandboxManager.shared.getAccounts(accessToken: token)
        return accounts.map { account in
            PlaidAccountDTO(
                id: account.id,
                name: account.name,
                type: account.type,
                balance: account.balance,
                institutionName: account.institutionName,
                institutionLogo: account.institutionLogo
            )
        }
    }
    
    public func fetchTransactions() async throws -> [PlaidTransactionDTO] {
        guard let token = accessToken else {
            throw NSError(domain: "PlaidAPIService", code: -1, userInfo: [NSLocalizedDescriptionKey: "No access token"])
        }
        
        let transactions = try await PlaidSandboxManager.shared.getTransactions(accessToken: token)
        return transactions.map { tx in
            PlaidTransactionDTO(
                id: tx.id,
                name: tx.name,
                amount: tx.amount,
                date: tx.date,
                category: tx.category,
                merchantName: tx.merchantName,
                accountId: tx.accountId,
                pending: tx.pending
            )
        }
    }
    
    public func prepareLinkController() async throws {
        let token = try await PlaidSandboxManager.shared.createLinkToken()
        UserDefaults.standard.set(token, forKey: "plaid_link_token")
        let config = self.buildLinkConfig(token: token)
        switch Plaid.create(config) {
        case .success(let controller):
            self.linkController = controller
        case .failure(let error):
            throw error
        }
    }
    
    /// Called when the user exits the Plaid Link flow (with or without linking).
    public var onExit: (() -> Void)?
    /// Called when the user successfully links an account (after token exchange).
    public var onSuccess: (() -> Void)?
    /// Called when token exchange fails after Link success.
    public var onLinkError: ((Error) -> Void)?

    private func buildLinkConfig(token: String) -> LinkTokenConfiguration {
        var config = LinkTokenConfiguration(token: token) { [weak self] success in
            Task {
                do {
                    _ = try await self?.exchangePublicToken(success.publicToken)
                    self?.onSuccess?()
                } catch {
                    self?.onLinkError?(error)
                }
            }
        }
        config.onExit = { [weak self] _ in
            self?.onExit?()
        }
        config.onEvent = { _ in }
        return config
    }
    
    public func hasAccessToken() -> Bool {
        accessToken != nil
    }
    
    public func clearAccessToken() {
        accessToken = nil
        NotificationCenter.default.post(name: PlaidNotifications.linkedStateChanged, object: nil)
    }
    
    public func disconnect() async throws {
        guard let token = accessToken else { return }
        try await PlaidSandboxManager.shared.removeItem(accessToken: token)
        self.clearAccessToken()
    }
}

