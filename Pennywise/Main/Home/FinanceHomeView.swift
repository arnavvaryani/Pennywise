//
//  FinanceHomeView.swift
//  Pennywise
//

import SwiftUI

struct EnhancedFinanceHomeView: View {
    // MARK: - Properties
    @StateObject private var authService = AuthenticationService.shared
    @EnvironmentObject var plaidManager: PlaidManager
    
    // State variables
    @State private var showNewTransaction: Bool = false
    @State private var hideBalance: Bool = false
    @State private var selectedCurrencyIndex: Int = 0
    @State private var showProfileSheet: Bool = false
    @State private var isRefreshing: Bool = false
    @State private var animateBalance: Bool = false
    @State private var showAllTransactions: Bool = false
    
    // Animation states
    @State private var cardOffset: CGFloat = 1000
    @State private var opacity: Double = 0
    @State private var scale: CGFloat = 0.8
    
    // Computed properties
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
                // Header with user info
                headerView
                    .padding(.horizontal)
                    .padding(.top, 8)
                    .padding(.bottom, 4)
                
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
        .sheet(isPresented: $showTransactionDetail) {
            if let transaction = selectedTransaction {
                TransactionDetailView(transaction: transaction)
            }
        }
        .onAppear {
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
    
    // Enhanced header view
    private var headerView: some View {
        HStack(alignment: .center, spacing: 8) {
            // User profile
            Button(action: {
                withAnimation {
                    showProfileSheet = true
                }
            }) {
                HStack(spacing: 8) {
                    // User profile image
                    if let photoURL = authService.user?.photoURL {
                        AsyncImage(url: photoURL) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 40, height: 40)
                                .clipShape(Circle())
                        } placeholder: {
                            Circle()
                                .fill(AppTheme.accentPurple.opacity(0.3))
                                .frame(width: 40, height: 40)
                                .overlay(
                                    Image(systemName: "person.fill")
                                        .font(.system(size: 20))
                                        .foregroundColor(AppTheme.textColor)
                                )
                        }
                    } else {
                        Circle()
                            .fill(AppTheme.accentPurple.opacity(0.3))
                            .frame(width: 40, height: 40)
                            .overlay(
                                Image(systemName: "person.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(AppTheme.textColor)
                            )
                    }
                    
                    Text("Hi, \(userName.components(separatedBy: " ").first ?? userName)!")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(AppTheme.textColor)
                }
            }
            .buttonStyle(ScaleButtonStyle())
            
            Spacer()
            
            // Add Transaction button
            Button(action: {
                showNewTransaction = true
            }) {
                Text("Add")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 16)
                    .background(AppTheme.primaryGreen)
                    .cornerRadius(20)
            }
            .buttonStyle(ScaleButtonStyle())
        }
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
        .refreshable {
            // Pull to refresh with animation
            isRefreshing = true
            
            // Fetch updated data from Plaid
            plaidManager.fetchTransactions { success in
                isRefreshing = false
            }
        }
    }
    
    // Balance card with income and expenses
    private var balanceCardView: some View {
        ZStack {
            // Card background with dynamic shadow
            RoundedRectangle(cornerRadius: 25)
                .fill(AppTheme.accentBlue)
                .shadow(color: AppTheme.accentBlue.opacity(0.3), radius: 15, x: 0, y: 8)
                .overlay(
                    RoundedRectangle(cornerRadius: 25)
                        .strokeBorder(Color.black.opacity(0.05), lineWidth: 1)
                )
            
            VStack(alignment: .leading, spacing: 16) {
                // Total Balance section
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Total Balance")
                            .font(.headline)
                            .foregroundColor(AppTheme.backgroundColor.opacity(0.8))
                        
                        Spacer()
                        
                        Button(action: {
                            // Toggle balance visibility with animation
                            withAnimation(.spring()) {
                                hideBalance.toggle()
                            }
                        }) {
                            Image(systemName: hideBalance ? "eye" : "eye.slash")
                                .foregroundColor(AppTheme.backgroundColor)
                                .padding(8)
                                .background(
                                    Circle()
                                        .fill(Color.black.opacity(0.05))
                                )
                        }
                        .buttonStyle(ScaleButtonStyle())
                    }
                    
                    Group {
                        if hideBalance {
                            Text("$•••••••")
                                .font(.system(size: 42, weight: .bold))
                                .foregroundColor(AppTheme.backgroundColor)
                                .transition(.opacity)
                        } else {
                            // Use CountingView for animation
                            CountingView(
                                value: animateBalance ? totalBalance : 0,
                                format: "$%.2f",
                                fontSize: 42,
                                textColor: AppTheme.backgroundColor
                            )
                            .transition(.opacity)
                        }
                    }
                }
                
                Divider()
                    .background(AppTheme.backgroundColor.opacity(0.2))
                
                // Income and Expenses row
                HStack {
                    // Income
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Income")
                            .font(.subheadline)
                            .foregroundColor(AppTheme.backgroundColor.opacity(0.8))
                        
                        if hideBalance {
                            Text("$•••••")
                                .font(.headline)
                                .foregroundColor(AppTheme.backgroundColor)
                        } else {
                            Text("$\(String(format: "%.2f", totalIncome))")
                                .font(.headline)
                                .foregroundColor(AppTheme.backgroundColor)
                        }
                    }
                    
                    Spacer()
                    
                    // Expenses
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Expenses")
                            .font(.subheadline)
                            .foregroundColor(AppTheme.backgroundColor.opacity(0.8))
                        
                        if hideBalance {
                            Text("$•••••")
                                .font(.headline)
                                .foregroundColor(AppTheme.backgroundColor)
                        } else {
                            Text("$\(String(format: "%.2f", totalExpenses))")
                                .font(.headline)
                                .foregroundColor(AppTheme.backgroundColor)
                        }
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 20)
        }
    }
    
    // Transactions section using currently displayed transactions
    private var transactionsSection: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Recent Transactions")
                    .font(AppTheme.headlineFont())
                    .foregroundColor(AppTheme.textColor)
                
                Spacer()
                
                Button(action: {
                    withAnimation {
                        showAllTransactions = true
                    }
                }) {
                    Text("See All")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(AppTheme.textColor)
                }
                .buttonStyle(ScaleButtonStyle())
            }
            .padding(.horizontal)
            
            if currentMonthTransactions.isEmpty {
                emptyTransactionsView(for: "this month")
            } else {
                ForEach(Array(currentMonthTransactions.prefix(5).enumerated()), id: \.element.id) { index, transaction in
                    Button(action: {
                        selectedTransaction = transaction
                        showTransactionDetail = true
                    }) {
                        TransactionRow(transaction: transaction)
                            .padding(.horizontal)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
    }
    
    // Empty transactions view with context
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
    
    // All transactions view - shows all transactions
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
            
            // Show all transactions
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
                                TransactionRow(transaction: transaction)
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
    
    // Accounts section
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
    
    // Account card view
    private func accountCard(for account: PlaidAccount) -> some View {
        Button(action: {
            // Show account details
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
    
    // Profile sheet view - placeholder for integration
    private var profileSheetView: some View {
        Text("Profile Sheet")
    }
    
    // MARK: - Functions
    private func addTransaction(transaction: Transaction) {
        // Create a new transaction
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

// Count animation for numbers
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
        EnhancedFinanceHomeView()
            .environmentObject(PlaidManager.shared)
            .preferredColorScheme(.dark)
    }
}

// Profile option row
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

// Count animation for numbers
//struct CountingView: View {
//    let value: Double
//    let format: String
//    let fontSize: CGFloat
//    let textColor: Color
//    
//    var body: some View {
//        Text(String(format: format, value))
//            .font(.system(size: fontSize, weight: .bold))
//            .foregroundColor(textColor)
//    }
//}

// Scale animation for buttons
//struct ScaleButtonStyle: ButtonStyle {
//    func makeBody(configuration: Configuration) -> some View {
//        configuration.label
//            .scaleEffect(configuration.isPressed ? 0.95 : 1)
//            .opacity(configuration.isPressed ? 0.9 : 1)
//            .animation(.spring(response: 0.2, dampingFraction: 0.7), value: configuration.isPressed)
//    }
//}
// MARK: - Supporting Views



// Transaction row with dynamic icons based on category
struct TransactionRow: View {
    let transaction: PlaidTransaction
    
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
                
                Text("\(formatTimeAgo(transaction.date))")
                    .font(.caption)
                    .foregroundColor(AppTheme.textColor.opacity(0.6))
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

// Currency card with tap/press effect instead of hover
struct CurrencyCard: View {
    let currency: Currency
    @State private var isPressed: Bool = false
    
    var body: some View {
        ZStack {
            // Card background with press animation
            RoundedRectangle(cornerRadius: 20)
                .fill(AppTheme.cardBackground)
                .frame(width: 100, height: 110)
                .shadow(color: Color.black.opacity(isPressed ? 0.15 : 0.05), radius: isPressed ? 12 : 8, x: 0, y: isPressed ? 6 : 4)
                .scaleEffect(isPressed ? 1.03 : 1.0)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(AppTheme.cardStroke, lineWidth: 1)
                )
                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
            
            VStack(alignment: .leading, spacing: 10) {
                // Symbol with dynamic color
                Text(currency.symbol)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(currency.code == "EUR" ? AppTheme.primaryGreen : AppTheme.accentBlue)
                    .padding(8)
                    .background(
                        Circle()
                            .fill(currency.code == "EUR" ? AppTheme.primaryGreen.opacity(0.15) : AppTheme.accentBlue.opacity(0.15))
                    )
                
                Text(currency.name)
                    .font(.caption)
                    .foregroundColor(AppTheme.textColor.opacity(0.7))
                    .lineLimit(1)
                
                Text("\(String(format: "%.2f", currency.rate))")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(AppTheme.textColor)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 12)
        }
        .contentShape(Rectangle())
        .onTapGesture {} // Empty tap gesture to capture taps
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    isPressed = true
                }
                .onEnded { _ in
                    isPressed = false
                }
        )
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

