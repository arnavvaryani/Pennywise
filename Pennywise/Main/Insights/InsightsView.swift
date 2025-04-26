//
//  InsightsView.swift
//  Pennywise
//
//  Created by Arnav Varyani on 4/8/25.
//

import SwiftUI
import Charts

struct InsightsView: View {
    @EnvironmentObject var plaidManager: PlaidManager
    
    // State variables
    @State private var selectedTimeframe: TimeFrame = .month
    @State private var selectedTab = 0
    @State private var isRefreshing = false
    @State private var selectedCategoryIndex: Int? = nil
    @State private var selectedTransaction: PlaidTransaction? = nil
    @State private var showIncomeCategories = false // Toggle between expense and income categories
    @State private var showIncomeSourceDetail: String? = nil // Selected income source for detail view
    @State private var selectedCategoryForDetail: CategoryDetailInfo? = nil // Selected category for detail view
    
    // Tab options
    let tabs = ["Overview", "Spending", "Income", "Categories"]
    
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
            // Get the first day of the current month
            var components = calendar.dateComponents([.year, .month], from: now)
            components.day = 1
            startDate = calendar.date(from: components) ?? calendar.date(byAdding: .month, value: -1, to: now) ?? now
        case .year:
            // Get the first day of the current year
            var components = calendar.dateComponents([.year], from: now)
            components.month = 1
            components.day = 1
            startDate = calendar.date(from: components) ?? calendar.date(byAdding: .year, value: -1, to: now) ?? now
        }
        
        return plaidManager.transactions.filter { transaction in
            transaction.date >= startDate && transaction.date <= now
        }
    }
    
    private var expenseTransactions: [PlaidTransaction] {
        transactionsInTimeframe.filter { transaction in
            transaction.amount > 0
        }
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
    
    // Income category breakdown
    private var incomeCategoryBreakdown: [(String, Double)] {
        // Group transactions by category and sum amounts
        var categories: [String: Double] = [:]
        
        for transaction in incomeTransactions {
            let category = transaction.category
            categories[category, default: 0] += abs(transaction.amount)
        }
        
        // Convert to array and sort by amount (highest first)
        return categories.map { ($0.key, $0.value) }
            .sorted { $0.1 > $1.1 }
    }
    
    // Top vendors calculation
    private var topVendors: [(String, Double)] {
        // Group expense transactions by vendor and sum amounts
        var vendors: [String: Double] = [:]
        
        for transaction in expenseTransactions {
            let merchant = transaction.merchantName.isEmpty ? "Unknown Vendor" : transaction.merchantName
            vendors[merchant, default: 0] += transaction.amount
        }
        
        // Convert to array and sort by amount (highest first)
        return vendors.map { ($0.key, $0.value) }
            .sorted { $0.1 > $1.1 }
            .prefix(5)
            .map { ($0.0, $0.1) }
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
    
    // Monthly income trend data
    private var monthlyIncomeTrend: [(String, Double)] {
        let calendar = Calendar.current
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM"
        
        var monthlyData: [String: Double] = [:]
        
        // Get last 6 months
        let currentDate = Date()
        for i in 0..<6 {
            if let date = calendar.date(byAdding: .month, value: -i, to: currentDate) {
                let monthString = dateFormatter.string(from: date)
                monthlyData[monthString] = 0
            }
        }
        
        // Sum income by month
        for transaction in plaidManager.transactions.filter({ $0.amount < 0 }) {
            let monthString = dateFormatter.string(from: transaction.date)
            if monthlyData[monthString] != nil {
                monthlyData[monthString]! += abs(transaction.amount)
            }
        }
        
        // Convert to array and sort by date
        let monthOrder = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
        let now = Date()
        let currentMonth = dateFormatter.string(from: now)
        let currentMonthIndex = monthOrder.firstIndex(of: currentMonth) ?? 0
        
        var sortedMonths: [String] = []
        for i in 0..<6 {
            let index = (currentMonthIndex - i + 12) % 12
            sortedMonths.append(monthOrder[index])
        }
        
        return sortedMonths.reversed().compactMap { month in
            if let amount = monthlyData[month] {
                return (month, amount)
            }
            return nil
        }
    }
    
    // Get transactions for specific income source
    private func transactionsForIncomeSource(_ source: String) -> [PlaidTransaction] {
        return incomeTransactions.filter {
            let merchant = $0.merchantName.isEmpty ? "Primary Income" : $0.merchantName
            return merchant == source
        }
    }
    
    // Get transactions for a specific category
    private func transactionsForCategory(_ category: String, isIncome: Bool) -> [PlaidTransaction] {
        if isIncome {
            return incomeTransactions.filter { $0.category == category }
        } else {
            return expenseTransactions.filter { $0.category == category }
        }
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
                        VStack(spacing: 20) {
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
                        .padding(.top, 12)
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
        .sheet(item: $selectedTransaction) { transaction in
            TransactionDetailViewFirestore(transaction: transaction)
                .environmentObject(plaidManager)
        }
        .sheet(item: Binding(
            get: { showIncomeSourceDetail.map { IncomeSourceDetail(name: $0) } },
            set: { showIncomeSourceDetail = $0?.name }
        )) { detail in
            incomeSourceDetailView(for: detail.name)
        }
        .sheet(item: $selectedCategoryForDetail) { categoryDetail in
            categoryDetailView(for: categoryDetail.name, isIncome: categoryDetail.isIncome)
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
        HStack(spacing: 0) {
            ForEach(0..<tabs.count, id: \.self) { index in
                Button(action: {
                    withAnimation {
                        selectedTab = index
                    }
                }) {
                    Text(tabs[index])
                        .font(.footnote)
                        .padding(.vertical, 8)
                        .frame(maxWidth: .infinity)
                        .background(selectedTab == index ? AppTheme.primaryGreen : Color.clear)
                        .foregroundColor(selectedTab == index ? .white : AppTheme.textColor.opacity(0.6))
                }
            }
        }
        .background(AppTheme.cardBackground)
        .cornerRadius(8)
        .padding(.horizontal, 16)
    }
    
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
    // Category Pie Chart for Overview Tab
    private var categoryPieChartCard: some View {
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
                
                // Use the Swift Charts-based PieChartView
                PieChartView(data: chartData)
                    .frame(height: 250)
                    .padding(.vertical, 8)
                
                // Add category legend below the chart
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(chartData.prefix(5), id: \.0) { category, amount in
                            Button(action: {
                                // Show transactions for this category
                                selectedCategoryForDetail = CategoryDetailInfo(
                                    name: category,
                                    isIncome: false
                                )
                            }) {
                                HStack(spacing: 10) {
                                    Circle()
                                        .fill(categoryColor(for: category))
                                        .frame(width: 12, height: 12)
                                    
                                    Text(category)
                                        .font(.caption)
                                        .foregroundColor(AppTheme.textColor)
                                    
                                    Spacer()
                                    
                                    Text("$\(amount, specifier: "%.0f")")
                                        .font(.caption)
                                        .foregroundColor(AppTheme.textColor)
                                    
                                    Text("(\(Int(amount / totalSpending * 100))%)")
                                        .font(.caption)
                                        .foregroundColor(AppTheme.textColor.opacity(0.6))
                                }
                                .padding(.vertical, 4)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding()
                    .background(AppTheme.cardBackground)
                    .cornerRadius(12)
                }
                .frame(maxHeight: 200)
            }
        }
        .padding()
        .background(AppTheme.cardBackground.opacity(0.3))
        .cornerRadius(20)
    }
    
    // Overview tab content
    private var overviewTabContent: some View {
        VStack(spacing: 20) {
            // Financial snapshot card
            financialSnapshotCard
                .padding(.horizontal)
            
            // Category breakdown pie chart (moved from categories tab)
            categoryPieChartCard
                .padding(.horizontal)
            
            // Top spending categories
            topSpendingCategoriesCard
                .padding(.horizontal)
            
            // Income Sources Breakdown
            topIncomeSourcesCard
                .padding(.horizontal)
        }
    }
    
    // Spending tab content
    private var spendingTabContent: some View {
        VStack(spacing: 20) {
            // Spending summary card
            spendingSummaryCard
                .padding(.horizontal)
            
            // Top vendors
            topVendorsCard
                .padding(.horizontal)
            
            // Recent transactions list
            recentTransactionsCard
                .padding(.horizontal)
        }
    }
    
    // Income tab content
    private var incomeTabContent: some View {
        VStack(spacing: 20) {
            // Income summary card
            incomeSummaryCard
                .padding(.horizontal)
            
            // Income Over Time Card (NEW)
            incomeOverTimeCard
                .padding(.horizontal)
            
            // Income distribution - showing actual Plaid data
            enhancedIncomeDistributionCard
                .padding(.horizontal)
            
            // Income transactions
            incomeTransactionsCard
                .padding(.horizontal)
        }
    }
    
    // Categories tab content
    private var categoriesTabContent: some View {
        VStack(spacing: 16) {
            // Toggle between expense and income categories
            Picker("Category Type", selection: $showIncomeCategories) {
                Text("Expenses").tag(false)
                Text("Income").tag(true)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.horizontal)
            
            if showIncomeCategories {
                // Show income categories
                if incomeCategoryBreakdown.isEmpty {
                    Text("No income categories found for \(timeframeTitle.lowercased())")
                        .font(.headline)
                        .foregroundColor(AppTheme.textColor.opacity(0.7))
                        .padding()
                } else {
                    ForEach(incomeCategoryBreakdown, id: \.0) { category, amount in
                        Button(action: {
                            // Show transactions for this income category
                            selectedCategoryForDetail = CategoryDetailInfo(
                                name: category,
                                isIncome: true
                            )
                        }) {
                            categoryCard(name: category, amount: amount, isIncome: true)
                                .padding(.horizontal)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            } else {
                // Show expense categories
                if categoryBreakdown.isEmpty {
                    Text("No expense categories found for \(timeframeTitle.lowercased())")
                        .font(.headline)
                        .foregroundColor(AppTheme.textColor.opacity(0.7))
                        .padding()
                } else {
                    ForEach(categoryBreakdown, id: \.0) { category, amount in
                        Button(action: {
                            // Show transactions for this expense category
                            selectedCategoryForDetail = CategoryDetailInfo(
                                name: category,
                                isIncome: false
                            )
                        }) {
                            categoryCard(name: category, amount: amount, isIncome: false)
                                .padding(.horizontal)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
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
    
    // NEW: Top Income Sources Card
    private var topIncomeSourcesCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Income Sources")
                .font(.headline)
                .foregroundColor(AppTheme.textColor)
            
            if !incomeSources.isEmpty {
                ForEach(incomeSources.prefix(3), id: \.0) { source, amount in
                    Button(action: {
                        // Show detail view for this income source
                        showIncomeSourceDetail = source
                    }) {
                        HStack(alignment: .center, spacing: 12) {
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
                                    .foregroundColor(AppTheme.primaryGreen)
                                
                                Text("\(Int(amount / totalIncome * 100))%")
                                    .font(.caption)
                                    .foregroundColor(AppTheme.textColor.opacity(0.6))
                            }
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding()
                    .background(AppTheme.cardBackground)
                    .cornerRadius(12)
                }
                
                // "See All" button if more than 3 sources
                if incomeSources.count > 3 {
                    Button(action: {
                        selectedTab = 2 // Switch to Income tab
                    }) {
                        Text("See All Income Sources")
                            .font(.subheadline)
                            .foregroundColor(AppTheme.primaryGreen)
                            .padding(.vertical, 10)
                            .frame(maxWidth: .infinity)
                            .background(AppTheme.primaryGreen.opacity(0.1))
                            .cornerRadius(12)
                    }
                }
            } else {
                Text("No income data available")
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
    
    // Top vendors card
    private var topVendorsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Top Spending Vendors")
                .font(.headline)
                .foregroundColor(AppTheme.textColor)
            
            if !topVendors.isEmpty {
                ForEach(topVendors, id: \.0) { vendor, amount in
                    HStack(alignment: .center, spacing: 12) {
                        // Vendor icon - using first letter of vendor name
                        ZStack {
                            Circle()
                                .fill(vendorColor(for: vendor).opacity(0.2))
                                .frame(width: 40, height: 40)
                            
                            Text(String(vendor.prefix(1).uppercased()))
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(vendorColor(for: vendor))
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(vendor)
                                .font(.subheadline)
                                .foregroundColor(AppTheme.textColor)
                            
                            // Progress bar
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 5)
                                    .fill(AppTheme.cardBackground)
                                    .frame(height: 6)
                                
                                RoundedRectangle(cornerRadius: 5)
                                    .fill(vendorColor(for: vendor))
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
                Text("No vendor data available")
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
                
                // Use the Swift Charts-based PieChartView
                PieChartView(data: chartData)
                    .frame(height: 250)
                    .padding(.vertical, 8)
                
                // Add category legend below the chart
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(chartData.prefix(5), id: \.0) { category, amount in
                            Button(action: {
                                // Show transactions for this category
                                selectedCategoryForDetail = CategoryDetailInfo(
                                    name: category,
                                    isIncome: false
                                )
                            }) {
                                HStack(spacing: 10) {
                                    Circle()
                                        .fill(categoryColor(for: category))
                                        .frame(width: 12, height: 12)
                                    
                                    Text(category)
                                        .font(.caption)
                                        .foregroundColor(AppTheme.textColor)
                                    
                                    Spacer()
                                    
                                    Text("$\(amount, specifier: "%.0f")")
                                        .font(.caption)
                                        .foregroundColor(AppTheme.textColor)
                                    
                                    Text("(\(Int(amount / totalSpending * 100))%)")
                                        .font(.caption)
                                        .foregroundColor(AppTheme.textColor.opacity(0.6))
                                }
                                .padding(.vertical, 4)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding()
                    .background(AppTheme.cardBackground)
                    .cornerRadius(12)
                }
                .frame(maxHeight: 200)
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
                // Sort transactions by date, newest first
                let sortedTransactions = expenseTransactions.sorted(by: { $0.date > $1.date })
                
                ForEach(sortedTransactions.prefix(5)) { transaction in
                    Button(action: {
                        selectedTransaction = transaction
                    }) {
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
                    .buttonStyle(PlainButtonStyle())
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
    
    // NEW: Income Over Time Card
    private var incomeOverTimeCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Income Over Time")
                .font(.headline)
                .foregroundColor(AppTheme.textColor)
            
            if monthlyIncomeTrend.isEmpty {
                Text("No income trend data available")
                    .font(.subheadline)
                    .foregroundColor(AppTheme.textColor.opacity(0.7))
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
                    .background(AppTheme.cardBackground)
                    .cornerRadius(12)
            } else {
                VStack {
                    Chart {
                        ForEach(monthlyIncomeTrend, id: \.0) { item in
                            BarMark(
                                x: .value("Month", item.0),
                                y: .value("Amount", item.1)
                            )
                            .foregroundStyle(AppTheme.primaryGreen.gradient)
                            .cornerRadius(6)
                        }
                    }
                    .frame(height: 200)
                    .chartYAxis {
                        AxisMarks(position: .leading) { value in
                            if let amount = value.as(Double.self) {
                                AxisValueLabel("$\(Int(amount))")
                            }
                            AxisGridLine()
                        }
                    }
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
                        ForEach(incomeSources, id: \.0) { source, amount in
                            Button(action: {
                                // Show detail view for this income source
                                showIncomeSourceDetail = source
                            }) {
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
                            }
                            .buttonStyle(PlainButtonStyle())
                            .padding()
                            .background(AppTheme.cardBackground)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(AppTheme.cardStroke, lineWidth: 1)
                            )
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
    
    // NEW: Income transactions card
    private var incomeTransactionsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Income Transactions")
                .font(.headline)
                .foregroundColor(AppTheme.textColor)
            
            if incomeTransactions.isEmpty {
                Text("No income transactions")
                    .font(.subheadline)
                    .foregroundColor(AppTheme.textColor.opacity(0.7))
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
                    .background(AppTheme.cardBackground)
                    .cornerRadius(12)
            } else {
                // Sort transactions by date, newest first
                let sortedTransactions = incomeTransactions.sorted(by: { $0.date > $1.date })
                
                ForEach(sortedTransactions.prefix(5)) { transaction in
                    Button(action: {
                        selectedTransaction = transaction
                    }) {
                        HStack(spacing: 12) {
                            // Icon
                            ZStack {
                                Circle()
                                    .fill(AppTheme.primaryGreen.opacity(0.2))
                                    .frame(width: 40, height: 40)
                                
                                Image(systemName: "arrow.down.circle.fill")
                                    .font(.system(size: 18))
                                    .foregroundColor(AppTheme.primaryGreen)
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(transaction.merchantName.isEmpty ? "Income Deposit" : transaction.merchantName)
                                    .font(.subheadline)
                                    .foregroundColor(AppTheme.textColor)
                                
                                Text(formatDate(transaction.date))
                                    .font(.caption)
                                    .foregroundColor(AppTheme.textColor.opacity(0.6))
                            }
                            
                            Spacer()
                            
                            Text("$\(abs(transaction.amount), specifier: "%.2f")")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(AppTheme.primaryGreen)
                        }
                        .padding()
                        .background(AppTheme.cardBackground)
                        .cornerRadius(12)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
        .padding()
        .background(AppTheme.cardBackground.opacity(0.3))
        .cornerRadius(20)
    }
    
    // Category card for the Categories tab
    private func categoryCard(name: String, amount: Double, isIncome: Bool) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                ZStack {
                    Circle()
                        .fill((isIncome ? AppTheme.primaryGreen : categoryColor(for: name)).opacity(0.2))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: isIncome ? "arrow.down.circle.fill" : getCategoryIcon(for: name))
                        .font(.system(size: 18))
                        .foregroundColor(isIncome ? AppTheme.primaryGreen : categoryColor(for: name))
                }
                
                Text(name)
                    .font(.headline)
                    .foregroundColor(AppTheme.textColor)
                
                Spacer()
                
                Text("$\(amount, specifier: "%.0f")")
                    .font(.headline)
                    .foregroundColor(isIncome ? AppTheme.primaryGreen : AppTheme.textColor)
            }
            
            // Percentage of total
            HStack {
                Text("\(Int(amount / (isIncome ? totalIncome : totalSpending) * 100))% of total")
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
                    .fill(isIncome ? AppTheme.primaryGreen : categoryColor(for: name))
                    .frame(width: (isIncome ? totalIncome : totalSpending) > 0
                           ? CGFloat(amount / (isIncome ? totalIncome : totalSpending)) * (UIScreen.main.bounds.width - 64)
                           : 0,
                           height: 8)
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
    
    // Income source detail view
    private func incomeSourceDetailView(for source: String) -> some View {
        let transactions = transactionsForIncomeSource(source)
        let totalAmount = transactions.reduce(0.0) { $0 + abs($1.amount) }
        
        return NavigationView {
            ZStack {
                AppTheme.backgroundGradient
                    .edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 16) {
                    // Header
                    VStack(spacing: 4) {
                        Text(source)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(AppTheme.textColor)
                        
                        Text("Income Source")
                            .font(.subheadline)
                            .foregroundColor(AppTheme.textColor.opacity(0.7))
                    }
                    .padding(.top)
                    
                    // Total income from this source
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Total Income")
                                .font(.subheadline)
                                .foregroundColor(AppTheme.textColor.opacity(0.7))
                            
                            Text("$\(totalAmount, specifier: "%.2f")")
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(AppTheme.primaryGreen)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("Percentage")
                                .font(.subheadline)
                                .foregroundColor(AppTheme.textColor.opacity(0.7))
                            
                            Text("\(Int(totalAmount / totalIncome * 100))%")
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(AppTheme.accentBlue)
                        }
                    }
                    .padding()
                    .background(AppTheme.cardBackground)
                    .cornerRadius(16)
                    .padding(.horizontal)
                    
                    // All transactions from this source
                    ScrollView {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Income Transactions")
                                .font(.headline)
                                .foregroundColor(AppTheme.textColor)
                                .padding(.horizontal)
                            
                            ForEach(transactions.sorted(by: { $0.date > $1.date })) { transaction in
                                Button(action: {
                                    selectedTransaction = transaction
                                    showIncomeSourceDetail = nil
                                }) {
                                    HStack(spacing: 12) {
                                        // Icon
                                        ZStack {
                                            Circle()
                                                .fill(AppTheme.primaryGreen.opacity(0.2))
                                                .frame(width: 40, height: 40)
                                            
                                            Image(systemName: "arrow.down.circle.fill")
                                                .font(.system(size: 18))
                                                .foregroundColor(AppTheme.primaryGreen)
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
                                        
                                        Text("$\(abs(transaction.amount), specifier: "%.2f")")
                                            .font(.subheadline)
                                            .fontWeight(.semibold)
                                            .foregroundColor(AppTheme.primaryGreen)
                                    }
                                    .padding()
                                    .background(AppTheme.cardBackground)
                                    .cornerRadius(12)
                                }
                                .buttonStyle(PlainButtonStyle())
                                .padding(.horizontal)
                            }
                        }
                        .padding(.bottom, 40)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        showIncomeSourceDetail = nil
                    }
                    .foregroundColor(AppTheme.primaryGreen)
                }
            }
        }
    }
    
    // Category detail view
    private func categoryDetailView(for category: String, isIncome: Bool) -> some View {
        let transactions = transactionsForCategory(category, isIncome: isIncome)
        let totalAmount = transactions.reduce(0.0) { $0 + (isIncome ? abs($1.amount) : $1.amount) }
        let totalCompare = isIncome ? totalIncome : totalSpending
        
        return NavigationView {
            ZStack {
                AppTheme.backgroundGradient
                    .edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 16) {
                    // Header
                    VStack(spacing: 4) {
                        Text(category)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(AppTheme.textColor)
                        
                        Text(isIncome ? "Income Category" : "Expense Category")
                            .font(.subheadline)
                            .foregroundColor(AppTheme.textColor.opacity(0.7))
                    }
                    .padding(.top)
                    
                    // Category icon
                    ZStack {
                        Circle()
                            .fill((isIncome ? AppTheme.primaryGreen : categoryColor(for: category)).opacity(0.2))
                            .frame(width: 60, height: 60)
                        
                        Image(systemName: isIncome ? "arrow.down.circle.fill" : getCategoryIcon(for: category))
                            .font(.system(size: 30))
                            .foregroundColor(isIncome ? AppTheme.primaryGreen : categoryColor(for: category))
                    }
                    .padding(.bottom, 8)
                    
                    // Total for this category
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(isIncome ? "Total Income" : "Total Spent")
                                .font(.subheadline)
                                .foregroundColor(AppTheme.textColor.opacity(0.7))
                            
                            Text("$\(totalAmount, specifier: "%.2f")")
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(isIncome ? AppTheme.primaryGreen : AppTheme.expenseColor)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("Percentage")
                                .font(.subheadline)
                                .foregroundColor(AppTheme.textColor.opacity(0.7))
                            
                            Text("\(Int(totalAmount / totalCompare * 100))%")
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(AppTheme.accentBlue)
                        }
                    }
                    .padding()
                    .background(AppTheme.cardBackground)
                    .cornerRadius(16)
                    .padding(.horizontal)
                    
                    // All transactions in this category
                    ScrollView {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("\(category) Transactions")
                                .font(.headline)
                                .foregroundColor(AppTheme.textColor)
                                .padding(.horizontal)
                            
                            if transactions.isEmpty {
                                Text("No transactions found in this category")
                                    .font(.subheadline)
                                    .foregroundColor(AppTheme.textColor.opacity(0.7))
                                    .frame(maxWidth: .infinity, alignment: .center)
                                    .padding()
                            } else {
                                ForEach(transactions.sorted(by: { $0.date > $1.date })) { transaction in
                                    Button(action: {
                                        selectedTransaction = transaction
                                        selectedCategoryForDetail = nil
                                    }) {
                                        HStack(spacing: 12) {
                                            // Icon
                                            ZStack {
                                                Circle()
                                                    .fill((isIncome ? AppTheme.primaryGreen : categoryColor(for: category)).opacity(0.2))
                                                    .frame(width: 40, height: 40)
                                                
                                                Image(systemName: isIncome ? "arrow.down.circle.fill" : getCategoryIcon(for: category))
                                                    .font(.system(size: 18))
                                                    .foregroundColor(isIncome ? AppTheme.primaryGreen : categoryColor(for: category))
                                            }
                                            
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text(transaction.merchantName.isEmpty ? transaction.name : transaction.merchantName)
                                                    .font(.subheadline)
                                                    .foregroundColor(AppTheme.textColor)
                                                
                                                Text(formatDate(transaction.date))
                                                    .font(.caption)
                                                    .foregroundColor(AppTheme.textColor.opacity(0.6))
                                            }
                                            
                                            Spacer()
                                            
                                            Text("$\(isIncome ? abs(transaction.amount) : transaction.amount, specifier: "%.2f")")
                                                .font(.subheadline)
                                                .fontWeight(.semibold)
                                                .foregroundColor(isIncome ? AppTheme.primaryGreen : AppTheme.expenseColor)
                                        }
                                        .padding()
                                        .background(AppTheme.cardBackground)
                                        .cornerRadius(12)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    .padding(.horizontal)
                                }
                            }
                        }
                        .padding(.bottom, 40)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        selectedCategoryForDetail = nil
                    }
                    .foregroundColor(AppTheme.primaryGreen)
                }
            }
        }
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
    
    // Vendor color generator
    private func vendorColor(for vendor: String) -> Color {
        let vendorColors: [Color] = [
            AppTheme.primaryGreen,
            AppTheme.accentBlue,
            AppTheme.accentPurple,
            Color(hex: "#FF5757"),
            Color(hex: "#FFD700"),
            Color(hex: "#9370DB"),
            Color(hex: "#FF8C00"),
            Color(hex: "#20B2AA"),
            Color(hex: "#FF7F50")
        ]
        
        // Generate a consistent index based on vendor name
        let hash = abs(vendor.hashValue)
        let index = hash % vendorColors.count
        
        return vendorColors[index]
    }
}

// Support for income source detail sheet
struct IncomeSourceDetail: Identifiable {
    var id: String { name }
    let name: String
}

// Support for category detail sheet
struct CategoryDetailInfo: Identifiable {
    var id: String { name + (isIncome ? "-income" : "-expense") }
    let name: String
    let isIncome: Bool
}

// Data structure for pie chart
struct PieChartDataPoint: Identifiable {
    var id = UUID()
    let category: String
    let amount: Double
    let color: Color
}
