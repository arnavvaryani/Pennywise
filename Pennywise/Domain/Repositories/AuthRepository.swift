//
//  AuthRepository.swift
//  Pennywise
//
//  Repository Protocol - Domain Layer
//

import Foundation
import Combine

/// Repository protocol for authentication operations
@MainActor
public protocol AuthRepository {
    /// Current authentication state
    var isAuthenticated: Bool { get }
    
    /// Publisher for authentication state changes
    var isAuthenticatedPublisher: AnyPublisher<Bool, Never> { get }
    
    /// Current user
    var currentUser: User? { get }
    
    /// Sign in with email and password
    func signIn(email: String, password: String) async throws -> User
    
    /// Sign up with email and password
    func signUp(email: String, password: String) async throws -> User
    
    /// Sign in with Google
    func signInWithGoogle() async throws -> User
    
    /// Sign out
    func signOut() throws
    
    /// Change password
    func changePassword(currentPassword: String, newPassword: String) async throws
    
    /// Delete account. Password is required for email/password accounts.
    func deleteAccount(password: String?) async throws
    
    /// Authenticate with biometrics
    func authenticateWithBiometrics(reason: String) async throws -> Bool
    
    /// Check if biometrics is available
    func canUseBiometrics() -> Bool
    
    /// Get biometric type (FaceID/TouchID)
    func getBiometricType() -> BiometricType
    
    /// Send password reset email
    func sendPasswordReset(email: String) async throws
}

/// Biometric authentication type
public enum BiometricType {
    case none
    case touchID
    case faceID
    
    public var displayName: String {
        switch self {
        case .none: return "None"
        case .touchID: return "Touch ID"
        case .faceID: return "Face ID"
        }
    }
}

