//
//  FinanceLoginView 2.swift
//  Pennywise
//
//  Created by Arnav Varyani on 4/11/25.
//

import SwiftUI

struct FinanceLoginView: View {
    @Bindable var viewModel: LoginViewModel
    
    @State private var showingAlert = false
    @State private var animationAmount: CGFloat = 1.0
    @FocusState private var focusedField: FocusField?
    
    private enum FocusField {
        case email
        case password
    }
    
    var body: some View {
        ZStack {
            AppTheme.enhancedBackgroundGradient
            
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
                message: Text(viewModel.errorMessage),
                dismissButton: .default(Text("OK")) {
                    viewModel.errorMessage = ""
                }
            )
        }
        .onChange(of: viewModel.errorMessage) { newValue in
            if !newValue.isEmpty {
                showingAlert = true
            }
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
        PWGlassCard {
            Picker("Mode", selection: $viewModel.isLoginMode) {
                Text("Login").tag(true)
                Text("Sign Up").tag(false)
            }
            .pickerStyle(.segmented)
        }
        .padding(.horizontal, 24)
    }
    
    private var inputFieldsSection: some View {
        VStack(spacing: 12) {
            PWGlassCard {
                VStack(spacing: 12) {
                    PWTextFieldRow(
                        placeholder: "Email",
                        text: $viewModel.email,
                        icon: "envelope.fill",
                        keyboardType: .emailAddress,
                        textContentType: .username
                    )
                    .focused($focusedField, equals: .email)
                    .submitLabel(.next)
                    .onSubmit { focusedField = .password }
                    
                    PWSecureFieldRow(
                        placeholder: "Password",
                        text: $viewModel.password,
                        icon: "lock.fill",
                        textContentType: viewModel.isLoginMode ? .password : .newPassword
                    )
                    .focused($focusedField, equals: .password)
                    .submitLabel(.go)
                    .onSubmit {
                        Task {
                            if viewModel.isLoginMode {
                                await viewModel.signIn()
                            } else {
                                await viewModel.signUp()
                            }
                        }
                    }
                    
                    if !viewModel.isLoginMode {
                        Text("At least 8 characters with uppercase, lowercase, and a number")
                            .font(.caption2)
                            .foregroundColor(AppTheme.textColor.opacity(0.6))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.top, 2)
                    }
                    
                    if viewModel.isLoginMode {
                        Button("Forgot password?") {
                            Task { await viewModel.sendPasswordReset() }
                        }
                        .font(.caption)
                        .foregroundColor(AppTheme.primaryGreen)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        .padding(.top, 2)
                    }
                }
            }
            
            if !viewModel.errorMessage.isEmpty {
                Text(viewModel.errorMessage)
                    .font(.caption)
                    .foregroundColor(AppTheme.expenseColor)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 6)
            }
        }
        .padding(.horizontal, 16)
    }
    
    private var loginButton: some View {
        PWPrimaryButton(
            title: viewModel.isLoginMode ? "Login" : "Create Account",
            isLoading: viewModel.isLoading,
            isDisabled: viewModel.email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                viewModel.password.isEmpty
        ) {
            Task {
                if viewModel.isLoginMode {
                    await viewModel.signIn()
                } else {
                    await viewModel.signUp()
                }
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 8)
    }
    
    private var socialLoginSection: some View {
        VStack(spacing: 20) {
            Text("Or continue with")
                .font(.footnote)
                .foregroundColor(AppTheme.textColor.opacity(0.7))
            
            Button(action: {
                Task {
                    _ = await viewModel.signInWithGoogle()
                }
            }) {
                PWGlassCard {
                    HStack(spacing: 12) {
                        Image("google_logo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 20, height: 20)
                        
                        Text("Sign in with Google")
                            .font(.headline)
                            .foregroundColor(AppTheme.textColor)
                        
                        Spacer()
                    }
                }
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
    
    private func forgotPassword() {
        Task {
            await viewModel.sendPasswordReset()
            if !viewModel.errorMessage.isEmpty {
                showingAlert = true
            }
        }
    }
}


