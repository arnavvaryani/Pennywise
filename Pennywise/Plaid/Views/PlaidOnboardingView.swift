//
//  PlaidOnboardingView.swift
//  Pennywise
//
//  Created by Arnav Varyani on 4/11/25.
//

import SwiftUI

struct PlaidOnboardingView: View {
    @Binding var isPresented: Bool
    @EnvironmentObject var plaidManager: PlaidManager
    @State private var isLoading = false
    
    var body: some View {
        ZStack {
            // Background gradient
            AppTheme.backgroundGradient
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
                            // Set hasLinkedPlaidAccount to true to bypass this screen
                            UserDefaults.standard.set(true, forKey: "hasLinkedPlaidAccount")
                        }
                    }) {
                        Text("Skip for now")
                            .font(.subheadline)
                            .foregroundColor(AppTheme.textColor.opacity(0.6))
                            .padding(.vertical, 10)
                    }
                    .padding(.bottom, 20)
                    
                    // Connect button
                    PlaidLinkView()
                        .padding(.bottom, 40)
                }
            }
            .padding()
        }
    }
}
