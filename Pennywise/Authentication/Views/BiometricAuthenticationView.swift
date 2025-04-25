//
//  BiometricAuthenticationView.swift
//  Pennywise
//
//  Created by Arnav Varyani on 4/10/25.
//


import SwiftUI
import LocalAuthentication

struct BiometricAuthenticationView: View {
    @StateObject private var authService = AuthenticationService.shared
    @Binding var isAuthenticated: Bool
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var isLoading = false
    @State private var authenticateOnAppear = true
    @State private var navigateToFinanceRoot = false
    
    var body: some View {
        NavigationView {
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
                        .scaleEffect(isLoading ? 1.05 : 1.0)
                        .animation(Animation.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: isLoading)
                    
                    Text("Biometric Authentication")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    // Biometric type message
                    if authService.getBiometricType() != .none {
                        Text("Please use \(authService.getBiometricType().name) to verify your identity")
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
                        if authService.getBiometricType() != .none {
                            Button(action: {
                                authenticate()
                            }) {
                                HStack {
                                    Image(systemName: authService.getBiometricType() == .faceID ? "faceid" : "touchid")
                                        .font(.headline)
                                    Text("Authenticate with \(authService.getBiometricType().name)")
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
                            .disabled(isLoading)
                            .opacity(isLoading ? 0.7 : 1.0)
                        }
                        
                        // Sign out option
                        Button(action: {
                            // Sign out and go back to login
                            authService.signOut()
                            isAuthenticated = false
                        }) {
                            Text("Sign Out")
                                .foregroundColor(.white.opacity(0.7))
                                .padding(.vertical, 10)
                        }
                    }
                    .padding(.top, 10)
                    
                    Spacer()
                    
                    // Hidden NavigationLink that gets activated when authentication succeeds
                    NavigationLink(
                                            destination: FinanceRootView()
                                                .navigationBarBackButtonHidden(true),
                                            isActive: $navigateToFinanceRoot,
                                            label: { EmptyView() }
                                        )
                }
                .padding()
                
                // Loading overlay
                if isLoading {
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
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        authenticate()
                    }
                    authenticateOnAppear = false
                }
            }
            .alert(isPresented: $showAlert) {
                Alert(
                    title: Text("Authentication Failed"),
                    message: Text(alertMessage),
                    dismissButton: .default(Text("Try Again"), action: {
                        authenticate()
                    })
                )
            }
        }
        .navigationViewStyle(StackNavigationViewStyle()) // Use stack navigation for consistency
    }
    
    private func authenticate() {
        isLoading = true
        
        let reason = "Log in to your Pennywise account using \(authService.getBiometricType().name)"
        
        authService.authenticateWithBiometrics(reason: reason) { success, error in
            DispatchQueue.main.async {
                isLoading = false
                
                if success {
                    withAnimation {
                        // Set authenticated state
                        isAuthenticated = true
                        
                        // Trigger navigation to FinanceRootView
                        navigateToFinanceRoot = true
                    }
                } else {
                    handleAuthenticationError(error)
                }
            }
        }
    }
    
    private func handleAuthenticationError(_ error: Error?) {
        if let error = error as NSError? {
            switch error.code {
            case LAError.userCancel.rawValue:
                break
                
            case LAError.biometryNotAvailable.rawValue:
                alertMessage = "Biometric authentication is not available on this device."
                showAlert = true
                
            case LAError.biometryNotEnrolled.rawValue:
                alertMessage = "Please set up \(authService.getBiometricType().name) in your device settings."
                showAlert = true
                
            case LAError.biometryLockout.rawValue:
                alertMessage = "Too many failed attempts. Please use your device passcode to re-enable \(authService.getBiometricType().name)."
                showAlert = true
                
            case LAError.authenticationFailed.rawValue:
                alertMessage = "Authentication failed. Please try again."
                showAlert = true
                
            default:
                alertMessage = "Authentication failed: \(error.localizedDescription)"
                showAlert = true
            }
        } else if let error = error {
            alertMessage = "Authentication failed: \(error.localizedDescription)"
            showAlert = true
        } else {
            alertMessage = "Authentication failed. Please try again."
            showAlert = true
        }
    }
}
