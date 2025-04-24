import SwiftUI

struct InsightsView: View {
    @EnvironmentObject var plaidManager: PlaidManager
    
    // State variables
    @State private var selectedTimeframe: TimeFrame = .month
    @State private var selectedTab = 0
    @State private var isRefreshing = false
    @State private var showingSavingsTips = false
    
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
                Button(action: { selectedTimeframe = .week }) {
                    Text("Week")
                        .font(.footnote)
                        .padding(.vertical, 6)
                        .padding(.horizontal, 12)
                        .background(selectedTimeframe == .week ? AppTheme.primaryGreen : Color.clear)
                        .foregroundColor(selectedTimeframe == .week ? .white : AppTheme.textColor.opacity(0.6))
                        .cornerRadius(20)
                }
                
                Button(action: { selectedTimeframe = .month }) {
                    Text("Month")
                        .font(.footnote)
                        .padding(.vertical, 6)
                        .padding(.horizontal, 12)
                        .background(selectedTimeframe == .month ? AppTheme.primaryGreen : Color.clear)
                        .foregroundColor(selectedTimeframe == .month ? .white : AppTheme.textColor.opacity(0.6))
                        .cornerRadius(20)
                }
                
                Button(action: { selectedTimeframe = .year }) {
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
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                ForEach(0..<tabs.count, id: \.self) { index in
                    Button(action: {
                        withAnimation {
                            selectedTab = index
                        }
                    }) {
                        VStack(spacing: 8) {
                            Text(tabs[index])
                                .font(.system(size: 16, weight: selectedTab == index ? .semibold : .regular))
                                .foregroundColor(selectedTab == index ? AppTheme.primaryGreen : AppTheme.textColor.opacity(0.6))
                            
                            if selectedTab == index {
                                Rectangle()
                                    .fill(AppTheme.primaryGreen)
                                    .frame(height: 3)
                                    .matchedGeometryEffect(id: "activeTab", in: namespace)
                            } else {
                                Rectangle()
                                    .fill(Color.clear)
                                    .frame(height: 3)
                            }
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal)
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
            
            Text("No data yet")
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
            
            // Spending by category
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
            
            // Income distribution
            incomeDistributionCard
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
            Text("Financial Summary")
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
                ForEach(savingsTips, id: \.title) { tip in
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
            Text("Spending Summary")
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
    
    // Category breakdown card
    private var categoryBreakdownCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Spending by Category")
                .font(.headline)
                .foregroundColor(AppTheme.textColor)
            
            ZStack {
                if categoryBreakdown.isEmpty {
                    Text("No category data for this period")
                        .font(.subheadline)
                        .foregroundColor(AppTheme.textColor.opacity(0.7))
                        .frame(height: 200)
                        .frame(maxWidth: .infinity)
                } else {
                    VStack {
                        // This would be your actual pie chart in a real implementation
                        Image(systemName: "chart.pie.fill")
                            .font(.system(size: 50))
                            .foregroundColor(AppTheme.accentBlue.opacity(0.7))
                        
                        Text("Category Breakdown Chart")
                            .font(.subheadline)
                            .foregroundColor(AppTheme.textColor.opacity(0.7))
                    }
                    .frame(height: 200)
                    .frame(maxWidth: .infinity)
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
                            Text(transaction.name)
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
            Text("Income Summary")
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
    
    // Income distribution card
    private var incomeDistributionCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Income Sources")
                .font(.headline)
                .foregroundColor(AppTheme.textColor)
            
            if incomeTransactions.isEmpty {
                Text("No income data for this period")
                    .font(.subheadline)
                    .foregroundColor(AppTheme.textColor.opacity(0.7))
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
                    .background(AppTheme.cardBackground)
                    .cornerRadius(12)
            } else {
                // Sample income sources (in a real app, this would be derived from data)
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
                        Text("Primary Income")
                            .font(.subheadline)
                            .foregroundColor(AppTheme.textColor)
                        
                        Text("85% of total income")
                            .font(.caption)
                            .foregroundColor(AppTheme.textColor.opacity(0.6))
                    }
                    
                    Spacer()
                    
                    Text("$\(totalIncome * 0.85, specifier: "%.0f")")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(AppTheme.primaryGreen)
                }
                .padding()
                .background(AppTheme.cardBackground)
                .cornerRadius(12)
                
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(AppTheme.accentBlue.opacity(0.2))
                            .frame(width: 40, height: 40)
                        
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 18))
                            .foregroundColor(AppTheme.accentBlue)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Other Sources")
                            .font(.subheadline)
                            .foregroundColor(AppTheme.textColor)
                        
                        Text("15% of total income")
                            .font(.caption)
                            .foregroundColor(AppTheme.textColor.opacity(0.6))
                    }
                    
                    Spacer()
                    
                    Text("$\(totalIncome * 0.15, specifier: "%.0f")")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(AppTheme.accentBlue)
                }
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
    
    // Sample savings tips
    private var savingsTips: [(title: String, description: String, icon: String)] {
        [
            (
                title: "Reduce dining out",
                description: "Eating at home more often could save you up to $200 per month based on your current spending patterns.",
                icon: "fork.knife"
            ),
            (
                title: "Review subscriptions",
                description: "You have several subscription services that could be consolidated or reduced.",
                icon: "creditcard.fill"
            ),
            (
                title: "Use public transport",
                description: "Consider using public transportation for your daily commute to save on fuel costs.",
                icon: "car.fill"
            )
        ]
    }
}

struct InsightsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            InsightsView()
                .environmentObject(PlaidManager.shared)
        }
        .preferredColorScheme(.dark)
    }
}
