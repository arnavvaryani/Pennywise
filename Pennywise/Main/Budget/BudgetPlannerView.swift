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
    @State private var showingCategoryDetail: Bool = false
    @State private var selectedCategory: BudgetCategory? = nil
    @State private var categorySpending: [String: Double] = [:]
    @State private var errorMessage: String? = nil
    @State private var showSuccessMessage = false
    @State private var successMessage = ""
    
    // Budget metrics
    var totalBudget: Double {
        categories.reduce(0) { $0 + $1.amount }
    }
    
    var remainingBudget: Double {
        monthlyIncome - totalBudget
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
        let ratio = totalSpentThisMonth / totalBudget
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
        .sheet(isPresented: $showingCategoryDetail) {
            if let category = selectedCategory {
                CategoryDetailView(
                    category: category,
                    onUpdate: { updatedCategory in
                        updateCategory(updatedCategory)
                    },
                    plaidManager: plaidManager
                )
            }
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
        }
    }
    
    // Budget overview card
    private var budgetOverviewCard: some View {
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
        .background(AppTheme.cardBackground)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(AppTheme.cardStroke, lineWidth: 1)
        )
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
                            .font(.headline)
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
                            .font(.headline)
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
                                showingCategoryDetail = true
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
                        ForEach(categories.prefix(5), id: \.id) { category in
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
            if categories.isEmpty {
                // Empty state is already shown in budgetAllocationCard
                EmptyView()
            } else {
                ForEach(Array(categories.enumerated()), id: \.element.id) { index, category in
                    BudgetCategoryRow(
                        category: category,
                        spent: calculateSpentForCategory(category),
                        onTap: {
                            selectedCategory = category
                            showingCategoryDetail = true
                        },
                        onAmountChange: { newAmount in
                            updateCategoryAmount(category, newAmount)
                        },
                        onDelete: { deleteCategory(category) }
                    )
                    .padding(.horizontal)
                    .transition(.scale(scale: 0.9).combined(with: .opacity))
                }
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
            
            // Amount
            Text("$\(Int(abs(amount)))")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(amount >= 0 ? AppTheme.textColor : AppTheme.expenseColor)
            
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
    
    // MARK: - Firebase Data Functions
    
    // Initialize data
    private func initializeData() {
        // Load user income from Firestore
        loadMonthlyIncome()
        
        // Load all budget categories
        loadBudgetCategories()
        
        // Calculate spending for each category
        calculateCategorySpending()
        
        // Turn off loading state
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            isLoading = false
        }
    }
    
    // Load monthly income
    private func loadMonthlyIncome() {
        guard let userId = Auth.auth().currentUser?.uid else {
            errorMessage = "User not logged in"
            return
        }
        
        let db = Firestore.firestore()
        db.collection("users").document(userId).getDocument { snapshot, error in
            if let error = error {
                errorMessage = "Error loading income: \(error.localizedDescription)"
                return
            }
            
            if let document = snapshot, document.exists {
                if let income = document.data()?["monthlyIncome"] as? Double {
                    DispatchQueue.main.async {
                        self.monthlyIncome = income
                    }
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
        
        DispatchQueue.main.async {
            if calculatedIncome > 0 {
                self.monthlyIncome = calculatedIncome
            } else {
                // Set default value for demo purposes
                self.monthlyIncome = 5000
            }
        }
    }

    // Load budget categories
    private func loadBudgetCategories() {
        guard let userId = Auth.auth().currentUser?.uid else {
            errorMessage = "User not logged in"
            return
        }
        
        let db = Firestore.firestore()
        
        db.collection("users/\(userId)/budgetCategories").getDocuments { snapshot, error in
            if let error = error {
                self.errorMessage = "Error loading categories: \(error.localizedDescription)"
                return
            }
            
            if let documents = snapshot?.documents {
                var loadedCategories: [BudgetCategory] = []
                
                for document in documents {
                    if let name = document.data()["name"] as? String,
                       let amount = document.data()["amount"] as? Double,
                       let icon = document.data()["icon"] as? String,
                       let colorHex = document.data()["color"] as? String {
                        
                        let category = BudgetCategory(
                            name: name,
                            amount: amount,
                            icon: icon,
                            color: Color(hex: colorHex)
                        )
                        
                        loadedCategories.append(category)
                    }
                }
                
                DispatchQueue.main.async {
                    self.categories = loadedCategories
                }
            }
        }
    }
    
    // Calculate spending for each category
    private func calculateCategorySpending() {
        let calendar = Calendar.current
        let now = Date()
        let currentMonth = calendar.component(.month, from: now)
        let currentYear = calendar.component(.year, from: now)
        
        var spending: [String: Double] = [:]
        
        // Get transactions for current month
        let monthTransactions = plaidManager.transactions.filter { transaction in
            let transactionMonth = calendar.component(.month, from: transaction.date)
            let transactionYear = calendar.component(.year, from: transaction.date)
            return transactionMonth == currentMonth && transactionYear == currentYear && transaction.amount > 0
        }
        
        // Group by category
        for transaction in monthTransactions {
            spending[transaction.category, default: 0] += transaction.amount
        }
        
        categorySpending = spending
    }
    
    // Calculate spent amount for a specific category
    private func calculateSpentForCategory(_ category: BudgetCategory) -> Double {
        return categorySpending[category.name] ?? 0.0
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
                name: category.name.trimmingCharacters(in: .whitespacesAndNewlines),
                amount: category.amount,
                icon: category.icon,
                color: category.color
            )
            
            DispatchQueue.main.async {
                self.categories.append(newCategory)
            }
        }
    }
    
    // Update a budget category
    private func updateCategory(_ category: BudgetCategory) {
        guard let userId = Auth.auth().currentUser?.uid else {
            errorMessage = "User not logged in"
            return
        }
        
        // Find the category index
        if let index = categories.firstIndex(where: { $0.id == category.id }) {
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
                
                DispatchQueue.main.async {
                    self.categories[index] = category
                }
            }
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
                DispatchQueue.main.async {
                    var updatedCategory = self.categories[index]
                    updatedCategory.amount = newAmount
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
            DispatchQueue.main.async {
                self.categories.removeAll { $0.id == category.id }
            }
        }
    }
    
    // Update budget usage in Firebase
    private func updateBudgetUsageInFirebase() {
        guard let userId = Auth.auth().currentUser?.uid else {
            errorMessage = "User not logged in"
            return
        }
        
        // Get current month and year
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM"
        let currentYearMonth = dateFormatter.string(from: Date())
        
        // Calculate spent amount per category
        var categoryData: [String: [String: Double]] = [:]
        var totalSpent: Double = 0
        
        for category in categories {
            let spent = calculateSpentForCategory(category)
            categoryData[category.id] = [
                "budget": category.amount,
                "spent": spent
            ]
            totalSpent += spent
        }
        
        // Save to Firestore
        let db = Firestore.firestore()
        let monthlyBudgetRef = db.collection("users").document(userId).collection("budget").document(currentYearMonth)
        
        let data: [String: Any] = [
            "totalBudget": totalBudget,
            "totalSpent": totalSpent,
            "categories": categoryData,
            "updatedAt": FieldValue.serverTimestamp()
        ]
        
        monthlyBudgetRef.setData(data, merge: true) { error in
            if let error = error {
                self.errorMessage = "Error updating budget: \(error.localizedDescription)"
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
    
    // MARK: - Auto Budget Function
    
    // Improved auto-budget function
    private func autoBudget() {
        // First verify we have income amount
        if monthlyIncome <= 0 {
            calculateMonthlyIncomeFromTransactions()
            
            if monthlyIncome <= 0 {
                monthlyIncome = 5000 // Set default for testing
                errorMessage = "Using a default monthly income of $5,000 for budget calculation. You can update this in your profile settings."
                return
            }
        }
        
        isLoading = true
        
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
            return
        }
        
        let db = Firestore.firestore()
        
        // First, get all existing categories to avoid duplicates
        db.collection("users/\(userId)/budgetCategories").getDocuments { [self] snapshot, error in
            if let error = error {
                DispatchQueue.main.async {
                    self.errorMessage = "Error fetching categories: \(error.localizedDescription)"
                    self.isLoading = false
                }
                return
            }
            
            // Dictionary to track existing categories by name
            var existingCategoriesById: [String: BudgetCategory] = [:]
            var existingCategoriesByName: [String: BudgetCategory] = [:]
            
            if let documents = snapshot?.documents {
                for document in documents {
                    if let name = document.data()["name"] as? String,
                       let amount = document.data()["amount"] as? Double,
                       let icon = document.data()["icon"] as? String,
                       let colorHex = document.data()["color"] as? String {
                        
                        let category = BudgetCategory(
                            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                            amount: amount,
                            icon: icon,
                            color: Color(hex: colorHex)
                        )
                        
                        existingCategoriesById[document.documentID] = category
                        existingCategoriesByName[name.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)] = category
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
                if let existingCategory = existingCategoriesByName[categoryNameLowercased] {
                    // Update existing category with new amount but keep other properties
                    let categoryRef = db.collection("users/\(userId)/budgetCategories").document(existingCategory.id)
                    
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
                    self.updateBudgetUsageInFirebase()
                }
            }
        }
    }
}

// MARK: - Supporting Types

struct AlertData: Identifiable {
    var id: String
    var message: String
}

enum BudgetStatus {
    case overBudget
    case warning
    case onTrack
    case underBudget
}

// MARK: - Supporting Components

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .opacity(configuration.isPressed ? 0.9 : 1)
            .animation(.spring(response: 0.2, dampingFraction: 0.7), value: configuration.isPressed)
    }
}
