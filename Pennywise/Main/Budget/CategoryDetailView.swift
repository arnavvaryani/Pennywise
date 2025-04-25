//
//  CategoryDetailView.swift
//  Pennywise
//
//  Created by Arnav Varyani on 4/24/25.
//


import SwiftUI
import Firebase
import FirebaseFirestore
import FirebaseAuth

struct CategoryDetailView: View {
    // MARK: - Properties
    let category: BudgetCategory
    let onUpdate: (BudgetCategory) -> Void
    let plaidManager: PlaidManager
    
    @Environment(\.presentationMode) var presentationMode
    @State private var updatedName: String
    @State private var updatedAmount: Double
    @State private var updatedIcon: String
    @State private var updatedColor: Color
    @State private var isEssential: Bool
    @State private var transactions: [PlaidTransaction] = []
    @State private var isLoading = false
    @State private var errorMessage: String? = nil
    @State private var totalSpent: Double = 0
    @State private var showingDeleteAlert = false
    @State private var showingInsights = false
    @State private var categoryInsights: [String] = []
    
    // MARK: - Init
    init(category: BudgetCategory, onUpdate: @escaping (BudgetCategory) -> Void, plaidManager: PlaidManager) {
        self.category = category
        self.onUpdate = onUpdate
        self.plaidManager = plaidManager
        _updatedName = State(initialValue: category.name)
        _updatedAmount = State(initialValue: category.amount)
        _updatedIcon = State(initialValue: category.icon)
        _updatedColor = State(initialValue: category.color)
        _isEssential = State(initialValue: CategoryDetailView.isEssentialCategory(category.name))
    }
    
    // MARK: - Body
    var body: some View {
        NavigationView {
            ZStack {
                AppTheme.backgroundGradient
                    .ignoresSafeArea()
                
                if isLoading {
                    ProgressView()
                        .scaleEffect(1.5)
                        .progressViewStyle(CircularProgressViewStyle(tint: AppTheme.primaryGreen))
                } else {
                    ScrollView {
                        VStack(spacing: 24) {
                            // Category summary card
                            categorySummaryCard
                            
                            // Details form
                            categoryDetailsForm
                            
                            // Appearance settings
                            categoryAppearanceForm
                            
                            // Spending breakdown
                            spendingBreakdownSection
                            
                            // Insights button
                            if !transactions.isEmpty {
                                Button(action: {
                                    generateCategoryInsights()
                                    showingInsights = true
                                }) {
                                    Label("View Spending Insights", systemImage: "lightbulb.fill")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                        .padding()
                                        .frame(maxWidth: .infinity)
                                        .background(AppTheme.accentBlue)
                                        .cornerRadius(12)
                                }
                                .buttonStyle(ScaleButtonStyle())
                                .padding(.top, 10)
                            }
                            
                            // Delete button
                            Button(action: {
                                showingDeleteAlert = true
                            }) {
                                Label("Delete Category", systemImage: "trash")
                                    .font(.headline)
                                    .foregroundColor(Color(hex: "#FF5757"))
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .background(Color(hex: "#FF5757").opacity(0.2))
                                    .cornerRadius(12)
                            }
                            .buttonStyle(ScaleButtonStyle())
                            .padding(.top, 10)
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Category Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        let updatedCategory = BudgetCategory(
            
                            name: updatedName,
                            amount: updatedAmount,
                            icon: updatedIcon,
                            color: updatedColor
                        )
                        onUpdate(updatedCategory)
                        presentationMode.wrappedValue.dismiss()
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(AppTheme.primaryGreen)
                }
            }
            .onAppear {
                isLoading = true
                loadCategoryData()
            }
            .alert(item: Binding<AlertData?>(
                get: { 
                    errorMessage.map { AlertData(id: UUID().uuidString, message: $0) }
                },
                set: { newValue in
                    errorMessage = newValue?.message
                }
            )) { alert in
                Alert(
                    title: Text("Error"),
                    message: Text(alert.message),
                    dismissButton: .default(Text("OK"))
                )
            }
            .alert("Delete Category", isPresented: $showingDeleteAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    deleteCategory()
                }
            } message: {
                Text("Are you sure you want to delete this category? This action cannot be undone.")
            }
            .sheet(isPresented: $showingInsights) {
                CategoryInsightsView(
                    category: category,
                    insights: categoryInsights,
                    spent: totalSpent,
                    transactions: transactions,
                    presentationMode: $showingInsights
                )
            }
        }
    }
    
    // MARK: - UI Components
    
    // Category summary card
    private var categorySummaryCard: some View {
        VStack(spacing: 20) {
            // Category icon
            ZStack {
                Circle()
                    .fill(updatedColor.opacity(0.2))
                    .frame(width: 80, height: 80)
                
                Image(systemName: updatedIcon)
                    .font(.system(size: 36))
                    .foregroundColor(updatedColor)
            }
            
            // Category stats
            HStack(spacing: 30) {
                // Budget amount
                VStack(spacing: 4) {
                    Text("Budget")
                        .font(.subheadline)
                        .foregroundColor(AppTheme.textColor.opacity(0.7))
                    
                    Text("$\(Int(updatedAmount))")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(AppTheme.textColor)
                }
                
                // Spent amount
                VStack(spacing: 4) {
                    Text("Spent")
                        .font(.subheadline)
                        .foregroundColor(AppTheme.textColor.opacity(0.7))
                    
                    Text("$\(Int(totalSpent))")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(totalSpent > updatedAmount ? AppTheme.expenseColor : AppTheme.accentBlue)
                }
                
                // Remaining amount
                VStack(spacing: 4) {
                    Text("Remaining")
                        .font(.subheadline)
                        .foregroundColor(AppTheme.textColor.opacity(0.7))
                    
                    Text("$\(Int(max(0, updatedAmount - totalSpent)))")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(updatedAmount > totalSpent ? AppTheme.primaryGreen : AppTheme.expenseColor)
                }
            }
            
            // Progress bar
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Budget Usage")
                        .font(.caption)
                        .foregroundColor(AppTheme.textColor.opacity(0.7))
                    
                    Spacer()
                    
                    let percentage = updatedAmount > 0 ? min(totalSpent / updatedAmount * 100, 100) : 0
                    Text("\(Int(percentage))%")
                        .font(.caption)
                        .foregroundColor(
                            percentage >= 100 ? AppTheme.expenseColor :
                            percentage >= 90 ? Color(hex: "#FFD700") :
                            AppTheme.primaryGreen
                        )
                }
                
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: 6)
                        .fill(AppTheme.cardStroke)
                        .frame(height: 10)
                    
                    // Progress
                    let progress = updatedAmount > 0 ? min(totalSpent / updatedAmount, 1.0) : 0
                    
                    RoundedRectangle(cornerRadius: 6)
                        .fill(
                            progress >= 1.0 ? AppTheme.expenseColor :
                            progress >= 0.9 ? Color(hex: "#FFD700") :
                            AppTheme.primaryGreen
                        )
                        .frame(width: max(CGFloat(progress) * (UIScreen.main.bounds.width - 64), 4), height: 10)
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
    
    // Category details form
    private var categoryDetailsForm: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Details")
                .font(.headline)
                .foregroundColor(AppTheme.textColor)
                .accessibilityAddTraits(.isHeader)
            
            FormField(title: "Name", isRequired: true) {
                TextField("Category Name", text: $updatedName)
                    .foregroundColor(AppTheme.textColor)
                    .padding()
                    .background(AppTheme.cardBackground)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(AppTheme.cardStroke, lineWidth: 1)
                    )
            }
            
            FormField(title: "Budget Amount", isRequired: true) {
                HStack {
                    Text("$")
                        .foregroundColor(AppTheme.textColor)
                    
                    TextField("Amount", value: $updatedAmount, formatter: NumberFormatter())
                        .keyboardType(.decimalPad)
                        .foregroundColor(AppTheme.textColor)
                }
                .padding()
                .background(AppTheme.cardBackground)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(AppTheme.cardStroke, lineWidth: 1)
                )
            }
            
            Toggle("Essential Expense", isOn: $isEssential)
                .foregroundColor(AppTheme.textColor)
                .padding()
                .background(AppTheme.cardBackground)
                .cornerRadius(12)
                .toggleStyle(SwitchToggleStyle(tint: AppTheme.primaryGreen))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(AppTheme.cardStroke, lineWidth: 1)
                )
        }
        .padding()
        .background(AppTheme.cardBackground.opacity(0.5))
        .cornerRadius(16)
    }
    
    // Category appearance form
    private var categoryAppearanceForm: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Appearance")
                .font(.headline)
                .foregroundColor(AppTheme.textColor)
                .accessibilityAddTraits(.isHeader)
            
            FormField(title: "Icon", isRequired: false) {
                // Icon selector (simplified for this example)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(commonIcons, id: \.self) { icon in
                            Button(action: {
                                updatedIcon = icon
                            }) {
                                ZStack {
                                    Circle()
                                        .fill(updatedIcon == icon ? updatedColor.opacity(0.2) : AppTheme.cardBackground)
                                        .frame(width: 50, height: 50)
                                    
                                    Image(systemName: icon)
                                        .font(.system(size: 20))
                                        .foregroundColor(updatedIcon == icon ? updatedColor : AppTheme.textColor.opacity(0.7))
                                }
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
            
            FormField(title: "Color", isRequired: false) {
                // Color selector (simplified for this example)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(themeColors, id: \.self) { color in
                            Button(action: {
                                updatedColor = color
                            }) {
                                ZStack {
                                    Circle()
                                        .fill(color)
                                        .frame(width: 40, height: 40)
                                    
                                    if color == updatedColor {
                                        Circle()
                                            .stroke(Color.white, lineWidth: 2)
                                            .frame(width: 46, height: 46)
                                    }
                                }
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
        }
        .padding()
        .background(AppTheme.cardBackground.opacity(0.5))
        .cornerRadius(16)
    }
    
    // Spending breakdown section
    private var spendingBreakdownSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Spending History")
                .font(.headline)
                .foregroundColor(AppTheme.textColor)
                .accessibilityAddTraits(.isHeader)
            
            if transactions.isEmpty {
                // Show empty state
                VStack(alignment: .center, spacing: 16) {
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.system(size: 40))
                        .foregroundColor(AppTheme.accentBlue.opacity(0.6))
                        .padding(.top, 10)
                    
                    Text("No transaction data available for this category")
                        .foregroundColor(AppTheme.textColor.opacity(0.6))
                        .multilineTextAlignment(.center)
                        .padding()
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(AppTheme.cardBackground)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(AppTheme.cardStroke, lineWidth: 1)
                )
            } else {
                // Show transactions
                VStack(spacing: 12) {
                    ForEach(transactions.prefix(5), id: \.id) { transaction in
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(transaction.merchantName)
                                    .font(.subheadline)
                                    .foregroundColor(AppTheme.textColor)
                                
                                Text(formatDate(transaction.date))
                                    .font(.caption)
                                    .foregroundColor(AppTheme.textColor.opacity(0.6))
                            }
                            
                            Spacer()
                            
                            Text("$\(String(format: "%.2f", transaction.amount))")
                                .font(.subheadline)
                                .foregroundColor(transaction.amount > 0 ?
                                              AppTheme.expenseColor :
                                              AppTheme.primaryGreen)
                        }
                        .padding()
                        .background(AppTheme.cardBackground)
                        .cornerRadius(10)
                    }
                    
                    if transactions.count > 5 {
                        Button(action: {
                            // Show all transactions
                            showingInsights = true
                        }) {
                            Text("View All \(transactions.count) Transactions")
                                .font(.subheadline)
                                .foregroundColor(AppTheme.accentBlue)
                                .padding(.vertical, 12)
                        }
                        .buttonStyle(ScaleButtonStyle())
                    }
                }
            }
        }
        .padding()
        .background(AppTheme.cardBackground.opacity(0.5))
        .cornerRadius(16)
    }
    
    // MARK: - Helper Variables
    
    // Common icons for categories
    private var commonIcons: [String] {
        [
            "house.fill", "cart.fill", "car.fill", "fork.knife",
            "medical.thermometer", "wifi", "tv.fill", "gamecontroller.fill",
            "airplane", "gift.fill", "dollarsign.circle.fill", "creditcard.fill",
            "book.fill", "graduationcap.fill", "bag.fill", "tray.full.fill"
        ]
    }
    
    // Theme colors for categories
    private var themeColors: [Color] {
        [
            AppTheme.primaryGreen, AppTheme.accentBlue, AppTheme.accentPurple,
            Color(hex: "#FF5757"), Color(hex: "#FFD700"), Color(hex: "#50C878"),
            Color(hex: "#FF8C00"), Color(hex: "#9370DB"), Color(hex: "#DA70D6"),
            Color(hex: "#20B2AA"), Color(hex: "#32CD32"), Color(hex: "#FA8072")
        ]
    }
    
    // MARK: - Helper Methods
    
    // Static method to determine if a category is essential
    static func isEssentialCategory(_ name: String) -> Bool {
        let essentialCategories = ["Groceries", "Rent", "Utilities", "Transportation", 
                                  "Healthcare", "Insurance", "Housing", "Medical", 
                                  "Bills", "Mortgage"]
        
        return essentialCategories.contains { essential in
            name.lowercased().contains(essential.lowercased())
        }
    }
    
    // Load category data
    private func loadCategoryData() {
        // Load transactions for this category
        loadCategoryTransactions()
        
        isLoading = false
    }
    
    // Load transactions for this category
    private func loadCategoryTransactions() {
        // Get current month and year
        let calendar = Calendar.current
        let currentMonth = calendar.component(.month, from: Date())
        let currentYear = calendar.component(.year, from: Date())
        
        // Filter transactions for the current month that match this category
        transactions = plaidManager.transactions.filter { transaction in
            let transactionMonth = calendar.component(.month, from: transaction.date)
            let transactionYear = calendar.component(.year, from: transaction.date)
            return transactionMonth == currentMonth &&
                   transactionYear == currentYear &&
                   transaction.category.lowercased() == category.name.lowercased()
        }
        
        // Calculate total spent
        totalSpent = transactions.reduce(0) { $0 + $1.amount }
    }
    
    // Delete this category
    private func deleteCategory() {
        guard let userId = Auth.auth().currentUser?.uid else {
            errorMessage = "User not logged in"
            return
        }
        
        let db = Firestore.firestore()
        let categoryRef = db.collection("users/\(userId)/budgetCategories").document(category.id)
        
        categoryRef.delete { error in
            if let error = error {
                errorMessage = "Error deleting category: \(error.localizedDescription)"
                return
            }
            
            // Success - dismiss the view
            presentationMode.wrappedValue.dismiss()
        }
    }
    
    // Generate insights for this category
    private func generateCategoryInsights() {
        var insights: [String] = []
        
        // Budget usage insight
        if updatedAmount > 0 {
            let percentageUsed = (totalSpent / updatedAmount) * 100
            
            if percentageUsed > 100 {
                insights.append("You've exceeded your \(category.name) budget by \(Int(percentageUsed - 100))%. Consider increasing your budget or reducing spending in this category.")
            } else if percentageUsed > 90 {
                insights.append("You're close to your \(category.name) budget limit with \(Int(percentageUsed))% used.")
            } else if percentageUsed < 10 && totalSpent > 0 {
                insights.append("You've only used \(Int(percentageUsed))% of your \(category.name) budget. Consider reallocating some funds to other categories if this trend continues.")
            } else {
                insights.append("You've used \(Int(percentageUsed))% of your \(category.name) budget.")
            }
        }
        
        // Merchant analysis
        if transactions.count > 0 {
            // Group by merchant
            var merchantTotals: [String: Double] = [:]
            for transaction in transactions {
                merchantTotals[transaction.merchantName, default: 0] += transaction.amount
            }
            
            // Find top merchant
            if let topMerchant = merchantTotals.max(by: { $0.value < $1.value }) {
                let percentage = (topMerchant.value / totalSpent) * 100
                insights.append("Your top spending in this category is with \(topMerchant.key) (\(Int(percentage))% of category total).")
                
                if percentage > 50 && merchantTotals.count > 1 {
                    insights.append("Consider diversifying your \(category.name) spending to get better value.")
                }
            }
            
            // Frequency analysis
            if transactions.count > 3 {
                let frequency = Double(transactions.count) / 30.0 * 7.0 // Weekly frequency
                
                if frequency > 3 {
                    insights.append("You make \(String(format: "%.1f", frequency)) \(category.name) transactions per week. Consider batching purchases to reduce impulse spending.")
                }
            }
            
            // Add category-specific tips
            switch category.name.lowercased() {
            case let name where name.contains("food") || name.contains("dining"):
                insights.append("- Try meal planning and preparation to save on food costs")
                insights.append("- Consider using grocery rewards programs")
                
            case let name where name.contains("shopping") || name.contains("retail"):
                insights.append("- Create a shopping list and stick to it")
                insights.append("- Try waiting 24-48 hours before making non-essential purchases")
                
            case let name where name.contains("entertainment"):
                insights.append("- Look for free or low-cost entertainment options")
                insights.append("- Consider sharing subscription services with family or friends")
                
            case let name where name.contains("travel") || name.contains("transportation"):
                insights.append("- Use public transportation when possible")
                insights.append("- Combine errands to save on transportation costs")
                
            case let name where name.contains("utilities"):
                insights.append("- Look into energy-efficient options to lower bills")
                insights.append("- Compare service providers for better rates")
                
            default:
                break
            }
        }
        
        // Historical comparison (would need more data in a real app)
        insights.append("Keep tracking your \(category.name) expenses to see how they change over time and identify potential savings.")
        
        categoryInsights = insights
    }
    
    // Format date for display
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}

// MARK: - Category Insights View

struct CategoryInsightsView: View {
    let category: BudgetCategory
    let insights: [String]
    let spent: Double
    let transactions: [PlaidTransaction]
    @Binding var presentationMode: Bool
    
    var body: some View {
        NavigationView {
            ZStack {
                AppTheme.backgroundGradient
                    .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    // Header
                    HStack(spacing: 15) {
                        ZStack {
                            Circle()
                                .fill(category.color.opacity(0.2))
                                .frame(width: 50, height: 50)
                            
                            Image(systemName: category.icon)
                                .font(.system(size: 24))
                                .foregroundColor(category.color)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(category.name)
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(AppTheme.textColor)
                            
                            Text("$\(Int(spent)) spent of $\(Int(category.amount))")
                                .font(.subheadline)
                                .foregroundColor(AppTheme.textColor.opacity(0.7))
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
                    .padding(.horizontal)
                    
                    // Tabs for Insights and Transactions
                    TabView {
                        // Insights tab
                        ScrollView {
                            VStack(alignment: .leading, spacing: 16) {
                                ForEach(insights.indices, id: \.self) { index in
                                    insightCard(text: insights[index], index: index)
                                }
                            }
                            .padding(.horizontal)
                        }
                        .tabItem {
                            Image(systemName: "lightbulb.fill")
                            Text("Insights")
                        }
                        
                        // Transactions tab
                        ScrollView {
                            VStack(spacing: 12) {
                                ForEach(transactions) { transaction in
                                    transactionRow(transaction)
                                        .padding(.horizontal)
                                }
                            }
                            .padding(.top, 8)
                        }
                        .tabItem {
                            Image(systemName: "list.bullet")
                            Text("Transactions")
                        }
                    }
                    .tabViewStyle(PageTabViewStyle())
                    
                    // Close button
                    Button(action: {
                        presentationMode = false
                    }) {
                        Text("Close")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(AppTheme.primaryGreen)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 20)
                }
                .padding(.top, 8)
            }
            .navigationBarHidden(true)
        }
    }
    
    // MARK: - Helper Views
    
    private func insightCard(text: String, index: Int) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            if text.starts(with: "-") {
                // List item
                HStack(alignment: .top, spacing: 10) {
                    Circle()
                        .fill(category.color)
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
                            .fill(category.color.opacity(0.2))
                            .frame(width: 36, height: 36)
                        
                        Image(systemName: insightIcon(for: index))
                            .font(.system(size: 16))
                            .foregroundColor(category.color)
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
        .background(AppTheme.cardBackground)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(AppTheme.cardStroke, lineWidth: 1)
        )
    }
    
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
                
                if !transaction.name.isEmpty && transaction.name != transaction.merchantName {
                    Text(transaction.name)
                        .font(.caption)
                        .foregroundColor(AppTheme.textColor.opacity(0.6))
                }
            }
            
            Spacer()
            
            // Amount
            Text("$\(String(format: "%.2f", transaction.amount))")
                .font(.subheadline)
                .foregroundColor(transaction.amount > 0 ? AppTheme.expenseColor : AppTheme.primaryGreen)
        }
        .padding()
        .background(AppTheme.cardBackground)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(AppTheme.cardStroke, lineWidth: 1)
        )
    }
    
    // MARK: - Helper Functions
    
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
    
    private func formatDay(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd"
        return formatter.string(from: date)
    }
    
    private func formatMonth(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        return formatter.string(from: date)
    }
}

struct FormField<Content: View>: View {
    let title: String
    let isRequired: Bool
    let content: Content
    
    init(title: String, isRequired: Bool = false, @ViewBuilder content: () -> Content) {
        self.title = title
        self.isRequired = isRequired
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(AppTheme.textColor.opacity(0.8))
                
                if isRequired {
                    Text("*")
                        .foregroundColor(Color(hex: "#FF5757"))
                }
            }
            
            content
        }
    }
}
