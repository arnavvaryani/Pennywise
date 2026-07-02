//
//  LogoutUseCase.swift
//  Pennywise
//
//  Use Case - Domain Layer
//

import Foundation

/// Use case for user logout
@MainActor
public final class LogoutUseCase {
    private let authRepository: AuthRepository
    
    public init(authRepository: AuthRepository) {
        self.authRepository = authRepository
    }
    
    public func execute() throws {
        try authRepository.signOut()
    }
}

