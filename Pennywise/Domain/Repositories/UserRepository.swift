//
//  UserRepository.swift
//  Pennywise
//
//  Repository Protocol - Domain Layer
//

import Foundation

/// Repository protocol for user profile operations
@MainActor
public protocol UserRepository {
    /// Get current user profile
    func getUserProfile() async throws -> User
    
    /// Update user profile
    func updateUserProfile(
        displayName: String?,
        monthlyIncome: Double?,
        currency: String?,
        notificationsEnabled: Bool?
    ) async throws
    
    /// Get monthly income
    func getMonthlyIncome() async throws -> Double
    
    /// Save monthly income
    func saveMonthlyIncome(_ amount: Double) async throws
    
    /// Get user preferences
    func getUserPreferences() async throws -> UserPreferences
    
    /// Save user preferences
    func saveUserPreferences(_ preferences: UserPreferences) async throws
}

/// User preferences
public struct UserPreferences: Codable, Equatable {
    public let currency: String
    public let notificationsEnabled: Bool
    public let biometricAuthEnabled: Bool
    public let requireBiometricsOnOpen: Bool
    public let requireBiometricsForTransactions: Bool
    
    public init(
        currency: String = "USD",
        notificationsEnabled: Bool = true,
        biometricAuthEnabled: Bool = false,
        requireBiometricsOnOpen: Bool = false,
        requireBiometricsForTransactions: Bool = false
    ) {
        self.currency = currency
        self.notificationsEnabled = notificationsEnabled
        self.biometricAuthEnabled = biometricAuthEnabled
        self.requireBiometricsOnOpen = requireBiometricsOnOpen
        self.requireBiometricsForTransactions = requireBiometricsForTransactions
    }
}

