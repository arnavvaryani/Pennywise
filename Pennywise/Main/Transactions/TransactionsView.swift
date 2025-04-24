//
//  TransactionsView.swift
//  Pennywise
//
//  Created by Arnav Varyani on 4/14/25.
//

import SwiftUI

struct TransactionsView: View {
    @EnvironmentObject var plaidManager: PlaidManager
    @State private var isLoading = false
    
    var body: some View {
        ZStack {
            // Background gradient
            AppTheme.backgroundGradient
                .edgesIgnoringSafeArea(.all)
            
            VStack {
                Text("Transactions")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(AppTheme.textColor)
                    .padding()
                
                if isLoading {
                    ProgressView()
                        .scaleEffect(1.5)
                        .padding()
                } else if plaidManager.transactions.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "doc.text.magnifyingglass")
                            .font(.system(size: 70))
                            .foregroundColor(AppTheme.accentBlue.opacity(0.7))
                        
                        Text("No transactions found")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(AppTheme.textColor)
                        
                        Text("Link your bank accounts or add transactions manually to track your spending.")
                            .multilineTextAlignment(.center)
                            .font(.body)
                            .foregroundColor(AppTheme.textColor.opacity(0.7))
                            .padding(.horizontal, 40)
                    }
                    .padding()
                } else {
                    // Display transactions from Plaid
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(plaidManager.transactions) { transaction in
                                TransactionRow(transaction: transaction)
                                    .padding(.horizontal)
                            }
                        }
                        .padding(.vertical)
                    }
                }
            }
        }
        .onAppear {
            isLoading = true
            plaidManager.fetchTransactions { success in
                isLoading = false
            }
        }
    }
}
