//
//  TransactionDetailView.swift
//  Pennywise
//
//  Detail view for a transaction
//

import SwiftUI

struct TransactionDetailView: View {
    let transaction: Transaction
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            AppTheme.enhancedBackgroundGradient
            
            ScrollView {
                VStack(spacing: 24) {
                    // Amount card
                    PWGlassCard {
                        VStack(spacing: 10) {
                            PWPill(
                                title: transaction.isIncome ? "Income" : "Expense",
                                systemImage: transaction.isIncome ? "arrow.down.circle" : "arrow.up.circle",
                                tint: transaction.isIncome ? AppTheme.primaryGreen : AppTheme.expenseColor
                            )
                            
                            Text(String(format: "$%.2f", abs(transaction.amount)))
                                .font(.system(size: 48, weight: .bold))
                                .foregroundColor(transaction.isIncome ? AppTheme.primaryGreen : AppTheme.expenseColor)
                                .monospacedDigit()
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    
                    // Details
                    PWGlassCard {
                        VStack(alignment: .leading, spacing: 12) {
                            PWSectionHeader("Details")
                            
                            DetailRow(title: "Name", value: transaction.name)
                            PWDivider(inset: 0, opacity: 0.8)
                            
                            DetailRow(title: "Merchant", value: transaction.merchantName.isEmpty ? "—" : transaction.merchantName)
                            PWDivider(inset: 0, opacity: 0.8)
                            
                            DetailRow(title: "Category", value: transaction.category)
                            PWDivider(inset: 0, opacity: 0.8)
                            
                            DetailRow(title: "Date", value: formatDate(transaction.date))
                            PWDivider(inset: 0, opacity: 0.8)
                            
                            DetailRow(title: "Account", value: transaction.accountId)
                            
                            if transaction.isPending {
                                PWPill(title: "Pending", systemImage: "clock", tint: AppTheme.alertOrange)
                                    .padding(.top, 6)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    
                    Spacer()
                }
                .padding(.bottom, 24)
            }
        }
        .navigationTitle("Transaction Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Done") {
                    dismiss()
                }
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
