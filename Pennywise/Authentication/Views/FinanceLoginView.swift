//
//  FinanceLoginView 2.swift
//  Pennywise
//
//  Created by Arnav Varyani on 4/11/25.
//

import SwiftUI
import FirebaseAuth

struct FinanceLoginView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var isLoginMode = true
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var animationAmount: CGFloat = 1.0
    
    @StateObject private var authService = AuthenticationService.shared
    @State private var firebaseUIController = FirebaseUIViewRepresentable { _ in }
    
    var body: some View {
        ZStack {
            // Background
            FinanceBackgroundView()
                .ignoresSafeArea()
            
            // Content
            ScrollView {
                VStack(spacing: 25) {
                    // Logo
                    LogoView(animationAmount: $animationAmount)
                    
                    // Login/Signup Toggle
                    Picker("Mode", selection: $isLoginMode) {
                        Text("Login").tag(true)
                        Text("Sign Up").tag(false)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.horizontal, 24)
                    
                    // Input Fields
                    LoginFieldsView(
                        email: $email,
                        password: $password,
                        isLoginMode: $isLoginMode,
                        forgotPasswordAction: forgotPassword,
                        authError: authService.authError
                    )
                    
                    // Login Button
                    LoginButtonView(
                        isLoading: authService.isLoading,
                        isLoginMode: isLoginMode,
                        action: handleEmailAuth
                    )
                    
                    // Social Login Options
                    SocialLoginView(
                        googleAction: handleGoogleSignIn,
                    )
                    
                    Spacer(minLength: 20)
                    
                    // Terms Text
                    HStack(spacing: 5) {
                        Text("By continuing, you agree to our")
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.7))
                        
                        Button(action: {
                            // Show terms & conditions
                        }) {
                            Text("Terms & Privacy Policy")
                                .font(.caption2)
                                .foregroundColor(.white)
                                .underline()
                        }
                    }
                    .padding(.bottom, 10)
                }
                .padding(.vertical, 30)
            }
        }
        .alert(isPresented: $showingAlert) {
            Alert(
                title: Text(alertMessage),
                dismissButton: .default(Text("OK"))
            )
        }
        .onAppear {
            // Start animation
            withAnimation(.linear(duration: 10).repeatForever(autoreverses: false)) {
                animationAmount = 1.2
            }
        }
    }
    
    // MARK: - Authentication Methods
    
    private func handleEmailAuth() {
        if isLoginMode {
            // Login
            authService.signInWithEmail(email: email, password: password) { result in
                switch result {
                case .success:
                    // Login successful, navigation will be handled by app state
                    break
                case .failure:
                    // Error already handled and displayed in AuthErrorView
                    break
                }
            }
        } else {
            // Sign up
            authService.signUpWithEmail(email: email, password: password) { result in
                switch result {
                case .success:
                    // Sign up successful, navigation will be handled by app state
                    break
                case .failure:
                    // Error already handled and displayed in AuthErrorView
                    break
                }
            }
        }
    }
    
    private func handleGoogleSignIn() {
        let completion: (Result<FirebaseAuth.User, Error>) -> Void = { result in
            switch result {
            case .success:
                // Google Sign In successful, navigation will be handled by app state
                break
            case .failure(let error):
                authService.authError = error
                break
            }
        }
        
        firebaseUIController = FirebaseUIViewRepresentable(signInCompletion: completion)
        firebaseUIController.signInWithGoogle()
    }
    
    private func forgotPassword() {
        if email.isEmpty {
            alertMessage = "Please enter your email address first"
            showingAlert = true
            return
        }
        
        Auth.auth().sendPasswordReset(withEmail: email) { error in
            if let error = error {
                alertMessage = "Error: \(error.localizedDescription)"
            } else {
                alertMessage = "Password reset email sent. Please check your inbox."
            }
            showingAlert = true
        }
    }
}
