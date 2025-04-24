//
//  TransactionDetailView.swift
//  Pennywise
//
//  Created by Arnav Varyani on 4/15/25.
//


import SwiftUI

struct TransactionDetailView: View {
    let transaction: PlaidTransaction
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var plaidManager: PlaidManager
    
    // Add these state variables for better state management
    @State private var isLoading = true
    @State private var showShareSheet = false
    @State private var isAddingNote = false
    @State private var noteText = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                AppTheme.backgroundGradient
                    .edgesIgnoringSafeArea(.all)
                
                if isLoading {
                    // Show loading state
                    VStack(spacing: 16) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: AppTheme.primaryGreen))
                            .scaleEffect(1.5)
                        
                        Text("Loading transaction details...")
                            .foregroundColor(AppTheme.textColor.opacity(0.7))
                    }
                } else {
                    // Content
                    ScrollView {
                        VStack(spacing: 25) {
                            // Transaction header
                            transactionHeader
                            
                            // Action buttons
                            actionButtonsRow
                            
                            // Details card
                            transactionDetails
                            
                            // Category information
                            categorySection
                            
                            // Payment method section
                            paymentMethodSection
                            
                            // Notes section
                            notesSection
                            
                            // Additional information
                            if !transaction.pending {
                                additionalInfo
                            }
                            
                            // Similar transactions
                            similarTransactionsSection
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Transaction Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "chevron.left")
                            .foregroundColor(AppTheme.primaryGreen)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: {
                            showShareSheet = true
                        }) {
                            Label("Share", systemImage: "square.and.arrow.up")
                        }
                        
                        Button(action: {
                            // Report functionality
                        }) {
                            Label("Report an Issue", systemImage: "exclamationmark.triangle")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .foregroundColor(AppTheme.primaryGreen)
                    }
                }
            }
            .onAppear {
                // Give a short delay to ensure the view is fully initialized
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    isLoading = false
                }
            }
        }
        .sheet(isPresented: $showShareSheet) {
            // Share sheet would go here
            Text("Share Transaction")
                .presentationDetents([.medium])
        }
    }
    
    // Transaction header section
    private var transactionHeader: some View {
        VStack(spacing: 16) {
            // Transaction date above the header
            Text(formatDate(transaction.date))
                .font(.subheadline)
                .foregroundColor(AppTheme.textColor.opacity(0.7))
                .padding(.vertical, 5)
                .padding(.horizontal, 12)
                .background(AppTheme.cardBackground)
                .cornerRadius(12)
            
            HStack(spacing: 20) {
                // Category icon in a large circle
                ZStack {
                    Circle()
                        .fill(transaction.category == "Income" ?
                            AppTheme.primaryGreen.opacity(0.2) :
                            AppTheme.accentPurple.opacity(0.3))
                        .frame(width: 70, height: 70)
                    
                    Image(systemName: getCategoryIcon(for: transaction.category))
                        .font(.system(size: 30))
                        .foregroundColor(transaction.category == "Income" ?
                                        AppTheme.primaryGreen :
                                        AppTheme.accentPurple)
                }
                
                VStack(alignment: .leading, spacing: 5) {
                    Text(transaction.merchantName)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(AppTheme.textColor)
                    
                    Text(transaction.category)
                        .font(.subheadline)
                        .foregroundColor(AppTheme.textColor.opacity(0.7))
                    
                    if transaction.pending {
                        Text("Pending")
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(AppTheme.accentBlue.opacity(0.2))
                            .foregroundColor(AppTheme.accentBlue)
                            .cornerRadius(4)
                    }
                }
                
                Spacer()
                
                // Amount with appropriate color
                VStack(alignment: .trailing, spacing: 5) {
                    Text(transaction.amount >= 0 ?
                        "+$\(String(format: "%.2f", transaction.amount))" :
                        "-$\(String(format: "%.2f", abs(transaction.amount)))")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(transaction.amount >= 0 ?
                                        AppTheme.primaryGreen :
                                        AppTheme.expenseColor)
                    
                    // Added time information
                    Text(formatTimeOnly(transaction.date))
                        .font(.caption)
                        .foregroundColor(AppTheme.textColor.opacity(0.5))
                }
            }
            .padding()
            .background(AppTheme.cardBackground)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(AppTheme.cardStroke, lineWidth: 1)
            )
        }
    }
    
    // Action buttons row
    private var actionButtonsRow: some View {
        HStack(spacing: 20) {
            // Split button
            Spacer()
            
            actionButton(icon: "arrow.triangle.branch", title: "Split") {
                // Split action
            }
            
            // Categorize button
            actionButton(icon: "tag", title: "Categorize") {
                // Categorize action
            }
            
            // Add note button
            actionButton(icon: "square.and.pencil", title: "Add Note") {
                isAddingNote = true
            }
            
            Spacer()
        }
    }
    
    // Transaction details card
    private var transactionDetails: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Details")
                .font(.headline)
                .foregroundColor(AppTheme.textColor)
                .padding(.bottom, 5)
            
            detailRow(title: "Date",
                    value: formatDate(transaction.date, includeWeekday: true),
                    icon: "calendar")
            
            Divider()
                .background(AppTheme.textColor.opacity(0.1))
            
            detailRow(title: "Account",
                    value: "Account ending in \(transaction.accountId.suffix(4))",
                    icon: "creditcard")
            
            Divider()
                .background(AppTheme.textColor.opacity(0.1))
            
            detailRow(title: "Status",
                    value: transaction.pending ? "Pending" : "Completed",
                    icon: "checkmark.circle")
            
            Divider()
                .background(AppTheme.textColor.opacity(0.1))
            
            detailRow(title: "Transaction ID",
                    value: formatTransactionId(transaction.id),
                    icon: "number")
        }
        .padding()
        .background(AppTheme.cardBackground)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(AppTheme.cardStroke, lineWidth: 1)
        )
    }
    
    // Category section with improved UI
    private var categorySection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Category")
                .font(.headline)
                .foregroundColor(AppTheme.textColor)
            
            HStack {
                ZStack {
                    Circle()
                        .fill(categoryColor(for: transaction.category).opacity(0.2))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: getCategoryIcon(for: transaction.category))
                        .font(.system(size: 20))
                        .foregroundColor(categoryColor(for: transaction.category))
                }
                
                VStack(alignment: .leading, spacing: 3) {
                    Text(transaction.category)
                        .font(.body)
                        .foregroundColor(AppTheme.textColor)
                    
                    // Added budget information
                    Text("15% of monthly budget")
                        .font(.caption)
                        .foregroundColor(AppTheme.textColor.opacity(0.6))
                }
                
                Spacer()
                
                Button(action: {
                    // Change category action
                }) {
                    Text("Change")
                        .font(.subheadline)
                        .foregroundColor(AppTheme.primaryGreen)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(AppTheme.primaryGreen.opacity(0.2))
                        .cornerRadius(12)
                }
            }
            .padding()
            .background(AppTheme.cardBackground)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(AppTheme.cardStroke, lineWidth: 1)
            )
        }
    }
    
    // Payment method section
    private var paymentMethodSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Payment Method")
                .font(.headline)
                .foregroundColor(AppTheme.textColor)
            
            HStack(spacing: 15) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(AppTheme.accentBlue.opacity(0.2))
                        .frame(width: 50, height: 35)
                    
                    Image(systemName: "creditcard.fill")
                        .font(.system(size: 20))
                        .foregroundColor(AppTheme.accentBlue)
                }
                
                VStack(alignment: .leading, spacing: 3) {
                    Text("Debit Card")
                        .font(.body)
                        .foregroundColor(AppTheme.textColor)
                    
                    Text("**** \(transaction.accountId.suffix(4))")
                        .font(.caption)
                        .foregroundColor(AppTheme.textColor.opacity(0.6))
                }
                
                Spacer()
            }
            .padding()
            .background(AppTheme.cardBackground)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(AppTheme.cardStroke, lineWidth: 1)
            )
        }
    }
    
    // Notes section
    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Notes")
                .font(.headline)
                .foregroundColor(AppTheme.textColor)
            
            if isAddingNote {
                // Note editor
                VStack(spacing: 10) {
                    TextField("Add a note about this transaction...", text: $noteText)
                        .padding()
                        .background(AppTheme.cardBackground)
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(AppTheme.cardStroke, lineWidth: 1)
                        )
                    
                    HStack {
                        Button("Cancel") {
                            isAddingNote = false
                            noteText = ""
                        }
                        .foregroundColor(AppTheme.textColor.opacity(0.7))
                        
                        Spacer()
                        
                        Button("Save") {
                            isAddingNote = false
                            // Save note logic would go here
                        }
                        .foregroundColor(AppTheme.primaryGreen)
                        .fontWeight(.semibold)
                    }
                }
            } else {
                // Empty note state or existing note
                Button(action: {
                    isAddingNote = true
                }) {
                    HStack {
                        Image(systemName: "square.and.pencil")
                            .font(.system(size: 20))
                            .foregroundColor(AppTheme.primaryGreen)
                        
                        Text("Add a note")
                            .font(.body)
                            .foregroundColor(AppTheme.primaryGreen)
                        
                        Spacer()
                    }
                    .padding()
                    .background(AppTheme.cardBackground)
                    .cornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(AppTheme.cardStroke, lineWidth: 1)
                    )
                }
            }
        }
    }
    
    // Additional information section
    private var additionalInfo: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Additional Information")
                .font(.headline)
                .foregroundColor(AppTheme.textColor)
            
            VStack(alignment: .leading, spacing: 12) {
                // Transaction processed time
                Text("Transaction processed on \(formatDate(transaction.date, includeTime: true))")
                    .font(.body)
                    .foregroundColor(AppTheme.textColor.opacity(0.7))
                
                Divider()
                    .background(AppTheme.textColor.opacity(0.1))
                
                // Transaction type
                HStack {
                    Text("Transaction Type:")
                        .font(.subheadline)
                        .foregroundColor(AppTheme.textColor.opacity(0.7))
                    
                    Spacer()
                    
                    Text(transaction.amount >= 0 ? "Expense" : "Income")
                        .font(.subheadline)
                        .foregroundColor(AppTheme.textColor)
                }
                
                Divider()
                    .background(AppTheme.textColor.opacity(0.1))
                
                // Reference number
                HStack {
                    Text("Reference Number:")
                        .font(.subheadline)
                        .foregroundColor(AppTheme.textColor.opacity(0.7))
                    
                    Spacer()
                    
                    Text("REF-\(transaction.id.prefix(6))")
                        .font(.subheadline)
                        .foregroundColor(AppTheme.textColor)
                }
                
                // Add dispute button
                Button(action: {
                    // Dispute action would go here
                }) {
                    HStack {
                        Image(systemName: "exclamationmark.triangle")
                            .foregroundColor(AppTheme.expenseColor)
                        
                        Text("Report an issue with this transaction")
                            .font(.subheadline)
                            .foregroundColor(AppTheme.expenseColor)
                    }
                    .padding(.top, 10)
                }
            }
            .padding()
            .background(AppTheme.cardBackground)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(AppTheme.cardStroke, lineWidth: 1)
            )
        }
    }
    
    // Similar transactions section
    private var similarTransactionsSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Similar Transactions")
                .font(.headline)
                .foregroundColor(AppTheme.textColor)
            
            VStack(spacing: 12) {
                // Create a couple mock similar transactions
                similarTransactionRow(
                    merchantName: transaction.merchantName,
                    amount: transaction.amount * 0.9,
                    date: Calendar.current.date(byAdding: .day, value: -14, to: transaction.date) ?? transaction.date
                )
                
                Divider()
                    .background(AppTheme.textColor.opacity(0.1))
                
                similarTransactionRow(
                    merchantName: transaction.merchantName,
                    amount: transaction.amount * 1.1,
                    date: Calendar.current.date(byAdding: .day, value: -28, to: transaction.date) ?? transaction.date
                )
                
                Button(action: {
                    // View all action
                }) {
                    Text("View All Similar Transactions")
                        .font(.subheadline)
                        .foregroundColor(AppTheme.accentBlue)
                        .padding(.top, 5)
                }
            }
            .padding()
            .background(AppTheme.cardBackground)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(AppTheme.cardStroke, lineWidth: 1)
            )
        }
    }
    
    // Action button helper
    private func actionButton(icon: String, title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 22))
                    .foregroundColor(AppTheme.primaryGreen)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(AppTheme.textColor)
            }
            .frame(width: 75)
            .padding(.vertical, 12)
            .background(AppTheme.cardBackground)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(AppTheme.cardStroke, lineWidth: 1)
            )
        }
    }
    
    // Helper view for detail rows
    private func detailRow(title: String, value: String, icon: String) -> some View {
        HStack(spacing: 15) {
            Image(systemName: icon)
                .foregroundColor(AppTheme.accentBlue)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(AppTheme.textColor.opacity(0.7))
                
                Text(value)
                    .font(.body)
                    .foregroundColor(AppTheme.textColor)
            }
            
            Spacer()
        }
    }
    
    // Similar transaction row helper
    private func similarTransactionRow(merchantName: String, amount: Double, date: Date) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(merchantName)
                    .font(.body)
                    .foregroundColor(AppTheme.textColor)
                
                Text(formatDate(date, shortFormat: true))
                    .font(.caption)
                    .foregroundColor(AppTheme.textColor.opacity(0.6))
            }
            
            Spacer()
            
            Text(amount >= 0 ?
                "+$\(String(format: "%.2f", amount))" :
                "-$\(String(format: "%.2f", abs(amount)))")
                .font(.body)
                .foregroundColor(amount >= 0 ?
                                AppTheme.primaryGreen :
                                AppTheme.expenseColor)
        }
    }
    
    // Helper functions
    private func formatDate(_ date: Date, includeTime: Bool = false, includeWeekday: Bool = false, shortFormat: Bool = false) -> String {
        let formatter = DateFormatter()
        
        if shortFormat {
            formatter.dateFormat = "MMM d, yyyy"
            return formatter.string(from: date)
        }
        
        if includeTime {
            formatter.dateFormat = "MMM d, yyyy 'at' h:mm a"
            return formatter.string(from: date)
        }
        
        if includeWeekday {
            formatter.dateFormat = "EEEE, MMMM d, yyyy"
            return formatter.string(from: date)
        }
        
        formatter.dateFormat = "MMMM d, yyyy"
        return formatter.string(from: date)
    }
    
    private func formatTimeOnly(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }
    
    private func formatTransactionId(_ id: String) -> String {
        // Return last 8 characters or just use the full ID if it's short
        if id.count > 8 {
            return "..." + String(id.suffix(8))
        }
        return id
    }
    
    // Helper function to determine icon based on category
    private func getCategoryIcon(for category: String) -> String {
        let lowercaseCategory = category.lowercased()
        
        if lowercaseCategory.contains("food") || lowercaseCategory.contains("restaurant") {
            return "fork.knife"
        } else if lowercaseCategory.contains("shop") || lowercaseCategory.contains("store") {
            return "cart"
        } else if lowercaseCategory.contains("transport") || lowercaseCategory.contains("travel") {
            return "car.fill"
        } else if lowercaseCategory.contains("entertainment") || lowercaseCategory.contains("recreation") {
            return "play.tv"
        } else if lowercaseCategory.contains("health") || lowercaseCategory.contains("medical") {
            return "heart.fill"
        } else if lowercaseCategory.contains("utility") || lowercaseCategory.contains("bill") {
            return "bolt.fill"
        } else if lowercaseCategory.contains("income") || lowercaseCategory.contains("deposit") {
            return "arrow.down.circle.fill"
        } else {
            return "dollarsign.circle"
        }
    }
    
    // Helper function to get color for category
    private func categoryColor(for category: String) -> Color {
        let lowercaseCategory = category.lowercased()
        
        if lowercaseCategory.contains("food") || lowercaseCategory.contains("restaurant") {
            return AppTheme.primaryGreen
        } else if lowercaseCategory.contains("shop") || lowercaseCategory.contains("retail") {
            return AppTheme.accentBlue
        } else if lowercaseCategory.contains("transport") || lowercaseCategory.contains("travel") {
            return AppTheme.accentPurple
        } else if lowercaseCategory.contains("entertainment") || lowercaseCategory.contains("leisure") {
            return Color(hex: "#FFD700").opacity(0.8)
        } else if lowercaseCategory.contains("health") || lowercaseCategory.contains("medical") {
            return Color(hex: "#FF5757")
        } else if lowercaseCategory.contains("utility") || lowercaseCategory.contains("bill") {
            return Color(hex: "#9370DB")
        } else if lowercaseCategory.contains("income") || lowercaseCategory.contains("deposit") {
            return AppTheme.primaryGreen
        } else {
            return AppTheme.accentBlue
        }
    }
}
