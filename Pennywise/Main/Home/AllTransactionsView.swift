//
//  AllTransactionsView.swift
//  Pennywise
//

import SwiftUI

struct AllTransactionsView: View {
    let transactions: [Transaction]
    @State private var selectedTransaction: Transaction? = nil
    
    var body: some View {
        ZStack {
            AppTheme.enhancedBackgroundGradient
            
            VStack(spacing: 12) {
                if transactions.isEmpty {
                    PWGlassCard {
                        VStack(spacing: 10) {
                            Image(systemName: "tray")
                                .font(.system(size: 28, weight: .semibold))
                                .foregroundColor(AppTheme.accentBlue.opacity(0.9))
                            Text("No transactions available")
                                .font(.headline)
                                .foregroundColor(AppTheme.textColor)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .padding(.horizontal, 16)
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 12) {
                            PWSectionHeader("All Transactions", subtitle: "\(transactions.count) total")
                                .padding(.horizontal, 16)
                            
                            PWGlassCard {
                                VStack(spacing: 0) {
                                    ForEach(Array(transactions.sorted(by: { $0.date > $1.date }).enumerated()), id: \.element.id) { idx, transaction in
                                        NavigationLink(value: AppRoute.transactionDetail(transaction: transaction)) {
                                            HomeActivityRow(transaction: transaction)
                                                .padding(.horizontal, 4)
                                        }
                                        .buttonStyle(.plain)
                                        
                                        if idx != transactions.count - 1 {
                                            PWDivider(inset: 56, opacity: 0.8)
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, 16)
                        }
                        .padding(.vertical, 12)
                    }
                }
            }
            .navigationTitle("All Transactions")
        }
    }
}
