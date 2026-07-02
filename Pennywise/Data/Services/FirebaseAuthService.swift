//
//  FirebaseAuthService.swift
//  Pennywise
//
//  Service for Firebase Authentication operations
//

import Foundation
import FirebaseAuth
import GoogleSignIn
import Firebase
import LocalAuthentication
import Combine

/// Service for Firebase Authentication
@MainActor
public final class FirebaseAuthService {
    private var authStateListener: AuthStateDidChangeListenerHandle?
    private let isAuthenticatedSubject = CurrentValueSubject<Bool, Never>(false)
    
    public var isAuthenticatedPublisher: AnyPublisher<Bool, Never> {
        isAuthenticatedSubject.eraseToAnyPublisher()
    }
    
    public var currentFirebaseUser: FirebaseAuth.User? {
        Auth.auth().currentUser
    }
    
    public init() {
        setupAuthStateListener()
    }
    
    // Isolated deinit so it can access the @MainActor-isolated, non-Sendable
    // listener handle to deregister it.
    isolated deinit {
        if let listener = authStateListener {
            Auth.auth().removeStateDidChangeListener(listener)
        }
    }
    
    private func setupAuthStateListener() {
        authStateListener = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            self?.isAuthenticatedSubject.send(user != nil)
        }
    }
    
    // MARK: - Authentication Methods
    
    public func signIn(email: String, password: String) async throws -> FirebaseAuth.User {
        let result = try await Auth.auth().signIn(withEmail: email, password: password)
        return result.user
    }
    
    public func signUp(email: String, password: String) async throws -> FirebaseAuth.User {
        let result = try await Auth.auth().createUser(withEmail: email, password: password)
        return result.user
    }
    
    public func signInWithGoogle() async throws -> FirebaseAuth.User {
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            throw NSError(domain: "FirebaseAuthService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Google Sign In configuration error"])
        }
        
        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config
        
        // Get top view controller
        guard let windowScene = await UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = await windowScene.windows.first?.rootViewController else {
            throw NSError(domain: "FirebaseAuthService", code: -1, userInfo: [NSLocalizedDescriptionKey: "No root view controller"])
        }
        
        let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController)
        
        guard let idToken = result.user.idToken?.tokenString else {
            throw NSError(domain: "FirebaseAuthService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to get ID token"])
        }
        
        let credential = GoogleAuthProvider.credential(
            withIDToken: idToken,
            accessToken: result.user.accessToken.tokenString
        )
        
        let authResult = try await Auth.auth().signIn(with: credential)
        return authResult.user
    }
    
    public func signOut() throws {
        try Auth.auth().signOut()
    }
    
    public func changePassword(currentPassword: String, newPassword: String) async throws {
        guard let user = Auth.auth().currentUser, let email = user.email else {
            throw NSError(domain: "FirebaseAuthService", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not signed in"])
        }
        
        let credential = EmailAuthProvider.credential(withEmail: email, password: currentPassword)
        try await user.reauthenticate(with: credential)
        try await user.updatePassword(to: newPassword)
    }
    
    public func sendPasswordReset(email: String) async throws {
        try await Auth.auth().sendPasswordReset(withEmail: email)
    }
    
    public func deleteAccount(password: String) async throws {
        guard let user = Auth.auth().currentUser, let email = user.email else {
            throw NSError(domain: "FirebaseAuthService", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not signed in"])
        }
        
        let credential = EmailAuthProvider.credential(withEmail: email, password: password)
        try await user.reauthenticate(with: credential)
        try await user.delete()
    }
    
    public func deleteAccountWithoutPassword() async throws {
        guard let user = Auth.auth().currentUser else {
            throw NSError(domain: "FirebaseAuthService", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not signed in"])
        }
        try await user.delete()
    }
    
    // MARK: - Biometric Authentication
    
    public func authenticateWithBiometrics(reason: String) async throws -> Bool {
        let context = LAContext()
        var error: NSError?
        
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            throw error ?? NSError(domain: "FirebaseAuthService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Biometric not available"])
        }
        
        return try await context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason)
    }
    
    public func canUseBiometrics() -> Bool {
        let context = LAContext()
        var error: NSError?
        return context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
    }
    
    public func getBiometricType() -> LABiometryType {
        let context = LAContext()
        _ = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
        return context.biometryType
    }
}

