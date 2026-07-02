//
//  LoginUseCase.swift
//  Pennywise
//
//  Use Case - Domain Layer
//

import Foundation

/// Use case for user login
@MainActor
public final class LoginUseCase {
    private let authRepository: AuthRepository
    
    public init(authRepository: AuthRepository) {
        self.authRepository = authRepository
    }
    
    public func execute(email: String, password: String) async throws -> User {
        // Business validation
        guard !email.trimmingCharacters(in: .whitespaces).isEmpty else {
            throw AuthError.invalidEmail
        }
        
        guard !password.isEmpty else {
            throw AuthError.invalidPassword
        }
        
        // Delegate to repository
        return try await authRepository.signIn(email: email, password: password)
    }
}

/// Authentication errors
public enum AuthError: LocalizedError {
    case invalidEmail
    case invalidPassword
    case userNotFound
    case wrongPassword
    case accountDisabled
    case unknown
    
    public var errorDescription: String? {
        switch self {
        case .invalidEmail:
            return "Please enter a valid email address"
        case .invalidPassword:
            return "Password must be at least 8 characters with an uppercase letter, a lowercase letter, and a number"
        case .userNotFound:
            return "No account found with this email"
        case .wrongPassword:
            return "Incorrect password"
        case .accountDisabled:
            return "This account has been disabled"
        case .unknown:
            return "An unknown error occurred"
        }
    }
}

