//
//  ChangePasswordView.swift
//  Pennywise
//
//  Created by Arnav Varyani on 4/23/25.
//

import SwiftUI
import Firebase
import FirebaseAuth

struct ChangePasswordView: View {
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var authService = AuthenticationService.shared
    
    @State private var currentPassword = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var errorMessage = ""
    @State private var successMessage = ""
    @State private var isLoading = false
    @State private var showAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    
    // Password validation states
    @State private var isPasswordLengthValid = false
    @State private var hasUppercase = false
    @State private var hasLowercase = false
    @State private var hasDigit = false
    @State private var hasSpecialChar = false
    
    var body: some View {
        ZStack {
            // Background gradient
            AppTheme.backgroundGradient
                .edgesIgnoringSafeArea(.all)
            
            ScrollView {
                VStack(spacing: 25) {
                    headerSection
                    
                    passwordFormSection
                    
                    if !errorMessage.isEmpty {
                        errorSection
                    }
                    
                    if !successMessage.isEmpty {
                        successSection
                    }
                    
                    passwordRequirementsSection
                    
                    changePasswordButton
                    
                    // Back button for when completed successfully
                    if !successMessage.isEmpty {
                        Button(action: {
                            presentationMode.wrappedValue.dismiss()
                        }) {
                            Text("Back to Settings")
                                .font(.headline)
                                .foregroundColor(AppTheme.backgroundColor)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(AppTheme.accentBlue)
                                .cornerRadius(12)
                        }
                        .padding(.top, 10)
                    }
                }
                .padding()
            }
        }
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text(alertTitle),
                message: Text(alertMessage),
                dismissButton: .default(Text("OK"))
            )
        }
        .navigationTitle("Change Password")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: newPassword) { value in
            validatePassword(value)
        }
    }
    
    // MARK: - UI Components
    
    private var headerSection: some View {
        VStack(spacing: 15) {
            // Icon
            ZStack {
                Circle()
                    .fill(AppTheme.accentPurple.opacity(0.3))
                    .frame(width: 80, height: 80)
                
                Image(systemName: "lock.rotation")
                    .font(.system(size: 40))
                    .foregroundColor(AppTheme.accentPurple)
            }
            
            Text("Change Your Password")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(AppTheme.textColor)
            
            Text("Ensure your account stays secure by periodically updating your password.")
                .font(.subheadline)
                .foregroundColor(AppTheme.textColor.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
        }
    }
    
    private var passwordFormSection: some View {
        VStack(spacing: 20) {
            // Current password field
            secureFieldWithIcon(
                title: "Current Password",
                text: $currentPassword,
                icon: "lock.fill"
            )
            
            // New password field
            secureFieldWithIcon(
                title: "New Password",
                text: $newPassword,
                icon: "lock.shield"
            )
            
            // Confirm new password field
            secureFieldWithIcon(
                title: "Confirm New Password",
                text: $confirmPassword,
                icon: "checkmark.shield"
            )
        }
    }
    
    private var errorSection: some View {
        HStack {
            Image(systemName: "exclamationmark.triangle")
                .foregroundColor(AppTheme.expenseColor)
            
            Text(errorMessage)
                .font(.callout)
                .foregroundColor(AppTheme.expenseColor)
                .multilineTextAlignment(.leading)
            
            Spacer()
        }
        .padding()
        .background(AppTheme.expenseColor.opacity(0.15))
        .cornerRadius(12)
    }
    
    private var successSection: some View {
        HStack {
            Image(systemName: "checkmark.circle")
                .foregroundColor(AppTheme.primaryGreen)
            
            Text(successMessage)
                .font(.callout)
                .foregroundColor(AppTheme.primaryGreen)
                .multilineTextAlignment(.leading)
            
            Spacer()
        }
        .padding()
        .background(AppTheme.primaryGreen.opacity(0.15))
        .cornerRadius(12)
    }
    
    private var passwordRequirementsSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Password Requirements")
                .font(.headline)
                .foregroundColor(AppTheme.textColor)
            
            // Password requirements
            requirementRow(
                text: "At least 8 characters",
                isValid: isPasswordLengthValid
            )
            
            requirementRow(
                text: "Contains uppercase letter (A-Z)",
                isValid: hasUppercase
            )
            
            requirementRow(
                text: "Contains lowercase letter (a-z)",
                isValid: hasLowercase
            )
            
            requirementRow(
                text: "Contains a number (0-9)",
                isValid: hasDigit
            )
            
            requirementRow(
                text: "Contains a special character (!@#$%^&*)",
                isValid: hasSpecialChar
            )
        }
        .padding()
        .background(AppTheme.cardBackground)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(AppTheme.cardStroke, lineWidth: 1)
        )
    }
    
    private var changePasswordButton: some View {
        Button(action: {
            changePassword()
        }) {
            if isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
            } else {
                Text("Update Password")
                    .font(.headline)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(isPasswordValid() ? AppTheme.primaryGreen : AppTheme.primaryGreen.opacity(0.5))
        .foregroundColor(.white)
        .cornerRadius(12)
        .disabled(!isPasswordValid() || isLoading)
    }
    
    // MARK: - Helper Components
    
    private func secureFieldWithIcon(title: String, text: Binding<String>, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.headline)
                .foregroundColor(AppTheme.textColor)
            
            HStack {
                Image(systemName: icon)
                    .foregroundColor(AppTheme.accentPurple)
                    .frame(width: 20)
                
                SecureField("", text: text)
                    .font(.body)
                    .foregroundColor(AppTheme.textColor)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .textContentType(.password)
            }
            .padding()
            .background(AppTheme.cardBackground)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(AppTheme.cardStroke, lineWidth: 1)
            )
        }
    }
    
    private func requirementRow(text: String, isValid: Bool) -> some View {
        HStack {
            Image(systemName: isValid ? "checkmark.circle.fill" : "circle")
                .foregroundColor(isValid ? AppTheme.primaryGreen : AppTheme.textColor.opacity(0.5))
            
            Text(text)
                .font(.subheadline)
                .foregroundColor(isValid ? AppTheme.textColor : AppTheme.textColor.opacity(0.7))
            
            Spacer()
        }
    }
    
    // MARK: - Password Validation Functions
    
    private func validatePassword(_ password: String) {
        isPasswordLengthValid = password.count >= 8
        hasUppercase = password.range(of: "[A-Z]", options: .regularExpression) != nil
        hasLowercase = password.range(of: "[a-z]", options: .regularExpression) != nil
        hasDigit = password.range(of: "[0-9]", options: .regularExpression) != nil
        hasSpecialChar = password.range(of: "[!@#$%^&*(),.?\":{}|<>]", options: .regularExpression) != nil
    }
    
    private func isPasswordValid() -> Bool {
        return !currentPassword.isEmpty &&
               isPasswordLengthValid &&
               hasUppercase &&
               hasLowercase &&
               hasDigit &&
               hasSpecialChar &&
               newPassword == confirmPassword
    }
    
    // MARK: - Password Change Function
    
    private func changePassword() {
        // Reset messages
        errorMessage = ""
        successMessage = ""
        
        // Validate passwords match
        if newPassword != confirmPassword {
            errorMessage = "New password and confirmation do not match."
            return
        }
        
        // Start loading state
        isLoading = true
        
        // Use the AuthenticationService to change the password
        authService.changePassword(currentPassword: currentPassword, newPassword: newPassword) { result in
            DispatchQueue.main.async {
                isLoading = false
                
                switch result {
                case .success:
                    // Clear password fields
                    currentPassword = ""
                    newPassword = ""
                    confirmPassword = ""
                    
                    // Show success message
                    successMessage = "Your password has been updated successfully."
                    
                    // Also show alert for additional confirmation
                    alertTitle = "Password Changed"
                    alertMessage = "Your password has been changed successfully. Please use your new password for future logins."
                    showAlert = true
                    
                case .failure(let error):
                    handleAuthError(error)
                }
            }
        }
    }
    
    private func reauthenticateUser(completion: @escaping (Bool, Error?) -> Void) {
        guard let user = Auth.auth().currentUser, let email = user.email else {
            completion(false, nil)
            return
        }
        
        // Create credential
        let credential = EmailAuthProvider.credential(withEmail: email, password: currentPassword)
        
        // Reauthenticate user
        user.reauthenticate(with: credential) { _, error in
            if let error = error {
                completion(false, error)
            } else {
                completion(true, nil)
            }
        }
    }
    
    private func updateUserPassword() {
        guard let user = Auth.auth().currentUser else {
            isLoading = false
            errorMessage = "User not signed in."
            return
        }
        
        // Update password
        user.updatePassword(to: newPassword) { error in
            DispatchQueue.main.async {
                isLoading = false
                
                if let error = error {
                    handleAuthError(error)
                } else {
                    // Clear password fields
                    currentPassword = ""
                    newPassword = ""
                    confirmPassword = ""
                    
                    // Show success message
                    successMessage = "Your password has been updated successfully."
                    
                    // Also show alert for additional confirmation
                    alertTitle = "Password Changed"
                    alertMessage = "Your password has been changed successfully. Please use your new password for future logins."
                    showAlert = true
                }
            }
        }
    }
    
    private func handleAuthError(_ error: Error) {
        if let authError = error as NSError? {
            switch authError.code {
            case AuthErrorCode.wrongPassword.rawValue:
                errorMessage = "Current password is incorrect."
            case AuthErrorCode.requiresRecentLogin.rawValue:
                errorMessage = "This operation is sensitive and requires recent authentication. Please log in again before retrying."
            case AuthErrorCode.networkError.rawValue:
                errorMessage = "Network error. Please check your internet connection."
            default:
                errorMessage = "Error: \(authError.localizedDescription)"
            }
        } else {
            errorMessage = "An error occurred: \(error.localizedDescription)"
        }
    }
}

struct ChangePasswordView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            ChangePasswordView()
        }
        .preferredColorScheme(.dark)
    }
}
