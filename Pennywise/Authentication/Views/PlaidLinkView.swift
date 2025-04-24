//
//  EnhancedPlaidLinkView.swift
//  Pennywise
//
//  Created by Arnav Varyani on 4/24/25.
//

import SwiftUI
import Combine
import LinkKit

struct PlaidLinkView: View {
    @EnvironmentObject var plaidManager: PlaidManager
    @State private var isLoading = false
    @State private var errorMessage: String? = nil
    var onDismiss: (() -> Void)? = nil
    
    var body: some View {
        VStack {
            Button(action: {
                // Start loading state
                isLoading = true
                errorMessage = nil
                
                // Force recreate the link controller
                plaidManager.prepareLinkForPresentation { success in
                    DispatchQueue.main.async {
                        isLoading = false
                        if success {
                            plaidManager.isLinkPresented = true
                        } else {
                            errorMessage = "Unable to initialize Plaid Link. Please try again."
                        }
                    }
                }
            }) {
                HStack {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .padding(.trailing, 8)
                    } else {
                        Image(systemName: "link.circle.fill")
                            .font(.system(size: 20))
                    }
                    
                    Text("Connect Bank Account")
                        .font(.headline)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(AppTheme.primaryGreen)
                .foregroundColor(.white)
                .cornerRadius(10)
                .shadow(color: AppTheme.primaryGreen.opacity(0.3), radius: 5, x: 0, y: 3)
                .opacity(isLoading ? 0.7 : 1.0)
            }
            .disabled(isLoading)
            .padding(.horizontal)
            .accessibilityLabel("Connect your bank account")
            
            if let error = errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding(.top, 8)
            }
        }
        .fullScreenCover(
            isPresented: Binding<Bool>(
                get: { plaidManager.isLinkPresented },
                set: { newValue in
                    plaidManager.isLinkPresented = newValue
                    if !newValue && !plaidManager.accounts.isEmpty {
                        // Only dismiss if we have accounts (successful link)
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            onDismiss?()
                        }
                    }
                }
            ),
            content: {
                if let linkController = plaidManager.linkController {
                    linkController
                        .ignoresSafeArea(.all)
                        .onDisappear {
                            // This ensures we can track when the link controller is dismissed
                            print("Plaid Link Controller dismissed")
                            // Check if we have accounts after disappearing
                            if !plaidManager.accounts.isEmpty {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                    onDismiss?()
                                }
                            }
                        }
                } else {
                    // Fallback view if controller is still nil
                    VStack(spacing: 20) {
                        Text("Error: LinkController not initialized")
                            .foregroundColor(.red)
                        
                        Button("Close") {
                            plaidManager.isLinkPresented = false
                        }
                        .padding()
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(8)
                    }
                    .padding()
                    .background(Color.black.opacity(0.9))
                    .edgesIgnoringSafeArea(.all)
                }
            }
        )
        // Listen for account changes
        .onReceive(plaidManager.$accounts) { accounts in
            // If accounts were added and the sheet is still presented, dismiss it
            if !accounts.isEmpty && plaidManager.isLinkPresented {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    plaidManager.isLinkPresented = false
                    onDismiss?()
                }
            }
        }
    }
}
