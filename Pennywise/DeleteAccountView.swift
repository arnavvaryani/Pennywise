//
//  DeleteAccountView.swift
//  Pennywise
//
//  Created by Arnav Varyani on 4/25/25.
//


import SwiftUI
import Firebase
import FirebaseAuth

struct DeleteAccountView: View {
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var authService = AuthenticationService.shared
    
    @State private var currentPassword = ""
    @State private var confirmText = ""
    @State private var isLoading = false
    @State private var errorMessage = ""
    @State private var showSuccess = false
    
    var body: some View {
        ZStack {
            AppTheme.backgroundGradient.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Warning icon
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 70))
                        .foregroundColor(AppTheme.expenseColor)
                        .padding(.top, 30)
                    
                    Text("Delete Your Account")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(AppTheme.textColor)
                    
                    // Warning message
                    VStack(alignment: .leading, spacing: 15) {
                        Text("Warning")
                            .font(.headline)
                            .foregroundColor(AppTheme.expenseColor)
                        
                        Text("This action cannot be undone. All your data will be permanently deleted, including:")
                            .foregroundColor(AppTheme.textColor)
                            .fixedSize(horizontal: false, vertical: true)
                        
                        // List of what will be deleted
                        VStack(alignment: .leading, spacing: 8) {
                            bulletPoint("Your account information and profile")
                            bulletPoint("All transaction history")
                            bulletPoint("Budget configurations and categories")
                            bulletPoint("Financial insights and reports")
                            bulletPoint("Connected bank accounts data")
                        }
                        .padding(.leading, 10)
                    }
                    .padding()
                    .background(AppTheme.cardBackground)
                    .cornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(AppTheme.cardStroke, lineWidth: 1)
                    )
                    
                    // Current password
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Current Password")
                            .font(.headline)
                            .foregroundColor(AppTheme.textColor)
                        
                        SecureField("", text: $currentPassword)
                            .foregroundColor(AppTheme.textColor)
                            .padding()
                            .background(AppTheme.cardBackground)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(AppTheme.cardStroke, lineWidth: 1)
                            )
                    }
                    
                    // Confirmation field
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Type \"DELETE\" to confirm")
                            .font(.headline)
                            .foregroundColor(AppTheme.textColor)
                        
                        TextField("", text: $confirmText)
                            .foregroundColor(AppTheme.textColor)
                            .padding()
                            .background(AppTheme.cardBackground)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(AppTheme.cardStroke, lineWidth: 1)
                            )
                    }
                    
                    // Error message
                    if !errorMessage.isEmpty {
                        HStack {
                            Image(systemName: "exclamationmark.triangle")
                                .foregroundColor(AppTheme.expenseColor)
                            
                            Text(errorMessage)
                                .font(.caption)
                                .foregroundColor(AppTheme.expenseColor)
                                .multilineTextAlignment(.leading)
                        }
                        .padding()
                        .background(AppTheme.expenseColor.opacity(0.1))
                        .cornerRadius(8)
                    }
                    
                    // Delete button
                    Button(action: {
                        deleteAccount()
                    }) {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text("Permanently Delete Account")
                                .font(.headline)
                                .foregroundColor(.white)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(isDeleteButtonEnabled() ? AppTheme.expenseColor : AppTheme.expenseColor.opacity(0.5))
                    .cornerRadius(12)
                    .disabled(!isDeleteButtonEnabled() || isLoading)
                    .padding(.top, 10)
                    
                    // Cancel button
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Text("Cancel")
                            .font(.headline)
                            .foregroundColor(AppTheme.textColor)
                    }
                    .padding()
                }
                .padding()
            }
        }
        .navigationTitle("Delete Account")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(isLoading)
        .alert("Account Deleted", isPresented: $showSuccess) {
            Button("OK", role: .cancel) {
                // Navigate back to login
                presentationMode.wrappedValue.dismiss()
            }
        } message: {
            Text("Your account and all associated data have been permanently deleted.")
        }
    }
    
    private func bulletPoint(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Text("•")
                .foregroundColor(AppTheme.expenseColor)
            
            Text(text)
                .foregroundColor(AppTheme.textColor)
                .fixedSize(horizontal: false, vertical: true)
            
            Spacer()
        }
    }
    
    private func isDeleteButtonEnabled() -> Bool {
        return !currentPassword.isEmpty && confirmText == "DELETE"
    }
    
    private func deleteAccount() {
        isLoading = true
        errorMessage = ""
        
        AccountDeletionManager.shared.deleteUserAccount(currentPassword: currentPassword) { result in
            DispatchQueue.main.async {
                isLoading = false
                
                switch result {
                case .success:
                    // Account deleted successfully
                    showSuccess = true
                    
                case .failure(let error):
                    // Handle specific errors
                    let nsError = error as NSError
                    
                    if nsError.domain == AuthErrorDomain {
                        switch nsError.code {
                        case AuthErrorCode.wrongPassword.rawValue:
                            errorMessage = "Current password is incorrect."
                        case AuthErrorCode.requiresRecentLogin.rawValue:
                            errorMessage = "For security reasons, please log out and log back in before deleting your account."
                        case AuthErrorCode.networkError.rawValue:
                            errorMessage = "Network error. Please check your connection and try again."
                        default:
                            errorMessage = "Error: \(error.localizedDescription)"
                        }
                    } else {
                        errorMessage = "Error: \(error.localizedDescription)"
                    }
                }
            }
        }
    }
}

struct DeleteAccountView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            DeleteAccountView()
        }
        .preferredColorScheme(.dark)
    }
}