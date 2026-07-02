//
//  UserRepositoryImpl.swift
//  Pennywise
//
//  Repository Implementation - Data Layer
//

import Foundation

/// Implementation of UserRepository
@MainActor
public final class UserRepositoryImpl: UserRepository {
    private let firestoreService: FirestoreService
    
    public init(firestoreService: FirestoreService) {
        self.firestoreService = firestoreService
    }
    
    public func getUserProfile() async throws -> User {
        guard let user = try await firestoreService.fetchUserProfile() else {
            throw NSError(domain: "UserRepository", code: -1, userInfo: [NSLocalizedDescriptionKey: "User profile not found"])
        }
        // Keep the app-wide currency in sync with the user's preference so all
        // CurrencyFormatter.format(_:) calls render in the right currency.
        CurrencyFormatter.currentCurrencyCode = user.currency
        return user
    }
    
    public func updateUserProfile(
        displayName: String?,
        monthlyIncome: Double?,
        currency: String?,
        notificationsEnabled: Bool?
    ) async throws {
        // Fetch current profile
        guard var user = try await firestoreService.fetchUserProfile() else {
            throw NSError(domain: "UserRepository", code: -1, userInfo: [NSLocalizedDescriptionKey: "User profile not found"])
        }
        
        // Update fields independently (do not gate on displayName presence)
        user = User(
            id: user.id,
            email: user.email,
            displayName: displayName ?? user.displayName,
            photoURL: user.photoURL,
            monthlyIncome: monthlyIncome ?? user.monthlyIncome,
            currency: currency ?? user.currency,
            notificationsEnabled: notificationsEnabled ?? user.notificationsEnabled,
            biometricAuthEnabled: user.biometricAuthEnabled
        )
        
        // Save updated profile
        try await firestoreService.saveUserProfile(user)

        // Reflect a currency change app-wide immediately.
        if currency != nil {
            CurrencyFormatter.currentCurrencyCode = user.currency
        }
    }
    
    public func getMonthlyIncome() async throws -> Double {
        return try await firestoreService.getMonthlyIncome()
    }
    
    public func saveMonthlyIncome(_ amount: Double) async throws {
        try await firestoreService.saveMonthlyIncome(amount)
    }
    
    public func getUserPreferences() async throws -> UserPreferences {
        guard let user = try await firestoreService.fetchUserProfile() else {
            return UserPreferences()
        }
        
        return UserPreferences(
            currency: user.currency,
            notificationsEnabled: user.notificationsEnabled,
            biometricAuthEnabled: user.biometricAuthEnabled,
            requireBiometricsOnOpen: false,
            requireBiometricsForTransactions: false
        )
    }
    
    public func saveUserPreferences(_ preferences: UserPreferences) async throws {
        guard var user = try await firestoreService.fetchUserProfile() else {
            throw NSError(domain: "UserRepository", code: -1, userInfo: [NSLocalizedDescriptionKey: "User profile not found"])
        }
        
        user = User(
            id: user.id,
            email: user.email,
            displayName: user.displayName,
            photoURL: user.photoURL,
            monthlyIncome: user.monthlyIncome,
            currency: preferences.currency,
            notificationsEnabled: preferences.notificationsEnabled,
            biometricAuthEnabled: preferences.biometricAuthEnabled
        )
        
        try await firestoreService.saveUserProfile(user)
    }
}

