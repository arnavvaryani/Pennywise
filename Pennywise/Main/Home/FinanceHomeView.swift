//
//  FinanceHomeView.swift
//  Pennywise
//
//  Created by Arnav Varyani on 4/8/25.
//


import SwiftUI
import FirebaseAuth
import FirebaseFirestore


struct FinanceHomeView: View {
    @StateObject private var authService = AuthenticationService.shared
    @EnvironmentObject var plaidManager: PlaidManager
    
    @State private var showNewTransaction: Bool = false
    @State private var hideBalance: Bool = false
    @State private var selectedCurrencyIndex: Int = 0
    @State private var showProfileSheet: Bool = false
    @State private var isRefreshing: Bool = false
    @State private var animateBalance: Bool = false
    @State private var showAllTransactions: Bool = false
    
    @State private var cardOffset: CGFloat = 1000
    @State private var opacity: Double = 0
    @State private var scale: CGFloat = 0.8
    
    @State private var selectedAccount: PlaidAccount? = nil
    @State private var showAccountDetails: Bool = false
    
    // State to track which transactions were manually added
    @State private var manualTransactionIds: Set<String> = []
    
    var totalBalance: Double {
        plaidManager.accounts.reduce(0) { $0 + $1.balance }
    }
    
    var totalIncome: Double {
        let incomeTransactions = plaidManager.transactions.filter { $0.amount < 0 }
        return abs(incomeTransactions.reduce(0) { $0 + $1.amount })
    }
    
    var totalExpenses: Double {
        let expenseTransactions = plaidManager.transactions.filter { $0.amount > 0 }
        return expenseTransactions.reduce(0) { $0 + $1.amount }
    }
    
    var userName: String {
        authService.user?.displayName ?? "User"
    }
    
    // Get transactions for the current month
    var currentMonthTransactions: [PlaidTransaction] {
        let calendar = Calendar.current
        let now = Date()
        let month = calendar.component(.month, from: now)
        let year = calendar.component(.year, from: now)
        
        return plaidManager.transactions.filter { transaction in
            let transactionMonth = calendar.component(.month, from: transaction.date)
            let transactionYear = calendar.component(.year, from: transaction.date)
            return transactionMonth == month && transactionYear == year
        }
    }
    
    // MARK: - Main View
    var body: some View {
        ZStack {
            // Background gradient from the theme
            AppTheme.backgroundGradient
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 0) {
                // Main content
                if showAllTransactions {
                    allTransactionsView
                } else {
                    mainScrollView
                }
            }
        }
        .sheet(isPresented: $showNewTransaction) {
            TransactionView(isPresented: $showNewTransaction, onSave: addTransaction)
        }
        .sheet(isPresented: $showProfileSheet) {
            profileSheetView
        }
        .sheet(item: $selectedTransaction) { transaction in
               // Check if this is a manual transaction before showing detail view
               if manualTransactionIds.contains(transaction.id) {
                   ManualTransactionDetailView(transaction: transaction)
                       .environmentObject(plaidManager)
               } else {
                   TransactionDetailViewFirestore(transaction: transaction)
                       .environmentObject(plaidManager)
               }
           }
        .sheet(item: $selectedAccount) { account in
            AccountDetailView(account: account)
                .environmentObject(plaidManager)
        }

        .onAppear {
            // Load previously stored manual transaction IDs
            loadManualTransactionIds()
            
            // Fetch data when view appears if we haven't already
            if plaidManager.transactions.isEmpty {
                plaidManager.fetchTransactions()
            }
            
            // Initialize animations
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1)) {
                cardOffset = 0
                opacity = 1
                scale = 1
            }
            
            withAnimation(.spring(response: 0.8, dampingFraction: 0.8).delay(0.3)) {
                animateBalance = true
            }
        }
    }
    
    // State for transaction detail sheet
    @State private var selectedTransaction: PlaidTransaction? = nil
    @State private var showTransactionDetail: Bool = false
    
    // MARK: - Subviews

    private func calculateTotalDebt() -> Double {
        // Implement your debt calculation logic
        // This is a placeholder - replace with actual debt calculation
        return plaidManager.transactions
            .filter { $0.category.lowercased().contains("debt") }
            .reduce(0) { $0 + abs($1.amount) }
    }

    private func calculateTotalInvestments() -> Double {
        // Implement your investments calculation logic
        // This is a placeholder - replace with actual investments calculation
        return plaidManager.transactions
            .filter { $0.category.lowercased().contains("investment") }
            .reduce(0) { $0 + abs($1.amount) }
    }
    
    // Main scrollable content
    private var mainScrollView: some View {
        ScrollView {
            VStack(spacing: 18) {
                // Main balance card
                balanceCardView
                    .padding(.horizontal)
                    .padding(.top, 10)
                    .offset(y: cardOffset)
                    .opacity(opacity)
                    .scaleEffect(scale)
                
                // Latest transactions section
                transactionsSection
                
                // Accounts section if we have any
                if !plaidManager.accounts.isEmpty {
                    accountsSection
                }
                
                // Spacer that pushes content up
                Spacer()
                    .frame(height: 50)
            }
        }
        // Removed refreshable modifier
    }
    
    private var balanceCardView: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Text("Total Bank Balance")
                    .font(.headline)
                    .foregroundColor(AppTheme.textColor.opacity(0.8))
                Spacer()
                Button {
                    withAnimation(.spring()) { hideBalance.toggle() }
                } label: {
                    Image(systemName: hideBalance ? "eye" : "eye.slash")
                        .font(.subheadline)
                        .foregroundColor(AppTheme.textColor)
                        .padding(6)
                        .background(Circle()
                            .fill(AppTheme.cardBackground)
                            .shadow(color: .black.opacity(0.06), radius: 2, x: 0, y: 1))
                }
                .buttonStyle(PlainButtonStyle())
            }

            // MARK: Balance
            Group {
                if hideBalance {
                    Text("$•••••••")
                } else {
                    CountingView(
                        value: animateBalance ? totalBalance : 0,
                        format: "$%.2f",
                        fontSize: 40,
                        textColor: AppTheme.textColor
                    )
                }
            }
            .font(.system(size: 40, weight: .bold))
            .frame(maxWidth: .infinity, alignment: .leading)

            Divider()

            // Income & Expenses
            HStack(spacing: 12) {
                // Monthly Income
                VStack(alignment: .leading, spacing: 4) {
                    Text("Monthly Income")
                        .font(.caption)
                        .foregroundColor(AppTheme.textColor.opacity(0.7))
                    Text(hideBalance ? "$•••••"
                         : "$\(totalIncome, specifier: "%.2f")")
                        .font(.headline)
                        .foregroundColor(AppTheme.primaryGreen)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                // Monthly Expenses
                VStack(alignment: .leading, spacing: 4) {
                    Text("Monthly Expenses")
                        .font(.caption)
                        .foregroundColor(AppTheme.textColor.opacity(0.7))
                    Text(hideBalance ? "$•••••"
                         : "$\(totalExpenses, specifier: "%.2f")")
                        .font(.headline)
                        .foregroundColor(AppTheme.expenseColor)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(AppTheme.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(AppTheme.cardStroke, lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 6)
        )
        .padding(.horizontal)
    }


    
    private var transactionsSection: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Recent Transactions")
                    .font(AppTheme.headlineFont())
                    .foregroundColor(AppTheme.textColor)
                
                Spacer()
                
                NavigationLink(destination: AllTransactionsView()) {
                    Text("See All")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(AppTheme.textColor)
                }
            }
            .padding(.horizontal)
            
            if currentMonthTransactions.isEmpty {
                emptyTransactionsView(for: "this month")
            } else {
                ForEach(Array(currentMonthTransactions.prefix(5).enumerated()), id: \.element.id) { index, transaction in
                    Button(action: {
                        selectedTransaction = transaction
                    }) {
                        // Enhanced check for cash transactions
                        let isCash = transaction.accountId == "cash" || manualTransactionIds.contains(transaction.id)
 
                        
                        TransactionRow(transaction: transaction, isCashTransaction: isCash)
                            .padding(.horizontal)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
    }

    private func loadManualTransactionIds() {
        if let savedIds = UserDefaults.standard.stringArray(forKey: "manualTransactionIds") {
            manualTransactionIds = Set(savedIds)
            print("Loaded manual transaction IDs: \(manualTransactionIds)")
        } else {
            print("No manual transaction IDs found in UserDefaults")
        }
    }

    
    private func emptyTransactionsView(for period: String) -> some View {
        VStack(spacing: 20) {
            Image(systemName: "doc.text")
                .font(.system(size: 50))
                .foregroundColor(AppTheme.accentBlue.opacity(0.7))
            
            Text("No transactions \(period)")
                .font(.headline)
                .foregroundColor(AppTheme.textColor)
            
            Button(action: {
                showNewTransaction = true
            }) {
                Text("Add Transaction")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(AppTheme.backgroundColor)
                    .padding(.vertical, 10)
                    .padding(.horizontal, 20)
                    .background(AppTheme.primaryGreen)
                    .cornerRadius(10)
            }
            .buttonStyle(ScaleButtonStyle())
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(AppTheme.cardBackground)
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(AppTheme.cardStroke, lineWidth: 1)
        )
        .padding(.horizontal)
    }
    
    private var allTransactionsView: some View {
        VStack(spacing: 12) {
            HStack {
                Button(action: {
                    withAnimation {
                        showAllTransactions = false
                    }
                }) {
                    HStack {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16))
                        
                        Text("Back")
                    }
                    .foregroundColor(AppTheme.primaryGreen)
                }
                
                Spacer()
                
                Text("All Transactions")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(AppTheme.textColor)
                
                Spacer()
                
                Button(action: {
                    showNewTransaction = true
                }) {
                    Image(systemName: "plus")
                        .font(.system(size: 16))
                        .foregroundColor(AppTheme.primaryGreen)
                }
            }
            .padding(.horizontal)
            
            if plaidManager.transactions.isEmpty {
                emptyTransactionsView(for: "available")
                    .padding(.top, 20)
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(plaidManager.transactions) { transaction in
                            Button(action: {
                                selectedTransaction = transaction
                                showTransactionDetail = true
                            }) {
                                // Check if this is a cash transaction
                                let isCash = transaction.accountId == "cash" || manualTransactionIds.contains(transaction.id)
                                
                                TransactionRow(transaction: transaction, isCashTransaction: isCash)
                                    .padding(.horizontal)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
        }
    }
    
    private var accountsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Your Accounts")
                .font(AppTheme.headlineFont())
                .foregroundColor(AppTheme.textColor)
                .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(plaidManager.accounts) { account in
                        accountCard(for: account)
                    }
                    
                    Button(action: {
                        plaidManager.presentLink()
                    }) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 20)
                                .fill(AppTheme.accentPurple)
                                .frame(width: 100, height: 120)
                                .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
                            
                            VStack(spacing: 10) {
                                Image(systemName: "plus")
                                    .font(.system(size: 20))
                                    .foregroundColor(AppTheme.textColor)
                                
                                Text("Add\nAccount")
                                    .font(.subheadline)
                                    .multilineTextAlignment(.center)
                                    .foregroundColor(AppTheme.textColor)
                            }
                        }
                    }
                    .buttonStyle(ScaleButtonStyle())
                }
                .padding(.horizontal)
            }
        }
    }
    
    private func accountCard(for account: PlaidAccount) -> some View {
        Button(action: {
            selectedAccount = account
            showAccountDetails = true
        }) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    ZStack {
                        Circle()
                            .fill(AppTheme.accentPurple.opacity(0.5))
                            .frame(width: 40, height: 40)
                        
                        if let logo = account.institutionLogo {
                            Image(uiImage: logo)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 25, height: 25)
                        } else {
                            Image(systemName: "building.columns")
                                .font(.system(size: 20))
                                .foregroundColor(AppTheme.textColor)
                        }
                    }
                    
                    Spacer()
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(account.name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(AppTheme.textColor)
                        .lineLimit(1)
                    
                    Text(account.institutionName)
                        .font(.caption)
                        .foregroundColor(AppTheme.textColor.opacity(0.7))
                        .lineLimit(1)
                    
                    Text("$\(String(format: "%.2f", account.balance))")
                        .font(.headline)
                        .foregroundColor(account.balance >= 0 ? AppTheme.primaryGreen : AppTheme.expenseColor)
                }
            }
            .frame(width: 160)
            .padding()
            .background(AppTheme.cardBackground)
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(AppTheme.cardStroke, lineWidth: 1)
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }
    
    private var profileSheetView: some View {
        Text("Profile Sheet")
    }
    
    // MARK: - Helper Methods for Manual Transactions
    
    // Save manual transaction IDs to UserDefaults
    private func saveManualTransactionIds() {
        UserDefaults.standard.set(Array(manualTransactionIds), forKey: "manualTransactionIds")
    }
    
    // Fetch data while preserving manual transactions
    private func fetchDataPreservingManualTransactions() {
        // Save current manual transactions
        let manualTransactions = plaidManager.transactions.filter { manualTransactionIds.contains($0.id) }
        
        // Fetch new transactions from Plaid
        plaidManager.fetchTransactions { success in
            if success {
                // Add back the manual transactions
                DispatchQueue.main.async {
                    // Add each manual transaction to the beginning of the array
                    for transaction in manualTransactions.reversed() {
                        if !self.plaidManager.transactions.contains(where: { $0.id == transaction.id }) {
                            self.plaidManager.transactions.insert(transaction, at: 0)
                        }
                    }
                    self.isRefreshing = false
                }
            } else {
                self.isRefreshing = false
            }
        }
    }
    
    private func addTransaction(transaction: Transaction) {
        // Create a transaction ID for the new manual transaction
        let transactionId = UUID().uuidString
        
        // Create a Plaid transaction format but clearly mark it as cash
        let newTransaction = PlaidTransaction(
            id: transactionId,
            name: transaction.title,
            amount: transaction.amount,
            date: transaction.date,
            category: transaction.category,
            merchantName: transaction.merchant,
            accountId: "cash", // Use "cash" as the account ID for all cash transactions
            pending: false
        )
        
        // Mark as manual transaction in UserDefaults
        manualTransactionIds.insert(transactionId)
        saveManualTransactionIds()
        
        // Add to local state
        withAnimation(.spring()) {
            plaidManager.transactions.insert(newTransaction, at: 0)
        }
        
        // Save to Firestore as a manual transaction
        saveManualTransactionToFirestore(newTransaction)
    }
    
    private func saveManualTransactionToFirestore(_ transaction: PlaidTransaction) {
        guard let userId = Auth.auth().currentUser?.uid else {
            print("Failed to save manual transaction: User not logged in")
            return
        }
        
        let db = Firestore.firestore()
        let transactionRef = db.collection("users/\(userId)/manualTransactions").document(transaction.id)
        
        // Convert Date to Timestamp
        let timestamp = Timestamp(date: transaction.date)
        
        let data: [String: Any] = [
            "id": transaction.id,
            "name": transaction.name,
            "amount": transaction.amount,
            "date": timestamp,
            "category": transaction.category,
            "merchantName": transaction.merchantName,
            "accountId": transaction.accountId,
            "pending": transaction.pending,
            "isManual": true,
            "createdAt": FieldValue.serverTimestamp(),
            "updatedAt": FieldValue.serverTimestamp()
        ]
        
        transactionRef.setData(data) { error in
            if let error = error {
                print("Error saving manual transaction: \(error.localizedDescription)")
            } else {
                print("Manual transaction saved successfully")
            }
        }
    }
}

// MARK: - Simple Manual Transaction Detail View
struct ManualTransactionDetailView: View {
    let transaction: PlaidTransaction
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            ZStack {
                AppTheme.backgroundGradient
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Transaction header
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
                                    
                                    Text("Cash Transaction")
                                        .font(.caption)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 3)
                                        .background(AppTheme.primaryGreen.opacity(0.2))
                                        .foregroundColor(AppTheme.primaryGreen)
                                        .cornerRadius(4)
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
                        
                        // Transaction details card - simplified for cash transactions
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
                            
                            detailRow(title: "Type",
                                    value: transaction.amount >= 0 ? "Expense" : "Income",
                                    icon: transaction.amount >= 0 ? "arrow.up" : "arrow.down")
                            
                            Divider()
                                .background(AppTheme.textColor.opacity(0.1))
                            
                            detailRow(title: "Method",
                                    value: "Cash",
                                    icon: "banknote")
                            
                            Divider()
                                .background(AppTheme.textColor.opacity(0.1))
                            
                            detailRow(title: "Category",
                                    value: transaction.category,
                                    icon: getCategoryIcon(for: transaction.category))
                        }
                        .padding()
                        .background(AppTheme.cardBackground)
                        .cornerRadius(16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(AppTheme.cardStroke, lineWidth: 1)
                        )
                    }
                    .padding()
                }
            }
            .navigationTitle("Cash Transaction")
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
        }
    }
    
    // Helper methods for formatting
    private func formatDate(_ date: Date, includeWeekday: Bool = false) -> String {
        let formatter = DateFormatter()
        if includeWeekday {
            formatter.dateFormat = "EEEE, MMMM d, yyyy"
        } else {
            formatter.dateFormat = "MMMM d, yyyy"
        }
        return formatter.string(from: date)
    }
    
    private func formatTimeOnly(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }
    
    private func getCategoryIcon(for category: String) -> String {
        let c = category.lowercased()
        if c.contains("food") || c.contains("restaurant") { return "fork.knife" }
        if c.contains("shop") || c.contains("store") { return "cart" }
        if c.contains("transport") || c.contains("travel") { return "car.fill" }
        if c.contains("entertainment") { return "play.tv" }
        if c.contains("health") || c.contains("medical") { return "heart.fill" }
        if c.contains("utility") || c.contains("bill") { return "bolt.fill" }
        if c.contains("income") || c.contains("deposit") { return "arrow.down.circle.fill" }
        return "dollarsign.circle"
    }
    
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
}



// MARK: - Transaction Row Component
struct TransactionRow: View {
    let transaction: PlaidTransaction
    var isCashTransaction: Bool = false
    
    init(transaction: PlaidTransaction, isCashTransaction: Bool? = nil) {
        self.transaction = transaction
        // If isCashTransaction is provided, use it; otherwise determine it from the accountId
        self.isCashTransaction = isCashTransaction ?? (transaction.accountId == "cash")
    }
    
    var body: some View {
        HStack(spacing: 15) {
            // Merchant icon with dynamic color
            ZStack {
                Circle()
                    .fill(transaction.category == "Income" ? AppTheme.primaryGreen.opacity(0.2) : AppTheme.accentPurple.opacity(0.5))
                    .frame(width: 44, height: 44)
                
                // Choose an appropriate icon based on the category
                Image(systemName: getCategoryIcon(for: transaction.category))
                    .font(.system(size: 18))
                    .foregroundColor(transaction.category == "Income" ? AppTheme.primaryGreen : AppTheme.textColor)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(transaction.merchantName)
                    .font(.headline)
                    .foregroundColor(AppTheme.textColor)
                
                HStack(spacing: 6) {
                    // Show "Cash" indicator for cash transactions
                    if isCashTransaction {
                        Text("Cash")
                            .font(.caption)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(AppTheme.primaryGreen.opacity(0.2))
                            .foregroundColor(AppTheme.primaryGreen)
                            .cornerRadius(4)
                    }
                    
                    Text("\(formatTimeAgo(transaction.date))")
                        .font(.caption)
                        .foregroundColor(AppTheme.textColor.opacity(0.6))
                }
            }
            
            Spacer()
            
            // Amount with dynamic color
            Text(transaction.amount >= 0 ? "+$\(String(format: "%.2f", transaction.amount))" : "-$\(String(format: "%.2f", abs(transaction.amount)))")
                .font(.headline)
                .foregroundColor(transaction.amount >= 0 ? AppTheme.primaryGreen : AppTheme.expenseColor)
                .transition(.scale.combined(with: .opacity))
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(AppTheme.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(AppTheme.cardStroke, lineWidth: 1)
                )
        )
    }
    
    private func formatTimeAgo(_ date: Date) -> String {
        let minutes = Int(-date.timeIntervalSinceNow / 60)
        
        if minutes < 60 {
            return "\(minutes) min ago"
        } else {
            let hours = minutes / 60
            if hours < 24 {
                return "\(hours) hour\(hours == 1 ? "" : "s") ago"
            } else {
                let days = hours / 24
                return "\(days) day\(days == 1 ? "" : "s") ago"
            }
        }
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
}

struct CountingView: View {
    let value: Double
    let format: String
    let fontSize: CGFloat
    let textColor: Color
    
    var body: some View {
        Text(String(format: format, value))
            .font(.system(size: fontSize, weight: .bold))
            .foregroundColor(textColor)
    }
}

// MARK: - Preview
struct FinanceHomeView_Previews: PreviewProvider {
    static var previews: some View {
       FinanceHomeView()
            .environmentObject(PlaidManager.shared)
            .preferredColorScheme(.dark)
    }
}

struct ProfileOptionRow: View {
    let icon: String
    let title: String
    
    var body: some View {
        Button(action: {}) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(AppTheme.textColor)
                    .frame(width: 30)
                
                Text(title)
                    .foregroundColor(AppTheme.textColor)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(AppTheme.textColor.opacity(0.5))
            }
            .padding()
            .background(AppTheme.accentPurple.opacity(0.2))
            .cornerRadius(12)
        }
    }
}

struct AllTransactionsView: View {
    @EnvironmentObject var plaidManager: PlaidManager
    @State private var selectedTransaction: PlaidTransaction? = nil
    // Add this state to track manual transactions
    @State private var manualTransactionIds: Set<String> = []
    
    var body: some View {
        ZStack {
            AppTheme.backgroundGradient.ignoresSafeArea()
            
            VStack(spacing: 12) {
                if plaidManager.transactions.isEmpty {
                    Text("No transactions available")
                        .foregroundColor(AppTheme.textColor)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(plaidManager.transactions) { transaction in
                                Button(action: {
                                    selectedTransaction = transaction
                                }) {
                                    // Check if it's a cash transaction
                                    let isCash = transaction.accountId == "cash" || manualTransactionIds.contains(transaction.id)
                                    TransactionRow(transaction: transaction, isCashTransaction: isCash)
                                        .padding(.horizontal)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(.vertical)
                    }
                }
            }
            .navigationTitle("All Transactions")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarBackground(Color(hex: "#161616"), for: .navigationBar)
            
            .sheet(item: $selectedTransaction) { transaction in
                if manualTransactionIds.contains(transaction.id) || transaction.accountId == "cash" {
                    ManualTransactionDetailView(transaction: transaction)
                        .environmentObject(plaidManager)
                } else {
                    TransactionDetailViewFirestore(transaction: transaction)
                        .environmentObject(plaidManager)
                }
            }
        }
        .onAppear {
            // Load manual transaction IDs when view appears
            loadManualTransactionIds()
        }
    }
    
    // Load previously saved manual transaction IDs
    private func loadManualTransactionIds() {
        if let savedIds = UserDefaults.standard.stringArray(forKey: "manualTransactionIds") {
            manualTransactionIds = Set(savedIds)
        }
    }
}

    private func formatTimeAgo(_ date: Date) -> String {
        let minutes = Int(-date.timeIntervalSinceNow / 60)
        
        if minutes < 60 {
            return "\(minutes) min ago"
        } else {
            let hours = minutes / 60
            if hours < 24 {
                return "\(hours) hour\(hours == 1 ? "" : "s") ago"
            } else {
                let days = hours / 24
                return "\(days) day\(days == 1 ? "" : "s") ago"
            }
        }
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


// Quick action button with tap animation
struct QuickActionButton: View {
    let iconName: String
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            // Button action with haptic feedback
            let impactLight = UIImpactFeedbackGenerator(style: .light)
            impactLight.impactOccurred()
            action()
        }) {
            VStack(spacing: 8) {
                Image(systemName: iconName)
                    .font(.system(size: 22))
                    .foregroundColor(AppTheme.textColor)
                
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(AppTheme.textColor)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(ScaleButtonStyle())
    }
}



// Category button component
struct CategoryButton: View {
    let name: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(isSelected ? AppTheme.backgroundColor : AppTheme.textColor)
                
                Text(name)
                    .font(.caption)
                    .fontWeight(isSelected ? .semibold : .regular)
                    .foregroundColor(isSelected ? AppTheme.backgroundColor : AppTheme.textColor)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? AppTheme.accentBlue : AppTheme.cardBackground)
            )
        }
    }
}

struct AccountDetailView: View {
    let account: PlaidAccount
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var plaidManager: PlaidManager
    
    // Get transactions for this specific account
    var accountTransactions: [PlaidTransaction] {
        return plaidManager.transactions.filter { $0.accountId == account.id }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                AppTheme.backgroundGradient.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Account header with logo and balance
                        VStack(spacing: 16) {
                            // Bank logo
                            ZStack {
                                Circle()
                                    .fill(AppTheme.accentPurple.opacity(0.3))
                                    .frame(width: 80, height: 80)
                                
                                if let logo = account.institutionLogo {
                                    Image(uiImage: logo)
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 50, height: 50)
                                } else {
                                    Image(systemName: "building.columns")
                                        .font(.system(size: 40))
                                        .foregroundColor(AppTheme.accentBlue)
                                }
                            }
                            
                            // Account name
                            Text(account.name)
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(AppTheme.textColor)
                            
                            Text(account.institutionName)
                                .font(.headline)
                                .foregroundColor(AppTheme.textColor.opacity(0.7))
                            
                            // Balance
                            VStack(spacing: 4) {
                                Text("Current Balance")
                                    .font(.subheadline)
                                    .foregroundColor(AppTheme.textColor.opacity(0.7))
                                
                                Text("$\(account.balance, specifier: "%.2f")")
                                    .font(.system(size: 36, weight: .bold))
                                    .foregroundColor(account.balance >= 0 ? AppTheme.primaryGreen : AppTheme.expenseColor)
                            }
                            .padding(.vertical, 8)
                        }
                        .padding()
                        .background(AppTheme.cardBackground)
                        .cornerRadius(20)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(AppTheme.cardStroke, lineWidth: 1)
                        )
                        .padding(.horizontal)
                        
                        // Account details
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Account Details")
                                .font(.headline)
                                .foregroundColor(AppTheme.textColor)
                                .padding(.horizontal)
                            
                            VStack(spacing: 12) {
                                detailRow(title: "Account Type", value: account.type)
                                
                                Divider().background(AppTheme.cardStroke)
                                
                                detailRow(title: "Account Number", value: "****\(account.id.suffix(4))")
                                
                                Divider().background(AppTheme.cardStroke)
                                
                                detailRow(title: "Institution", value: account.institutionName)
                                
                                if !accountTransactions.isEmpty {
                                    Divider().background(AppTheme.cardStroke)
                                    
                                    detailRow(
                                        title: "Last Transaction",
                                        value: formatDate(accountTransactions.sorted(by: { $0.date > $1.date }).first!.date)
                                    )
                                }
                            }
                            .padding()
                            .background(AppTheme.cardBackground)
                            .cornerRadius(16)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(AppTheme.cardStroke, lineWidth: 1)
                            )
                            .padding(.horizontal)
                        }
                        
                        // Recent transactions
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Recent Transactions")
                                .font(.headline)
                                .foregroundColor(AppTheme.textColor)
                                .padding(.horizontal)
                            
                            if accountTransactions.isEmpty {
                                Text("No transactions for this account")
                                    .font(.subheadline)
                                    .foregroundColor(AppTheme.textColor.opacity(0.7))
                                    .frame(maxWidth: .infinity, alignment: .center)
                                    .padding()
                                    .background(AppTheme.cardBackground)
                                    .cornerRadius(16)
                                    .padding(.horizontal)
                            } else {
                                ForEach(accountTransactions.prefix(5)) { transaction in
                                    TransactionRow(transaction: transaction)
                                        .padding(.horizontal)
                                }
                                
                              
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.vertical)
                }
            }
            .navigationTitle("Account Details")
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

