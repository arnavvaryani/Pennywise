import SwiftUI

struct BudgetPlannerView: View {
    // MARK: - Dependencies
    @Bindable var viewModel: BudgetViewModel
    @EnvironmentObject private var navigationManager: NavigationManager
    
    // MARK: - View State
    @State private var errorMessage: String? = nil
    @State private var showSuccessMessage = false
    @State private var successMessage = ""
    
    // Track if auto budget has been used
    @AppStorage("hasUsedAutoBudget") private var hasUsedAutoBudget = false
    
    var body: some View {
        ZStack {
            // Background gradient
            AppTheme.enhancedBackgroundGradient
            
            if viewModel.isLoading {
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
        .sheet(isPresented: $viewModel.showAddCategory) {
            NavigationStack {
                AddBudgetCategoryView(onAdd: addCategory, monthlyIncome: viewModel.monthlyIncome)
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
                            .font(.system(size: 14, weight: .semibold))
                        Text("Auto Budget")
                            .font(.subheadline.weight(.semibold))
                    }
                    .foregroundColor(hasUsedAutoBudget ? AppTheme.textColor.opacity(0.45) : AppTheme.primary)
                }
                .buttonStyle(ScaleButtonStyle())
                .disabled(hasUsedAutoBudget)
            }
        }
        .task {
            await viewModel.loadData()
            viewModel.initializeAnimations()
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
                    .scaleEffect(viewModel.animateCards ? 1.0 : 0.95)
                    .opacity(viewModel.animateCards ? 1.0 : 0)
                
                // Budget progress card only shown when we have viewModel.categories
                if !viewModel.categories.isEmpty {
                    budgetProgressCard
                        .padding(.horizontal)
                        .scaleEffect(viewModel.animateCards ? 1.0 : 0.95)
                        .opacity(viewModel.animateCards ? 1.0 : 0)
                }
                
                // Budget allocation visualization
                if !viewModel.categories.isEmpty {
                    budgetAllocationCard
                        .padding(.horizontal)
                        .scaleEffect(viewModel.animateCards ? 1.0 : 0.95)
                        .opacity(viewModel.animateCards ? 1.0 : 0)
                        
                    // Category section header - only shown when we have viewModel.categories
                    HStack {
                        Text("Budget Categories")
                            .font(AppTheme.headlineFont())
                            .foregroundColor(AppTheme.textColor)
                        
                        Spacer()
                        
                        Button(action: {
                            viewModel.showAddCategory = true
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
                    categoriesListView(categories: viewModel.categories)
                } else {
                    // Single empty state view when no viewModel.categories exist
                    noBudgetCategoriesView
                        .padding(.horizontal)
                        .scaleEffect(viewModel.animateCards ? 1.0 : 0.95)
                        .opacity(viewModel.animateCards ? 1.0 : 0)
                }
                
                // Bottom padding
                Spacer(minLength: 40)
            }
            .padding(.top, 16)
            .onAppear {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1)) {
                    viewModel.animateCards = true
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
        PWSectionHeader("Monthly Budget", subtitle: "Plan, track, and adjust")
    }
    
    // Budget overview card
    private var budgetOverviewCard: some View {
        PWGlassCard {
            HStack(spacing: 0) {
                budgetStatColumn(
                    title: "Budgeted",
                    amount: viewModel.totalBudget,
                    icon: "chart.pie.fill",
                    color: AppTheme.accentBlue
                )
                
                Rectangle()
                    .frame(width: 1)
                    .foregroundColor(AppTheme.cardStroke)
                    .padding(.vertical, 10)
                
                budgetStatColumn(
                    title: "Remaining",
                    amount: viewModel.remainingBudget,
                    icon: "banknote.fill",
                    color: viewModel.remainingBudget >= 0 ? AppTheme.primaryGreen : Color(hex: "#FF5757")
                )
            }
        }
    }
    
    // Budget progress card
    private var budgetProgressCard: some View {
        PWGlassCard {
            VStack(alignment: .leading, spacing: 16) {
            PWSectionHeader("Budget Progress")
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
                        .trim(from: 0, to: CGFloat(viewModel.spendingPercentage))
                        .stroke(
                            viewModel.budgetStatusColor(for: viewModel.budgetStatus),
                            style: StrokeStyle(lineWidth: 12, lineCap: .round)
                        )
                        .frame(width: 150, height: 150)
                        .rotationEffect(.degrees(-90))
                    
                    // Center text
                    VStack(spacing: 2) {
                        Text("\(Int(viewModel.spendingPercentage * 100))%")
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
                        
                        Text("\(CurrencyFormatter.format(viewModel.totalSpent))")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(AppTheme.accentBlue)
                    }
                    
                    PWDivider(opacity: 0.8)
                    
                    // Budget
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Total Budget")
                            .font(.caption)
                            .foregroundColor(AppTheme.textColor.opacity(0.7))
                        
                        Text("\(CurrencyFormatter.format(viewModel.totalBudget))")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(AppTheme.textColor)
                    }
                    
                    PWDivider(opacity: 0.8)
                    
                    // Status
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Status")
                            .font(.caption)
                            .foregroundColor(AppTheme.textColor.opacity(0.7))
                        
                        HStack(spacing: 6) {
                            Circle()
                                .fill(viewModel.budgetStatusColor(for: viewModel.budgetStatus))
                                .frame(width: 8, height: 8)
                            
                            Text(viewModel.budgetStatusText(for: viewModel.budgetStatus))
                                .font(.subheadline)
                                .foregroundColor(viewModel.budgetStatusColor(for: viewModel.budgetStatus))
                        }
                    }
                }
            }
            }
        }
    }
    
    // Budget allocation card
    private var budgetAllocationCard: some View {
        PWGlassCard {
            VStack(alignment: .leading, spacing: 16) {
                PWSectionHeader("Budget Allocation")
                    .accessibilityAddTraits(.isHeader)
                
                if viewModel.totalBudget > 0 {
                    HStack {
                        ZStack {
                            ForEach(0..<viewModel.categories.count, id: \.self) { index in
                                PieSlice(
                                    startAngle: calculateStartAngle(for: index),
                                    endAngle: calculateEndAngle(for: index)
                                )
                                .fill(Color(hex: viewModel.categories[index].colorHex))
                            }
                            
                            Circle()
                                .fill(AppTheme.backgroundColor)
                                .frame(width: 60, height: 60)
                            
                            VStack(spacing: 0) {
                                Text("\(CurrencyFormatter.format(viewModel.totalBudget))")
                                    .font(.subheadline)
                                    .fontWeight(.bold)
                                    .foregroundColor(AppTheme.textColor)
                                
                                Text("Total")
                                    .font(.caption2)
                                    .foregroundColor(AppTheme.textColor.opacity(0.7))
                            }
                        }
                        .frame(width: 150, height: 150)
                        
                        VStack(alignment: .leading, spacing: 10) {
                            ForEach(Array(viewModel.categories.prefix(5))) { category in
                                Button {
                                    navigationManager.navigate(to: .categoryInsights(category: category))
                                } label: {
                                    HStack(spacing: 8) {
                                        RoundedRectangle(cornerRadius: 2)
                                            .fill(Color(hex: category.colorHex))
                                            .frame(width: 12, height: 12)
                                        
                                        Text(category.name)
                                            .font(.caption)
                                            .foregroundColor(AppTheme.textColor)
                                        
                                        Spacer()
                                        
                                        Text("\(Int(category.amount / viewModel.totalBudget * 100))%")
                                            .font(.caption)
                                            .foregroundColor(AppTheme.textColor.opacity(0.7))
                                    }
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                            
                            if viewModel.categories.count > 5 {
                                Text("+ \(viewModel.categories.count - 5) more categories")
                                    .font(.caption)
                                    .foregroundColor(AppTheme.accentBlue)
                            }
                        }
                        .padding(.leading, 16)
                    }
                } else {
                    Text("Add budget categories to see your allocation")
                        .font(.subheadline)
                        .foregroundColor(AppTheme.textColor.opacity(0.7))
                        .frame(maxWidth: .infinity, minHeight: 150)
                        .multilineTextAlignment(.center)
                }
            }
        }
    }
    
    // Categories list view
    private func categoriesListView(categories: [BudgetCategory]) -> some View {
        VStack(spacing: 16) {
            if categories.isEmpty {
                // Empty state is already shown in budgetAllocationCard
                EmptyView()
            } else {
                ForEach(categories) { category in
                    BudgetCategoryRow(
                        category: category,
                        spent: calculateSpentForCategory(category),
                        onTap: {
                            navigationManager.navigate(to: .categoryInsights(category: category))
                        },
                        onAmountChange: { newAmount in
                            Task {
                                await viewModel.updateCategoryAmount(category: category, newAmount: newAmount)
                            }
                        },
                        onDelete: { 
                            Task {
                                await viewModel.deleteCategory(category: category)
                            }
                        }
                    )
                    .padding(.horizontal)
                    .transition(.scale(scale: 0.9).combined(with: .opacity))
                }
            }
        }
    }
    
    // Budget stat column
    private func budgetStatColumn(title: String, amount: Double, icon: String, color: Color) -> some View {
        VStack(spacing: 10) {
            // Icon
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(color)
            
            // Amount
            Text("\(CurrencyFormatter.format(abs(amount)))")
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
        .pwGlassSurface(cornerRadius: 16)
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
                viewModel.showAddCategory = true
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
        .pwGlassSurface(cornerRadius: 16)
    }
    
    // MARK: - Helper Methods
    
    // Calculate spent amount for a specific category
    private func calculateSpentForCategory(_ category: BudgetCategory) -> Double {
        return viewModel.calculateSpentForCategory(category)
    }
    
    // Add a new budget category
    private func addCategory(_ category: BudgetCategory) {
        // Check for duplicate category names
        let categoryNameLowercased = category.name.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        let existingNames = viewModel.categories.map { $0.name.lowercased().trimmingCharacters(in: .whitespacesAndNewlines) }
        
        if existingNames.contains(categoryNameLowercased) {
            errorMessage = "A category with this name already exists"
            return
        }
        
        Task {
            await viewModel.addCategory(
                name: category.name.trimmingCharacters(in: .whitespacesAndNewlines),
                amount: category.amount,
                icon: category.icon,
                colorHex: category.colorHex,
                isEssential: category.isEssential
            )
        }
    }
    
    // Update a budget category
    private func updateCategory(_ category: BudgetCategory) {
        Task {
            await viewModel.updateCategory(category)
        }
    }
    
    // MARK: - Auto Budget Method
    
    // Auto budget function
    func autoBudget() {
        // Prevent multiple uses of auto budget
        if hasUsedAutoBudget {
            errorMessage = "You've already used Auto Budget. You can manually edit categories instead."
            return
        }
        
        // First verify we have income amount
        if viewModel.monthlyIncome <= 0 {
            errorMessage = "Please add your monthly income first in settings."
            return
        }
        
        Task {
            await viewModel.generateAutoBudget()
            if viewModel.error == nil {
                hasUsedAutoBudget = true
                successMessage = "Successfully generated an auto-budget for you based on the 50/30/20 rule!"
                showSuccessMessage = true
            } else {
                errorMessage = "Failed to generate auto-budget: \(viewModel.error?.localizedDescription ?? "Unknown error")"
            }
        }
    }
    
    /* OLD FIREBASE AUTO-BUDGET CODE - REMOVED
     Will be re-implemented using repositories and ViewModels
     
     Previous implementation:
     - Define default categories (50% Needs, 30% Wants, 20% Savings/Debt)
     - Check existing Firestore categories
     - Batch update or create categories
     - Update local UI state
     */
    
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
        let precedingTotal = viewModel.categories.prefix(index).reduce(0) { $0 + $1.amount }
        return .degrees(precedingTotal / viewModel.totalBudget * 360 - 90)
    }
    
    // Calculate end angle for pie slice
    private func calculateEndAngle(for index: Int) -> Angle {
        let precedingTotal = viewModel.categories.prefix(index).reduce(0) { $0 + $1.amount }
        let categoryAmount = viewModel.categories[index].amount
        return .degrees((precedingTotal + categoryAmount) / viewModel.totalBudget * 360 - 90)
    }
}
