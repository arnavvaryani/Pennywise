//
//  TransactionDetailView+Firestore.swift
//  Pennywise
//
//  Created for Pennywise App
//

import SwiftUI
import Firebase
import FirebaseFirestore
import FirebaseAuth

struct TransactionDetailViewFirestore: View {
    let transaction: PlaidTransaction
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var plaidManager: PlaidManager
    
    // State variables for Firestore integration
    @State private var isLoading = true
    @State private var transactionNotes = ""
    @State private var selectedCategory = ""
    @State private var similarTransactions: [PlaidTransaction] = []
    
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
                        VStack(spacing: 20) {
                            // Transaction header
                            transactionHeader
                            
                            // Details card
                            transactionDetails
                            
                            // Category information
                            categorySection
                            
                            // Payment method section
                            paymentMethodSection
                            
                            // Notes section (simplified)
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
            }
            .onAppear {
                // Fetch transaction details from Firestore
                loadTransactionDetails()
                // Find similar transactions
                findSimilarTransactions()
            }
        }
    }
    
    // MARK: - Firestore Integration Methods
    
    /// Load transaction details from Firestore
    private func loadTransactionDetails() {
        guard let userId = Auth.auth().currentUser?.uid else {
            isLoading = false
            return
        }
        
        let db = Firestore.firestore()
        let transactionRef = db.collection("users/\(userId)/transactions").document(transaction.id)
        
        transactionRef.getDocument { (document, error) in
            if let document = document, document.exists {
                // Extract data from Firestore
                if let notes = document.data()?["notes"] as? String {
                    self.transactionNotes = notes
                }
                
                if let category = document.data()?["category"] as? String {
                    self.selectedCategory = category
                } else {
                    self.selectedCategory = self.transaction.category
                }
            } else {
                // Set default values from transaction
                self.selectedCategory = self.transaction.category
            }
            
            self.isLoading = false
        }
    }
    
    /// Find similar transactions
    private func findSimilarTransactions() {
        // First try to find from Firestore
        findSimilarTransactionsFromFirestore()
        
        // Also find from local transactions as a fallback
        findSimilarTransactionsLocally()
    }
    
    /// Find similar transactions from Firestore
    private func findSimilarTransactionsFromFirestore() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        let db = Firestore.firestore()
        
        // Query for transactions with the same merchant name or category
        let merchantQuery = db.collection("users/\(userId)/transactions")
            .whereField("merchantName", isEqualTo: transaction.merchantName)
            .whereField("id", isNotEqualTo: transaction.id)
            .limit(to: 5)
        
        merchantQuery.getDocuments { (snapshot, error) in
            if let error = error {
                print("Error finding similar transactions: \(error.localizedDescription)")
                return
            }
            
            if let documents = snapshot?.documents, !documents.isEmpty {
                let transactions = self.parseFirestoreTransactions(documents)
                
                // If we found transactions with the same merchant name, use those
                if !transactions.isEmpty {
                    DispatchQueue.main.async {
                        self.similarTransactions = transactions
                    }
                    return
                }
            }
            
            // If no merchant matches, try to find by category
            let categoryQuery = db.collection("users/\(userId)/transactions")
                .whereField("category", isEqualTo: self.transaction.category)
                .whereField("id", isNotEqualTo: self.transaction.id)
                .limit(to: 5)
            
            categoryQuery.getDocuments { (snapshot, error) in
                if let error = error {
                    print("Error finding category transactions: \(error.localizedDescription)")
                    return
                }
                
                if let documents = snapshot?.documents {
                    let transactions = self.parseFirestoreTransactions(documents)
                    
                    DispatchQueue.main.async {
                        self.similarTransactions = transactions
                    }
                }
            }
        }
    }
    
    /// Parse Firestore documents into PlaidTransaction objects
    private func parseFirestoreTransactions(_ documents: [QueryDocumentSnapshot]) -> [PlaidTransaction] {
        return documents.compactMap { document -> PlaidTransaction? in
            guard
                let name = document.data()["name"] as? String,
                let amount = document.data()["amount"] as? Double,
                let dateTimestamp = document.data()["date"] as? Timestamp,
                let category = document.data()["category"] as? String,
                let merchantName = document.data()["merchantName"] as? String,
                let accountId = document.data()["accountId"] as? String,
                let pending = document.data()["pending"] as? Bool
            else {
                return nil
            }
            
            return PlaidTransaction(
                id: document.documentID,
                name: name,
                amount: amount,
                date: dateTimestamp.dateValue(),
                category: category,
                merchantName: merchantName,
                accountId: accountId,
                pending: pending
            )
        }
    }
    
    /// Find similar transactions locally as fallback
    private func findSimilarTransactionsLocally() {
        // If we already found transactions from Firestore, don't override
        if !similarTransactions.isEmpty {
            return
        }
        
        // First try to find transactions with the same merchant name
        let merchantMatches = plaidManager.transactions.filter {
            $0.id != transaction.id &&
            $0.merchantName.lowercased() == transaction.merchantName.lowercased()
        }
        
        if !merchantMatches.isEmpty {
            DispatchQueue.main.async {
                self.similarTransactions = Array(merchantMatches.prefix(5))
            }
            return
        }
        
        // If no merchant matches, try to find by category
        let categoryMatches = plaidManager.transactions.filter {
            $0.id != transaction.id &&
            $0.category.lowercased() == transaction.category.lowercased()
        }
        
        DispatchQueue.main.async {
            self.similarTransactions = Array(categoryMatches.prefix(5))
        }
    }
    
    // MARK: - UI Components
    
    // Transaction header with date information
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
                    
                    Text(selectedCategory)
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
    
    // Category section
    private var categorySection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Category")
                .font(.headline)
                .foregroundColor(AppTheme.textColor)
            
            HStack {
                ZStack {
                    Circle()
                        .fill(categoryColor(for: selectedCategory).opacity(0.2))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: getCategoryIcon(for: selectedCategory))
                        .font(.system(size: 20))
                        .foregroundColor(categoryColor(for: selectedCategory))
                }
                
                VStack(alignment: .leading, spacing: 3) {
                    Text(selectedCategory)
                        .font(.body)
                        .foregroundColor(AppTheme.textColor)
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
    
    // Simplified notes section
    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Notes")
                .font(.headline)
                .foregroundColor(AppTheme.textColor)
            
            if !transactionNotes.isEmpty {
                // Show existing note
                VStack(alignment: .leading) {
                    Text(transactionNotes)
                        .foregroundColor(AppTheme.textColor)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .background(AppTheme.cardBackground)
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(AppTheme.cardStroke, lineWidth: 1)
                )
            } else {
                // Empty note state
                Text("No notes for this transaction")
                    .font(.subheadline)
                    .foregroundColor(AppTheme.textColor.opacity(0.6))
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .center)
                    .background(AppTheme.cardBackground)
                    .cornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(AppTheme.cardStroke, lineWidth: 1)
                    )
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
    
    // Similar transactions section - enhanced to show by category or merchant
    private var similarTransactionsSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Similar Transactions")
                .font(.headline)
                .foregroundColor(AppTheme.textColor)
            
            VStack(spacing: 12) {
                if similarTransactions.isEmpty {
                    // Empty state
                    Text("No similar transactions found")
                        .font(.subheadline)
                        .foregroundColor(AppTheme.textColor.opacity(0.7))
                        .padding()
                        .frame(maxWidth: .infinity)
                } else {
                    // Show similar transactions
                    ForEach(similarTransactions) { tx in
                        similarTransactionRow(transaction: tx)
                        
                        if tx.id != similarTransactions.last?.id {
                            Divider()
                                .background(AppTheme.textColor.opacity(0.1))
                        }
                    }
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
    
    // MARK: - Helper Views
    
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
    
    // Similar transaction row
    private func similarTransactionRow(transaction: PlaidTransaction) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(transaction.merchantName)
                    .font(.body)
                    .foregroundColor(AppTheme.textColor)
                
                HStack {
                    Text(formatDate(transaction.date, shortFormat: true))
                        .font(.caption)
                        .foregroundColor(AppTheme.textColor.opacity(0.6))
                    
                    Spacer()
                    
                    Text(transaction.category)
                        .font(.caption)
                        .foregroundColor(categoryColor(for: transaction.category))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(categoryColor(for: transaction.category).opacity(0.2))
                        .cornerRadius(4)
                }
            }
            
            Spacer()
            
            Text(transaction.amount >= 0 ?
                "+$\(String(format: "%.2f", transaction.amount))" :
                "-$\(String(format: "%.2f", abs(transaction.amount)))")
                .font(.body)
                .foregroundColor(transaction.amount >= 0 ?
                                AppTheme.primaryGreen :
                                AppTheme.expenseColor)
        }
    }
    
    // MARK: - Helper Methods
    
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
        if id.count > 8 {
            return "..." + String(id.suffix(8))
        }
        return id
    }
    
    // Helper function to determine icon based on category
    private func getCategoryIcon(for category: String) -> String {
        let lowercaseCategory = category.lowercased()
        
        if lowercaseCategory.contains("food") || lowercaseCategory.contains("restaurant") || lowercaseCategory.contains("dining") {
            return "fork.knife"
        } else if lowercaseCategory.contains("shop") || lowercaseCategory.contains("store") || lowercaseCategory.contains("retail") {
            return "cart"
        } else if lowercaseCategory.contains("transport") || lowercaseCategory.contains("travel") || lowercaseCategory.contains("uber") {
            return "car.fill"
        } else if lowercaseCategory.contains("entertainment") || lowercaseCategory.contains("recreation") {
            return "play.tv"
        } else if lowercaseCategory.contains("health") || lowercaseCategory.contains("medical") {
            return "heart.fill"
        } else if lowercaseCategory.contains("utility") || lowercaseCategory.contains("bill") {
            return "bolt.fill"
        } else if lowercaseCategory.contains("income") || lowercaseCategory.contains("deposit") {
            return "arrow.down.circle.fill"
        } else if lowercaseCategory.contains("education") || lowercaseCategory.contains("school") {
            return "book.fill"
        } else if lowercaseCategory.contains("home") || lowercaseCategory.contains("housing") || lowercaseCategory.contains("rent") {
            return "house.fill"
        } else if lowercaseCategory.contains("personal") || lowercaseCategory.contains("care") {
            return "person.fill"
        } else if lowercaseCategory.contains("gift") || lowercaseCategory.contains("donation") {
            return "gift.fill"
        } else if lowercaseCategory.contains("fee") || lowercaseCategory.contains("charge") {
            return "creditcard.fill"
        } else {
            return "dollarsign.circle"
        }
    }
    
    private func categoryColor(for category: String) -> Color {
        let lowercaseCategory = category.lowercased()
        
        if lowercaseCategory.contains("food") || lowercaseCategory.contains("restaurant") || lowercaseCategory.contains("dining") {
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
        } else if lowercaseCategory.contains("education") {
            return Color(hex: "#20B2AA")
        } else if lowercaseCategory.contains("home") || lowercaseCategory.contains("housing") {
            return Color(hex: "#FF8C00")
        } else {
            return AppTheme.accentBlue
        }
    }
}
// MARK: - Similar Transactions View

struct SimilarTransactionsView: View {
    let transactions: [PlaidTransaction]
    @Environment(\.presentationMode) private var presentationMode
    
    var body: some View {
        NavigationView {
            ZStack {
                AppTheme.backgroundGradient
                    .edgesIgnoringSafeArea(.all)
                
                if transactions.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "doc.text.magnifyingglass")
                            .font(.system(size: 50))
                            .foregroundColor(AppTheme.accentBlue.opacity(0.7))
                        
                        Text("No similar transactions found")
                            .font(.headline)
                            .foregroundColor(AppTheme.textColor)
                        
                        Text("There are no other transactions with this merchant.")
                            .font(.subheadline)
                            .foregroundColor(AppTheme.textColor.opacity(0.7))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                } else {
                    List {
                        ForEach(transactions) { transaction in
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Text(transaction.merchantName)
                                        .font(.headline)
                                        .foregroundColor(AppTheme.textColor)
                                    
                                    Spacer()
                                    
                                    Text(transaction.amount >= 0 ?
                                        "+$\(String(format: "%.2f", transaction.amount))" :
                                        "-$\(String(format: "%.2f", abs(transaction.amount)))")
                                        .font(.headline)
                                        .foregroundColor(transaction.amount >= 0 ?
                                                       AppTheme.primaryGreen :
                                                       AppTheme.expenseColor)
                                }
                                
                                HStack {
                                    Text(formatDate(transaction.date))
                                        .font(.subheadline)
                                        .foregroundColor(AppTheme.textColor.opacity(0.7))
                                    
                                    Spacer()
                                    
                                    Text(transaction.category)
                                        .font(.caption)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 2)
                                        .background(categoryColor(for: transaction.category).opacity(0.2))
                                        .foregroundColor(categoryColor(for: transaction.category))
                                        .cornerRadius(4)
                                }
                            }
                            .padding(.vertical, 6)
                        }
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .navigationTitle("Similar Transactions")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(AppTheme.primaryGreen)
                }
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: date)
    }
    
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

// MARK: - Flow Layout for Tags

struct FlowLayout: Layout {
    var spacing: CGFloat
    
    init(spacing: CGFloat = 8) {
        self.spacing = spacing
    }
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? .infinity
        
        var height: CGFloat = 0
        var rowWidth: CGFloat = 0
        var rowHeight: CGFloat = 0
        
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            
            if rowWidth + size.width > width {
                // Start a new row
                height += rowHeight + spacing
                rowWidth = size.width
                rowHeight = size.height
            } else {
                // Add to current row
                rowWidth += size.width + spacing
                rowHeight = max(rowHeight, size.height)
            }
        }
        
        // Add the last row's height
        height += rowHeight
        
        return CGSize(width: width, height: height)
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let width = bounds.width
        
        var rowX: CGFloat = bounds.minX
        var rowY: CGFloat = bounds.minY
        var rowHeight: CGFloat = 0
        
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            
            if rowX + size.width > width {
                // Start a new row
                rowX = bounds.minX
                rowY += rowHeight + spacing
                rowHeight = 0
            }
            
            subview.place(at: CGPoint(x: rowX, y: rowY), proposal: ProposedViewSize(size))
            
            rowX += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}

// Extension for String to get the first 6 characters
extension String {
    var prefix6: String {
        return String(prefix(6))
    }
}
