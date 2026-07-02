//
//  BiometricAuthenticationView.swift
//  Pennywise
//
//  Created by Arnav Varyani on 4/10/25.
//


import SwiftUI
import LocalAuthentication

struct BiometricAuthenticationView: View {
    var viewModel: BiometricViewModel
    @Binding var isPresented: Bool
    var onSignOut: () -> Void
    @State private var showAlert = false
    @State private var authenticateOnAppear = true
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient
                LinearGradient(
                    gradient: Gradient(colors: [
                        AppTheme.backgroundPrimary,
                        AppTheme.primary.opacity(0.1),
                        AppTheme.backgroundPrimary
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .edgesIgnoringSafeArea(.all)
                
                // Content
                VStack(spacing: 30) {
                    // App logo
                    Image(systemName: "dollarsign.circle.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 80, height: 80)
                        .foregroundColor(AppTheme.primaryGreen)
                        .padding(.top, 60)
                    
                    // Lock icon - animated
                    Image(systemName: "lock.shield")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 80, height: 80)
                        .foregroundColor(AppTheme.primaryGreen)
                        .shadow(color: AppTheme.primaryGreen.opacity(0.5), radius: 10)
                        .scaleEffect(viewModel.isLoading ? 1.05 : 1.0)
                        .animation(Animation.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: viewModel.isLoading)
                    
                    Text("Biometric Authentication")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    // Biometric type message
                    if viewModel.isBiometricAvailable {
                        Text("Please use \(viewModel.biometricDisplayName) to verify your identity")
                            .font(.headline)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.white.opacity(0.8))
                            .padding(.horizontal, 30)
                    } else {
                        Text("Biometric authentication is not available on this device")
                            .font(.headline)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.white.opacity(0.8))
                            .padding(.horizontal, 30)
                    }
                    
                    // Authentication buttons
                    VStack(spacing: 15) {
                        // Biometric button - only show if biometrics are available
                        if viewModel.isBiometricAvailable {
                            Button(action: {
                                Task {
                                    let success = await viewModel.authenticate()
                                    if success {
                                        UserDefaults.standard.set(true, forKey: AppConstants.UserDefaults.hasPassedBiometricCheck)
                                        isPresented = false
                                    } else if !viewModel.errorMessage.isEmpty {
                                        showAlert = true
                                    }
                                }
                            }) {
                                HStack {
                                    Image(systemName: viewModel.biometricIcon)
                                        .font(.headline)
                                    Text("Authenticate with \(viewModel.biometricDisplayName)")
                                        .font(.headline)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(AppTheme.primaryGreen.opacity(0.8))
                                .foregroundColor(.white)
                                .cornerRadius(15)
                            }
                            .buttonStyle(ScaleButtonStyle())
                            .padding(.horizontal, 40)
                            .padding(.top, 20)
                            .disabled(viewModel.isLoading)
                            .opacity(viewModel.isLoading ? 0.7 : 1.0)
                        }
                        
                        // Sign out option
                        Button(action: {
                            onSignOut()
                        }) {
                            Text("Sign Out")
                                .foregroundColor(.white.opacity(0.7))
                                .padding(.vertical, 10)
                        }
                    }
                    .padding(.top, 10)
                    
                    Spacer()
                }
                .padding()
                
                // Loading overlay
                if viewModel.isLoading {
                    Color.black.opacity(0.4)
                        .edgesIgnoringSafeArea(.all)
                        .transition(.opacity)
                    
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(2)
                }
            }
            .onAppear {
                if authenticateOnAppear {
                    Task {
                        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
                        let success = await viewModel.authenticate()
                        if success {
                            UserDefaults.standard.set(true, forKey: AppConstants.UserDefaults.hasPassedBiometricCheck)
                            isPresented = false
                        } else if !viewModel.errorMessage.isEmpty {
                            showAlert = true
                        }
                    }
                    authenticateOnAppear = false
                }
            }
            .alert(isPresented: $showAlert) {
                Alert(
                    title: Text("Authentication Failed"),
                    message: Text(viewModel.errorMessage),
                    dismissButton: .default(Text("Try Again"), action: {
                        Task {
                            let success = await viewModel.authenticate()
                            if success {
                                UserDefaults.standard.set(true, forKey: AppConstants.UserDefaults.hasPassedBiometricCheck)
                                isPresented = false
                            } else if !viewModel.errorMessage.isEmpty {
                                showAlert = true
                            }
                        }
                    })
                )
            }
        }
    }
}
