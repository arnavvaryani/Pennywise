//
//  User.swift
//  Pennywise
//
//  Domain Entity - Pure Swift, no framework dependencies
//

import Foundation

/// Domain entity representing a user
public struct User: Identifiable, Equatable, Codable, Sendable {
    public let id: String
    public let email: String
    public let displayName: String?
    public let photoURL: String?
    public let monthlyIncome: Double
    public let currency: String
    public let notificationsEnabled: Bool
    public let biometricAuthEnabled: Bool
    
    public init(
        id: String,
        email: String,
        displayName: String? = nil,
        photoURL: String? = nil,
        monthlyIncome: Double = 0,
        currency: String = "USD",
        notificationsEnabled: Bool = true,
        biometricAuthEnabled: Bool = false
    ) {
        self.id = id
        self.email = email
        self.displayName = displayName
        self.photoURL = photoURL
        self.monthlyIncome = monthlyIncome
        self.currency = currency
        self.notificationsEnabled = notificationsEnabled
        self.biometricAuthEnabled = biometricAuthEnabled
    }
}

// MARK: - Business Logic

extension User {
    /// User's display name or email
    public var displayNameOrEmail: String {
        displayName ?? email
    }
    
    /// First name from display name
    public var firstName: String {
        displayName?.components(separatedBy: " ").first ?? "User"
    }
    
    /// Has completed profile
    public var hasCompletedProfile: Bool {
        monthlyIncome > 0 && displayName != nil
    }
}

