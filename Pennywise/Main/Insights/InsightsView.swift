import SwiftUI
import Charts

struct InsightsView: View {
    @EnvironmentObject var plaidManager: PlaidManager
    
    // State variables
    @State private var selectedTimeframe: TimeFrame = .month
    @State private var selectedTab = 0
    @State private var isRefreshing = false
    @State private var showingSavingsTips = false
    @State private var selectedCategoryIndex: Int? = nil
    
    // Tab options
    let tabs = ["Overview", "Spending", "Income", "Categories"]
    
    // Timeframe options
    enum TimeFrame {
        case week, month, year
    }
    
    // Computed properties
    private var timeframeTitle: String {
        switch selectedTimeframe {
        case .week: return "This Week"
        case .month: return "This Month"
        case .year: return "This Year"
        }
    }
    
    private var transactionsInTimeframe: [PlaidTransaction] {
        let calendar = Calendar.current
        let now = Date()
        
        let startDate: Date
        switch selectedTimeframe {
        case .week:
            startDate = calendar.date(byAdding: .day, value: -7, to: now) ?? now
        case .month:
            startDate = calendar.date(byAdding: .month, value: -1, to: now) ?? now
        case .year:
            startDate = calendar.date(byAdding: .year, value: -1, to: now) ?? now
        }
        
        return plaidManager.transactions.filter { transaction in
            transaction.date >= startDate && transaction.date <= now
        }
    }
    
    private var expenseTransactions: [PlaidTransaction] {
        transactionsInTimeframe.filter { $0.amount > 0 }
    }
    
    private var incomeTransactions: [PlaidTransaction] {
        transactionsInTimeframe.filter { $0.amount < 0 }
    }
    
    private var categoryBreakdown: [(String, Double)] {
        // Group transactions by category and sum amounts
        var categories: [String: Double] = [:]
        
        for transaction in expenseTransactions {
            let category = transaction.category
            categories[category, default: 0] += transaction.amount
        }
        
        // Convert to array and sort by amount (highest first)
        return categories.map { ($0.key, $0.value) }
            .sorted { $0.1 > $1.1 }
    }
    
    private var totalSpending: Double {
        expenseTransactions.reduce(0) { $0 + $1.amount }
    }
    
    private var totalIncome: Double {
        abs(incomeTransactions.reduce(0) { $0 + $1.amount })
    }
    
    private var netCashflow: Double {
        totalIncome - totalSpending
    }
    
    // Data for pie chart
    private var pieChartData: [PieChartDataPoint] {
        categoryBreakdown.map { category in
            PieChartDataPoint(
                category: category.0,
                amount: category.1,
                color: categoryColor(for: category.0)
            )
        }
    }
    
    // Income sources breakdown
    private var incomeSources: [(String, Double)] {
        // Group income transactions by merchant name or type
        var sources: [String: Double] = [:]
        
        for transaction in incomeTransactions {
            // Use merchant name or a default if empty
            let source = transaction.merchantName.isEmpty ? "Primary Income" : transaction.merchantName
            sources[source, default: 0] += abs(transaction.amount)
        }
        
        return sources.map { ($0.key, $0.value) }
            .sorted { $0.1 > $1.1 }
    }
    
    var body: some View {
        ZStack {
            // Background gradient
            AppTheme.backgroundGradient
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 0) {
                // Header with time period selector
                headerView
                    .padding(.horizontal)
                    .padding(.top, 8)
                    .padding(.bottom, 4)
                
                // Tab selector
                tabSelectorView
                    .padding(.bottom, 4)
                
                // Main content area
                if isRefreshing {
                    loadingView
                } else if transactionsInTimeframe.isEmpty {
                    emptyStateView
                } else {
                    ScrollView {
                        // Display content based on selected tab
                        VStack(spacing: 16) {
                            switch selectedTab {
                            case 0:
                                overviewTabContent
                            case 1:
                                spendingTabContent
                            case 2:
                                incomeTabContent
                            case 3:
                                categoriesTabContent
                            default:
                                overviewTabContent
                            }
                        }
                        .padding(.top, 8)
                        .padding(.bottom, 60)
                    }
                }
            }
        }
        .onAppear {
            // If we don't have transaction data, fetch it
            if plaidManager.transactions.isEmpty {
                isRefreshing = true
                plaidManager.fetchTransactions { success in
                    isRefreshing = false
                }
            }
        }
        .navigationTitle("Insights")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // MARK: - Header View
    
    private var headerView: some View {
        HStack {
            Text("Financial Insights")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(AppTheme.textColor)
            
            Spacer()
            
            // Timeframe selector
            HStack(spacing: 0) {
                Button(action: {
                    withAnimation {
                        selectedTimeframe = .week
                    }
                }) {
                    Text("Week")
                        .font(.footnote)
                        .padding(.vertical, 6)
                        .padding(.horizontal, 12)
                        .background(selectedTimeframe == .week ? AppTheme.primaryGreen : Color.clear)
                        .foregroundColor(selectedTimeframe == .week ? .white : AppTheme.textColor.opacity(0.6))
                        .cornerRadius(20)
                }
                
                Button(action: {
                    withAnimation {
                        selectedTimeframe = .month
                    }
                }) {
                    Text("Month")
                        .font(.footnote)
                        .padding(.vertical, 6)
                        .padding(.horizontal, 12)
                        .background(selectedTimeframe == .month ? AppTheme.primaryGreen : Color.clear)
                        .foregroundColor(selectedTimeframe == .month ? .white : AppTheme.textColor.opacity(0.6))
                        .cornerRadius(20)
                }
                
                Button(action: {
                    withAnimation {
                        selectedTimeframe = .year
                    }
                }) {
                    Text("Year")
                        .font(.footnote)
                        .padding(.vertical, 6)
                        .padding(.horizontal, 12)
                        .background(selectedTimeframe == .year ? AppTheme.primaryGreen : Color.clear)
                        .foregroundColor(selectedTimeframe == .year ? .white : AppTheme.textColor.opacity(0.6))
                        .cornerRadius(20)
                }
            }
            .background(AppTheme.cardBackground)
            .cornerRadius(20)
        }
    }
    
    // MARK: - Tab Selector
    
    private var tabSelectorView: some View {
        VStack(spacing: 0) {
            Picker("", selection: $selectedTab) {
                Text("Overview").tag(0)
                Text("Spending").tag(1)
                Text("Income").tag(2)
                Text("Categories").tag(3)
            }
            .pickerStyle(SegmentedPickerStyle())
            // Apply specific theme colors to match the timeframe selector exactly
            .onAppear {
                UISegmentedControl.appearance().selectedSegmentTintColor = UIColor(AppTheme.primaryGreen)
                UISegmentedControl.appearance().setTitleTextAttributes([.foregroundColor: UIColor.white], for: .selected)
                UISegmentedControl.appearance().setTitleTextAttributes([.foregroundColor: UIColor(AppTheme.textColor.opacity(0.6))], for: .normal)
                UISegmentedControl.appearance().backgroundColor = UIColor(AppTheme.cardBackground)
            }
            .padding(4)
            .background(AppTheme.cardBackground)
            .cornerRadius(8)
            .padding(.horizontal, 16)
            .padding(.bottom, 8)
        }
    }
    
    // For the matched geometry effect
    @Namespace private var namespace
    
    // MARK: - Loading State
    
    private var loadingView: some View {
        VStack {
            Spacer()
            ProgressView()
                .scaleEffect(1.5)
                .progressViewStyle(CircularProgressViewStyle(tint: AppTheme.primaryGreen))
            Text("Loading insights...")
                .font(.headline)
                .foregroundColor(AppTheme.textColor.opacity(0.7))
                .padding(.top, 16)
            Spacer()
        }
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "chart.pie")
                .font(.system(size: 70))
                .foregroundColor(AppTheme.accentBlue.opacity(0.7))
            
            Text("No data for \(timeframeTitle.lowercased())")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(AppTheme.textColor)
            
            Text("Connect your accounts or add transactions to see spending insights and personalized saving tips.")
                .multilineTextAlignment(.center)
                .font(.body)
                .foregroundColor(AppTheme.textColor.opacity(0.7))
                .padding(.horizontal, 40)
            
            Button(action: {
                plaidManager.presentLink()
            }) {
                HStack {
                    Image(systemName: "link")
                        .font(.headline)
                    
                    Text("Connect Accounts")
                        .font(.headline)
                }
                .padding()
                .frame(width: 250)
                .background(AppTheme.primaryGreen)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .buttonStyle(ScaleButtonStyle())
            
            Spacer()
        }
        .padding()
    }
    
    // MARK: - Tab Content
    
    // Overview tab content
    private var overviewTabContent: some View {
        VStack(spacing: 16) {
            // Financial snapshot card
            financialSnapshotCard
                .padding(.horizontal)
            
            // Top spending categories
            topSpendingCategoriesCard
                .padding(.horizontal)
            
            // Savings insights card
            savingsInsightsCard
                .padding(.horizontal)
        }
    }
    
    // Spending tab content
    private var spendingTabContent: some View {
        VStack(spacing: 16) {
            // Spending summary card
            spendingSummaryCard
                .padding(.horizontal)
            
            // Category breakdown card - now with actual pie chart
            categoryBreakdownCard
                .padding(.horizontal)
            
            // Recent transactions list
            recentTransactionsCard
                .padding(.horizontal)
        }
    }
    
    // Income tab content
    private var incomeTabContent: some View {
        VStack(spacing: 16) {
            // Income summary card
            incomeSummaryCard
                .padding(.horizontal)
            
            // Income distribution - showing actual Plaid data
            enhancedIncomeDistributionCard
                .padding(.horizontal)
        }
    }
    
    // Categories tab content
    private var categoriesTabContent: some View {
        VStack(spacing: 16) {
            if !categoryBreakdown.isEmpty {
                // Show categories
                ForEach(categoryBreakdown.prefix(5), id: \.0) { category, amount in
                    categoryCard(name: category, amount: amount)
                        .padding(.horizontal)
                }
                
                // View more button if needed
                if categoryBreakdown.count > 5 {
                    Button(action: {
                        // Show all categories
                    }) {
                        Text("View \(categoryBreakdown.count - 5) More Categories")
                            .font(.subheadline)
                            .foregroundColor(AppTheme.primaryGreen)
                            .padding(.vertical, 10)
                            .padding(.horizontal, 20)
                            .background(AppTheme.primaryGreen.opacity(0.15))
                            .cornerRadius(10)
                    }
                    .padding(.horizontal)
                }
            } else {
                Text("No categories found for \(timeframeTitle.lowercased())")
                    .font(.headline)
                    .foregroundColor(AppTheme.textColor.opacity(0.7))
                    .padding()
            }
        }
    }
    
    // MARK: - Card Components
    
    // Financial snapshot card
    private var financialSnapshotCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Financial Summary - \(timeframeTitle)")
                .font(.headline)
                .foregroundColor(AppTheme.textColor)
            
            HStack(spacing: 20) {
                // Income
                VStack {
                    Text("Income")
                        .font(.subheadline)
                        .foregroundColor(AppTheme.textColor.opacity(0.7))
                    
                    Text("$\(totalIncome, specifier: "%.0f")")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(AppTheme.primaryGreen)
                }
                .frame(maxWidth: .infinity)
                
                Divider()
                    .background(AppTheme.cardStroke)
                
                // Expenses
                VStack {
                    Text("Expenses")
                        .font(.subheadline)
                        .foregroundColor(AppTheme.textColor.opacity(0.7))
                    
                    Text("$\(totalSpending, specifier: "%.0f")")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(AppTheme.expenseColor)
                }
                .frame(maxWidth: .infinity)
                
                Divider()
                    .background(AppTheme.cardStroke)
                
                // Net
                VStack {
                    Text("Net")
                        .font(.subheadline)
                        .foregroundColor(AppTheme.textColor.opacity(0.7))
                    
                    Text("$\(netCashflow, specifier: "%.0f")")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(netCashflow >= 0 ? AppTheme.primaryGreen : AppTheme.expenseColor)
                }
                .frame(maxWidth: .infinity)
            }
            .padding()
            .background(AppTheme.cardBackground)
            .cornerRadius(16)
        }
        .padding()
        .background(AppTheme.cardBackground.opacity(0.3))
        .cornerRadius(20)
    }
    
    // Top spending categories card
    private var topSpendingCategoriesCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Top Spending Categories")
                .font(.headline)
                .foregroundColor(AppTheme.textColor)
            
            if !categoryBreakdown.isEmpty {
                ForEach(categoryBreakdown.prefix(3), id: \.0) { category, amount in
                    HStack {
                        // Category icon
                        ZStack {
                            Circle()
                                .fill(categoryColor(for: category).opacity(0.2))
                                .frame(width: 40, height: 40)
                            
                            Image(systemName: getCategoryIcon(for: category))
                                .font(.system(size: 18))
                                .foregroundColor(categoryColor(for: category))
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(category)
                                .font(.subheadline)
                                .foregroundColor(AppTheme.textColor)
                            
                            // Progress bar
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 5)
                                    .fill(AppTheme.cardBackground)
                                    .frame(height: 6)
                                
                                RoundedRectangle(cornerRadius: 5)
                                    .fill(categoryColor(for: category))
                                    .frame(width: totalSpending > 0
                                           ? CGFloat(amount / totalSpending) * 150
                                           : 0,
                                           height: 6)
                            }
                            .frame(width: 150)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("$\(amount, specifier: "%.0f")")
                                .font(.headline)
                                .foregroundColor(AppTheme.textColor)
                            
                            Text("\(Int(amount / totalSpending * 100))%")
                                .font(.caption)
                                .foregroundColor(AppTheme.textColor.opacity(0.6))
                        }
                    }
                    .padding()
                    .background(AppTheme.cardBackground)
                    .cornerRadius(12)
                }
            } else {
                Text("No spending data available")
                    .font(.subheadline)
                    .foregroundColor(AppTheme.textColor.opacity(0.7))
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
                    .background(AppTheme.cardBackground)
                    .cornerRadius(12)
            }
        }
        .padding()
        .background(AppTheme.cardBackground.opacity(0.3))
        .cornerRadius(20)
    }
    
    /// Generate a list of savings tips based on transaction history
    func generateSavingsTips(from transactions: [PlaidTransaction]) -> [(title: String, description: String, icon: String)] {
        var tips: [(title: String, description: String, icon: String)] = []
        
        // Group transactions by category
        let categorySpending = Dictionary(
            grouping: transactions.filter { $0.amount > 0 },
            by: { $0.category }
        )
        
        // Find top spending categories
        let sortedCategories = categorySpending.sorted {
            $0.value.reduce(0) { $0 + $1.amount } > $1.value.reduce(0) { $0 + $1.amount }
        }
        
        // Tip for highest spending category
        if let topCategory = sortedCategories.first {
            let totalSpent = topCategory.value.reduce(0) { $0 + $1.amount }
            let potentialSavings = totalSpent * 0.15 // 15% reduction potential
            
            tips.append((
                title: "Reduce \(topCategory.key) Spending",
                description: "You've spent $\(String(format: "%.2f", totalSpent)) on \(topCategory.key) \(timeframeTitle.lowercased()). Consider cutting back by 15%, which could save you $\(String(format: "%.2f", potentialSavings)).",
                icon: "dollarsign.circle"
            ))
        }
        
        // Tip for dining out
        let diningTransactions = transactions.filter {
            $0.category.lowercased().contains("food") ||
            $0.category.lowercased().contains("restaurant")
        }
        
        if !diningTransactions.isEmpty {
            let totalDining = diningTransactions.reduce(0) { $0 + $1.amount }
            let potentialSavings = totalDining * 0.2 // 20% reduction potential
            
            tips.append((
                title: "Cook More, Eat Out Less",
                description: "You spent $\(String(format: "%.2f", totalDining)) on dining out \(timeframeTitle.lowercased()). Cooking at home 2-3 more times a week could save you $\(String(format: "%.2f", potentialSavings)).",
                icon: "fork.knife"
            ))
        }
        
        // Tip for subscriptions
        let subscriptionTransactions = transactions.filter { transaction in
            transaction.amount >= 5 && transaction.amount <= 50 &&
            (transaction.merchantName.lowercased().contains("netflix") ||
             transaction.merchantName.lowercased().contains("spotify") ||
             transaction.merchantName.lowercased().contains("hulu") ||
             transaction.merchantName.lowercased().contains("disney") ||
             transaction.merchantName.lowercased().contains("apple") ||
             transaction.merchantName.lowercased().contains("amazon"))
        }
        
        if !subscriptionTransactions.isEmpty {
            let totalSubscriptions = subscriptionTransactions.reduce(0) { $0 + $1.amount }
            
            tips.append((
                title: "Review Subscriptions",
                description: "You have \(subscriptionTransactions.count) potential subscriptions costing $\(String(format: "%.2f", totalSubscriptions)) \(timeframeTitle == "This Week" ? "weekly" : timeframeTitle == "This Month" ? "monthly" : "yearly"). Consider canceling unused services.",
                icon: "repeat"
            ))
        }
        
        // Ensure we have at least one tip
        if tips.isEmpty {
            tips.append((
                title: "Keep Tracking Your Spending",
                description: "Continue monitoring your expenses \(timeframeTitle.lowercased()) to find more savings opportunities.",
                icon: "chart.bar.fill"
            ))
        }
        
        return tips
    }
    
    // Savings insights card
    private var savingsInsightsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Savings Opportunities")
                    .font(.headline)
                    .foregroundColor(AppTheme.textColor)
                
                Spacer()
                
                Button(action: {
                    withAnimation {
                        showingSavingsTips.toggle()
                    }
                }) {
                    Image(systemName: showingSavingsTips ? "chevron.up" : "chevron.down")
                        .foregroundColor(AppTheme.primaryGreen)
                        .padding(8)
                        .background(Circle().fill(AppTheme.primaryGreen.opacity(0.2)))
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            if showingSavingsTips {
                let savingsTips = generateSavingsTips(from: transactionsInTimeframe)
                
                ForEach(Array(savingsTips.enumerated()), id: \.offset) { _, tip in
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: tip.icon)
                            .foregroundColor(AppTheme.primaryGreen)
                            .frame(width: 24, height: 24)
                            .padding(8)
                            .background(Circle().fill(AppTheme.primaryGreen.opacity(0.2)))
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(tip.title)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(AppTheme.textColor)
                            
                            Text(tip.description)
                                .font(.caption)
                                .foregroundColor(AppTheme.textColor.opacity(0.7))
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        
                        Spacer()
                    }
                    .padding()
                    .background(AppTheme.cardBackground)
                    .cornerRadius(12)
                }
            } else {
                HStack {
                    Image(systemName: "lightbulb.fill")
                        .foregroundColor(AppTheme.primaryGreen)
                    
                    Text("Tap to see personalized savings tips")
                        .font(.subheadline)
                        .foregroundColor(AppTheme.textColor.opacity(0.8))
                    
                    Spacer()
                }
                .padding()
                .background(AppTheme.cardBackground)
                .cornerRadius(12)
            }
        }
        .padding()
        .background(AppTheme.cardBackground.opacity(0.3))
        .cornerRadius(20)
        .animation(.spring(), value: showingSavingsTips)
    }
    
    // Spending summary card
    private var spendingSummaryCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Spending Summary - \(timeframeTitle)")
                .font(.headline)
                .foregroundColor(AppTheme.textColor)
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Total Spent")
                        .font(.subheadline)
                        .foregroundColor(AppTheme.textColor.opacity(0.7))
                    
                    Text("$\(totalSpending, specifier: "%.0f")")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(AppTheme.textColor)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Transactions")
                        .font(.subheadline)
                        .foregroundColor(AppTheme.textColor.opacity(0.7))
                    
                    Text("\(expenseTransactions.count)")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(AppTheme.accentBlue)
                }
            }
            .padding()
            .background(AppTheme.cardBackground)
            .cornerRadius(12)
        }
        .padding()
        .background(AppTheme.cardBackground.opacity(0.3))
        .cornerRadius(20)
    }
    
    private var categoryBreakdownCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Spending by Category")
                .font(.headline)
                .foregroundColor(AppTheme.textColor)
            
            if categoryBreakdown.isEmpty {
                Text("No category data for this period")
                    .font(.subheadline)
                    .foregroundColor(AppTheme.textColor.opacity(0.7))
                    .frame(height: 200)
                    .frame(maxWidth: .infinity)
            } else {
                // Convert category breakdown data to the format needed for PieChartView
                let chartData = categoryBreakdown.map { (name, amount) in
                    return (name, amount)
                }
                
                // Use the new Swift Charts-based PieChartView
                PieChartView(data: chartData)
                                .frame(height: 300)
                                .padding(.vertical, 8)
            }
        }
        .padding()
        .background(AppTheme.cardBackground.opacity(0.3))
        .cornerRadius(20)
    }
    
    // Recent transactions card
    private var recentTransactionsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Transactions")
                .font(.headline)
                .foregroundColor(AppTheme.textColor)
            
            if expenseTransactions.isEmpty {
                Text("No recent transactions")
                    .font(.subheadline)
                    .foregroundColor(AppTheme.textColor.opacity(0.7))
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
                    .background(AppTheme.cardBackground)
                    .cornerRadius(12)
            } else {
                ForEach(expenseTransactions.prefix(5)) { transaction in
                    HStack(spacing: 12) {
                        // Category icon
                        ZStack {
                            Circle()
                                .fill(categoryColor(for: transaction.category).opacity(0.2))
                                .frame(width: 40, height: 40)
                            
                            Image(systemName: getCategoryIcon(for: transaction.category))
                                .font(.system(size: 18))
                                .foregroundColor(categoryColor(for: transaction.category))
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(transaction.merchantName)
                                .font(.subheadline)
                                .foregroundColor(AppTheme.textColor)
                            
                            Text(formatDate(transaction.date))
                                .font(.caption)
                                .foregroundColor(AppTheme.textColor.opacity(0.6))
                        }
                        
                        Spacer()
                        
                        Text("$\(transaction.amount, specifier: "%.2f")")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(transaction.amount >= 0 ? AppTheme.expenseColor : AppTheme.primaryGreen)
                    }
                    .padding()
                    .background(AppTheme.cardBackground)
                    .cornerRadius(12)
                }
            }
        }
        .padding()
        .background(AppTheme.cardBackground.opacity(0.3))
        .cornerRadius(20)
    }
    
    // Income summary card
    private var incomeSummaryCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Income Summary - \(timeframeTitle)")
                .font(.headline)
                .foregroundColor(AppTheme.textColor)
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Total Income")
                        .font(.subheadline)
                        .foregroundColor(AppTheme.textColor.opacity(0.7))
                    
                    Text("$\(totalIncome, specifier: "%.0f")")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(AppTheme.primaryGreen)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Deposits")
                        .font(.subheadline)
                        .foregroundColor(AppTheme.textColor.opacity(0.7))
                    
                    Text("\(incomeTransactions.count)")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(AppTheme.accentBlue)
                }
            }
            .padding()
            .background(AppTheme.cardBackground)
            .cornerRadius(12)
        }
        .padding()
        .background(AppTheme.cardBackground.opacity(0.3))
        .cornerRadius(20)
    }
    
    // Enhanced income distribution card
    private var enhancedIncomeDistributionCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Income Sources")
                .font(.headline)
                .foregroundColor(AppTheme.textColor)
            
            if !incomeTransactions.isEmpty {
                // Show actual income sources from Plaid data
                VStack(spacing: 15) {
                    if !incomeSources.isEmpty {
                        ForEach(incomeSources.prefix(5), id: \.0) { source, amount in
                            HStack(spacing: 15) {
                                // Source icon
                                ZStack {
                                    Circle()
                                        .fill(sourceColor(for: source).opacity(0.2))
                                        .frame(width: 40, height: 40)
                                    
                                    Image(systemName: sourceIcon(for: source))
                                        .font(.system(size: 18))
                                        .foregroundColor(sourceColor(for: source))
                                }
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(source)
                                        .font(.subheadline)
                                        .foregroundColor(AppTheme.textColor)
                                    
                                    // Progress bar
                                    ZStack(alignment: .leading) {
                                        RoundedRectangle(cornerRadius: 5)
                                            .fill(AppTheme.cardBackground)
                                            .frame(height: 6)
                                        
                                        RoundedRectangle(cornerRadius: 5)
                                            .fill(sourceColor(for: source))
                                            .frame(width: totalIncome > 0
                                                   ? CGFloat(amount / totalIncome) * 150
                                                   : 0,
                                                   height: 6)
                                    }
                                    .frame(width: 150)
                                }
                                
                                Spacer()
                                
                                VStack(alignment: .trailing, spacing: 4) {
                                    Text("$\(amount, specifier: "%.0f")")
                                        .font(.headline)
                                        .foregroundColor(AppTheme.textColor)
                                    
                                    Text("\(Int(amount / totalIncome * 100))%")
                                        .font(.caption)
                                        .foregroundColor(AppTheme.textColor.opacity(0.6))
                                }
                            }
                            .padding()
                            .background(AppTheme.cardBackground)
                            .cornerRadius(12)
                        }
                    } else {
                        // Fallback for when we can't determine sources
                        HStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(AppTheme.primaryGreen.opacity(0.2))
                                    .frame(width: 40, height: 40)
                                
                                Image(systemName: "briefcase.fill")
                                    .font(.system(size: 18))
                                    .foregroundColor(AppTheme.primaryGreen)
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Total Income")
                                    .font(.subheadline)
                                    .foregroundColor(AppTheme.textColor)
                                
                                Text("100% of total income")
                                    .font(.caption)
                                    .foregroundColor(AppTheme.textColor.opacity(0.6))
                            }
                            
                            Spacer()
                            
                            Text("$\(totalIncome, specifier: "%.0f")")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(AppTheme.primaryGreen)
                        }
                        .padding()
                        .background(AppTheme.cardBackground)
                        .cornerRadius(12)
                    }
                }
            } else {
                Text("No income data for this period")
                    .font(.subheadline)
                    .foregroundColor(AppTheme.textColor.opacity(0.7))
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
                    .background(AppTheme.cardBackground)
                    .cornerRadius(12)
            }
        }
        .padding()
        .background(AppTheme.cardBackground.opacity(0.3))
        .cornerRadius(20)
    }

    
    // Category card for the Categories tab
    private func categoryCard(name: String, amount: Double) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                ZStack {
                    Circle()
                        .fill(categoryColor(for: name).opacity(0.2))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: getCategoryIcon(for: name))
                        .font(.system(size: 18))
                        .foregroundColor(categoryColor(for: name))
                }
                
                Text(name)
                    .font(.headline)
                    .foregroundColor(AppTheme.textColor)
                
                Spacer()
                
                Text("$\(amount, specifier: "%.0f")")
                    .font(.headline)
                    .foregroundColor(AppTheme.textColor)
            }
            
            // Percentage of total spending
            HStack {
                Text("\(Int(amount / totalSpending * 100))% of total")
                    .font(.caption)
                    .foregroundColor(AppTheme.textColor.opacity(0.7))
                
                Spacer()
            }
            
            // Progress bar
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(AppTheme.cardBackground)
                    .frame(height: 8)
                
                RoundedRectangle(cornerRadius: 4)
                    .fill(categoryColor(for: name))
                    .frame(width: totalSpending > 0
                           ? CGFloat(amount / totalSpending) * (UIScreen.main.bounds.width - 64)
                           : 0,
                           height: 8)
            }
        }
        .padding()
        .background(AppTheme.cardBackground)
        .cornerRadius(16)
    }
    
    // MARK: - Helper Methods
    
    // Format date to string
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
    
    // Get icon for category
    private func getCategoryIcon(for category: String) -> String {
        let c = category.lowercased()
        if c.contains("food") || c.contains("restaurant") || c.contains("dining") { return "fork.knife" }
        if c.contains("shop") || c.contains("store") { return "cart" }
        if c.contains("transport") || c.contains("travel") { return "car.fill" }
        if c.contains("entertainment") { return "play.tv" }
        if c.contains("health") || c.contains("medical") { return "heart.fill" }
        if c.contains("utility") || c.contains("bill") { return "bolt.fill" }
        if c.contains("income") || c.contains("deposit") { return "arrow.down.circle.fill" }
        if c.contains("subscription") { return "repeat" }
        if c.contains("housing") || c.contains("rent") || c.contains("mortgage") { return "house.fill" }
        if c.contains("education") { return "book.fill" }
        if c.contains("personal") { return "person.fill" }
        return "dollarsign.circle"
    }
    
    // Get color for category
    private func categoryColor(for category: String) -> Color {
        let c = category.lowercased()
        if c.contains("food") || c.contains("restaurant") || c.contains("dining") {
            return AppTheme.primaryGreen
        } else if c.contains("shop") || c.contains("store") {
            return AppTheme.accentBlue
        } else if c.contains("transport") || c.contains("travel") {
            return AppTheme.accentPurple
        } else if c.contains("entertainment") {
            return Color(hex: "#FFD700")
        } else if c.contains("health") || c.contains("medical") {
            return Color(hex: "#FF5757")
        } else if c.contains("utility") || c.contains("bill") {
            return Color(hex: "#9370DB")
        } else if c.contains("housing") || c.contains("rent") || c.contains("mortgage") {
            return Color(hex: "#CD853F")
        } else if c.contains("education") {
            return Color(hex: "#4682B4")
        } else if c.contains("personal") {
            return Color(hex: "#FF7F50")
        } else if c.contains("subscription") {
            return Color(hex: "#BA55D3")
        } else {
            // Use a deterministic color based on the category name
            let hash = category.hashValue
            return Color(
                hue: Double(abs(hash % 256)) / 256.0,
                saturation: 0.7,
                brightness: 0.8
            )
        }
    }
    
    // Income source icon
    private func sourceIcon(for source: String) -> String {
        let s = source.lowercased()
        if s.contains("salary") || s.contains("payroll") || s.contains("income") || s.contains("primary") {
            return "briefcase.fill"
        }
        if s.contains("dividend") || s.contains("interest") || s.contains("investment") {
            return "chart.line.uptrend.xyaxis"
        }
        if s.contains("gift") {
            return "gift.fill"
        }
        if s.contains("refund") || s.contains("return") {
            return "arrow.counterclockwise"
        }
        if s.contains("transfer") {
            return "arrow.left.arrow.right"
        }
        return "dollarsign.square.fill"
    }
    
    // Income source color
    private func sourceColor(for source: String) -> Color {
        let s = source.lowercased()
        if s.contains("salary") || s.contains("payroll") || s.contains("income") || s.contains("primary") {
            return AppTheme.primaryGreen
        }
        if s.contains("dividend") || s.contains("interest") || s.contains("investment") {
            return Color(hex: "#4682B4")
        }
        if s.contains("gift") {
            return Color(hex: "#FF69B4")
        }
        if s.contains("refund") || s.contains("return") {
            return AppTheme.accentBlue
        }
        if s.contains("transfer") {
            return AppTheme.accentPurple
        }
        
        // Use a deterministic color based on the source name
        let hash = source.hashValue
        return Color(
            hue: Double(abs(hash % 256)) / 256.0,
            saturation: 0.7,
            brightness: 0.8
        )
    }
}

// MARK: - Supporting Views

// Data structure for pie chart
struct PieChartDataPoint: Identifiable {
    var id = UUID()
    let category: String
    let amount: Double
    let color: Color
}

// Category Pie Chart View
struct CategoryPieChartView: View {
    let dataPoints: [PieChartDataPoint]
    let totalAmount: Double
    @Binding var selectedIndex: Int?
    
    var body: some View {
        ZStack {
            // The pie chart
            GeometryReader { geometry in
                ZStack(alignment: .center) {
                    ForEach(dataPoints.indices, id: \.self) { index in
                        PieSlice(
                            startAngle: startAngle(at: index),
                            endAngle: endAngle(at: index)
                        )
                        .fill(dataPoints[index].color)
                        .scaleEffect(selectedIndex == index ? 1.05 : 1.0)
                        .animation(.spring(), value: selectedIndex)
                        .onTapGesture {
                            withAnimation {
                                if selectedIndex == index {
                                    selectedIndex = nil
                                } else {
                                    selectedIndex = index
                                }
                            }
                        }
                    }
                    
                    // Center circle
                    Circle()
                        .fill(AppTheme.cardBackground.opacity(0.8))
                        .frame(width: min(geometry.size.width, geometry.size.height) * 0.5)
                    
                    // Text in center
                    VStack(spacing: 4) {
                        if let selectedIndex = selectedIndex {
                            let dataPoint = dataPoints[selectedIndex]
                            Text(dataPoint.category)
                                .font(.headline)
                                .foregroundColor(AppTheme.textColor)
                                .lineLimit(1)
                                .fixedSize(horizontal: false, vertical: true)
                            
                            Text("$\(dataPoint.amount, specifier: "%.0f")")
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(dataPoint.color)
                            
                            Text("\(Int(dataPoint.amount / totalAmount * 100))%")
                                .font(.caption)
                                .foregroundColor(AppTheme.textColor.opacity(0.7))
                        } else {
                            Text("$\(totalAmount, specifier: "%.0f")")
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(AppTheme.textColor)
                            
                            Text("Total")
                                .font(.caption)
                                .foregroundColor(AppTheme.textColor.opacity(0.7))
                        }
                    }
                    .padding()
                    .multilineTextAlignment(.center)
                }
                .frame(width: min(geometry.size.width, geometry.size.height), height: min(geometry.size.width, geometry.size.height))
                .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
            }
        }
    }
    
    private func startAngle(at index: Int) -> Angle {
        let precedingSum = dataPoints.prefix(index).reduce(0) { $0 + $1.amount }
        return .degrees(precedingSum / totalAmount * 360 - 90)
    }
    
    private func endAngle(at index: Int) -> Angle {
        let precedingSum = dataPoints.prefix(index).reduce(0) { $0 + $1.amount }
        let currentAmount = dataPoints[index].amount
        return .degrees((precedingSum + currentAmount) / totalAmount * 360 - 90)
    }
}


