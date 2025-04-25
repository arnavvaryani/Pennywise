//
//  FinanceRootView.swift
//  Pennywise
//
//  Created by Arnav Varyani on 4/11/25.
//

import SwiftUI

struct FinanceRootView: View {
    @State private var selectedTab: Int = 0
    @State private var showAddTransaction = false
    @State private var previousTab = 0
    @EnvironmentObject var plaidManager: PlaidManager
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Apply the background color to the entire view
            AppTheme.backgroundGradient
                .edgesIgnoringSafeArea(.all)
            
            // Main content area
            VStack(spacing: 0) {
                TabView(selection: $selectedTab) {
                    // Home Tab
                    NavigationView {
                        FinanceHomeView()
                            .navigationTitle("Home")
                            .navigationBarTitleDisplayMode(.inline)
                    }
                    .tag(0)
                    
                    // Insights Tab
                    NavigationView {
                        InsightsView()
                            .navigationTitle("Insights")
                            .navigationBarTitleDisplayMode(.inline)
                    }
                    .tag(1)
                    
                    // This is a placeholder for the Add button
                    Color.clear
                        .tag(2)
                    
                    // Budget Tab
                    NavigationView {
                        BudgetPlannerView()
                            .navigationTitle("Budget")
                            .navigationBarTitleDisplayMode(.inline)
                    }
                    .tag(3)
                    
                    // Settings Tab
                    NavigationView {
                       SettingsView()
                            .navigationTitle("Settings")
                            .navigationBarTitleDisplayMode(.inline)
                    }
                    .tag(4)
                    
//                    NavigationView {
//                        PennyGPTView()
//                            .navigationTitle("GPT")
//                            .navigationBarTitleDisplayMode(.inline)
//                    }
//                    .tag(5)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                
                // Use our enhanced tab bar
            TabBar(selectedTab: $selectedTab, showAddTransaction: $showAddTransaction)
            }
            .edgesIgnoringSafeArea(.bottom)
        }
        .sheet(isPresented: $showAddTransaction) {
            // Add transaction modal
            TransactionView(isPresented: $showAddTransaction) { transaction in
                // Handle the new transaction
                addTransaction(transaction: transaction)
            }
        }
        .fullScreenCover(isPresented: $plaidManager.isLinkPresented) {
            if let linkController = plaidManager.linkController {
                linkController
                    .ignoresSafeArea(.all)
            }
        }
    }
    
    // Function to add a transaction to the Plaid manager
    private func addTransaction(transaction: Transaction) {
        // In a real app, you would save the transaction to the database
        // For now, we'll just update the local state with a new PlaidTransaction
        let newTransaction = PlaidTransaction(
            id: UUID().uuidString,
            name: transaction.title,
            amount: transaction.amount,
            date: transaction.date,
            category: transaction.category,
            merchantName: transaction.merchant,
            accountId: plaidManager.accounts.first?.id ?? "default",
            pending: false
        )
        
        withAnimation(.spring()) {
            plaidManager.transactions.insert(newTransaction, at: 0)
        }
    }
}

struct FixedFinanceRootView_Previews: PreviewProvider {
    static var previews: some View {
        FinanceRootView()
            .environmentObject(PlaidManager.shared)
            .preferredColorScheme(.dark)
    }
}

// MARK: - Supporting Models

struct SavingsSuggestion: Identifiable {
    let id: UUID
    let title: String
    let description: String
    let icon: String
    let category: String
    let potentialSavings: Double
}

