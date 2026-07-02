//
//  AuthRepositoryImpl.swift
//  Pennywise
//
//  Repository Implementation - Data Layer
//

import Foundation
import Combine
import LocalAuthentication

/// Implementation of AuthRepository
@MainActor
public final class AuthRepositoryImpl: AuthRepository {
    private let authService: FirebaseAuthService
    private let firestoreService: FirestoreService
    private let plaidService: PlaidAPIService
    
    public var isAuthenticated: Bool {
        authService.currentFirebaseUser != nil
    }
    
    public var isAuthenticatedPublisher: AnyPublisher<Bool, Never> {
        authService.isAuthenticatedPublisher
    }
    
    public var currentUser: User? {
        guard let firebaseUser = authService.currentFirebaseUser else { return nil }
        
        return User(
            id: firebaseUser.uid,
            email: firebaseUser.email ?? "",
            displayName: firebaseUser.displayName,
            photoURL: firebaseUser.photoURL?.absoluteString,
            monthlyIncome: 0,
            currency: "USD",
            notificationsEnabled: true,
            biometricAuthEnabled: false
        )
    }
    
    public init(authService: FirebaseAuthService, firestoreService: FirestoreService, plaidService: PlaidAPIService) {
        self.authService = authService
        self.firestoreService = firestoreService
        self.plaidService = plaidService
    }
    
    public func signIn(email: String, password: String) async throws -> User {
        let firebaseUser = try await authService.signIn(email: email, password: password)
        
        // Fetch user profile from Firestore
        if let user = try await firestoreService.fetchUserProfile() {
            return user
        }
        
        // Return basic user info if profile doesn't exist
        return User(
            id: firebaseUser.uid,
            email: firebaseUser.email ?? "",
            displayName: firebaseUser.displayName,
            photoURL: firebaseUser.photoURL?.absoluteString
        )
    }
    
    public func signUp(email: String, password: String) async throws -> User {
        let firebaseUser = try await authService.signUp(email: email, password: password)
        
        // Create user profile in Firestore
        let user = User(
            id: firebaseUser.uid,
            email: firebaseUser.email ?? "",
            displayName: firebaseUser.displayName
        )
        
        try await firestoreService.saveUserProfile(user)
        
        return user
    }
    
    public func signInWithGoogle() async throws -> User {
        let firebaseUser = try await authService.signInWithGoogle()
        
        // Check if user profile exists
        if let user = try await firestoreService.fetchUserProfile() {
            return user
        }
        
        // Create profile for new user
        let user = User(
            id: firebaseUser.uid,
            email: firebaseUser.email ?? "",
            displayName: firebaseUser.displayName,
            photoURL: firebaseUser.photoURL?.absoluteString
        )
        
        try await firestoreService.saveUserProfile(user)
        
        return user
    }
    
    public func signOut() throws {
        try authService.signOut()
        
        // Clear local-only session flags
        UserDefaults.standard.set(false, forKey: AppConstants.UserDefaults.hasPassedBiometricCheck)
        CategoryMappingService.clearAllOverrides()
        plaidService.clearAccessToken()
    }
    
    public func changePassword(currentPassword: String, newPassword: String) async throws {
        try await authService.changePassword(currentPassword: currentPassword, newPassword: newPassword)
    }
    
    public func deleteAccount(password: String?) async throws {
        guard let userId = authService.currentFirebaseUser?.uid else {
            throw NSError(domain: "AuthRepository", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not signed in"])
        }
        
        // Delete Firestore data first (requires auth)
        try await firestoreService.deleteAllUserData(userId: userId)
        
        // Unlink Plaid + clear local state (best-effort)
        do { try await plaidService.disconnect() } catch { print("Plaid disconnect failed: \(error)") }
        CategoryMappingService.clearAllOverrides()
        UserDefaults.standard.set(false, forKey: AppConstants.UserDefaults.hasPassedBiometricCheck)
        
        // Delete Firebase user (may require reauth depending on provider)
        if let password, !password.isEmpty {
            try await authService.deleteAccount(password: password)
        } else {
            try await authService.deleteAccountWithoutPassword()
        }
    }
    
    public func authenticateWithBiometrics(reason: String) async throws -> Bool {
        return try await authService.authenticateWithBiometrics(reason: reason)
    }
    
    public func canUseBiometrics() -> Bool {
        return authService.canUseBiometrics()
    }
    
    public func getBiometricType() -> BiometricType {
        let type = authService.getBiometricType()
        switch type {
        case .faceID:
            return .faceID
        case .touchID:
            return .touchID
        default:
            return .none
        }
    }
    
    public func sendPasswordReset(email: String) async throws {
        try await authService.sendPasswordReset(email: email)
    }
}

