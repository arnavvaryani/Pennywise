//
//  EditProfileView.swift
//  Pennywise
//
//  Created by Arnav Varyani on 4/24/25.
//

import SwiftUI

struct EditProfileView: View {
    @Binding var isPresented: Bool
    @StateObject private var authService = AuthenticationService.shared
    
    @State private var displayName = ""
    @State private var email = ""
    @State private var isLoading = false
    @State private var showSuccessAlert = false
    @State private var errorMessage = ""
    @State private var showError = false
    
    var body: some View {
        NavigationView {
            ZStack {
                AppTheme.backgroundGradient.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Profile image
                        ZStack {
                            Circle()
                                .fill(AppTheme.accentPurple.opacity(0.3))
                                .frame(width: 120, height: 120)
                            
                            Image(systemName: "person.fill")
                                .font(.system(size: 60))
                                .foregroundColor(AppTheme.textColor)
                                
                            // Edit button overlay
                            Circle()
                                .fill(AppTheme.primaryGreen)
                                .frame(width: 36, height: 36)
                                .overlay(
                                    Image(systemName: "camera.fill")
                                        .font(.system(size: 16))
                                        .foregroundColor(.white)
                                )
                                .offset(x: 42, y: 42)
                        }
                        .padding(.top, 20)
                        
                        // Display name field
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Display Name")
                                .font(.headline)
                                .foregroundColor(AppTheme.textColor)
                            
                            TextField("", text: $displayName)
                                .foregroundColor(AppTheme.textColor)
                                .padding()
                                .background(AppTheme.cardBackground)
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(AppTheme.cardStroke, lineWidth: 1)
                                )
                        }
                        
                        // Email field (read-only)
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Email Address")
                                .font(.headline)
                                .foregroundColor(AppTheme.textColor)
                            
                            TextField("", text: $email)
                                .foregroundColor(AppTheme.textColor.opacity(0.7))
                                .disabled(true)
                                .padding()
                                .background(AppTheme.cardBackground.opacity(0.7))
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(AppTheme.cardStroke, lineWidth: 1)
                                )
                            
                            Text("Email cannot be changed")
                                .font(.caption)
                                .foregroundColor(AppTheme.textColor.opacity(0.6))
                        }
                        
                        // Save button
                        Button(action: {
                            updateProfile()
                        }) {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Text("Save Changes")
                                    .font(.headline)
                                    .foregroundColor(.white)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(displayName.isEmpty ? AppTheme.primaryGreen.opacity(0.5) : AppTheme.primaryGreen)
                        .cornerRadius(12)
                        .disabled(displayName.isEmpty || isLoading)
                        .padding(.top, 20)
                        
                        if !errorMessage.isEmpty {
                            HStack {
                                Image(systemName: "exclamationmark.triangle")
                                    .foregroundColor(AppTheme.expenseColor)
                                
                                Text(errorMessage)
                                    .font(.caption)
                                    .foregroundColor(AppTheme.expenseColor)
                            }
                            .padding()
                            .background(AppTheme.expenseColor.opacity(0.1))
                            .cornerRadius(8)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        isPresented = false
                    }
                    .foregroundColor(AppTheme.primaryGreen)
                }
            }
            .onAppear {
                loadUserData()
            }
            .alert(isPresented: $showSuccessAlert) {
                Alert(
                    title: Text("Profile Updated"),
                    message: Text("Your profile has been updated successfully."),
                    dismissButton: .default(Text("OK")) {
                        isPresented = false
                    }
                )
            }
        }
    }
    
    private func loadUserData() {
        if let user = authService.user {
            displayName = user.displayName ?? ""
            email = user.email ?? ""
        }
    }
    
    private func updateProfile() {
        guard let user = authService.user else {
            errorMessage = "User not found"
            showError = true
            return
        }
        
        isLoading = true
        
        let changeRequest = user.createProfileChangeRequest()
        changeRequest.displayName = displayName
        
        changeRequest.commitChanges { error in
            DispatchQueue.main.async {
                isLoading = false
                
                if let error = error {
                    errorMessage = "Error updating profile: \(error.localizedDescription)"
                    showError = true
                } else {
                    showSuccessAlert = true
                }
            }
        }
    }
}
