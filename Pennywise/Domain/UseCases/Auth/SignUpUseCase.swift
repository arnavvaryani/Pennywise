//
//  SignUpUseCase.swift
//  Pennywise
//
//  Use Case - Domain Layer
//

import Foundation

/// Use case for user sign up
@MainActor
public final class SignUpUseCase {
    private let authRepository: AuthRepository
    
    public init(authRepository: AuthRepository) {
        self.authRepository = authRepository
    }
    
    public func execute(email: String, password: String) async throws -> User {
        // Business validation
        guard isValidEmail(email) else {
            throw AuthError.invalidEmail
        }
        
        guard isValidPassword(password) else {
            throw AuthError.invalidPassword
        }
        
        // Delegate to repository
        return try await authRepository.signUp(email: email, password: password)
    }
    
    // MARK: - Validation Logic
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPred = NSPredicate(format: "SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: email)
    }
    
    private func isValidPassword(_ password: String) -> Bool {
        // At least 8 characters, 1 uppercase, 1 lowercase, 1 digit
        guard password.count >= 8 else { return false }
        
        let hasUppercase = password.range(of: "[A-Z]", options: .regularExpression) != nil
        let hasLowercase = password.range(of: "[a-z]", options: .regularExpression) != nil
        let hasDigit = password.range(of: "[0-9]", options: .regularExpression) != nil
        
        return hasUppercase && hasLowercase && hasDigit
    }
}

