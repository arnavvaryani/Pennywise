import SwiftUI
import Firebase
import FirebaseFirestore
import FirebaseAuth

struct BudgetPlannerView: View {
    @EnvironmentObject var plaidManager: PlaidManager
    
    // State variables
    @State private var showAddCategory = false
    @State private var categories: [BudgetCategory] = []
    @State private var monthlyIncome: Double = 0
    @State private var isRefreshing: Bool = false
    @State private var animateCards: Bool = false
    @State private var isLoading: Bool = true
    @State private var selectedCategory: BudgetCategory? = nil
    @State private var categorySpending: [String: Double] = [:]
    @State private var errorMessage: String? = nil
    @State private var showSuccessMessage = false
    @State private var successMessage = ""
    
    // Control auto-budget feature - Reset on each app run
    @State private var isAutobudgetRunning = false
    @AppStorage("lastAutobudgetDate") private var lastAutobudgetDate: Double = 0
    
    // Budget metrics
    var totalBudget: Double {
        categories.reduce(0) { $0 + $1.amount }
    }
    
    var remainingBudget: Double {
        monthlyIncome - totalBudget
    }
    
    // Debug logging for budget calculation
    func logBudgetValues() {
        print("DEBUG: Monthly Income = \(monthlyIncome)")
        print("DEBUG: Total Budget = \(totalBudget)")
        print("DEBUG: Remaining = \(remainingBudget)")
        print("DEBUG: Categories count = \(categories.count)")
        print("DEBUG: Total Spent This Month = \(totalSpentThisMonth)")
        if !categories.isEmpty {
            for category in categories {
                let spent = calculateSpentForCategory(category)
                print("DEBUG: Category \(category.name) = Budget: $\(category.amount), Spent: $\(spent)")
            }
        }
        
        print("DEBUG: Category Spending Map:")
        for (category, amount) in categorySpending {
            print("DEBUG:  - \(category): $\(amount)")
        }
    }
    
    var totalSpentThisMonth: Double {
        let calendar = Calendar.current
        let now = Date()
        let currentMonth = calendar.component(.month, from: now)
        let currentYear = calendar.component(.year, from: now)
        
        // Get transactions for current month
        return plaidManager.transactions
            .filter { transaction in
                let transactionMonth = calendar.component(.month, from: transaction.date)
                let transactionYear = calendar.component(.year, from: transaction.date)
                return transactionMonth == currentMonth && transactionYear == currentYear && transaction.amount > 0
            }
            .reduce(0) { $0 + $1.amount }
    }
    
    var budgetProgressPercentage: Double {
        if totalBudget == 0 { return 0 }
        return min(totalSpentThisMonth / totalBudget, 1.0)
    }
    
    var budgetStatus: BudgetStatus {
        let ratio = totalBudget > 0 ? totalSpentThisMonth / totalBudget : 0
        if ratio > 1.0 {
            return .overBudget
        } else if ratio > 0.9 {
            return .warning
        } else if ratio > 0.1 {
            return .onTrack
        } else {
            return .underBudget
        }
    }
    
    var body: some View {
        ZStack {
            // Background gradient
            AppTheme.backgroundGradient
                .edgesIgnoringSafeArea(.all)
            
            if isLoading {
                loadingView
            } else {
                VStack(spacing: 0) {
                    // Header
                    headerView
                        .padding(.horizontal)
                        .padding(.top, 12)
                        .padding(.bottom, 8)
                    
                    // Main content
                    mainContent
                }
            }
        }
        .sheet(isPresented: $showAddCategory) {
            AddBudgetCategoryView(onAdd: addCategory)
        }
        .sheet(item: $selectedCategory) { category in
            CategoryDetailView(
                category: category,
                onUpdate: { updatedCategory in
                    updateCategory(updatedCategory)
                },
                plaidManager: plaidManager
            )
        }
        .navigationTitle("Budget")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    autoBudget()
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "wand.and.stars")
                            .font(.system(size: 14))
                        Text("Auto Budget")
                            .font(.subheadline)
                    }
                    .padding(.vertical, 6)
                    .padding(.horizontal, 10)
                    .background(AppTheme.primaryGreen.opacity(0.2))
                    .cornerRadius(8)
                    .foregroundColor(AppTheme.primaryGreen)
                }
                .buttonStyle(ScaleButtonStyle())
                .disabled(isAutobudgetRunning) // Disable only during operation
            }
        }
        .onAppear {
            isLoading = true
            initializeData()
        }
        .alert(isPresented: $showSuccessMessage) {
            Alert(
                title: Text("Success"),
                message: Text(successMessage),
                dismissButton: .default(Text("OK"))
            )
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
    }
    
    // MARK: - Main Content Views
    
    // Main content area with tabs
    private var mainContent: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Budget overview card
                budgetOverviewCard
                    .padding(.horizontal)
                    .scaleEffect(animateCards ? 1.0 : 0.95)
                    .opacity(animateCards ? 1.0 : 0)
                
                // Budget progress card only shown when we have categories
                if !categories.isEmpty {
                    budgetProgressCard
                        .padding(.horizontal)
                        .scaleEffect(animateCards ? 1.0 : 0.95)
                        .opacity(animateCards ? 1.0 : 0)
                }
                
                // Budget allocation visualization
                if !categories.isEmpty {
                    budgetAllocationCard
                        .padding(.horizontal)
                        .scaleEffect(animateCards ? 1.0 : 0.95)
                        .opacity(animateCards ? 1.0 : 0)
                        
                    // Category section header - only shown when we have categories
                    HStack {
                        Text("Budget Categories")
                            .font(AppTheme.headlineFont())
                            .foregroundColor(AppTheme.textColor)
                        
                        Spacer()
                        
                        Button(action: {
                            showAddCategory = true
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: "plus")
                                    .font(.system(size: 14))
                                
                                Text("Add")
                                    .font(.subheadline)
                            }
                            .foregroundColor(AppTheme.textColor)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(AppTheme.primaryGreen.opacity(0.2))
                            .cornerRadius(10)
                        }
                        .buttonStyle(ScaleButtonStyle())
                    }
                    .padding(.horizontal)
                    
                    // Categories list
                    categoriesListView(categories: categories)
                } else {
                    // Single empty state view when no categories exist
                    noBudgetCategoriesView
                        .padding(.horizontal)
                        .scaleEffect(animateCards ? 1.0 : 0.95)
                        .opacity(animateCards ? 1.0 : 0)
                }
                
                // Bottom padding
                Spacer(minLength: 40)
            }
            .padding(.top, 16)
            .onAppear {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1)) {
                    animateCards = true
                }
            }
        }
    }
    
    // Loading view
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
                .progressViewStyle(CircularProgressViewStyle(tint: AppTheme.primaryGreen))
            
            Text("Loading your budget data...")
                .font(.headline)
                .foregroundColor(AppTheme.textColor)
                .padding(.top, 8)
        }
    }
    
    // Header view
    private var headerView: some View {
        HStack {
            Text("Monthly Budget")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(AppTheme.textColor)
            
            Spacer()
            
            // Optional refresh button
            Button(action: {
                refreshBudgetData()
            }) {
                Image(systemName: "arrow.clockwise")
                    .foregroundColor(AppTheme.primaryGreen)
                    .rotationEffect(Angle(degrees: isRefreshing ? 360 : 0))
                    .animation(isRefreshing ? Animation.linear(duration: 1).repeatForever(autoreverses: false) : .default, value: isRefreshing)
            }
            .disabled(isRefreshing)
        }
    }
    
    // Budget overview card
    private var budgetOverviewCard: some View {
        VStack(spacing: 5) {
            HStack(spacing: 0) {
                // Income
                budgetStatColumn(
                    title: "Income",
                    amount: monthlyIncome,
                    icon: "arrow.down.circle.fill",
                    color: AppTheme.primaryGreen,
                    showBorder: true
                )
                
                // Budgeted
                budgetStatColumn(
                    title: "Budgeted",
                    amount: totalBudget,
                    icon: "chart.pie.fill",
                    color: AppTheme.accentBlue,
                    showBorder: true
                )
                
                // Remaining
                budgetStatColumn(
                    title: "Remaining",
                    amount: remainingBudget,
                    icon: "banknote.fill",
                    color: remainingBudget >= 0 ? AppTheme.primaryGreen : Color(hex: "#FF5757"),
                    showBorder: false
                )
            }
            
            // Debug line for transparency - shown only in debug
            #if DEBUG
            Text("Income: $\(Int(monthlyIncome)) - Budgeted: $\(Int(totalBudget)) = Remaining: $\(Int(remainingBudget))")
                .font(.caption2)
                .foregroundColor(AppTheme.textColor.opacity(0.5))
                .padding(.bottom, 5)
            #endif
        }
        .background(AppTheme.cardBackground)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(AppTheme.cardStroke, lineWidth: 1)
        )
        .id("budget-overview-\(monthlyIncome)-\(totalBudget)") // Force refresh when values change
    }
    
    private var budgetProgressCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Budget Progress")
                .font(AppTheme.headlineFont())
                .foregroundColor(AppTheme.textColor)
                .accessibilityAddTraits(.isHeader)
            
            HStack(alignment: .center, spacing: 20) {
                // Progress circular indicator
                ZStack {
                    // Background circle
                    Circle()
                        .stroke(AppTheme.cardStroke, lineWidth: 12)
                        .frame(width: 150, height: 150)
                    
                    // Progress
                    Circle()
                        .trim(from: 0, to: CGFloat(budgetProgressPercentage))
                        .stroke(
                            budgetStatusColor(for: budgetStatus),
                            style: StrokeStyle(lineWidth: 12, lineCap: .round)
                        )
                        .frame(width: 150, height: 150)
                        .rotationEffect(.degrees(-90))
                    
                    // Center text
                    VStack(spacing: 2) {
                        Text("\(Int(budgetProgressPercentage * 100))%")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(AppTheme.textColor)
                        
                        Text("Spent")
                            .font(.subheadline)
                            .foregroundColor(AppTheme.textColor.opacity(0.7))
                    }
                }
                
                // Spending details
                VStack(alignment: .leading, spacing: 15) {
                    // Spent
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Spent This Month")
                            .font(.caption)
                            .foregroundColor(AppTheme.textColor.opacity(0.7))
                        
                        Text("$\(Int(totalSpentThisMonth))")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(AppTheme.accentBlue)
                    }
                    
                    Divider()
                        .background(AppTheme.cardStroke)
                    
                    // Budget
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Total Budget")
                            .font(.caption)
                            .foregroundColor(AppTheme.textColor.opacity(0.7))
                        
                        Text("$\(Int(totalBudget))")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(AppTheme.textColor)
                    }
                    
                    Divider()
                        .background(AppTheme.cardStroke)
                    
                    // Status
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Status")
                            .font(.caption)
                            .foregroundColor(AppTheme.textColor.opacity(0.7))
                        
                        HStack(spacing: 6) {
                            Circle()
                                .fill(budgetStatusColor(for: budgetStatus))
                                .frame(width: 8, height: 8)
                            
                            Text(budgetStatusText(for: budgetStatus))
                                .font(.subheadline)
                                .foregroundColor(budgetStatusColor(for: budgetStatus))
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
        .padding()
        .background(AppTheme.cardBackground)
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(AppTheme.cardStroke, lineWidth: 1)
        )
    }
    
    // Budget allocation card
    private var budgetAllocationCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Budget Allocation")
                .font(AppTheme.headlineFont())
                .foregroundColor(AppTheme.textColor)
                .accessibilityAddTraits(.isHeader)
            
            if totalBudget > 0 {
                // Pie chart visualization
                HStack {
                    // Chart
                    ZStack {
                        ForEach(0..<categories.count, id: \.self) { index in
                            PieSlice(
                                startAngle: calculateStartAngle(for: index),
                                endAngle: calculateEndAngle(for: index)
                            )
                            .fill(categories[index].color)
                            .onTapGesture {
                                selectedCategory = categories[index]
                            }
                        }
                        
                        // Center circle
                        Circle()
                            .fill(AppTheme.backgroundColor)
                            .frame(width: 60, height: 60)
                        
                        // Total amount
                        VStack(spacing: 0) {
                            Text("$\(Int(totalBudget))")
                                .font(.subheadline)
                                .fontWeight(.bold)
                                .foregroundColor(AppTheme.textColor)
                            
                            Text("Total")
                                .font(.caption2)
                                .foregroundColor(AppTheme.textColor.opacity(0.7))
                        }
                    }
                    .frame(width: 150, height: 150)
                    
                    // Legend
                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(categories.prefix(5)) { category in
                            Button(action: {
                                selectedCategory = category
                            }) {
                                HStack(spacing: 8) {
                                    RoundedRectangle(cornerRadius: 2)
                                        .fill(category.color)
                                        .frame(width: 12, height: 12)
                                    
                                    Text(category.name)
                                        .font(.caption)
                                        .foregroundColor(AppTheme.textColor)
                                    
                                    Spacer()
                                    
                                    Text("\(Int(category.amount / totalBudget * 100))%")
                                        .font(.caption)
                                        .foregroundColor(AppTheme.textColor.opacity(0.7))
                                }
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        
                        if categories.count > 5 {
                            Text("+ \(categories.count - 5) more categories")
                                .font(.caption)
                                .foregroundColor(AppTheme.accentBlue)
                        }
                    }
                    .padding(.leading, 16)
                }
                .padding()
                .background(AppTheme.cardBackground.opacity(0.5))
                .cornerRadius(12)
            } else {
                // Empty state
                Text("Add budget categories to see your allocation")
                    .font(.subheadline)
                    .foregroundColor(AppTheme.textColor.opacity(0.7))
                    .frame(maxWidth: .infinity, minHeight: 150)
                    .multilineTextAlignment(.center)
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
    
    // Empty budget categories view
    private var noBudgetCategoriesView: some View {
        VStack(spacing: 24) {
            Image(systemName: "chart.pie")
                .font(.system(size: 50))
                .foregroundColor(AppTheme.accentBlue.opacity(0.7))
            
            Text("No budget categories yet")
                .font(.headline)
                .foregroundColor(AppTheme.textColor)
            
            Text("Set up budget categories to track your spending and stay on top of your financial goals")
                .multilineTextAlignment(.center)
                .font(.subheadline)
                .foregroundColor(AppTheme.textColor.opacity(0.7))
                .padding(.horizontal)
            
            Button(action: {
                showAddCategory = true
            }) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 16))
                    
                    Text("Add First Category")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                .foregroundColor(AppTheme.backgroundColor)
                .padding(.vertical, 12)
                .padding(.horizontal, 24)
                .background(AppTheme.primaryGreen)
                .cornerRadius(12)
                .shadow(color: AppTheme.primaryGreen.opacity(0.3), radius: 5, x: 0, y: 2)
            }
            .buttonStyle(ScaleButtonStyle())
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(AppTheme.cardBackground)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(AppTheme.cardStroke, lineWidth: 1)
        )
    }
    
    // Categories list view
    private func categoriesListView(categories: [BudgetCategory]) -> some View {
        VStack(spacing: 16) {
            ForEach(categories) { category in
                BudgetCategoryRow(
                    category: category,
                    spent: calculateSpentForCategory(category),
                    onTap: {
                        selectedCategory = category
                    },
                    onAmountChange: { newAmount in
                        updateCategoryAmount(category, newAmount)
                    },
                    onDelete: { deleteCategory(category) }
                )
                .padding(.horizontal)
                .transition(.scale(scale: 0.9).combined(with: .opacity))
                .id("category-row-\(category.id)-\(calculateSpentForCategory(category))")
            }
        }
    }
    
    // Budget stat column
    private func budgetStatColumn(title: String, amount: Double, icon: String, color: Color, showBorder: Bool = false) -> some View {
        VStack(spacing: 10) {
            // Icon
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(color)
            
            // Amount - ensure we show the correct amount
            Text("$\(Int(abs(amount)))")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(amount >= 0 ? AppTheme.textColor : AppTheme.expenseColor)
                .id("budget-\(title)-\(amount)") // Force refresh when amount changes
            
            // Title
            Text(title)
                .font(.caption)
                .foregroundColor(AppTheme.textColor.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(AppTheme.cardBackground)
        .overlay(
            showBorder ? Rectangle()
                .frame(width: 1)
                .foregroundColor(AppTheme.cardStroke)
                .padding(.vertical, 10)
                .position(x: UIScreen.main.bounds.width / 3, y: 0) : nil
        )
    }
    
    // MARK: - Refresh Budget Data
    
    private func refreshBudgetData() {
        isRefreshing = true
        
        // Reload transactions from Plaid
        plaidManager.fetchTransactionsWithSync { success in
            DispatchQueue.main.async {
                // Recalculate category spending
                self.calculateCategorySpending()
                
                // Refresh UI
                self.isRefreshing = false
                
                // Log refreshed values
                print("DEBUG: Budget values after refresh:")
                self.logBudgetValues()
            }
        }
    }
    
    // MARK: - Initialize Data
    
    // Initialize data
    private func initializeData() {
        // Load user income from Firestore
        loadMonthlyIncome()
        
        // Load all budget categories
        loadBudgetCategories()
        
        // Reset Auto Budget availability if last run was on a different day
        checkAndResetAutoBudget()
        
        // Wait for both income and categories to load before calculating spending
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            // Calculate spending for each category
            self.calculateCategorySpending()
            
            // Turn off loading state after a short delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                self.isLoading = false
                
                // Log budget values for debugging
                self.logBudgetValues()
            }
        }
    }
    
    // Check if Auto Budget should be reset (new day)
    private func checkAndResetAutoBudget() {
        let currentDate = Date()
        let lastDate = Date(timeIntervalSince1970: lastAutobudgetDate)
        
        // Check if the dates are from different days
        if !Calendar.current.isDate(lastDate, inSameDayAs: currentDate) {
            // Reset Auto Budget if it's a new day
            isAutobudgetRunning = false
        }
    }
    
    // Load monthly income
    private func loadMonthlyIncome() {
        guard let userId = Auth.auth().currentUser?.uid else {
            errorMessage = "User not logged in"
            isLoading = false
            return
        }
        
        let db = Firestore.firestore()
        db.collection("users").document(userId).getDocument { snapshot, error in
            if let error = error {
                errorMessage = "Error loading income: \(error.localizedDescription)"
                isLoading = false
                return
            }
            
            if let document = snapshot, document.exists {
                if let income = document.data()?["monthlyIncome"] as? Double {
                    self.monthlyIncome = income
                } else {
                    // Fetch from Plaid transactions as a fallback
                    self.calculateMonthlyIncomeFromTransactions()
                }
            } else {
                // Fetch from Plaid transactions if no document exists
                self.calculateMonthlyIncomeFromTransactions()
            }
        }
    }
    
    private func calculateMonthlyIncomeFromTransactions() {
        let calendar = Calendar.current
        let now = Date()
        let currentMonth = calendar.component(.month, from: now)
        let currentYear = calendar.component(.year, from: now)
        
        // Filter for income transactions (negative amounts)
        let incomeTransactions = plaidManager.transactions.filter { transaction in
            let transactionMonth = calendar.component(.month, from: transaction.date)
            let transactionYear = calendar.component(.year, from: transaction.date)
            return transactionMonth == currentMonth &&
            transactionYear == currentYear &&
            transaction.amount < 0
        }
        
        // Sum absolute values of income transactions
        let calculatedIncome = abs(incomeTransactions.reduce(0) { $0 + $1.amount })
        
        if calculatedIncome > 0 {
            self.monthlyIncome = calculatedIncome
            print("DEBUG: Set monthly income from transactions to $\(calculatedIncome)")
        } else {
            // Set default value for demo purposes
            self.monthlyIncome = 5000
            print("DEBUG: Set default monthly income to $5000")
        }
        
        // Save the income to Firestore to ensure persistence
        saveMonthlyIncome(self.monthlyIncome)
    }
    
    // Save monthly income to Firestore
    private func saveMonthlyIncome(_ income: Double) {
        guard let userId = Auth.auth().currentUser?.uid else {
            return
        }
        
        let db = Firestore.firestore()
        let userRef = db.collection("users").document(userId)
        
        userRef.updateData([
            "monthlyIncome": income,
            "updatedAt": FieldValue.serverTimestamp()
        ]) { error in
            if let error = error {
                print("DEBUG: Error saving monthly income: \(error.localizedDescription)")
            } else {
                print("DEBUG: Successfully saved monthly income of $\(income) to Firestore")
            }
        }
    }

    // Load budget categories
    private func loadBudgetCategories() {
        guard let userId = Auth.auth().currentUser?.uid else {
            errorMessage = "User not logged in"
            isLoading = false
            return
        }
        
        let db = Firestore.firestore()
        
        db.collection("users/\(userId)/budgetCategories").getDocuments { snapshot, error in
            if let error = error {
                self.errorMessage = "Error loading categories: \(error.localizedDescription)"
                self.isLoading = false
                return
            }
            
            if let documents = snapshot?.documents {
                var loadedCategories: [BudgetCategory] = []
                
                for document in documents {
                    if let name = document.data()["name"] as? String,
                       let amount = document.data()["amount"] as? Double,
                       let icon = document.data()["icon"] as? String,
                       let colorHex = document.data()["color"] as? String {
                        
                        // Create a BudgetCategory with the document ID
                        let category = BudgetCategory(
                            id: document.documentID,  // Store the Firestore document ID
                            name: name,
                            amount: amount,
                            icon: icon,
                            color: Color(hex: colorHex)
                        )
                        
                        loadedCategories.append(category)
                    }
                }
                
                self.categories = loadedCategories
            }
        }
    }
    
    // Calculate spending for each category - FIXED to match categories correctly
    private func calculateCategorySpending() {
        let calendar = Calendar.current
        let now = Date()
        let currentMonth = calendar.component(.month, from: now)
        let currentYear = calendar.component(.year, from: now)
        
        var spending: [String: Double] = [:]
        
        // Pre-initialize all budget categories with zero spending
        for category in categories {
            spending[category.name] = 0.0
        }
        
        // Get transactions for current month
        let monthTransactions = plaidManager.transactions.filter { transaction in
            let transactionMonth = calendar.component(.month, from: transaction.date)
            let transactionYear = calendar.component(.year, from: transaction.date)
            return transactionMonth == currentMonth && transactionYear == currentYear && transaction.amount > 0
        }
        
        print("DEBUG: Found \(monthTransactions.count) transactions for current month")
        
        // Get all unique Plaid transaction categories
        var plaidCategories = Set<String>()
        for transaction in monthTransactions {
            plaidCategories.insert(transaction.category)
        }
        
        print("DEBUG: Unique Plaid transaction categories: \(plaidCategories.sorted())")
        
        // Map transactions directly to categories
        for transaction in monthTransactions {
            // Find exact match first
            if let exactMatch = categories.first(where: { $0.name == transaction.category }) {
                spending[exactMatch.name, default: 0] += transaction.amount
                print("DEBUG: Direct match: '\(transaction.merchantName)' ($\(transaction.amount)) → '\(exactMatch.name)'")
            }
            // Try case-insensitive match
            else if let caseInsensitiveMatch = categories.first(where: {
                $0.name.lowercased() == transaction.category.lowercased()
            }) {
                spending[caseInsensitiveMatch.name, default: 0] += transaction.amount
                print("DEBUG: Case-insensitive match: '\(transaction.merchantName)' ($\(transaction.amount)) → '\(caseInsensitiveMatch.name)'")
            }
            // No match found - need to handle this transaction
            else {
                handleUnmatchedTransaction(transaction, spending: &spending)
            }
        }
        
        self.categorySpending = spending
        
        // Log the spending mapping for debugging
        print("DEBUG: Final category spending mapping:")
        for (category, amount) in spending {
            print("DEBUG: Category '\(category)': $\(amount)")
        }
    }

    // Handles transactions that don't have a direct category match
    private func handleUnmatchedTransaction(_ transaction: PlaidTransaction, spending: inout [String: Double]) {
        let transactionCategory = transaction.category
        let merchantName = transaction.merchantName
        
        // If we have an "Other" or "Miscellaneous" category, use it
        if let otherCategory = categories.first(where: {
            $0.name == "Other" || $0.name == "Miscellaneous"
        }) {
            spending[otherCategory.name, default: 0] += transaction.amount
            print("DEBUG: Unmatched transaction '\(merchantName)' ($\(transaction.amount)) added to '\(otherCategory.name)'")
            return
        }
        
        // Try to find the most similar category based on substrings
        var bestMatch: BudgetCategory? = nil
        var bestMatchScore = 0
        
        for category in categories {
            var score = 0
            
            // Check if transaction category contains budget category name
            if transactionCategory.lowercased().contains(category.name.lowercased()) {
                score += 5
            }
            
            // Check if budget category name contains transaction category
            if category.name.lowercased().contains(transactionCategory.lowercased()) {
                score += 5
            }
            
            // Check if merchant name matches category
            if merchantName.lowercased().contains(category.name.lowercased()) {
                score += 3
            }
            
            if score > bestMatchScore {
                bestMatchScore = score
                bestMatch = category
            }
        }
        
        if let match = bestMatch, bestMatchScore > 0 {
            spending[match.name, default: 0] += transaction.amount
            print("DEBUG: Fuzzy match: '\(merchantName)' ($\(transaction.amount)) → '\(match.name)' (score: \(bestMatchScore))")
        } else {
            // Last resort: add to the largest budget category
            let largestCategory = categories.max(by: { $0.amount < $1.amount })
            if let category = largestCategory {
                spending[category.name, default: 0] += transaction.amount
                print("DEBUG: Fallback match: '\(merchantName)' ($\(transaction.amount)) → '\(category.name)' (largest category)")
            }
        }
    }

    // MARK: - Auto Category Creation from Plaid Data

    // This function can be called to automatically create budget categories from actual Plaid transactions
    func createBudgetCategoriesFromPlaidTransactions() {
        guard let userId = Auth.auth().currentUser?.uid else {
            errorMessage = "User not logged in"
            return
        }
        
        // Set auto-budget running state
        isAutobudgetRunning = true
        
        // Get unique transaction categories from Plaid
        let plaidTransactionCategories = getUniquePlaidCategories()
        
        // Check if we have categories to create
        if plaidTransactionCategories.isEmpty {
            errorMessage = "No transaction categories found in your Plaid data"
            isAutobudgetRunning = false
            return
        }
        
        // Target percentages based on typical spending patterns
        // These will be distributed among the available categories proportionally
        var targetPercentages: [String: Double] = [
            "Food and Drink": 0.15,
            "Groceries": 0.10,
            "General Merchandise": 0.10,
            "Travel": 0.05,
            "Home Improvement": 0.05,
            "Entertainment": 0.05,
            "Restaurants": 0.08,
            "Transportation": 0.07,
            "Utilities": 0.06,
            "Housing": 0.20,
            "Healthcare": 0.05,
            "Service": 0.04
            // Default other categories will get equal share of remaining percentage
        ]
        
        // Total allocated percentage
        let totalAllocatedPercentage = targetPercentages.values.reduce(0, +)
        
        // Default percentage for categories not explicitly defined
        let defaultPercentage = (1.0 - totalAllocatedPercentage) / Double(max(1, plaidTransactionCategories.count - targetPercentages.count))
        
        print("DEBUG: Creating budget categories from \(plaidTransactionCategories.count) Plaid categories")
        
        let db = Firestore.firestore()
        let batch = db.batch()
        
        // Track new categories to be added
        var newCategories: [BudgetCategory] = []
        
        // Check which categories already exist
        let existingCategoryNames = categories.map { $0.name }
        
        for categoryName in plaidTransactionCategories {
            // Skip if category already exists
            if existingCategoryNames.contains(categoryName) {
                continue
            }
            
            // Determine icon and color based on category name
            let (icon, color) = getIconAndColor(for: categoryName)
            
            // Determine budget percentage
            let percentage = targetPercentages[categoryName] ?? defaultPercentage
            let budgetAmount = monthlyIncome * percentage
            
            // Create document reference
            let categoryRef = db.collection("users/\(userId)/budgetCategories").document()
            
            let categoryData: [String: Any] = [
                "name": categoryName,
                "amount": budgetAmount,
                "icon": icon,
                "color": color.hexString,
                "isEssential": CategoryDetailView.isEssentialCategory(categoryName),
                "updatedAt": FieldValue.serverTimestamp()
            ]
            
            batch.setData(categoryData, forDocument: categoryRef)
            
            // Create local category object
            let newCategory = BudgetCategory(
                id: categoryRef.documentID,
                name: categoryName,
                amount: budgetAmount,
                icon: icon,
                color: color
            )
            
            newCategories.append(newCategory)
        }
        
        // Commit all the changes
        batch.commit { error in
            DispatchQueue.main.async {
                self.isAutobudgetRunning = false
                
                if let error = error {
                    self.errorMessage = "Error creating categories: \(error.localizedDescription)"
                } else {
                    // Add new categories to our local array
                    if !newCategories.isEmpty {
                        withAnimation {
                            self.categories.append(contentsOf: newCategories)
                        }
                        
                        self.successMessage = "Created \(newCategories.count) budget categories from your transaction data"
                        self.showSuccessMessage = true
                        
                        // Recalculate category spending
                        self.calculateCategorySpending()
                    } else {
                        self.errorMessage = "No new categories needed - all transaction categories are already set up"
                    }
                }
            }
        }
    }

    // Get unique transaction categories from Plaid
    private func getUniquePlaidCategories() -> [String] {
        // Get all transactions
        let transactions = plaidManager.transactions
        
        // Extract unique categories
        var uniqueCategories = Set<String>()
        for transaction in transactions {
            if !transaction.category.isEmpty {
                uniqueCategories.insert(transaction.category)
            }
        }
        
        return Array(uniqueCategories)
    }

    // Helper to determine icon and color for a given category
    private func getIconAndColor(for categoryName: String) -> (String, Color) {
        let categoryLower = categoryName.lowercased()
        
        // Shopping/retail
        if categoryLower.contains("shop") || categoryLower.contains("merchandise") {
            return ("cart.fill", AppTheme.accentBlue)
        }
        // Food
        else if categoryLower.contains("food") || categoryLower.contains("restaurant") || categoryLower.contains("groceries") {
            return ("fork.knife", Color(hex: "#FF8C00"))
        }
        // Housing/utilities
        else if categoryLower.contains("home") || categoryLower.contains("house") || categoryLower.contains("mortgage") || categoryLower.contains("rent") {
            return ("house.fill", AppTheme.primaryGreen)
        }
        // Utilities
        else if categoryLower.contains("utilities") || categoryLower.contains("bill") {
            return ("bolt.fill", Color(hex: "#9370DB"))
        }
        // Transportation
        else if categoryLower.contains("transport") || categoryLower.contains("travel") || categoryLower.contains("gas") {
            return ("car.fill", AppTheme.accentPurple)
        }
        // Healthcare
        else if categoryLower.contains("health") || categoryLower.contains("medical") {
            return ("heart.fill", Color(hex: "#FF5757"))
        }
        // Entertainment
        else if categoryLower.contains("entertainment") || categoryLower.contains("recreation") {
            return ("play.tv", Color(hex: "#FFD700"))
        }
        // Education
        else if categoryLower.contains("education") || categoryLower.contains("school") {
            return ("book.fill", Color(hex: "#4682B4"))
        }
        // Personal care
        else if categoryLower.contains("personal") || categoryLower.contains("beauty") {
            return ("person.fill", Color(hex: "#FF7F50"))
        }
        // Financial
        else if categoryLower.contains("finance") || categoryLower.contains("bank") || categoryLower.contains("invest") {
            return ("dollarsign.circle.fill", Color(hex: "#50C878"))
        }
        // Debt
        else if categoryLower.contains("debt") || categoryLower.contains("loan") || categoryLower.contains("credit") {
            return ("creditcard.fill", Color(hex: "#20B2AA"))
        }
        // Default
        else {
            return ("tag.fill", Color(hex: "#BA55D3"))
        }
    }

    // Compute a hash color from a string (for consistent category colors)
    private func hashColor(from string: String) -> Color {
        let hash = abs(string.hashValue)
        let hue = Double(hash % 256) / 256.0
        return Color(hue: hue, saturation: 0.7, brightness: 0.9)
    }
    
    private func findBestCategoryMatch(for transaction: PlaidTransaction) -> String {
        // Check if we have an "Other" category defined
        if let otherCategory = categories.first(where: { $0.name == "Other" }) {
            return otherCategory.name
        }
        
        // Try to find a category based on transaction name and merchant name keywords
        let transactionCategory = transaction.category.lowercased()
        let merchantName = transaction.merchantName.lowercased()
        
        // Define keyword mappings to categories
        let keywordMappings: [(keywords: [String], categoryType: String)] = [
            (["grocery", "food", "supermarket", "market"], "Groceries"),
            (["restaurant", "dining", "cafe", "coffee", "food service"], "Dining Out"),
            (["transport", "uber", "lyft", "taxi", "train", "transit", "gas", "fuel"], "Transportation"),
            (["utility", "electric", "gas", "water", "internet", "phone", "bill"], "Utilities"),
            (["entertainment", "movie", "netflix", "spotify", "streaming", "game"], "Entertainment"),
            (["shopping", "retail", "amazon", "walmart", "target"], "Shopping"),
            (["health", "doctor", "medical", "pharmacy", "hospital", "clinic"], "Healthcare"),
            (["rent", "mortgage", "housing", "apartment", "condo"], "Housing"),
            (["subscription", "membership"], "Subscriptions"),
            (["personal care", "beauty", "haircut", "salon", "spa"], "Personal Care"),
            (["education", "school", "tuition", "book", "course"], "Education"),
            (["save", "saving", "investment"], "Savings"),
            (["debt", "loan", "credit card", "payment"], "Debt Repayment")
        ]
        
        // Check for keyword matches
        for (keywords, categoryType) in keywordMappings {
            for keyword in keywords {
                if transactionCategory.contains(keyword) || merchantName.contains(keyword) {
                    // Try to find the matching category in our budget categories
                    if let matchingCategory = categories.first(where: {
                        $0.name.lowercased().contains(categoryType.lowercased())
                    }) {
                        return matchingCategory.name
                    }
                }
            }
        }
        
        // If we couldn't find a match and don't have an "Other" category,
        // return the first category as a fallback
        return categories.first?.name ?? "Uncategorized"
    }

    
    // Assign a transaction to the closest matching category based on keywords
    private func assignTransactionToClosestCategory(_ transaction: PlaidTransaction, spending: inout [String: Double]) {
        let transactionCategory = transaction.category.lowercased()
        let merchantName = transaction.merchantName.lowercased()
        
        // Category matching logic - check if any of our budget categories match this transaction
        var bestMatch: String? = nil
        var bestScore = 0
        
        for category in categories {
            let categoryName = category.name.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
            var score = 0
            
            // Exact category match
            if transactionCategory == categoryName {
                score += 100
            }
            // Contains category name
            else if transactionCategory.contains(categoryName) {
                score += 50
            }
            // Merchant name contains category name
            else if merchantName.contains(categoryName) {
                score += 25
            }
            
            // Additional keyword matching for common categories
            if categoryName == "groceries" && (
                transactionCategory.contains("groceries") ||
                transactionCategory.contains("supermarket") ||
                merchantName.contains("food") ||
                merchantName.contains("market") ||
                merchantName.contains("grocery")
            ) {
                score += 40
            } else if categoryName == "dining out" && (
                transactionCategory.contains("restaurant") ||
                transactionCategory.contains("food") ||
                transactionCategory.contains("dining") ||
                merchantName.contains("restaurant") ||
                merchantName.contains("cafe") ||
                merchantName.contains("coffee")
            ) {
                score += 40
            } else if categoryName == "transportation" && (
                transactionCategory.contains("travel") ||
                transactionCategory.contains("transit") ||
                transactionCategory.contains("uber") ||
                transactionCategory.contains("lyft") ||
                transactionCategory.contains("taxi") ||
                merchantName.contains("gas") ||
                merchantName.contains("transit") ||
                merchantName.contains("uber") ||
                merchantName.contains("lyft")
            ) {
                score += 40
            } else if categoryName == "utilities" && (
                transactionCategory.contains("utilities") ||
                transactionCategory.contains("bill") ||
                merchantName.contains("electric") ||
                merchantName.contains("gas") ||
                merchantName.contains("water") ||
                merchantName.contains("internet") ||
                merchantName.contains("phone")
            ) {
                score += 40
            } else if categoryName == "entertainment" && (
                transactionCategory.contains("entertainment") ||
                transactionCategory.contains("recreation") ||
                merchantName.contains("netflix") ||
                merchantName.contains("spotify") ||
                merchantName.contains("movie") ||
                merchantName.contains("theater") ||
                merchantName.contains("cinema")
            ) {
                score += 40
            } else if categoryName == "shopping" && (
                transactionCategory.contains("shopping") ||
                transactionCategory.contains("retail") ||
                merchantName.contains("amazon") ||
                merchantName.contains("walmart") ||
                merchantName.contains("target")
            ) {
                score += 40
            } else if categoryName == "healthcare" && (
                transactionCategory.contains("health") ||
                transactionCategory.contains("medical") ||
                transactionCategory.contains("pharmacy") ||
                merchantName.contains("clinic") ||
                merchantName.contains("doctor") ||
                merchantName.contains("pharmacy") ||
                merchantName.contains("hospital")
            ) {
                score += 40
            } else if categoryName == "housing" && (
                transactionCategory.contains("housing") ||
                transactionCategory.contains("rent") ||
                transactionCategory.contains("mortgage") ||
                merchantName.contains("apartment") ||
                merchantName.contains("rent") ||
                merchantName.contains("mortgage")
            ) {
                score += 40
            }
            
            if score > bestScore {
                bestScore = score
                bestMatch = categoryName
            }
        }
        
        // If we found a match with a reasonable score, assign transaction to that category
        if let categoryName = bestMatch, bestScore >= 20 {
            // Find the original category name with proper case
            if let matchedCategory = categories.first(where: { $0.name.lowercased().trimmingCharacters(in: .whitespacesAndNewlines) == categoryName }) {
                let originalName = matchedCategory.name.trimmingCharacters(in: .whitespacesAndNewlines)
                spending[originalName, default: 0] += transaction.amount
            }
        } else {
            // Add to "Other" or a general category if no good match found
            let otherCategory = "Other"
            spending[otherCategory, default: 0] += transaction.amount
        }
    }
    
    // Calculate spent amount for a specific category
    private func calculateSpentForCategory(_ category: BudgetCategory) -> Double {
        let categoryName = category.name.trimmingCharacters(in: .whitespacesAndNewlines)
        return categorySpending[categoryName] ?? 0.0
    }
    
    // Add a new budget category
    private func addCategory(_ category: BudgetCategory) {
        guard let userId = Auth.auth().currentUser?.uid else {
            errorMessage = "User not logged in"
            return
        }
        
        // Check for duplicate category names
        let categoryNameLowercased = category.name.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        let existingNames = categories.map { $0.name.lowercased().trimmingCharacters(in: .whitespacesAndNewlines) }
        
        if existingNames.contains(categoryNameLowercased) {
            errorMessage = "A category with this name already exists"
            return
        }
        
        let db = Firestore.firestore()
        let categoryRef = db.collection("users/\(userId)/budgetCategories").document()
        
        // Convert Color to hex string
        let colorHex = category.color.hexString
        
        let data: [String: Any] = [
            "name": category.name.trimmingCharacters(in: .whitespacesAndNewlines),
            "amount": category.amount,
            "icon": category.icon,
            "color": colorHex,
            "isEssential": CategoryDetailView.isEssentialCategory(category.name),
            "updatedAt": FieldValue.serverTimestamp()
        ]
        
        categoryRef.setData(data) { error in
            if let error = error {
                self.errorMessage = "Error adding category: \(error.localizedDescription)"
                return
            }
            
            // Add the category locally with the Firestore ID
            let newCategory = BudgetCategory(
                id: categoryRef.documentID,  // Use the Firestore document ID
                name: category.name.trimmingCharacters(in: .whitespacesAndNewlines),
                amount: category.amount,
                icon: category.icon,
                color: category.color
            )
            
            // Update our local categories array
            withAnimation {
                self.categories.append(newCategory)
            }
            
            // Recalculate spending to include the new category
            self.calculateCategorySpending()
        }
    }
    
    // Update a budget category
    private func updateCategory(_ category: BudgetCategory) {
        guard let userId = Auth.auth().currentUser?.uid else {
            errorMessage = "User not logged in"
            return
        }
        
        let db = Firestore.firestore()
        let categoryRef = db.collection("users/\(userId)/budgetCategories").document(category.id)
        
        // Convert Color to hex string
        let colorHex = category.color.hexString
        
        let data: [String: Any] = [
            "name": category.name.trimmingCharacters(in: .whitespacesAndNewlines),
            "amount": category.amount,
            "icon": category.icon,
            "color": colorHex,
            "isEssential": CategoryDetailView.isEssentialCategory(category.name),
            "updatedAt": FieldValue.serverTimestamp()
        ]
        
        categoryRef.updateData(data) { error in
            if let error = error {
                self.errorMessage = "Error updating category: \(error.localizedDescription)"
                return
            }
            
            // Find and update the category in our local array
            if let index = self.categories.firstIndex(where: { $0.id == category.id }) {
                withAnimation {
                    self.categories[index] = category
                }
            }
            
            // Recalculate category spending
            self.calculateCategorySpending()
        }
    }
    
    // Update category amount
    private func updateCategoryAmount(_ category: BudgetCategory, _ newAmount: Double) {
        guard let userId = Auth.auth().currentUser?.uid else {
            errorMessage = "User not logged in"
            return
        }
        
        let db = Firestore.firestore()
        let categoryRef = db.collection("users/\(userId)/budgetCategories").document(category.id)
        
        categoryRef.updateData([
            "amount": newAmount,
            "updatedAt": FieldValue.serverTimestamp()
        ]) { error in
            if let error = error {
                self.errorMessage = "Error updating category amount: \(error.localizedDescription)"
                return
            }
            
            // Update local category
            if let index = self.categories.firstIndex(where: { $0.id == category.id }) {
                var updatedCategory = self.categories[index]
                updatedCategory.amount = newAmount
                
                withAnimation {
                    self.categories[index] = updatedCategory
                }
            }
        }
    }
    
    // Delete a budget category
    private func deleteCategory(_ category: BudgetCategory) {
        guard let userId = Auth.auth().currentUser?.uid else {
            errorMessage = "User not logged in"
            return
        }
        
        let db = Firestore.firestore()
        let categoryRef = db.collection("users/\(userId)/budgetCategories").document(category.id)
        
        categoryRef.delete { error in
            if let error = error {
                self.errorMessage = "Error deleting category: \(error.localizedDescription)"
                return
            }
            
            // Remove from local array
            withAnimation {
                self.categories.removeAll { $0.id == category.id }
                
                // Also remove from category spending map
                self.categorySpending.removeValue(forKey: category.name.trimmingCharacters(in: .whitespacesAndNewlines))
            }
        }
    }
    
    // MARK: - Auto Budget Method
    
    // Auto budget function
    func autoBudget() {
        // Set auto-budget running state
        isAutobudgetRunning = true
        
        // Record when Auto Budget was last run
        lastAutobudgetDate = Date().timeIntervalSince1970
        
        // First verify we have income amount
        if monthlyIncome <= 0 {
            calculateMonthlyIncomeFromTransactions()
            
            if monthlyIncome <= 0 {
                monthlyIncome = 5000 // Set default for testing
                errorMessage = "Using a default monthly income of $5,000 for budget calculation."
                isAutobudgetRunning = false
                return
            }
        }
        
        // Debug budget before auto-budget
        print("DEBUG: Budget values BEFORE auto-budget:")
        logBudgetValues()
        
        isLoading = true
        
        // Define default categories using the 50/30/20 rule
        let defaultCategories = [
            // Needs (50%)
            ("Housing", "house.fill", AppTheme.primaryGreen, 0.25, true),  // 25% of income
            ("Groceries", "cart.fill", AppTheme.accentBlue, 0.10, true),   // 10% of income
            ("Utilities", "bolt.fill", Color(hex: "#9370DB"), 0.05, true), // 5% of income
            ("Transportation", "car.fill", AppTheme.accentPurple, 0.05, true), // 5% of income
            ("Healthcare", "heart.fill", Color(hex: "#FF5757"), 0.05, true), // 5% of income
            
            // Wants (30%)
            ("Dining Out", "fork.knife", Color(hex: "#FF8C00"), 0.08, false), // 8% of income
            ("Entertainment", "play.tv", Color(hex: "#FFD700"), 0.07, false), // 7% of income
            ("Shopping", "bag.fill", Color(hex: "#FF69B4"), 0.08, false),    // 8% of income
            ("Subscriptions", "repeat", Color(hex: "#BA55D3"), 0.04, false), // 4% of income
            ("Personal Care", "person.fill", Color(hex: "#FF7F50"), 0.03, false), // 3% of income
            
            // Savings/Debt (20%)
            ("Savings", "banknote.fill", AppTheme.primaryGreen, 0.15, false), // 15% of income
            ("Debt Repayment", "creditcard.fill", Color(hex: "#20B2AA"), 0.05, false) // 5% of income
        ]
        
        guard let userId = Auth.auth().currentUser?.uid else {
            errorMessage = "User not logged in"
            isLoading = false
            isAutobudgetRunning = false
            return
        }
        
        let db = Firestore.firestore()
        
        // Get all existing categories to identify which to update vs. create
        db.collection("users/\(userId)/budgetCategories").getDocuments { [self] snapshot, error in
            if let error = error {
                self.errorMessage = "Error fetching categories: \(error.localizedDescription)"
                self.isLoading = false
                self.isAutobudgetRunning = false
                return
            }
            
            // Dictionary to track existing categories by name
            var existingCategoriesById: [String: BudgetCategory] = [:]
            var existingCategoriesByName: [String: (BudgetCategory, String)] = [:]
            
            if let documents = snapshot?.documents {
                for document in documents {
                    if let name = document.data()["name"] as? String,
                       let amount = document.data()["amount"] as? Double,
                       let icon = document.data()["icon"] as? String,
                       let colorHex = document.data()["color"] as? String {
                        
                        let normalizedName = name.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
                        
                        let category = BudgetCategory(
                            id: document.documentID,
                            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                            amount: amount,
                            icon: icon,
                            color: Color(hex: colorHex)
                        )
                        
                        existingCategoriesById[document.documentID] = category
                        existingCategoriesByName[normalizedName] = (category, document.documentID)
                    }
                }
            }
            
            // Now create a batch to update or add categories
            let batch = db.batch()
            
            // Track categories that will be updated or added
            var categoriesToUpdate: [BudgetCategory] = []
            var newCategoriesToAdd: [BudgetCategory] = []
            
            // Process each default category
            for (categoryName, icon, color, percentage, isEssential) in defaultCategories {
                let categoryNameLowercased = categoryName.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
                let budgetAmount = monthlyIncome * percentage
                
                // Check if this category already exists (by normalized name)
                if let (existingCategory, docId) = existingCategoriesByName[categoryNameLowercased] {
                    // Update existing category with new amount but keep other properties
                    let categoryRef = db.collection("users/\(userId)/budgetCategories").document(docId)
                    
                    batch.updateData([
                        "amount": budgetAmount,
                        "updatedAt": FieldValue.serverTimestamp()
                    ], forDocument: categoryRef)
                    
                    // Update local copy with new amount
                    var updatedCategory = existingCategory
                    updatedCategory.amount = budgetAmount
                    categoriesToUpdate.append(updatedCategory)
                } else {
                    // Create new category
                    let newCategoryRef = db.collection("users/\(userId)/budgetCategories").document()
                    
                    let newCategoryData: [String: Any] = [
                        "name": categoryName.trimmingCharacters(in: .whitespacesAndNewlines),
                        "amount": budgetAmount,
                        "icon": icon,
                        "color": color.hexString,
                        "isEssential": isEssential,
                        "updatedAt": FieldValue.serverTimestamp()
                    ]
                    
                    batch.setData(newCategoryData, forDocument: newCategoryRef)
                    
                    // Create local copy for immediate UI update
                    let newCategory = BudgetCategory(
                        id: newCategoryRef.documentID,
                        name: categoryName.trimmingCharacters(in: .whitespacesAndNewlines),
                        amount: budgetAmount,
                        icon: icon,
                        color: color
                    )
                    
                    newCategoriesToAdd.append(newCategory)
                }
            }
            
            // Commit all the changes
            batch.commit { error in
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.isAutobudgetRunning = false
                    
                    if let error = error {
                        self.errorMessage = "Error updating budget: \(error.localizedDescription)"
                        return
                    }
                    
                    // Update our local array
                    
                    // First update existing categories
                    for updatedCategory in categoriesToUpdate {
                        if let index = self.categories.firstIndex(where: { $0.id == updatedCategory.id }) {
                            self.categories[index] = updatedCategory
                        }
                    }
                    
                    // Then add new categories
                    self.categories.append(contentsOf: newCategoriesToAdd)
                    
                    // Show success message
                    self.successMessage = "Budget has been optimized with the 50/30/20 rule: 50% for needs, 30% for wants, 20% for savings & debt repayment."
                    self.showSuccessMessage = true
                    
                    // Update budget usage
                    self.calculateCategorySpending()
                    
                    // Debug budget after auto-budget
                    print("DEBUG: Budget values AFTER auto-budget:")
                    self.logBudgetValues()
                }
            }
        }
    }
    
    // MARK: - Helper Functions
    
    // Get budget status color
    private func budgetStatusColor(for status: BudgetStatus) -> Color {
        switch status {
        case .overBudget:
            return Color(hex: "#FF5757") // Red
        case .warning:
            return Color(hex: "#FFD700") // Yellow
        case .onTrack:
            return AppTheme.primaryGreen // Green
        case .underBudget:
            return AppTheme.accentBlue // Blue
        }
    }
    
    // Get budget status text
    private func budgetStatusText(for status: BudgetStatus) -> String {
        switch status {
        case .overBudget:
            return "Over Budget"
        case .warning:
            return "Approaching Limit"
        case .onTrack:
            return "On Track"
        case .underBudget:
            return "Under Budget"
        }
    }
    
    // Calculate start angle for pie slice
    private func calculateStartAngle(for index: Int) -> Angle {
        let precedingTotal = categories.prefix(index).reduce(0) { $0 + $1.amount }
        return .degrees(precedingTotal / totalBudget * 360 - 90)
    }
    
    // Calculate end angle for pie slice
    private func calculateEndAngle(for index: Int) -> Angle {
        let precedingTotal = categories.prefix(index).reduce(0) { $0 + $1.amount }
        let categoryAmount = categories[index].amount
        return .degrees((precedingTotal + categoryAmount) / totalBudget * 360 - 90)
    }
}

// MARK: - Supporting Types

// Alert data for error handling
struct AlertData: Identifiable {
    var id: String
    var message: String
}

// Budget status types
enum BudgetStatus {
    case overBudget
    case warning
    case onTrack
    case underBudget
}

// Button style with scale animation
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .opacity(configuration.isPressed ? 0.9 : 1)
            .animation(.spring(response: 0.2, dampingFraction: 0.7), value: configuration.isPressed)
    }
}
