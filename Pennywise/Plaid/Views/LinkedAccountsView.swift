//
//  LinkedAccountsView.swift
//  Pennywise
//
//  Created by Arnav Varyani on 4/10/25.
//

import SwiftUI
import LinkKit

struct PlaidAccountsView: View {
    @EnvironmentObject var plaidManager: PlaidManager
    @State private var showingAddAccountSheet = false
    @State private var showingError = false
    @State private var errorMessage = ""
    
    var body: some View {
        ZStack {
            // Background gradient
            AppTheme.backgroundGradient
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 20) {
                // Header
                HStack {
                    Text("Connected Accounts")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(AppTheme.textColor)
                    
                    Spacer()
                    
                    Button(action: {
                        showingAddAccountSheet = true
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundColor(AppTheme.primaryGreen)
                    }
                    .buttonStyle(ScaleButtonStyle())
                }
                .padding(.horizontal)
                
                if plaidManager.accounts.isEmpty {
                    emptyStateView
                } else {
                    accountsList
                }
            }
            .padding(.top)
        }
        .sheet(isPresented: $showingAddAccountSheet) {
            addAccountView
        }
        .alert(isPresented: $showingError) {
            Alert(
                title: Text("Connection Error"),
                message: Text(errorMessage),
                dismissButton: .default(Text("OK"))
            )
        }
        .onReceive(plaidManager.$error) { error in
            if let error = error {
                errorMessage = error.localizedDescription
                showingError = true
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: "building.columns")
                .font(.system(size: 70))
                .foregroundColor(AppTheme.accentBlue.opacity(0.7))
            
            Text("No accounts connected")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(AppTheme.textColor)
            
            Text("Link your bank accounts to automatically track your income and expenses.")
                .multilineTextAlignment(.center)
                .font(.body)
                .foregroundColor(AppTheme.textColor.opacity(0.7))
                .padding(.horizontal, 40)
            
            Button(action: {
                showingAddAccountSheet = true
            }) {
                HStack {
                    Image(systemName: "plus")
                        .font(.headline)
                    
                    Text("Connect Account")
                        .font(.headline)
                }
                .padding()
                .frame(maxWidth: 250)
                .background(AppTheme.primaryGreen)
                .foregroundColor(.white)
                .cornerRadius(10)
                .shadow(color: AppTheme.primaryGreen.opacity(0.4), radius: 8, x: 0, y: 4)
            }
            .buttonStyle(ScaleButtonStyle())
            .padding(.top, 16)
            
            Spacer()
        }
    }
    
    private var accountsList: some View {
        ScrollView {
            VStack(spacing: 16) {
                ForEach(plaidManager.accounts) { account in
                    accountCard(for: account)
                }
            }
            .padding(.horizontal)
        }
    }
    
    private func accountCard(for account: PlaidAccount) -> some View {
        HStack(spacing: 16) {
            // Bank logo or icon
            ZStack {
                Circle()
                    .fill(AppTheme.accentPurple.opacity(0.2))
                    .frame(width: 50, height: 50)
                
                if let logo = account.institutionLogo {
                    Image(uiImage: logo)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 28, height: 28)
                } else {
                    Image(systemName: "building.columns")
                        .font(.system(size: 22))
                        .foregroundColor(AppTheme.accentBlue)
                }
            }
            
            // Account details
            VStack(alignment: .leading, spacing: 4) {
                Text(account.name)
                    .font(.headline)
                    .foregroundColor(AppTheme.textColor)
                
                Text(account.institutionName)
                    .font(.subheadline)
                    .foregroundColor(AppTheme.textColor.opacity(0.7))
            }
            
            Spacer()
            
            // Balance with positive/negative color
            Text("$\(account.balance, specifier: "%.2f")")
                .font(.headline)
                .foregroundColor(account.balance >= 0 ? AppTheme.primaryGreen : AppTheme.expenseColor)
        }
        .padding()
        .background(AppTheme.cardBackground)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(AppTheme.cardStroke, lineWidth: 1)
        )
    }
    
    private var addAccountView: some View {
        NavigationView {
            ZStack {
                // Background
                AppTheme.backgroundGradient.ignoresSafeArea()
                
                VStack(spacing: 24) {
                    // Plaid illustration
                    Image(systemName: "building.columns.fill")
                        .font(.system(size: 60))
                        .foregroundColor(AppTheme.accentBlue)
                        .padding()
                    
                    Text("Connect your accounts")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(AppTheme.textColor)
                    
                    Text("Link your bank accounts securely with Plaid to automatically track your transactions and balances.")
                        .multilineTextAlignment(.center)
                        .font(.body)
                        .foregroundColor(AppTheme.textColor.opacity(0.8))
                        .padding(.horizontal, 24)
                    
                    Spacer()
                    
                    // Secure badge
                    HStack {
                        Image(systemName: "lock.fill")
                            .foregroundColor(AppTheme.primaryGreen)
                        
                        Text("Your credentials are never stored")
                            .font(.caption)
                            .foregroundColor(AppTheme.textColor.opacity(0.7))
                    }
                    .padding(.bottom, 8)
                    
                    // Connect button
                    PlaidLinkView(onDismiss: {
                        showingAddAccountSheet = false
                    })
                    .padding(.bottom, 40)
                }
                .padding()
            }
            .navigationTitle("Add Account")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        showingAddAccountSheet = false
                    }
                    .foregroundColor(AppTheme.primaryGreen)
                }
            }
        }
    }
}

// MARK: - Preview
struct LinkedAccountsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            PlaidAccountsView()
                .environmentObject(PlaidManager.shared)
        }
    }
}
