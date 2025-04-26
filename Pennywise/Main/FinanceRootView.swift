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
                                    .toolbarBackground(AppTheme.backgroundPrimary, for: .navigationBar)
                                    .toolbarBackground(.visible, for: .navigationBar)
                    }
                    .tag(0)
                    
                    // Insights Tab
                    NavigationView {
                        InsightsView()
                            .navigationBarTitleDisplayMode(.inline)
                            .navigationTitle("Insights")
                                    .navigationBarTitleDisplayMode(.inline)
                                    .toolbarBackground(AppTheme.backgroundPrimary, for: .navigationBar)
                                    .toolbarBackground(.visible, for: .navigationBar)
                    }
                    .tag(1)
                    
                    NavigationView {
                        BudgetPlannerView()
                            .navigationTitle("Budget")
                            .navigationBarTitleDisplayMode(.inline)
                    }
                    .tag(3)
                    
//                    NavigationView {
//                        FinancialAssistantView()
//                            .navigationTitle("Assistant")
//                            .navigationBarTitleDisplayMode(.inline)
//                    }
//                    .tag(4)
                    
                    NavigationView {
                       SettingsView()
                            .navigationTitle("Settings")
                            .navigationBarTitleDisplayMode(.inline)
                    }
                    .tag(4)

                    
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                
            TabBar(selectedTab: $selectedTab, showAddTransaction: $showAddTransaction)
            }
            .edgesIgnoringSafeArea(.bottom)
        }
        .sheet(isPresented: $showAddTransaction) {
            TransactionView(isPresented: $showAddTransaction) { transaction in
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
    
    private func addTransaction(transaction: Transaction) {
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

