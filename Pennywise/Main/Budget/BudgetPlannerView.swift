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
                
                // Budget progress card
                budgetProgressCard
                    .padding(.horizontal)
                    .scaleEffect(animateCards ? 1.0 : 0.95)
                    .opacity(animateCards ? 1.0 : 0)
                
                // Budget allocation visualization
                if !categories.isEmpty {
                    budgetAllocationCard
                        .padding(.horizontal)
                        .scaleEffect(animateCards ? 1.0 : 0.95)
                        .opacity(animateCards ? 1.0 : 0)
                } else {
                    noBudgetCategoriesView
                        .padding(.horizontal)
                        .scaleEffect(animateCards ? 1.0 : 0.95)
                        .opacity(animateCards ? 1.0 : 0)
                }
                
                // Category section
                VStack(spacing: 16) {
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
    
    // Budget progress card
    private var budgetProgressCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Title
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
                        .frame(width: 120, height: 120)
                    
                    // Progress
                    Circle()
                        .trim(from: 0, to: CGFloat(budgetProgressPercentage))
                        .stroke(
                            budgetStatusColor(for: budgetStatus),
                            style: StrokeStyle(lineWidth: 12, lineCap: .round)
                        )
                        .frame(width: 120, height: 120)
                        .rotationEffect(.degrees(-90))
                    
                    // Center text
                    VStack(spacing: 2) {
                        Text("\(Int(budgetProgressPercentage * 100))%")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(AppTheme.textColor)
                        
                        Text("Spent")
                            .font(.caption)
                            .foregroundColor(AppTheme.textColor.opacity(0.7))
                    }
                }
                
                // Spending details
                VStack(alignment: .leading, spacing: 12) {
                    // Spent
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Spent This Month")
                            .font(.caption)
                            .foregroundColor(AppTheme.textColor.opacity(0.7))
                        
                        Text("$\(Int(totalSpentThisMonth))")
                            .font(.headline)
                            .foregroundColor(AppTheme.accentBlue)
                    }
                    
                    // Budget
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Total Budget")
                            .font(.caption)
                            .foregroundColor(AppTheme.textColor.opacity(0.7))
                        
                        Text("$\(Int(totalBudget))")
                            .font(.headline)
                            .foregroundColor(AppTheme.textColor)
                    }
                    
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
            .background(AppTheme.cardBackground.opacity(0.5))
            .cornerRadius(12)
        }
        .padding()
        .background(AppTheme.cardBackground)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
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
                noBudgetCategoriesView
                    .padding(.horizontal)
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
        isLoading = false
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
                        monthlyIncome = income
                    }
                }
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
                    self.isLoading = false
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
        
        let db = Firestore.firestore()
        let categoryRef = db.collection("users/\(userId)/budgetCategories").document()
        
        // Convert Color to hex string
        let colorHex = category.color.hexString
        
        let data: [String: Any] = [
            "name": category.name,
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
               
                name: category.name,
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
                "name": category.name,
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
    
    // Auto-budget function
    private func autoBudget() {
        // Check if we have income set
        guard monthlyIncome > 0 else {
            errorMessage = "Please set your monthly income in your profile first"
            return
        }
        
        isLoading = true
        
        // Apply the 50/30/20 rule (50% needs, 30% wants, 20% savings)
        let needsBudget = monthlyIncome * 0.5
        let wantsBudget = monthlyIncome * 0.3
        let savingsBudget = monthlyIncome * 0.2
        
        // Group categories
        var needsCategories: [BudgetCategory] = []
        var wantsCategories: [BudgetCategory] = []
        
        for category in categories {
            if CategoryDetailView.isEssentialCategory(category.name) {
                needsCategories.append(category)
            } else if category.name != "Savings" {
                wantsCategories.append(category)
            }
        }
        
        // Allocate budgets
        // For needs categories
        if !needsCategories.isEmpty {
            let amountPerNeedsCategory = needsBudget / Double(needsCategories.count)
            for category in needsCategories {
                updateCategoryAmount(category, amountPerNeedsCategory)
            }
        }
        
        // For wants categories
        if !wantsCategories.isEmpty {
            let amountPerWantsCategory = wantsBudget / Double(wantsCategories.count)
            for category in wantsCategories {
                updateCategoryAmount(category, amountPerWantsCategory)
            }
        }
        
        // Create "Savings" category if it doesn't exist
        if !categories.contains(where: { $0.name == "Savings" }) {
            let savingsCategory = BudgetCategory(
                name: "Savings",
                amount: savingsBudget,
                icon: "bag.fill",
                color: AppTheme.primaryGreen
            )
            
            addCategory(savingsCategory)
        } else if let savingsCategory = categories.first(where: { $0.name == "Savings" }) {
            // Update existing savings category
            updateCategoryAmount(savingsCategory, savingsBudget)
        }
        
        // Finish loading
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.isLoading = false
            self.errorMessage = "Auto-budget complete! Your budget has been optimized using the 50/30/20 rule."
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
