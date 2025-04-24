//
//  AppCoordinator.swift
//  Pennywise
//
//  Created by Arnav Varyani on 4/10/25.
//


import SwiftUI

struct AppCoordinator: View {
    
    @StateObject private var authService = AuthenticationService.shared
    @StateObject private var plaidManager = PlaidManager.shared
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage("hasLinkedPlaidAccount") private var hasLinkedPlaidAccount = false
    @State private var showBiometricAuth = false
    @State private var hasCheckedAuth = false
    @State private var showPlaidOnboarding = false
    
    var body: some View {
        Group {
            if !hasCompletedOnboarding {
                FinanceOnboardingView()
            } else if !authService.isAuthenticated {
                FinanceLoginView()
            } else if showBiometricAuth {
                BiometricAuthenticationView(isAuthenticated: $showBiometricAuth)
            } else if !hasLinkedPlaidAccount && plaidManager.accounts.isEmpty {
 
                PlaidOnboardingView(isPresented: $showPlaidOnboarding)
                    .onAppear {
                        showPlaidOnboarding = true
                    }
                    .onChange(of: plaidManager.accounts) { accounts in
                        if !accounts.isEmpty {
                    
                            hasLinkedPlaidAccount = true
                        }
                    }
            } else {
                FinanceRootView()
                    .environmentObject(plaidManager)
            }
        }
        .onAppear {
            checkBiometricAuthRequirement()
            
            if !plaidManager.accounts.isEmpty {
                hasLinkedPlaidAccount = true
            }
            
        
            if authService.isAuthenticated {
                plaidManager.prepareLinkController()
            }
        }
        .onChange(of: authService.isAuthenticated) { isAuthenticated in
            if isAuthenticated {
                checkBiometricAuthRequirement()
            }
        }
    }

    private var mainAppContent: some View {
        FinanceRootView()
            .environmentObject(plaidManager)
    }
    
    private func checkBiometricAuthRequirement() {
        if !hasCheckedAuth && authService.isAuthenticated && authService.shouldRequireBiometricAuth() {

            let biometricType = authService.getBiometricType()
            if biometricType != .none {
                showBiometricAuth = true
            } else {
                // If biometrics is not available, mark as passed
                UserDefaults.standard.set(true, forKey: "hasPassedBiometricCheck")
            }
        }
        hasCheckedAuth = true
    }
}

struct EnhancedAppCoordinator_Previews: PreviewProvider {
    static var previews: some View {
        AppCoordinator()
    }
}
