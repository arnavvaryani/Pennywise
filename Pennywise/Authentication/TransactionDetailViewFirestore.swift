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

// MARK: - TransactionDetailViewFirestore
// Enhanced TransactionDetailView that supports Firestore features

struct TransactionDetailViewFirestore: View {
    let transaction: PlaidTransaction
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var plaidManager: PlaidManager
    
    // Add these state variables for Firestore integration
    @State private var isLoading = true
    @State private var showShareSheet = false
    @State private var isAddingNote = false
    @State private var noteText = ""
    @State private var transactionNotes = ""
    @State private var transactionTags: [String] = []
    @State private var newTag = ""
    @State private var isAddingTag = false
    @State private var isEditingCategory = false
    @State private var selectedCategory = ""
    @State private var showingSimilarTransactions = false
    @State private var similarTransactions: [PlaidTransaction] = []
    
    // Categories for selection
    private let categories = [
        "Food & Dining", "Shopping", "Transportation", "Entertainment",
        "Bills & Utilities", "Health & Medical", "Travel", "Education",
        "Groceries", "Personal Care", "Home", "Gifts & Donations",
        "Income", "Transfer", "Fees & Charges", "Other"
    ]
    
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
                            
                            // Tags section (new)
                            tagsSection
                            
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
                        
                        Button(action: {
                            // Hide transaction
                            hideTransaction()
                        }) {
                            Label("Hide Transaction", systemImage: "eye.slash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
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
        .sheet(isPresented: $showShareSheet) {
            // Share sheet would go here
            shareTransactionSheet
        }
        .sheet(isPresented: $showingSimilarTransactions) {
            // Similar transactions view
            SimilarTransactionsView(transactions: similarTransactions)
        }
        .sheet(isPresented: $isEditingCategory) {
            // Category selection sheet
            categorySelectionSheet
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
                
                if let tags = document.data()?["tags"] as? [String] {
                    self.transactionTags = tags
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
    
    /// Save transaction notes to Firestore
    private func saveTransactionNotes() {
        guard !noteText.isEmpty else { return }
        
        PlaidFirestoreSync.shared.updateTransactionDetails(
            transaction: transaction,
            notes: noteText,
            tags: nil,
            isHidden: nil
        ) { success in
            if success {
                // Update local state
                transactionNotes = noteText
                noteText = ""
                isAddingNote = false
            }
        }
    }
    
    /// Add a tag to the transaction
    private func addTransactionTag() {
        guard !newTag.isEmpty else { return }
        
        // Prevent duplicate tags
        if !transactionTags.contains(newTag) {
            var updatedTags = transactionTags
            updatedTags.append(newTag)
            
            PlaidFirestoreSync.shared.updateTransactionDetails(
                transaction: transaction,
                notes: nil,
                tags: updatedTags,
                isHidden: nil
            ) { success in
                if success {
                    // Update local state
                    transactionTags = updatedTags
                    newTag = ""
                    isAddingTag = false
                }
            }
        } else {
            // Tag already exists
            newTag = ""
            isAddingTag = false
        }
    }
    
    /// Remove a tag from the transaction
    private func removeTag(_ tag: String) {
        var updatedTags = transactionTags
        updatedTags.removeAll { $0 == tag }
        
        PlaidFirestoreSync.shared.updateTransactionDetails(
            transaction: transaction,
            notes: nil,
            tags: updatedTags,
            isHidden: nil
        ) { success in
            if success {
                // Update local state
                transactionTags = updatedTags
            }
        }
    }
    
    /// Update transaction category
    private func updateTransactionCategory() {
        PlaidFirestoreSync.shared.updateTransactionCategory(
            transaction: transaction,
            newCategory: selectedCategory
        ) { success in
            if success {
                // Category updated successfully
            }
        }
    }
    
    /// Hide this transaction
    private func hideTransaction() {
        PlaidFirestoreSync.shared.updateTransactionDetails(
            transaction: transaction,
            notes: nil,
            tags: nil,
            isHidden: true
        ) { success in
            if success {
                // Dismiss the view
                presentationMode.wrappedValue.dismiss()
            }
        }
    }
    
    /// Find similar transactions
    private func findSimilarTransactions() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        let db = Firestore.firestore()
        
        // Query for transactions with the same merchant name or category
        db.collection("users/\(userId)/transactions")
            .whereField("merchantName", isEqualTo: transaction.merchantName)
            .whereField("id", isNotEqualTo: transaction.id) // Exclude current transaction
            .limit(to: 5)
            .getDocuments { (snapshot, error) in
                if let error = error {
                    print("Error finding similar transactions: \(error.localizedDescription)")
                    return
                }
                
                if let documents = snapshot?.documents {
                    self.similarTransactions = documents.compactMap { document -> PlaidTransaction? in
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
    
    // Action buttons row
    private var actionButtonsRow: some View {
        HStack(spacing: 20) {
            Spacer()
            
            // Split button
            actionButton(icon: "arrow.triangle.branch", title: "Split") {
                // Split action
            }
            
            // Categorize button
            actionButton(icon: "tag", title: "Categorize") {
                isEditingCategory = true
            }
            
            // Add note button
            actionButton(icon: "square.and.pencil", title: "Add Note") {
                isAddingNote = true
            }
            
            Spacer()
        }
    }
    
    // Tags section
    private var tagsSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Tags")
                .font(.headline)
                .foregroundColor(AppTheme.textColor)
            
            VStack(alignment: .leading, spacing: 15) {
                // Show existing tags
                if !transactionTags.isEmpty {
                    // Wrap tags in a flow layout
                    FlowLayout(spacing: 8) {
                        ForEach(transactionTags, id: \.self) { tag in
                            tagView(tag: tag)
                        }
                    }
                }
                
                // Add tag button or tag editor
                if isAddingTag {
                    HStack {
                        TextField("New tag", text: $newTag)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(AppTheme.cardBackground)
                            .cornerRadius(8)
                            .foregroundColor(AppTheme.textColor)
                        
                        Button(action: addTransactionTag) {
                            Text("Add")
                                .foregroundColor(AppTheme.primaryGreen)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                        }
                        
                        Button(action: { isAddingTag = false }) {
                            Text("Cancel")
                                .foregroundColor(AppTheme.textColor.opacity(0.7))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                        }
                    }
                } else {
                    Button(action: { isAddingTag = true }) {
                        HStack {
                            Image(systemName: "plus")
                                .font(.system(size: 14))
                            
                            Text("Add Tag")
                                .font(.subheadline)
                        }
                        .foregroundColor(AppTheme.primaryGreen)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 16)
                        .background(AppTheme.primaryGreen.opacity(0.2))
                        .cornerRadius(20)
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
                    
                    // Added budget information
                    Text("15% of monthly budget")
                        .font(.caption)
                        .foregroundColor(AppTheme.textColor.opacity(0.6))
                }
                
                Spacer()
                
                Button(action: {
                    isEditingCategory = true
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
                    TextEditor(text: $noteText)
                        .padding()
                        .frame(minHeight: 100)
                        .background(AppTheme.cardBackground)
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(AppTheme.cardStroke, lineWidth: 1)
                        )
                        .foregroundColor(AppTheme.textColor)
                    
                    HStack {
                        Button(action: { isAddingNote = false }) {
                            Text("Cancel")
                                .foregroundColor(AppTheme.textColor.opacity(0.7))
                        }
                        
                        Spacer()
                        
                        Button(action: saveTransactionNotes) {
                            Text("Save")
                                .foregroundColor(AppTheme.primaryGreen)
                                .fontWeight(.semibold)
                        }
                    }
                }
            } else if !transactionNotes.isEmpty {
                // Show existing note
                VStack(alignment: .leading) {
                    Text(transactionNotes)
                        .foregroundColor(AppTheme.textColor)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    HStack {
                        Spacer()
                        
                        Button(action: {
                            noteText = transactionNotes
                            isAddingNote = true
                        }) {
                            Text("Edit")
                                .font(.caption)
                                .foregroundColor(AppTheme.primaryGreen)
                        }
                        .padding(8)
                    }
                }
                .background(AppTheme.cardBackground)
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(AppTheme.cardStroke, lineWidth: 1)
                )
            } else {
                // Empty note state
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
                if similarTransactions.isEmpty {
                    // Empty state
                    HStack {
                        Spacer()
                        
                        Text("No similar transactions found")
                            .font(.subheadline)
                            .foregroundColor(AppTheme.textColor.opacity(0.7))
                            .padding()
                        
                        Spacer()
                    }
                } else {
                    // Show up to 2 similar transactions
                    ForEach(similarTransactions.prefix(2), id: \.id) { transaction in
                        similarTransactionRow(
                            merchantName: transaction.merchantName,
                            amount: transaction.amount,
                            date: transaction.date
                        )
                        
                        if transaction.id != similarTransactions.prefix(2).last?.id {
                            Divider()
                                .background(AppTheme.textColor.opacity(0.1))
                        }
                    }
                    
                    // Show button to view all if there are more than 2
                    if similarTransactions.count > 2 {
                        Button(action: {
                            showingSimilarTransactions = true
                        }) {
                            Text("View All Similar Transactions")
                                .font(.subheadline)
                                .foregroundColor(AppTheme.accentBlue)
                                .padding(.top, 5)
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
    
    // Share Transaction Sheet
    private var shareTransactionSheet: some View {
        VStack(spacing: 25) {
            // Header
            Text("Share Transaction")
                .font(.title2)
                .fontWeight(.bold)
                .padding(.top)
            
            // Transaction summary
            VStack(spacing: 15) {
                HStack {
                    Text(transaction.merchantName)
                        .font(.headline)
                    
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
                        .foregroundColor(.gray)
                    
                    Spacer()
                    
                    Text(selectedCategory)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(12)
            
            // Share options
            Text("Share via")
                .font(.headline)
                .padding(.top)
            
            HStack(spacing: 30) {
                shareOption(title: "Message", icon: "message.fill", color: .blue)
                shareOption(title: "Mail", icon: "envelope.fill", color: .red)
                shareOption(title: "Notes", icon: "note.text", color: .yellow)
                shareOption(title: "Copy", icon: "doc.on.doc", color: .gray)
            }
            .padding(.bottom)
            
            // Include details checkbox
            Toggle("Include transaction details", isOn: .constant(true))
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
            
            // Cancel button
            Button("Cancel") {
                showShareSheet = false
            }
            .foregroundColor(.red)
            .padding(.vertical)
            .padding(.bottom, 20)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .presentationDetents([.medium])
    }
    
    // Helper for share options
    private func shareOption(title: String, icon: String, color: Color) -> some View {
        Button(action: {
            // Share action
            showShareSheet = false
        }) {
            VStack {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.2))
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: icon)
                        .font(.system(size: 28))
                        .foregroundColor(color)
                }
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.primary)
            }
        }
    }
    
    // Category selection sheet
    private var categorySelectionSheet: some View {
        NavigationView {
            ZStack {
                AppTheme.backgroundGradient
                    .edgesIgnoringSafeArea(.all)
                
                List {
                    ForEach(categories, id: \.self) { category in
                        Button(action: {
                            selectedCategory = category
                            isEditingCategory = false
                            updateTransactionCategory()
                        }) {
                            HStack {
                                Image(systemName: getCategoryIcon(for: category))
                                    .foregroundColor(categoryColor(for: category))
                                    .frame(width: 30)
                                
                                Text(category)
                                    .foregroundColor(AppTheme.textColor)
                                
                                Spacer()
                                
                                if category == selectedCategory {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(AppTheme.primaryGreen)
                                }
                            }
                            .padding(.vertical, 8)
                        }
                    }
                }
                .listStyle(InsetGroupedListStyle())
            }
            .navigationTitle("Select Category")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        isEditingCategory = false
                    }
                    .foregroundColor(AppTheme.primaryGreen)
                }
            }
        }
    }
    
    // MARK: - Helper Views
    
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
    
    // Tag view for a single tag
    private func tagView(tag: String) -> some View {
        HStack(spacing: 4) {
            Text(tag)
                .font(.caption)
                .foregroundColor(AppTheme.textColor)
                .padding(.leading, 8)
                .padding(.vertical, 4)
            
            Button(action: {
                removeTag(tag)
            }) {
                Image(systemName: "xmark")
                    .font(.system(size: 8))
                    .foregroundColor(AppTheme.textColor.opacity(0.7))
                    .padding(4)
            }
        }
        .background(AppTheme.cardBackground.opacity(0.5))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(AppTheme.cardStroke, lineWidth: 1)
        )
        .cornerRadius(12)
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
    
    // MARK: - Helper Methods
    
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
    
    // Helper function to get color for category
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
