//
//  ChangePasswordView.swift
//  Pennywise
//
//  Created by Arnav Varyani on 4/8/25.
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
    
    // Keyboard visibility tracking
    @State private var keyboardHeight: CGFloat = 0
    @FocusState private var activeField: Field?
    
    // Form field identifiers
    enum Field {
        case currentPassword, newPassword, confirmPassword
    }
    
    // Simplified password validation states
    @State private var isPasswordLengthValid = false
    @State private var hasUppercase = false
    @State private var hasLowercase = false
    
    var body: some View {
        ZStack {
            // Background gradient
            AppTheme.backgroundGradient
                .edgesIgnoringSafeArea(.all)
            
            // Main content in a ScrollView with keyboard awareness
            ScrollViewReader { scrollProxy in
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
                        
                        // Simplified password requirements section
                        passwordRequirementsSection
                            .id("requirements")
                        
                        changePasswordButton
                            .id("changeButton")
                        
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
                        
                        // Extra padding at bottom to ensure content is scrollable above keyboard
                        Spacer()
                            .frame(height: keyboardHeight > 0 ? keyboardHeight + 20 : 100)
                    }
                    .padding()
                }
                .onChange(of: activeField) { field in
                    if let field = field {
                        // When field changes, scroll to keep active field visible
                        withAnimation {
                            if field == .confirmPassword {
                                scrollProxy.scrollTo("requirements", anchor: .top)
                            } else if field == .newPassword {
                                scrollProxy.scrollTo("newPassword", anchor: .top)
                            }
                        }
                    }
                }
            }
        }
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text(alertTitle),
                message: Text(alertMessage),
                dismissButton: .default(Text("OK")) {
                    // If success message is not empty, that means password change was successful
                    if !successMessage.isEmpty {
                        // Log the user out
                        authService.signOut()
                    }
                }
            )
        }
        .navigationTitle("Change Password")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: newPassword) { value in
            validatePassword(value)
        }
        // Keyboard appearance monitoring
        .onAppear {
            NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillShowNotification, object: nil, queue: .main) { notification in
                if let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
                    keyboardHeight = keyboardFrame.height
                }
            }
            
            NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillHideNotification, object: nil, queue: .main) { _ in
                keyboardHeight = 0
            }
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
                icon: "lock.fill",
                field: .currentPassword
            )
            .id("currentPassword")
            
            // New password field
            secureFieldWithIcon(
                title: "New Password",
                text: $newPassword,
                icon: "lock.shield",
                field: .newPassword
            )
            .id("newPassword")
            
            // Confirm new password field
            secureFieldWithIcon(
                title: "Confirm New Password",
                text: $confirmPassword,
                icon: "checkmark.shield",
                field: .confirmPassword
            )
            .id("confirmPassword")
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
    
    // Simplified password requirements section
    private var passwordRequirementsSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Password Requirements")
                .font(.headline)
                .foregroundColor(AppTheme.textColor)
            
            // Simplified password requirements
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
    
    private func secureFieldWithIcon(title: String, text: Binding<String>, icon: String, field: Field) -> some View {
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
                    .focused($activeField, equals: field)
                    .submitLabel(field == .confirmPassword ? .done : .next)
                    .onSubmit {
                        switch field {
                        case .currentPassword:
                            activeField = .newPassword
                        case .newPassword:
                            activeField = .confirmPassword
                        case .confirmPassword:
                            activeField = nil
                            if isPasswordValid() {
                                changePassword()
                            }
                        }
                    }
            }
            .padding()
            .background(AppTheme.cardBackground)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(activeField == field ? AppTheme.accentPurple : AppTheme.cardStroke, lineWidth: 1)
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
    
    // Simplified password validation
    private func validatePassword(_ password: String) {
        isPasswordLengthValid = password.count >= 8
        hasUppercase = password.range(of: "[A-Z]", options: .regularExpression) != nil
        hasLowercase = password.range(of: "[a-z]", options: .regularExpression) != nil
    }
    
    // Simplified password validation check
    private func isPasswordValid() -> Bool {
        return !currentPassword.isEmpty &&
               isPasswordLengthValid &&
               hasUppercase &&
               hasLowercase &&
               newPassword == confirmPassword
    }
    
    // MARK: - Password Change Function
    
    private func changePassword() {
        // Dismiss keyboard
        activeField = nil
        
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
        // This uses Firebase Auth to update the password in the backend
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
                    successMessage = "Your password has been updated successfully. You will be logged out."
                    
                    // Also show alert for additional confirmation
                    alertTitle = "Password Changed"
                    alertMessage = "Your password has been changed successfully. You will be logged out now for security purposes."
                    showAlert = true
                    
                case .failure(let error):
                    handleAuthError(error)
                }
            }
        }
    }
    
    private func handleAuthError(_ error: Error) {
        // Handle specific Firebase Auth errors
        let authError = error as NSError
        if authError.domain == AuthErrorDomain {
            switch authError.code {
            case AuthErrorCode.wrongPassword.rawValue:
                errorMessage = "Current password is incorrect."
            case AuthErrorCode.tooManyRequests.rawValue:
                errorMessage = "Too many attempts. Please try again later."
            case AuthErrorCode.networkError.rawValue:
                errorMessage = "Network error. Please check your connection."
            case AuthErrorCode.weakPassword.rawValue:
                errorMessage = "The password is too weak."
            case AuthErrorCode.requiresRecentLogin.rawValue:
                errorMessage = "This operation requires recent authentication. Please log in again."
            default:
                errorMessage = "Authentication error: \(error.localizedDescription)"
            }
        } else {
            errorMessage = "Error: \(error.localizedDescription)"
        }
    }
}
