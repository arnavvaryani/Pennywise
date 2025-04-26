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
            // Background gradient - using the same gradient as the rest of the app
            AppTheme.backgroundGradient
                .edgesIgnoringSafeArea(.all)
            
            // Content
            ScrollView {
                VStack(spacing: 25) {
                    // Logo with animation
                    logoSection
                    
                    // Login/Signup Toggle with app theme colors
                    segmentedPicker
                    
                    // Input Fields
                    inputFieldsSection
                    
                    // Login Button with app theme colors
                    loginButton
                    
                    // Social Login Options
                    socialLoginSection
                    
                    Spacer(minLength: 20)
                    
                    // Terms Text
                    termsSection
                }
                .padding(.vertical, 30)
                .padding(.horizontal)
            }
        }
        .alert(isPresented: $showingAlert) {
            Alert(
                title: Text("Notice"),
                message: Text(alertMessage),
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
    
    // MARK: - UI Components
    
    private var logoSection: some View {
        VStack(spacing: 15) {
            Image(systemName: "dollarsign.circle.fill")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 80, height: 80)
                .foregroundColor(AppTheme.primaryGreen)
                .scaleEffect(animationAmount)
                .opacity(2 - animationAmount)
            
            Text("Pennywise")
                .font(.system(size: 38, weight: .bold, design: .rounded))
                .foregroundColor(AppTheme.textColor)
            
            Text("Take Control of Your Money")
                .font(.subheadline)
                .foregroundColor(AppTheme.textColor.opacity(0.8))
        }
        .padding(.bottom, 20)
    }
    
    private var segmentedPicker: some View {
        Picker("Mode", selection: $isLoginMode) {
            Text("Login").tag(true)
            Text("Sign Up").tag(false)
        }
        .pickerStyle(SegmentedPickerStyle())
        .padding(.horizontal, 24)
        .onAppear {
            UISegmentedControl.appearance().selectedSegmentTintColor = UIColor(AppTheme.primaryGreen)
            UISegmentedControl.appearance().setTitleTextAttributes(
                [.foregroundColor: UIColor.white],
                for: .selected
            )
            UISegmentedControl.appearance().setTitleTextAttributes(
                [.foregroundColor: UIColor(AppTheme.textColor.opacity(0.7))],
                for: .normal
            )
        }
    }
    
    private var inputFieldsSection: some View {
        VStack(spacing: 20) {
            // Email field
            HStack {
                Image(systemName: "envelope.fill")
                    .foregroundColor(AppTheme.primaryGreen)
                    .frame(width: 24)
                
                TextField("", text: $email)
                    .placeholder(when: email.isEmpty) {
                        Text("Email").foregroundColor(AppTheme.textColor.opacity(0.7))
                    }
                    .foregroundColor(AppTheme.textColor)
                    .keyboardType(.emailAddress)
                    .disableAutocorrection(true)
                    .autocapitalization(.none)
            }
            .padding()
            .background(AppTheme.cardBackground)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(AppTheme.cardStroke, lineWidth: 1)
            )
            
            // Password field
            HStack {
                Image(systemName: "lock.fill")
                    .foregroundColor(AppTheme.primaryGreen)
                    .frame(width: 24)
                
                SecureField("", text: $password)
                    .placeholder(when: password.isEmpty) {
                        Text("Password").foregroundColor(AppTheme.textColor.opacity(0.7))
                    }
                    .foregroundColor(AppTheme.textColor)
            }
            .padding()
            .background(AppTheme.cardBackground)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(AppTheme.cardStroke, lineWidth: 1)
            )
            
            // Error message
            if let error = authService.authError {
                AuthErrorView(error: error)
            }
            
        }
        .padding(.horizontal, 16)
    }
    
    private var loginButton: some View {
        Button(action: handleEmailAuth) {
            HStack {
                if authService.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.0, anchor: .center)
                        .padding(.trailing, 5)
                }
                
                Text(isLoginMode ? "Login" : "Create Account")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
            }
            .background(AppTheme.primaryGreen)
            .cornerRadius(12)
            .shadow(color: AppTheme.primaryGreen.opacity(0.3), radius: 5, x: 0, y: 5)
        }
        .padding(.horizontal, 24)
        .padding(.top, 10)
        .disabled(authService.isLoading)
        .opacity(authService.isLoading ? 0.7 : 1.0)
        .buttonStyle(ScaleButtonStyle())
    }
    
    private var socialLoginSection: some View {
        VStack(spacing: 20) {
            Text("Or continue with")
                .font(.footnote)
                .foregroundColor(AppTheme.textColor.opacity(0.7))
            
            Button(action: handleGoogleSignIn) {
                HStack {
                    Image("google_logo") // You'll need to add this to your assets
                        .resizable()
                        .scaledToFit()
                        .frame(width: 20, height: 20)
                    
                    Text("Sign in with Google")
                        .font(.headline)
                        .foregroundColor(AppTheme.textColor)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(AppTheme.cardBackground)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(AppTheme.cardStroke, lineWidth: 1)
                )
            }
            .buttonStyle(ScaleButtonStyle())
            .padding(.horizontal, 24)
        }
        .padding(.top, 15)
    }
    
    private var termsSection: some View {
        HStack(spacing: 5) {
            Text("By continuing, you agree to our")
                .font(.caption2)
                .foregroundColor(AppTheme.textColor.opacity(0.7))
            
            Button(action: {
                // Show terms & conditions
            }) {
                Text("Terms & Privacy Policy")
                    .font(.caption2)
                    .foregroundColor(AppTheme.primaryGreen)
                    .underline()
            }
        }
        .padding(.bottom, 10)
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


