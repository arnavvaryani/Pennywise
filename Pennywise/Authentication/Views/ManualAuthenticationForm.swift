//
//  ManualAuthenticationForm.swift
//  Pennywise
//
//  Created by Arnav Varyani on 4/24/25.
//

import SwiftUI

struct ManualAuthenticationForm: View {
    @StateObject private var authService = AuthenticationService.shared
    @State private var email = ""
    @State private var password = ""
    @State private var errorMessage = ""
    @State private var isLoading = false
    var onSuccess: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            // Email field
            VStack(alignment: .leading, spacing: 8) {
                Text("Email")
                    .font(.subheadline)
                    .foregroundColor(AppTheme.textColor.opacity(0.8))
                
                TextField("", text: $email)
                    .padding()
                    .background(AppTheme.cardBackground)
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(AppTheme.cardStroke, lineWidth: 1)
                    )
                    .foregroundColor(AppTheme.textColor)
                    .autocapitalization(.none)
                    .keyboardType(.emailAddress)
            }
            
            // Password field
            VStack(alignment: .leading, spacing: 8) {
                Text("Password")
                    .font(.subheadline)
                    .foregroundColor(AppTheme.textColor.opacity(0.8))
                
                SecureField("", text: $password)
                    .padding()
                    .background(AppTheme.cardBackground)
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(AppTheme.cardStroke, lineWidth: 1)
                    )
                    .foregroundColor(AppTheme.textColor)
            }
            
            // Error message if any
            if !errorMessage.isEmpty {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundColor(AppTheme.expenseColor)
                    .padding(.top, 5)
            }
            
            // Sign in button
            Button(action: {
                attemptSignIn()
            }) {
                HStack {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .padding(.trailing, 5)
                    }
                    
                    Text("Sign In")
                        .font(.headline)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(AppTheme.primaryGreen)
                .foregroundColor(.white)
                .cornerRadius(10)
                .opacity(isLoading ? 0.7 : 1.0)
            }
            .disabled(email.isEmpty || password.isEmpty || isLoading)
            .padding(.top, 10)
        }
        .padding()
    }
    
    private func attemptSignIn() {
        isLoading = true
        errorMessage = ""
        
        authService.signInWithEmail(email: email, password: password) { result in
            DispatchQueue.main.async {
                isLoading = false
                
                switch result {
                case .success:
                    onSuccess()
                case .failure(let error):
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
}
