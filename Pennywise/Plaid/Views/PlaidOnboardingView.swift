//
//  PlaidOnboardingView.swift
//  Pennywise
//
//  Created by Arnav Varyani on 4/11/25.
//

import SwiftUI

struct PlaidOnboardingView: View {
    @Binding var isPresented: Bool
    private let container = DependencyContainer.shared
    @State private var isLoading = false
    @State private var showingLink = false
    @State private var errorMessage: String? = nil
    @AppStorage("hasSkippedPlaidLink") private var hasSkippedPlaidLink = false
    
    var body: some View {
        ZStack {
            Color(AppTheme.backgroundPrimary)
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 30) {
                // Plaid logo/icon
                ZStack {
                    Circle()
                        .fill(AppTheme.accentBlue.opacity(0.2))
                        .frame(width: 120, height: 120)
                    
                    Image(systemName: "building.columns.fill")
                        .font(.system(size: 60))
                        .foregroundColor(AppTheme.accentBlue)
                }
                .padding(.top, 50)
                
                Text("Link Your Accounts")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(AppTheme.textColor)
                
                Text("Connect your bank accounts securely with Plaid to automatically track your transactions and balances.")
                    .multilineTextAlignment(.center)
                    .font(.body)
                    .foregroundColor(AppTheme.textColor.opacity(0.8))
                    .padding(.horizontal, 30)
                
                Spacer()
                
                VStack(spacing: 15) {
                    // Secure badge
                    HStack {
                        Image(systemName: "lock.fill")
                            .foregroundColor(AppTheme.primaryGreen)
                        
                        Text("Your credentials are never stored")
                            .font(.caption)
                            .foregroundColor(AppTheme.textColor.opacity(0.7))
                    }
                    
                    // Skip for now option
                    Button(action: {
                        // Allow users to skip linking accounts
                        withAnimation {
                            isPresented = false
                            hasSkippedPlaidLink = true
                        }
                    }) {
                        Text("Skip for now")
                            .font(.subheadline)
                            .foregroundColor(AppTheme.textColor.opacity(0.6))
                            .padding(.vertical, 10)
                    }
                    .padding(.bottom, 20)
                    
                    // Connect button
                    Button(action: {
                        Task {
                            isLoading = true
                            do {
                                try await container.preparePlaidLink()
                                if container.plaidService.linkController != nil {
                                    showingLink = true
                                } else {
                                    errorMessage = "Unable to start Plaid Link. Please try again."
                                }
                            } catch {
                                errorMessage = error.localizedDescription
                            }
                            isLoading = false
                        }
                    }) {
                        Text("Connect Account")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(AppTheme.primaryGreen)
                            .cornerRadius(12)
                            .shadow(color: AppTheme.primaryGreen.opacity(0.3), radius: 5, x: 0, y: 5)
                    }
                    .disabled(isLoading)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)
                }
            }
            .padding()
        }
        .fullScreenCover(isPresented: $showingLink) {
            if let handler = container.plaidService.linkController {
                PlaidLinkView(handler: handler) {
                    showingLink = false
                }
                .onAppear {
                    container.plaidService.onSuccess = {
                        showingLink = false
                        hasSkippedPlaidLink = false
                        isPresented = false
                    }
                    container.plaidService.onLinkError = { error in
                        showingLink = false
                        errorMessage = error.localizedDescription
                    }
                    container.plaidService.onExit = {
                        showingLink = false
                    }
                }
            }
        }
        .alert("Plaid Link Error", isPresented: Binding(get: { errorMessage != nil }, set: { _ in errorMessage = nil })) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "")
        }
    }
}
