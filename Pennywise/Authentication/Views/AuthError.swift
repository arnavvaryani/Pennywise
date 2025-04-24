//
//  AuthError.swift
//  Pennywise
//
//  Created by Arnav Varyani on 4/24/25.
//

import SwiftUI

enum AuthError: LocalizedError {
    case signInFailed(String)
    case signUpFailed(String)
    case biometricAuthFailed(String)
    case biometricNotAvailable
    case userNotFound
    case networkError
    
    var errorDescription: String? {
        switch self {
        case .signInFailed(let message):
            return "Sign in failed: \(message)"
        case .signUpFailed(let message):
            return "Sign up failed: \(message)"
        case .biometricAuthFailed(let message):
            return "Biometric authentication failed: \(message)"
        case .biometricNotAvailable:
            return "Biometric authentication is not available on this device"
        case .userNotFound:
            return "No user record found. Please sign in again."
        case .networkError:
            return "Network error. Please check your connection and try again."
        }
    }
}
