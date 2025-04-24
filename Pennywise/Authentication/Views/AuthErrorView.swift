//
//  AuthErrorView.swift
//  Pennywise
//
//  Created by Arnav Varyani on 4/8/25.
//

import SwiftUI
import Firebase
import FirebaseAuth

struct AuthErrorView: View {
    let error: Error
    
    var errorMessage: String {
        if let authError = error as? NSError {
            // Map Firebase Auth error codes to user-friendly messages
            switch authError.code {
            case AuthErrorCode.invalidEmail.rawValue:
                return "The email address is badly formatted."
            case AuthErrorCode.wrongPassword.rawValue:
                return "The password is incorrect."
            case AuthErrorCode.userNotFound.rawValue:
                return "There is no user record corresponding to this email."
            case AuthErrorCode.emailAlreadyInUse.rawValue:
                return "The email address is already in use by another account."
            case AuthErrorCode.weakPassword.rawValue:
                return "The password must be at least 6 characters."
            case AuthErrorCode.networkError.rawValue:
                return "Network error. Please check your internet connection."
            case AuthErrorCode.tooManyRequests.rawValue:
                return "Too many unsuccessful login attempts. Please try again later."
            default:
                return "An error occurred: \(authError.localizedDescription)"
            }
        }
        
        return error.localizedDescription
    }
    
    var body: some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.red)
            
            Text(errorMessage)
                .font(.caption)
                .foregroundColor(.red)
        }
        .padding(.horizontal)
    }
}
