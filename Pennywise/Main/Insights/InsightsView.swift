import SwiftUI
import Charts

struct InsightsView: View {
    // MARK: - Dependencies
    var viewModel: InsightsViewModel
    private let container = DependencyContainer.shared
    @EnvironmentObject private var navigationManager: NavigationManager
    @Environment(\.dismiss) private var dismiss
    
    // State variables
    @State private var selectedTimeframe: TimeFrame = .month
    @State private var selectedTab = 0
    @State private var isRefreshing = false
    @State private var selectedCategoryIndex: Int? = nil
//    @State private var selectedTransaction: Transaction? = nil
    @State private var showingPlaidLink = false
    @State private var isPreparingPlaidLink = false
    @State private var plaidErrorMessage: String? = nil
    
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
    
    // MARK: - Derived from the prepared summary (all finance math lives in
    // FetchInsightsUseCase; these are thin, math-free accessors for rendering).

    private var summary: InsightsSummary? { viewModel.summary }

    private var expenseTransactions: [Transaction] { summary?.expenseTransactions ?? [] }
    private var incomeTransactions: [Transaction] { summary?.incomeTransactions ?? [] }
    private var hasNoData: Bool { summary?.isEmpty ?? true }

    private var categoryBreakdown: [(String, Double)] {
        (summary?.categoryBreakdown ?? []).map { ($0.name, $0.amount) }
    }
    private var topVendors: [(String, Double)] {
        (summary?.topVendors ?? []).map { ($0.name, $0.amount) }
    }
    private var incomeSources: [(String, Double)] {
        (summary?.incomeSources ?? []).map { ($0.name, $0.amount) }
    }
    private var totalSpending: Double { summary?.totalSpending ?? 0 }
    private var totalIncome: Double { summary?.totalIncome ?? 0 }
    private var netCashflow: Double { summary?.netCashflow ?? 0 }
    private var last30DaysSpending: Double { summary?.last30DaysSpending ?? 0 }
    private var allTimeSpending: Double { summary?.allTimeSpending ?? 0 }
    private var spendingVsIncomePercent: Int { summary?.spendingVsIncomePercent ?? 0 }

    private var analysisBars: [MiniBarChart.Bar] {
        (summary?.bars ?? []).map { MiniBarChart.Bar(value: $0.value, label: $0.label) }
    }

    private var analysisTimeframeLabel: String {
        switch selectedTimeframe {
        case .week: return "Week"
        case .month: return "Month"
        case .year: return "Year"
        }
    }

    var body: some View {
        ZStack {
            AppTheme.enhancedBackgroundGradient

            if isRefreshing {
                loadingView
            } else if hasNoData {
                emptyStateView
            } else {
                ScrollView {
                    VStack(spacing: 14) {
                        summaryRow
                            .padding(.top, 6)
                        
                        analysisCard
                            .padding(.top, 6)
                        
                        totalSpentSection
                            .padding(.top, 6)
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 32)
                }
            }
        }
        .task {
            await viewModel.load(timeframe: selectedTimeframe)
        }
        .onChange(of: selectedTimeframe) { _, newValue in
            Task { await viewModel.load(timeframe: newValue) }
        }
        .fullScreenCover(isPresented: $showingPlaidLink) {
            if let handler = container.plaidService.linkController {
                PlaidLinkView(handler: handler) {
                    showingPlaidLink = false
                }
                .onAppear {
                    container.plaidService.onSuccess = {
                        showingPlaidLink = false
                        Task { await viewModel.load(timeframe: selectedTimeframe) }
                    }
                    container.plaidService.onLinkError = { error in
                        showingPlaidLink = false
                        plaidErrorMessage = error.localizedDescription
                    }
                    container.plaidService.onExit = {
                        showingPlaidLink = false
                    }
                }
            } else {
                ZStack {
                    AppTheme.enhancedBackgroundGradient
                    ProgressView("Preparing Plaid Link…")
                        .foregroundStyle(AppTheme.textColor)
                }
            }
        }
        .alert("Plaid Link Error", isPresented: Binding(get: { plaidErrorMessage != nil }, set: { _ in plaidErrorMessage = nil })) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(plaidErrorMessage ?? "")
        }
        .navigationTitle("Insights")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Reference layout (Sport Activities style)
    
    private var topBar: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(AppTheme.textColor.opacity(0.85))
                    .frame(width: 42, height: 42)
                    .glassEffect(.regular.interactive(), in: .circle)
            }
            .buttonStyle(ScaleButtonStyle())
            
            Spacer()
            
            Text("Spending Activities")
                .font(.headline)
                .foregroundColor(AppTheme.textColor)
            
            Spacer()
            
            // Balance spacing with a hidden button
            Circle()
                .fill(Color.clear)
                .frame(width: 42, height: 42)
        }
    }
    
    private var summaryRow: some View {
        HStack(spacing: 12) {
            summaryCard(
                title: "Last 30 days",
                value: -last30DaysSpending,
                trailing: AnyView(
                    Image(systemName: "waveform.path.ecg")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(AppTheme.accentPurple.opacity(0.9))
                )
            )
            
            summaryCard(
                title: "All time",
                value: -allTimeSpending,
                trailing: AnyView(ringPercentBadge(percent: spendingVsIncomePercent))
            )
        }
    }
    
    private func summaryCard(title: String, value: Double, trailing: AnyView) -> some View {
        PWGlassCard {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text(title)
                        .font(.caption)
                        .foregroundColor(AppTheme.textColor.opacity(0.65))
                    
                    Spacer()
                    
                    trailing
                }
                
                Text("\(value < 0 ? "-" : "")\(CurrencyFormatter.format(abs(value)))")
                    .font(.title3.weight(.bold))
                    .foregroundColor(AppTheme.textColor)
                    .monospacedDigit()
            }
        }
        .frame(maxWidth: .infinity)
    }
    
    private func ringPercentBadge(percent: Int) -> some View {
        ZStack {
            Circle()
                .stroke(AppTheme.cardStroke, lineWidth: 5)
            
            Circle()
                .trim(from: 0, to: CGFloat(min(max(Double(percent) / 100.0, 0), 1)))
                .stroke(AppTheme.accentPurple, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                .rotationEffect(.degrees(-90))
            
            Text("\(percent)%")
                .font(.caption.weight(.semibold))
                .foregroundColor(AppTheme.textColor.opacity(0.8))
        }
        .frame(width: 34, height: 34)
    }
    
    private var analysisCard: some View {
        PWGlassCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Spending Analysis")
                        .font(.headline)
                        .foregroundColor(AppTheme.textColor)
                    
                    Spacer()
                    
                    Menu {
                        Button("Week") { selectedTimeframe = .week }
                        Button("Month") { selectedTimeframe = .month }
                        Button("Year") { selectedTimeframe = .year }
                    } label: {
                        PWPill(title: analysisTimeframeLabel, systemImage: "chevron.down", tint: AppTheme.cardBackground)
                    }
                }
                
                if let maxBar = analysisBars.max(by: { $0.value < $1.value }), maxBar.value > 0 {
                    PWPill(
                        title: "-\(CurrencyFormatter.format(maxBar.value))",
                        tint: AppTheme.accentPurple,
                        isSelected: true
                    )
                }
                
                MiniBarChart(bars: analysisBars, accent: AppTheme.accentPurple)
            }
        }
    }
    
    private var totalSpentSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Total Spent")
                        .font(.headline)
                        .foregroundColor(AppTheme.textColor)
                    Text("\(timeframeTitle) total spend")
                        .font(.caption)
                        .foregroundColor(AppTheme.textColor.opacity(0.65))
                }
                
                Spacer()
                
                let dateString = formattedShortDate(Date())
                PWPill(title: dateString, systemImage: "calendar", tint: AppTheme.cardBackground)
            }
            
            PWGlassCard {
                if expenseTransactions.isEmpty {
                    Text("No spending transactions in this period.")
                        .font(.subheadline)
                        .foregroundColor(AppTheme.textColor.opacity(0.7))
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 10)
                } else {
                    VStack(spacing: 0) {
                        ForEach(Array(expenseTransactions.sorted(by: { $0.date > $1.date }).prefix(12).enumerated()), id: \.element.id) { idx, tx in
                            Button {
                                navigationManager.navigate(to: .transactionDetail(transaction: tx))
                            } label: {
                                HomeActivityRow(transaction: tx)
                            }
                            .buttonStyle(.plain)
                            
                            if idx != min(expenseTransactions.count, 12) - 1 {
                                PWDivider(inset: 56, opacity: 0.8)
                            }
                        }
                    }
                }
            }
        }
    }
    
    private func formattedShortDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd MMM yyyy"
        return formatter.string(from: date)
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
            
            PWPrimaryButton(title: isPreparingPlaidLink ? "Preparing..." : "Connect accounts", isLoading: isPreparingPlaidLink, isDisabled: isPreparingPlaidLink) {
                Task {
                    isPreparingPlaidLink = true
                    defer { isPreparingPlaidLink = false }
                    do {
                        try await container.preparePlaidLink()
                        if container.plaidService.linkController != nil {
                            showingPlaidLink = true
                        } else {
                            plaidErrorMessage = "Unable to start Plaid Link. Please try again."
                        }
                    } catch {
                        plaidErrorMessage = error.localizedDescription
                    }
                }
            }
            .frame(width: 260)
            
            Spacer()
        }
        .padding()
    }
    
    // MARK: - Tab Content
    
    // Overview tab content
    private var overviewTabContent: some View {
        VStack(spacing: 20) {
            // Financial snapshot card
            financialSnapshotCard
                .padding(.horizontal)
            
            // Top spending categories
            topSpendingCategoriesCard
                .padding(.horizontal)
            
            // Top spending vendors card (replacing Savings Insights)
            topVendorsCard
                .padding(.horizontal)
        }
    }
    
    // Spending tab content
    private var spendingTabContent: some View {
        VStack(spacing: 20) {
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
        VStack(spacing: 20) {
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
                ForEach(categoryBreakdown, id: \.0) { category, amount in
                    categoryCard(name: category, amount: amount)
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
        PWGlassCard {
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
                    
                    Text("\(CurrencyFormatter.format(totalIncome))")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(AppTheme.primaryGreen)
                }
                .frame(maxWidth: .infinity)
                
                PWDivider(opacity: 0.8)
                
                // Expenses
                VStack {
                    Text("Expenses")
                        .font(.subheadline)
                        .foregroundColor(AppTheme.textColor.opacity(0.7))
                    
                    Text("\(CurrencyFormatter.format(totalSpending))")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(AppTheme.expenseColor)
                }
                .frame(maxWidth: .infinity)
                
                PWDivider(opacity: 0.8)
                
                // Net
                VStack {
                    Text("Net")
                        .font(.subheadline)
                        .foregroundColor(AppTheme.textColor.opacity(0.7))
                    
                    Text("\(CurrencyFormatter.format(netCashflow))")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(netCashflow >= 0 ? AppTheme.primaryGreen : AppTheme.expenseColor)
                 }
                .frame(maxWidth: .infinity)
            }
            .padding(12)
        }
        }
    }
    
    // Top spending categories card
    private var topSpendingCategoriesCard: some View {
        PWGlassCard {
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
                            Text("\(CurrencyFormatter.format(amount))")
                                .font(.headline)
                                .foregroundColor(AppTheme.textColor)
                            
                            Text("\(Int(amount / totalSpending * 100))%")
                                .font(.caption)
                                .foregroundColor(AppTheme.textColor.opacity(0.6))
                        }
                    }
                    .padding()
                    .pwGlassSurface(cornerRadius: 12)
                }
            } else {
                Text("No spending data available")
                    .font(.subheadline)
                    .foregroundColor(AppTheme.textColor.opacity(0.7))
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
                    .pwGlassSurface(cornerRadius: 12)
            }
        }
        }
    }
    
    // NEW: Top Vendors Card (replacing Savings Insights)
    private var topVendorsCard: some View {
        PWGlassCard {
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
                            Text("\(CurrencyFormatter.format(amount))")
                                .font(.headline)
                                .foregroundColor(AppTheme.textColor)
                            
                            Text("\(Int(amount / totalSpending * 100))%")
                                .font(.caption)
                                .foregroundColor(AppTheme.textColor.opacity(0.6))
                        }
                    }
                    .padding()
                    .pwGlassSurface(cornerRadius: 12)
                }
            } else {
                Text("No vendor data available")
                    .font(.subheadline)
                    .foregroundColor(AppTheme.textColor.opacity(0.7))
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
                    .pwGlassSurface(cornerRadius: 12)
            }
        }
        }
    }
    
    // Spending summary card
    private var spendingSummaryCard: some View {
        PWGlassCard {
            VStack(alignment: .leading, spacing: 12) {
            Text("Spending Summary - \(timeframeTitle)")
                .font(.headline)
                .foregroundColor(AppTheme.textColor)
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Total Spent")
                        .font(.subheadline)
                        .foregroundColor(AppTheme.textColor.opacity(0.7))
                    
                    Text("\(CurrencyFormatter.format(totalSpending))")
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
            .padding(12)
        }
        }
    }
    
    private var categoryBreakdownCard: some View {
        PWGlassCard {
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
                            HStack(spacing: 10) {
                                Circle()
                                    .fill(categoryColor(for: category))
                                    .frame(width: 12, height: 12)
                                
                                Text(category)
                                    .font(.caption)
                                    .foregroundColor(AppTheme.textColor)
                                
                                Spacer()
                                
                                Text("\(CurrencyFormatter.format(amount))")
                                    .font(.caption)
                                    .foregroundColor(AppTheme.textColor)
                                
                                Text("(\(Int(amount / totalSpending * 100))%)")
                                    .font(.caption)
                                    .foregroundColor(AppTheme.textColor.opacity(0.6))
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .padding(12)
                    .pwGlassSurface(cornerRadius: 12)
                }
                .frame(maxHeight: 200)
            }
            }
        }
    }
    
    // Recent transactions card
    private var recentTransactionsCard: some View {
        PWGlassCard {
            VStack(alignment: .leading, spacing: 12) {
            Text("Recent Transactions")
                .font(.headline)
                .foregroundColor(AppTheme.textColor)
            
            if expenseTransactions.isEmpty {
                Text("No recent transactions")
                    .font(.subheadline)
                    .foregroundColor(AppTheme.textColor.opacity(0.7))
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 12)
            } else {
                // Sort transactions by date, newest first
                let sortedTransactions = expenseTransactions.sorted(by: { $0.date > $1.date })
                
                VStack(spacing: 0) {
                    ForEach(Array(sortedTransactions.prefix(5).enumerated()), id: \.element.id) { idx, transaction in
                        Button {
                            navigationManager.navigate(to: .transactionDetail(transaction: transaction))
                        } label: {
                            HomeActivityRow(transaction: transaction)
                        }
                        .buttonStyle(.plain)
                        
                        if idx != min(sortedTransactions.count, 5) - 1 {
                            PWDivider(inset: 56, opacity: 0.8)
                        }
                    }
                }
            }
        }
        }
    }
    
    // Income summary card
    private var incomeSummaryCard: some View {
        PWGlassCard {
            VStack(alignment: .leading, spacing: 12) {
            Text("Income Summary - \(timeframeTitle)")
                .font(.headline)
                .foregroundColor(AppTheme.textColor)
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Total Income")
                        .font(.subheadline)
                        .foregroundColor(AppTheme.textColor.opacity(0.7))
                    
                    Text("\(CurrencyFormatter.format(totalIncome))")
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
            .padding(12)
        }
        }
    }
    
    // Enhanced income distribution card
    private var enhancedIncomeDistributionCard: some View {
        PWGlassCard {
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
                                    Text("\(CurrencyFormatter.format(amount))")
                                        .font(.headline)
                                        .foregroundColor(AppTheme.textColor)
                                    
                                    Text("\(Int(amount / totalIncome * 100))%")
                                        .font(.caption)
                                        .foregroundColor(AppTheme.textColor.opacity(0.6))
                                }
                            }
                            .padding()
                            .pwGlassSurface(cornerRadius: 12)
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
                            
                            Text("\(CurrencyFormatter.format(totalIncome))")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(AppTheme.primaryGreen)
                        }
                        .padding()
                        .pwGlassSurface(cornerRadius: 12)
                    }
                }
            } else {
                Text("No income data for this period")
                    .font(.subheadline)
                    .foregroundColor(AppTheme.textColor.opacity(0.7))
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
                    .pwGlassSurface(cornerRadius: 12)
            }
        }
        }
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
                
                Text("\(CurrencyFormatter.format(amount))")
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
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(AppTheme.cardBackground)
                        .frame(height: 8)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(categoryColor(for: name))
                        .frame(width: totalSpending > 0
                               ? CGFloat(amount / totalSpending) * geometry.size.width
                               : 0,
                               height: 8)
                }
            }
            .frame(height: 8)
        }
        .padding()
        .pwGlassSurface(cornerRadius: 16)
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
    
    // NEW: Vendor color generator
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
