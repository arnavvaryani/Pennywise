//
//  AppConstants.swift
//  Pennywise
//
//  Centralized constants for the application
//

import Foundation

public struct AppConstants: Sendable {
    // MARK: - Firestore Collections
    public struct Firestore {
        public static let users = "users"
        public static let transactions = "transactions"
        public static let accounts = "accounts"
        public static let budgetCategories = "budgetCategories"
    }
    
    // MARK: - Plaid Configuration
    // Credentials and base URL are loaded from Secrets.swift (gitignored).
    // See Secrets.swift.example to configure a new environment.
    public struct Plaid {
        public static let clientID = Secrets.Plaid.clientID
        public static let secret = Secrets.Plaid.secret
        public static let baseURL = Secrets.Plaid.baseURL

        // Products and country codes
        public static let products = ["transactions"]
        public static let countryCodes = ["US"]
        public static let language = "en"
    }
    
    // MARK: - User Defaults Keys
    public struct UserDefaults {
        public static let hasCompletedOnboarding = "hasCompletedOnboarding"
        public static let hasLinkedPlaidAccount = "hasLinkedPlaidAccount"
        public static let hasPassedBiometricCheck = "hasPassedBiometricCheck"
        public static let biometricAuthEnabled = "biometricAuthEnabled"
        public static let plaidLinkToken = "plaid_link_token"
        public static let plaidAccessToken = "plaid_access_token"
    }
}
