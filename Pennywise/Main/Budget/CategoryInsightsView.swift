//
//  CategoryInsightsView.swift
//  Pennywise
//
//  Created by Arnav Varyani on 4/25/25.
//


import SwiftUI

struct CategoryInsightsView: View {
    let category: BudgetCategory
    var insights: [String] = []
    var spent: Double = 0
    var transactions: [PlaidTransaction] = []
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var navigationManager: NavigationManager
    
    @State private var selectedTab = 0
    
    var body: some View {
        ZStack {
                AppTheme.enhancedBackgroundGradient
                
                VStack(spacing: 20) {
                    // Header
                    PWGlassCard {
                        HStack(spacing: 15) {
                            ZStack {
                                Circle()
                                    .fill(Color(hex: category.colorHex).opacity(0.2))
                                    .frame(width: 50, height: 50)
                                
                                Image(systemName: category.icon)
                                    .font(.system(size: 24))
                                    .foregroundColor(Color(hex: category.colorHex))
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(category.name)
                                    .font(.title3)
                                    .fontWeight(.bold)
                                    .foregroundColor(AppTheme.textColor)
                                
                                Text("\(CurrencyFormatter.format(spent)) spent of \(CurrencyFormatter.format(category.amount))")
                                    .font(.subheadline)
                                    .foregroundColor(AppTheme.textColor.opacity(0.7))
                            }
                            
                            Spacer()
                            
                            Button(action: {
                                navigationManager.navigate(to: .categoryMapping(budgetCategory: category.name))
                            }) {
                                Image(systemName: "slider.horizontal.3")
                                    .font(.system(size: 18))
                                    .foregroundColor(AppTheme.accentBlue)
                                    .padding(10)
                                    .background(AppTheme.accentBlue.opacity(0.12))
                                    .clipShape(Circle())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal)
                    
                    // Tab selector
                    HStack {
                        tabButton(title: "Insights", isSelected: selectedTab == 0) {
                            withAnimation {
                                selectedTab = 0
                            }
                        }
                        
                        tabButton(title: "Transactions", isSelected: selectedTab == 1) {
                            withAnimation {
                                selectedTab = 1
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    // Content based on selected tab
                    if selectedTab == 0 {
                        insightsContent
                    } else {
                        transactionsContent
                    }
                    
                    // Close button
                    Button(action: {
                        dismiss()
                    }) {
                        Text("Close")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(AppTheme.primaryGreen)
                            .cornerRadius(12)
                    }
                    .buttonStyle(ScaleButtonStyle())
                    .padding(.horizontal)
                    .padding(.bottom, 20)
                }
                .padding(.top, 8)
            }
        }
    
    // MARK: - Tab Content Views
    
    // Insights tab content
    private var insightsContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if insights.isEmpty {
                    // Empty state for insights
                    VStack(spacing: 20) {
                        Image(systemName: "lightbulb.slash")
                            .font(.system(size: 40))
                            .foregroundColor(AppTheme.accentBlue.opacity(0.6))
                            .padding(.top, 20)
                        
                        Text("No insights available")
                            .font(.headline)
                            .foregroundColor(AppTheme.textColor)
                        
                        Text("Continue tracking your spending in this category to receive personalized insights.")
                            .font(.subheadline)
                            .foregroundColor(AppTheme.textColor.opacity(0.7))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                } else {
                    // Show insights
                    ForEach(insights.indices, id: \.self) { index in
                        insightCard(text: insights[index], index: index)
                    }
                }
            }
            .padding(.horizontal)
        }
    }
    
    // Transactions tab content
    private var transactionsContent: some View {
        ScrollView {
            VStack(spacing: 12) {
                if transactions.isEmpty {
                    // Empty state for transactions
                    VStack(spacing: 20) {
                        Image(systemName: "doc.text.magnifyingglass")
                            .font(.system(size: 40))
                            .foregroundColor(AppTheme.accentBlue.opacity(0.6))
                            .padding(.top, 20)
                        
                        Text("No transactions found")
                            .font(.headline)
                            .foregroundColor(AppTheme.textColor)
                        
                        Text("There are no transactions in this category for the current period.")
                            .font(.subheadline)
                            .foregroundColor(AppTheme.textColor.opacity(0.7))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                } else {
                    // Show transactions
                    ForEach(transactions) { transaction in
                        transactionRow(transaction)
                    }
                }
            }
            .padding(.horizontal)
        }
    }
    
    // MARK: - Helper Views
    
    // Tab button helper
    private func tabButton(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.headline)
                .foregroundColor(isSelected ? .white : AppTheme.textColor.opacity(0.7))
                .padding(.vertical, 10)
                .padding(.horizontal, 20)
                .background(
                    isSelected ? 
                        AppTheme.primaryGreen :
                        AppTheme.cardBackground
                )
                .cornerRadius(10)
        }
        .frame(maxWidth: .infinity)
    }
    
    // Insight card
    private func insightCard(text: String, index: Int) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            if text.starts(with: "-") {
                // List item
                HStack(alignment: .top, spacing: 10) {
                    Circle()
                        .fill(Color(hex: category.colorHex))
                        .frame(width: 8, height: 8)
                        .padding(.top, 6)
                    
                    Text(text.dropFirst(2))
                        .foregroundColor(AppTheme.textColor)
                }
                .padding(.leading, 20)
            } else {
                // Regular insight
                HStack(alignment: .top, spacing: 15) {
                    // Icon
                    ZStack {
                        Circle()
                            .fill(Color(hex: category.colorHex).opacity(0.2))
                            .frame(width: 36, height: 36)
                        
                        Image(systemName: insightIcon(for: index))
                            .font(.system(size: 16))
                            .foregroundColor(Color(hex: category.colorHex))
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(text)
                            .foregroundColor(AppTheme.textColor)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
        .padding()
        .pwGlassSurface(cornerRadius: 12)
    }
    
    // Transaction row
    private func transactionRow(_ transaction: PlaidTransaction) -> some View {
        HStack(spacing: 15) {
            // Date column
            VStack(alignment: .center, spacing: 2) {
                Text(formatDay(transaction.date))
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(AppTheme.textColor)
                
                Text(formatMonth(transaction.date))
                    .font(.caption2)
                    .foregroundColor(AppTheme.textColor.opacity(0.6))
            }
            .frame(width: 40)
            
            // Transaction details
            VStack(alignment: .leading, spacing: 4) {
                Text(transaction.merchantName)
                    .font(.subheadline)
                    .foregroundColor(AppTheme.textColor)
                
                // Show the transaction's Plaid category if it's different from budget category
                if transaction.category != category.name {
                    Text(transaction.category)
                        .font(.caption)
                        .foregroundColor(AppTheme.textColor.opacity(0.6))
                }
            }
            
            Spacer()
            
            // Amount
            Text("\(CurrencyFormatter.format(transaction.amount))")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(transaction.amount > 0 ? AppTheme.expenseColor : AppTheme.primaryGreen)
        }
        .padding()
        .pwGlassSurface(cornerRadius: 12)
    }
    
    // MARK: - Helper Functions
    
    // Get appropriate icon for insight based on index
    private func insightIcon(for index: Int) -> String {
        let icons = [
            "chart.pie.fill",
            "arrow.up.right",
            "cart.fill",
            "calendar",
            "arrow.triangle.swap",
            "dollarsign.circle.fill",
            "waveform.path.ecg",
            "lightbulb.fill"
        ]
        
        return icons[index % icons.count]
    }
    
    // Format day number from date
    private func formatDay(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd"
        return formatter.string(from: date)
    }
    
    // Format month from date
    private func formatMonth(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        return formatter.string(from: date)
    }
}