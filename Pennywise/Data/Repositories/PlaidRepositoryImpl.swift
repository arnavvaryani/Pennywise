//
//  PlaidRepositoryImpl.swift
//  Pennywise
//
//  Repository Implementation - Data Layer
//

import Foundation
import LinkKit

/// Implementation of PlaidRepository
@MainActor
public final class PlaidRepositoryImpl: PlaidRepository {
    private let plaidService: PlaidAPIService
    
    public var isPlaidLinked: Bool {
        plaidService.hasAccessToken()
    }
    
    public init(plaidService: PlaidAPIService) {
        self.plaidService = plaidService
    }
    
    public func preparePlaidLink() async throws {
        try await plaidService.prepareLinkController()
    }
    
    public func presentPlaidLink() async throws {
        // Handled by the coordinator/view — link controller is prepared and ready
    }
    
    public func exchangePublicToken(_ publicToken: String) async throws {
        _ = try await plaidService.exchangePublicToken(publicToken)
    }
}
