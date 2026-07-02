//
//  ManualAuthenticationForm.swift
//  Pennywise
//
//  Created by Arnav Varyani on 4/24/25.
//

import SwiftUI

struct ManualAuthenticationForm: View {
    @Bindable var viewModel: LoginViewModel
    var onSuccess: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            // Email field
            VStack(alignment: .leading, spacing: 8) {
                Text("Email")
                    .font(.subheadline)
                    .foregroundColor(AppTheme.textColor.opacity(0.8))
                
                TextField("", text: $viewModel.email)
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
                
                SecureField("", text: $viewModel.password)
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
            if !viewModel.errorMessage.isEmpty {
                Text(viewModel.errorMessage)
                    .font(.caption)
                    .foregroundColor(AppTheme.expenseColor)
                    .padding(.top, 5)
            }
            
            // Sign in button
            Button(action: {
                Task {
                    await viewModel.signIn()
                    if viewModel.isAuthenticated {
                        onSuccess()
                    }
                }
            }) {
                HStack {
                    if viewModel.isLoading {
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
                .opacity(viewModel.isLoading ? 0.7 : 1.0)
            }
            .disabled(viewModel.email.isEmpty || viewModel.password.isEmpty || viewModel.isLoading)
            .padding(.top, 10)
        }
        .padding()
    }
}
