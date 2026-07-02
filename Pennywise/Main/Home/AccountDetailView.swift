//
//  AccountDetailView.swift
//  Pennywise
//

import SwiftUI

struct AccountDetailView: View {
    let account: Account
    @Environment(\.dismiss) var dismiss
    let transactions: [Transaction]
    
    var accountTransactions: [Transaction] {
        transactions.filter { $0.accountId == account.id }
    }
    
    init(account: Account) {
        self.account = account
        self.transactions = []
    }
    
    var body: some View {
        ZStack {
            AppTheme.enhancedBackgroundGradient
            
            ScrollView {
                VStack(spacing: 20) {
                    PWGlassCard {
                        VStack(spacing: 14) {
                            ZStack {
                                Circle()
                                    .fill(AppTheme.accentPurple.opacity(0.22))
                                    .frame(width: 80, height: 80)
                                
                                if let logoData = account.institutionLogo,
                                   let uiImage = UIImage(data: logoData) {
                                    Image(uiImage: uiImage)
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 50, height: 50)
                                } else {
                                    Image(systemName: "building.columns")
                                        .font(.system(size: 40, weight: .semibold))
                                        .foregroundColor(AppTheme.accentBlue)
                                }
                            }
                            
                            VStack(spacing: 2) {
                                Text(account.name)
                                    .font(.title2.weight(.bold))
                                    .foregroundColor(AppTheme.textColor)
                                
                                Text(account.institutionName)
                                    .font(.subheadline)
                                    .foregroundColor(AppTheme.textColor.opacity(0.7))
                            }
                            
                            VStack(spacing: 4) {
                                Text("Current Balance")
                                    .font(.caption)
                                    .foregroundColor(AppTheme.textColor.opacity(0.65))
                                
                                Text("\(CurrencyFormatter.format(account.balance))")
                                    .font(.system(size: 36, weight: .bold))
                                    .foregroundColor(account.balance >= 0 ? AppTheme.primaryGreen : AppTheme.expenseColor)
                                    .monospacedDigit()
                            }
                            .padding(.top, 2)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .padding(.horizontal, 16)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        PWSectionHeader("Account Details")
                            .padding(.horizontal, 16)
                        
                        PWGlassCard {
                            VStack(spacing: 12) {
                                detailRow(title: "Account Type", value: account.type)
                                PWDivider(opacity: 0.8)
                                detailRow(title: "Account Number", value: "****\(account.id.suffix(4))")
                                PWDivider(opacity: 0.8)
                                detailRow(title: "Institution", value: account.institutionName)
                                
                                if let lastDate = accountTransactions.sorted(by: { $0.date > $1.date }).first?.date {
                                    PWDivider(opacity: 0.8)
                                    detailRow(
                                        title: "Last Transaction",
                                        value: formatDate(lastDate)
                                    )
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                    
                    VStack(alignment: .leading, spacing: 12) {
                        PWSectionHeader("Recent Transactions")
                            .padding(.horizontal, 16)
                        
                        if accountTransactions.isEmpty {
                            PWGlassCard {
                                Text("No transactions for this account")
                                    .font(.subheadline)
                                    .foregroundColor(AppTheme.textColor.opacity(0.7))
                                    .frame(maxWidth: .infinity, alignment: .center)
                            }
                            .padding(.horizontal, 16)
                        } else {
                            PWGlassCard {
                                VStack(spacing: 0) {
                                    ForEach(Array(accountTransactions.sorted(by: { $0.date > $1.date }).prefix(5).enumerated()), id: \.element.id) { idx, transaction in
                                        NavigationLink(value: AppRoute.transactionDetail(transaction: transaction)) {
                                            HomeActivityRow(transaction: transaction)
                                                .padding(.horizontal, 4)
                                        }
                                        .buttonStyle(.plain)
                                        
                                        if idx != min(accountTransactions.count, 5) - 1 {
                                            PWDivider(inset: 56, opacity: 0.8)
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, 16)
                            
                            if accountTransactions.count > 5 {
                                Button(action: {}) {
                                    Text("View All Transactions")
                                        .font(.subheadline)
                                        .foregroundColor(AppTheme.primaryGreen)
                                        .padding()
                                        .frame(maxWidth: .infinity)
                                        .background(AppTheme.primaryGreen.opacity(0.12))
                                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                                }
                                .padding(.horizontal, 16)
                                .buttonStyle(ScaleButtonStyle())
                            }
                        }
                    }
                    
                    HStack(spacing: 16) {
                        Button(action: {}) {
                            Label("Refresh", systemImage: "arrow.clockwise")
                                .font(.subheadline)
                                .foregroundColor(AppTheme.textColor)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .pwGlassSurface(cornerRadius: 16)
                                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .stroke(AppTheme.cardStroke, lineWidth: 1)
                                )
                        }
                        .buttonStyle(ScaleButtonStyle())
                        
                        Button(action: {}) {
                            Label("Disconnect", systemImage: "minus.circle")
                                .font(.subheadline)
                                .foregroundColor(AppTheme.expenseColor)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .pwGlassSurface(cornerRadius: 16)
                                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .stroke(AppTheme.cardStroke, lineWidth: 1)
                                )
                        }
                        .buttonStyle(ScaleButtonStyle())
                    }
                    .padding(.horizontal, 16)
                }
                .padding(.vertical)
            }
        }
        .navigationTitle("Account Details")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Done") {
                    dismiss()
                }
                .foregroundColor(AppTheme.primaryGreen)
            }
        }
    }
    
    private func detailRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundColor(AppTheme.textColor.opacity(0.7))
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .foregroundColor(AppTheme.textColor)
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
