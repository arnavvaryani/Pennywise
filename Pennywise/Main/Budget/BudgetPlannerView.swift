//
//  BudgetPlannerView.swift
//  Pennywise
//
//  Created by Arnav Varyani on 4/10/25.
//

import SwiftUI

//
//  EnhancedBudgetPlannerView.swift
//  Pennywise
//
//  Created for Pennywise App
//

//struct BudgetPlannerView: View {
//    @EnvironmentObject var plaidManager: PlaidManager
//    
//    // State variables
//    @State private var selectedTimeframe: Int = 1 // 0: Weekly, 1: Monthly, 2: Yearly, 3: Custom
//    @State private var selectedCategoryTab: Int = 0 // 0: All, 1: Essential, 2: Non-Essential
//    @State private var selectedMonth: String = "May"
//    @State private var showAddCategory = false
//    @State private var categories: [BudgetCategory] = []
//    @State private var monthlyIncome: Double = 0
//    @State private var isRefreshing: Bool = false
//    @State private var animateCards: Bool = false
//    @State private var isLoading: Bool = false
//    @State private var showingCategoryDetail: Bool = false
//    @State private var selectedCategory: BudgetCategory? = nil
//    @State private var showExportOptions: Bool = false
//    @State private var showingSettingsSheet: Bool = false
//    @State private var showingAnalysisView: Bool = false
//    @State private var analysisInsights: [String] = []
//    
//    // Tab definitions
//    let timeframeTabs = ["Weekly", "Monthly", "Yearly", "Custom"]
//    let categoryFilterTabs = ["All", "Essential", "Non-Essential"]
//    
//    // Budget metrics
//    var totalBudget: Double {
//        categories.reduce(0) { $0 + $1.amount }
//    }
//    
//    var remainingBudget: Double {
//        monthlyIncome - totalBudget
//    }
//    
//    var totalSpentThisMonth: Double {
//        let calendar = Calendar.current
//        let now = Date()
//        let currentMonth = calendar.component(.month, from: now)
//        let currentYear = calendar.component(.year, from: now)
//        
//        // Get transactions for current month
//        return plaidManager.transactions
//            .filter { transaction in
//                let transactionMonth = calendar.component(.month, from: transaction.date)
//                let transactionYear = calendar.component(.year, from: transaction.date)
//                return transactionMonth == currentMonth && transactionYear == currentYear && transaction.amount > 0
//            }
//            .reduce(0) { $0 + $1.amount }
//    }
//    
//    var budgetProgressPercentage: Double {
//        if totalBudget == 0 { return 0 }
//        return min(totalSpentThisMonth / totalBudget, 1.0)
//    }
//    
//    var budgetStatus: BudgetStatus {
//        let ratio = totalSpentThisMonth / totalBudget
//        if ratio > 1.0 {
//            return .overBudget
//        } else if ratio > 0.9 {
//            return .warning
//        } else if ratio > 0.1 {
//            return .onTrack
//        } else {
//            return .underBudget
//        }
//    }
//    
//    // Filtered categories based on selected tab
//    var filteredCategories: [BudgetCategory] {
//        switch selectedCategoryTab {
//        case 1: // Essential
//            return categories.filter { CategoryDetailView.isEssentialCategory($0.name) }
//        case 2: // Non-Essential
//            return categories.filter { !CategoryDetailView.isEssentialCategory($0.name) }
//        default: // All
//            return categories
//        }
//    }
//    
//    var body: some View {
//        ZStack {
//            // Background gradient
//            AppTheme.backgroundGradient
//                .edgesIgnoringSafeArea(.all)
//            
//            if isLoading {
//                loadingView
//            } else {
//                VStack(spacing: 0) {
//                    // Header with month selector
//                    headerView
//                        .padding(.horizontal)
//                        .padding(.top, 12)
//                        .padding(.bottom, 8)
//                    
//                    // Timeframe tabs
//                    VersatileTopTabs(
//                        selectedIndex: $selectedTimeframe,
//                        tabs: timeframeTabs,
//                        style: .segmented,
//                        distribution: .fillEqually,
//                        height: 44,
//                        backgroundColor: AppTheme.cardBackground,
//                        cornerRadius: 12,
//                        padding: EdgeInsets(top: 0, leading: 16, bottom: 8, trailing: 16)
//                    ) { _ in
//                        // This content will be replaced by our main scroll view
//                        EmptyView()
//                    }
//                    .frame(height: 44)
//                    
//                    // Main content
//                    mainContent
//                }
//            }
//        }
//        .sheet(isPresented: $showAddCategory) {
//            AddBudgetCategoryView(onAdd: addCategory)
//        }
//        .sheet(isPresented: $showingCategoryDetail) {
//            if let category = selectedCategory {
//                CategoryDetailView(
//                    category: category,
//                    onUpdate: { updatedCategory in
//                        updateCategory(updatedCategory)
//                    },
//                    plaidManager: plaidManager
//                )
//            }
//        }
//        .sheet(isPresented: $showingSettingsSheet) {
//            BudgetSettingsView(
//                showNotifications: true,
//                enableReminders: true,
//                defaultCurrency: "USD"
//            )
//        }
//        .sheet(isPresented: $showingAnalysisView) {
//            BudgetAnalysisView(insights: analysisInsights, presentationMode: $showingAnalysisView)
//        }
//        .actionSheet(isPresented: $showExportOptions) {
//            ActionSheet(
//                title: Text("Export Budget"),
//                message: Text("Choose export format"),
//                buttons: [
//                    .default(Text("PDF")) { exportBudget(format: "pdf") },
//                    .default(Text("CSV")) { exportBudget(format: "csv") },
//                    .default(Text("Share")) { shareBudget() },
//                    .cancel()
//                ]
//            )
//        }
//        .navigationTitle("Budget Planner")
//        .navigationBarTitleDisplayMode(.inline)
//        .toolbar {
//            ToolbarItem(placement: .navigationBarTrailing) {
//                Menu {
//                    Button(action: {
//                        showingSettingsSheet = true
//                    }) {
//                        Label("Settings", systemImage: "gear")
//                    }
//                    
//                    Button(action: {
//                        showExportOptions = true
//                    }) {
//                        Label("Export", systemImage: "square.and.arrow.up")
//                    }
//                    
//                    Button(action: refreshData) {
//                        Label("Refresh", systemImage: "arrow.clockwise")
//                    }
//                } label: {
//                    Image(systemName: "ellipsis.circle")
//                        .foregroundColor(AppTheme.primaryGreen)
//                }
//            }
//        }
//        .onAppear {
//            isLoading = true
//            loadInitialData()
//        }
//        .onChange(of: selectedMonth) { newMonth in
//            loadBudgetForMonth(newMonth)
//        }
//        .onChange(of: selectedTimeframe) { newValue in
//            adjustBudgetForTimeframe(BudgetTimeframe(rawValue: timeframeTabs[newValue].lowercased()) ?? .month)
//        }
//    }
//    
//    // MARK: - Main Content Views
//    
//    // Main content area with tabs
//    private var mainContent: some View {
//        GeometryReader { geometry in
//            ScrollView {
//                VStack(spacing: 20) {
//                    // Budget overview card
//                    budgetOverviewCard
//                        .padding(.horizontal)
//                        .scaleEffect(animateCards ? 1.0 : 0.95)
//                        .opacity(animateCards ? 1.0 : 0)
//                    
//                    // Budget progress card
//                    budgetProgressCard
//                        .padding(.horizontal)
//                        .scaleEffect(animateCards ? 1.0 : 0.95)
//                        .opacity(animateCards ? 1.0 : 0)
//                    
//                    // Budget allocation visualization
//                    if !categories.isEmpty {
//                        budgetAllocationCard
//                            .padding(.horizontal)
//                            .scaleEffect(animateCards ? 1.0 : 0.95)
//                            .opacity(animateCards ? 1.0 : 0)
//                    } else {
//                        noBudgetCategoriesView
//                            .padding(.horizontal)
//                            .scaleEffect(animateCards ? 1.0 : 0.95)
//                            .opacity(animateCards ? 1.0 : 0)
//                    }
//                    
//                    // Category section with tabs
//                    VStack(spacing: 16) {
//                        HStack {
//                            Text("Budget Categories")
//                                .font(AppTheme.headlineFont())
//                                .foregroundColor(AppTheme.textColor)
//                            
//                            Spacer()
//                            
//                            Button(action: {
//                                showAddCategory = true
//                            }) {
//                                HStack(spacing: 6) {
//                                    Image(systemName: "plus")
//                                        .font(.system(size: 14))
//                                    
//                                    Text("Add")
//                                        .font(.subheadline)
//                                }
//                                .foregroundColor(AppTheme.textColor)
//                                .padding(.horizontal, 12)
//                                .padding(.vertical, 6)
//                                .background(AppTheme.primaryGreen.opacity(0.2))
//                                .cornerRadius(10)
//                            }
//                            .buttonStyle(ScaleButtonStyle())
//                        }
//                        .padding(.horizontal)
//                        
//                        // Tabs for category filtering
//                        TabView(selection: $selectedCategoryTab) {
//                            // All Categories Tab
//                            categoriesListView(categories: filteredCategories)
//                                .tag(0)
//                            
//                            // Essential Tab
//                            categoriesListView(categories: filteredCategories)
//                                .tag(1)
//                            
//                            // Non-Essential Tab
//                            categoriesListView(categories: filteredCategories)
//                                .tag(2)
//                        }
//                        .tabViewStyle(.page(indexDisplayMode: .never))
//                        
//                        // Category filter tabs
//                        VersatileTopTabs(
//                            selectedIndex: $selectedCategoryTab,
//                            tabs: categoryFilterTabs,
//                            style: .pill,
//                            distribution: .fillEqually,
//                            height: 36,
//                            backgroundColor: Color.clear,
//                            selectedColor: AppTheme.primaryGreen,
//                            font: .subheadline
//                        ) { _ in
//                            // This is just a placeholder as we're manually handling the TabView above
//                            EmptyView()
//                        }
//                        .frame(height: 36)
//                    }
//                    
//                    // Action buttons
//                    actionButtonsView
//                        .padding(.horizontal)
//                        .padding(.top, 10)
//                        .padding(.bottom, 100)
//                }
//                .padding(.top, 16)
//                .frame(minHeight: geometry.size.height)
//            }
//            .refreshable {
//                await refreshBudgetData()
//            }
//            .onAppear {
//                withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1)) {
//                    animateCards = true
//                }
//            }
//            
//            // Bottom action bar - fixed to bottom of screen
//            VStack {
//                Spacer()
//                
//                HStack(spacing: 20) {
//                    // Analyze button
//                    SecondaryActionButton(
//                        icon: "chart.bar.xaxis",
//                        title: "Analyze",
//                        action: { analyzeSpending() }
//                    )
//                    
//                    // Auto-budget button
//                    SecondaryActionButton(
//                        icon: "wand.and.stars",
//                        title: "Auto-Budget",
//                        action: { autoBudget() }
//                    )
//                    
//                    // Share button
//                    SecondaryActionButton(
//                        icon: "square.and.arrow.up",
//                        title: "Share",
//                        action: { showExportOptions = true }
//                    )
//                }
//                .padding(.horizontal, 20)
//                .padding(.vertical, 12)
//                .background(
//                    Rectangle()
//                        .fill(AppTheme.cardBackground)
//                        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: -5)
//                )
//            }
//            .edgesIgnoringSafeArea(.bottom)
//        }
//    }
//    
//    // Loading view
//    private var loadingView: some View {
//        VStack(spacing: 16) {
//            ProgressView()
//                .scaleEffect(1.5)
//                .progressViewStyle(CircularProgressViewStyle(tint: AppTheme.primaryGreen))
//            
//            Text("Loading your budget data...")
//                .font(.headline)
//                .foregroundColor(AppTheme.textColor)
//                .padding(.top, 8)
//        }
//    }
//    
//    // Header view with month selector
//    private var headerView: some View {
//        HStack {
//            Text("Budget Planner")
//                .font(.title2)
//                .fontWeight(.bold)
//                .foregroundColor(AppTheme.textColor)
//            
//            Spacer()
//            
//            Menu {
//                ForEach(getMonths(), id: \.self) { month in
//                    Button(month) {
//                        withAnimation {
//                            selectedMonth = month
//                        }
//                    }
//                }
//            } label: {
//                HStack(spacing: 6) {
//                    Text(selectedMonth)
//                        .font(.subheadline)
//                        .foregroundColor(AppTheme.textColor)
//                    
//                    Image(systemName: "chevron.down")
//                        .font(.system(size: 12))
//                        .foregroundColor(AppTheme.textColor.opacity(0.7))
//                }
//                .padding(.horizontal, 12)
//                .padding(.vertical, 8)
//                .background(AppTheme.cardBackground)
//                .cornerRadius(12)
//                .overlay(
//                    RoundedRectangle(cornerRadius: 12)
//                        .stroke(AppTheme.cardStroke, lineWidth: 1)
//                )
//            }
//            .buttonStyle(ScaleButtonStyle())
//        }
//    }
//    
//    // Budget overview card
//    private var budgetOverviewCard: some View {
//        HStack(spacing: 0) {
//            // Income
//            budgetStatColumn(
//                title: "Income",
//                amount: monthlyIncome,
//                icon: "arrow.down.circle.fill",
//                color: AppTheme.primaryGreen,
//                showBorder: true
//            )
//            
//            // Budgeted
//            budgetStatColumn(
//                title: "Budgeted",
//                amount: totalBudget,
//                icon: "chart.pie.fill",
//                color: AppTheme.accentBlue,
//                showBorder: true
//            )
//            
//            // Remaining
//            budgetStatColumn(
//                title: "Remaining",
//                amount: remainingBudget,
//                icon: "banknote.fill",
//                color: remainingBudget >= 0 ? AppTheme.primaryGreen : Color(hex: "#FF5757"),
//                showBorder: false
//            )
//        }
//        .background(AppTheme.cardBackground)
//        .cornerRadius(16)
//        .overlay(
//            RoundedRectangle(cornerRadius: 16)
//                .stroke(AppTheme.cardStroke, lineWidth: 1)
//        )
//    }
//    
//    // Budget progress card
//    private var budgetProgressCard: some View {
//        VStack(alignment: .leading, spacing: 16) {
//            // Title
//            Text("Budget Progress")
//                .font(AppTheme.headlineFont())
//                .foregroundColor(AppTheme.textColor)
//            
//            HStack(alignment: .center, spacing: 20) {
//                // Progress circular indicator
//                ZStack {
//                    // Background circle
//                    Circle()
//                        .stroke(AppTheme.cardStroke, lineWidth: 12)
//                        .frame(width: 120, height: 120)
//                    
//                    // Progress
//                    Circle()
//                        .trim(from: 0, to: CGFloat(budgetProgressPercentage))
//                        .stroke(
//                            budgetStatusColor(for: budgetStatus),
//                            style: StrokeStyle(lineWidth: 12, lineCap: .round)
//                        )
//                        .frame(width: 120, height: 120)
//                        .rotationEffect(.degrees(-90))
//                    
//                    // Center text
//                    VStack(spacing: 2) {
//                        Text("\(Int(budgetProgressPercentage * 100))%")
//                            .font(.title3)
//                            .fontWeight(.bold)
//                            .foregroundColor(AppTheme.textColor)
//                        
//                        Text("Spent")
//                            .font(.caption)
//                            .foregroundColor(AppTheme.textColor.opacity(0.7))
//                    }
//                }
//                
//                // Spending details
//                VStack(alignment: .leading, spacing: 12) {
//                    // Spent
//                    VStack(alignment: .leading, spacing: 4) {
//                        Text("Spent This Month")
//                            .font(.caption)
//                            .foregroundColor(AppTheme.textColor.opacity(0.7))
//                        
//                        Text("$\(Int(totalSpentThisMonth))")
//                            .font(.headline)
//                            .foregroundColor(AppTheme.accentBlue)
//                    }
//                    
//                    // Budget
//                    VStack(alignment: .leading, spacing: 4) {
//                        Text("Total Budget")
//                            .font(.caption)
//                            .foregroundColor(AppTheme.textColor.opacity(0.7))
//                        
//                        Text("$\(Int(totalBudget))")
//                            .font(.headline)
//                            .foregroundColor(AppTheme.textColor)
//                    }
//                    
//                    // Status
//                    VStack(alignment: .leading, spacing: 4) {
//                        Text("Status")
//                            .font(.caption)
//                            .foregroundColor(AppTheme.textColor.opacity(0.7))
//                        
//                        HStack(spacing: 6) {
//                            Circle()
//                                .fill(budgetStatusColor(for: budgetStatus))
//                                .frame(width: 8, height: 8)
//                            
//                            Text(budgetStatusText(for: budgetStatus))
//                                .font(.subheadline)
//                                .foregroundColor(budgetStatusColor(for: budgetStatus))
//                        }
//                    }
//                }
//            }
//            .padding()
//            .background(AppTheme.cardBackground.opacity(0.5))
//            .cornerRadius(12)
//        }
//        .padding()
//        .background(AppTheme.cardBackground)
//        .cornerRadius(16)
//        .overlay(
//            RoundedRectangle(cornerRadius: 16)
//                .stroke(AppTheme.cardStroke, lineWidth: 1)
//        )
//    }
//    
//    // Budget allocation card
//    private var budgetAllocationCard: some View {
//        VStack(alignment: .leading, spacing: 16) {
//            Text("Budget Allocation")
//                .font(AppTheme.headlineFont())
//                .foregroundColor(AppTheme.textColor)
//            
//            if totalBudget > 0 {
//                // Pie chart visualization
//                HStack {
//                    // Chart
//                    ZStack {
//                        ForEach(0..<categories.count, id: \.self) { index in
//                            PieSlice(
//                                startAngle: calculateStartAngle(for: index),
//                                endAngle: calculateEndAngle(for: index)
//                            )
//                            .fill(categories[index].color)
//                            .onTapGesture {
//                                selectedCategory = categories[index]
//                                showingCategoryDetail = true
//                            }
//                        }
//                        
//                        // Center circle
//                        Circle()
//                            .fill(AppTheme.backgroundColor)
//                            .frame(width: 60, height: 60)
//                        
//                        // Total amount
//                        VStack(spacing: 0) {
//                            Text("$\(Int(totalBudget))")
//                                .font(.subheadline)
//                                .fontWeight(.bold)
//                                .foregroundColor(AppTheme.textColor)
//                            
//                            Text("Total")
//                                .font(.caption2)
//                                .foregroundColor(AppTheme.textColor.opacity(0.7))
//                        }
//                    }
//                    .frame(width: 150, height: 150)
//                    
//                    // Legend
//                    VStack(alignment: .leading, spacing: 10) {
//                        ForEach(categories.prefix(5), id: \.id) { category in
//                            HStack(spacing: 8) {
//                                RoundedRectangle(cornerRadius: 2)
//                                    .fill(category.color)
//                                    .frame(width: 12, height: 12)
//                                
//                                Text(category.name)
//                                    .font(.caption)
//                                    .foregroundColor(AppTheme.textColor)
//                                
//                                Spacer()
//                                
//                                Text("\(Int(category.amount / totalBudget * 100))%")
//                                    .font(.caption)
//                                    .foregroundColor(AppTheme.textColor.opacity(0.7))
//                            }
//                        }
//                        
//                        if categories.count > 5 {
//                            Text("+ \(categories.count - 5) more categories")
//                                .font(.caption)
//                                .foregroundColor(AppTheme.accentBlue)
//                        }
//                    }
//                    .padding(.leading, 16)
//                }
//                .padding()
//                .background(AppTheme.cardBackground.opacity(0.5))
//                .cornerRadius(12)
//            } else {
//                // Empty state
//                Text("Add budget categories to see your allocation")
//                    .font(.subheadline)
//                    .foregroundColor(AppTheme.textColor.opacity(0.7))
//                    .frame(maxWidth: .infinity, minHeight: 150)
//                    .multilineTextAlignment(.center)
//            }
//        }
//        .padding()
//        .background(AppTheme.cardBackground)
//        .cornerRadius(16)
//        .overlay(
//            RoundedRectangle(cornerRadius: 16)
//                .stroke(AppTheme.cardStroke, lineWidth: 1)
//        )
//    }
//    
//    // Empty budget categories view
//    private var noBudgetCategoriesView: some View {
//        VStack(spacing: 24) {
//            Image(systemName: "chart.pie")
//                .font(.system(size: 50))
//                .foregroundColor(AppTheme.accentBlue.opacity(0.7))
//            
//            Text("No budget categories yet")
//                .font(.headline)
//                .foregroundColor(AppTheme.textColor)
//            
//            Text("Set up budget categories to track your spending and stay on top of your financial goals")
//                .multilineTextAlignment(.center)
//                .font(.subheadline)
//                .foregroundColor(AppTheme.textColor.opacity(0.7))
//                .padding(.horizontal)
//            
//            Button(action: {
//                showAddCategory = true
//            }) {
//                HStack {
//                    Image(systemName: "plus.circle.fill")
//                        .font(.system(size: 16))
//                    
//                    Text("Add First Category")
//                        .font(.subheadline)
//                        .fontWeight(.medium)
//                }
//                .foregroundColor(AppTheme.backgroundColor)
//                .padding(.vertical, 12)
//                .padding(.horizontal, 24)
//                .background(AppTheme.primaryGreen)
//                .cornerRadius(12)
//                .shadow(color: AppTheme.primaryGreen.opacity(0.3), radius: 5, x: 0, y: 2)
//            }
//            .buttonStyle(ScaleButtonStyle())
//        }
//        .padding(24)
//        .frame(maxWidth: .infinity)
//        .background(AppTheme.cardBackground)
//        .cornerRadius(16)
//        .overlay(
//            RoundedRectangle(cornerRadius: 16)
//                .stroke(AppTheme.cardStroke, lineWidth: 1)
//        )
//    }
//    
//    // Categories list view
//    private func categoriesListView(categories: [BudgetCategory]) -> some View {
//        VStack(spacing: 16) {
//            if categories.isEmpty {
//                if selectedCategoryTab == 0 {
//                    noBudgetCategoriesView
//                        .padding(.horizontal)
//                } else {
//                    Text("No \(categoryFilterTabs[selectedCategoryTab].lowercased()) categories found")
//                        .font(.headline)
//                        .foregroundColor(AppTheme.textColor)
//                        .frame(maxWidth: .infinity, minHeight: 200)
//                        .multilineTextAlignment(.center)
//                }
//            } else {
//                ForEach(Array(categories.enumerated()), id: \.element.id) { index, category in
//                    BudgetCategoryRow(
//                        category: category,
//                        spent: calculateSpentForCategory(category),
//                        onTap: {
//                            selectedCategory = category
//                            showingCategoryDetail = true
//                        },
//                        onAmountChange: { newAmount in
//                            updateCategoryAmount(category, newAmount)
//                        },
//                        onDelete: { deleteCategory(category) }
//                    )
//                    .padding(.horizontal)
//                    .transition(.scale(scale: 0.9).combined(with: .opacity))
//                    .onAppear {
//                        withAnimation(.spring(response: 0.5, dampingFraction: 0.7).delay(Double(index) * 0.05 + 0.3)) {
//                            animateCards = true
//                        }
//                    }
//                }
//            }
//        }
//    }
//}

// MARK: - Supporting Views
//
//struct BudgetCategoryRow: View {
//    let category: BudgetCategory
//    let spent: Double
//    let onTap: () -> Void
//    let onAmountChange: (Double) -> Void
//    let onDelete: () -> Void
//    
//    @State private var isEditing = false
//    @State private var editedAmount: String = ""
//    
//    var progress: Double {
//        category.amount > 0 ? min(spent / category.amount, 1.0) : 0
//    }
//    
//    var statusColor: Color {
//        if progress >= 1.0 {
//            return Color(hex: "#FF5757") // Over budget - red
//        } else if progress >= 0.9 {
//            return Color(hex: "#FFD700") // Near limit - yellow
//        } else if progress >= 0.25 {
//            return AppTheme.primaryGreen // On track - green
//        } else {
//            return AppTheme.accentBlue // Just started - blue
//        }
//    }
//    
//    var body: some View {
//        Button(action: onTap) {
//            VStack(spacing: 12) {
//                // Top row with category info and amount
//                HStack(spacing: 15) {
//                    // Category icon
//                    ZStack {
//                        Circle()
//                            .fill(category.color.opacity(0.2))
//                            .frame(width: 46, height: 46)
//                        
//                        Image(systemName: category.icon)
//                            .font(.system(size: 20))
//                            .foregroundColor(category.color)
//                    }
//                    
//                    // Category name and details
//                    VStack(alignment: .leading, spacing: 3) {
//                        Text(category.name)
//                            .font(.headline)
//                            .foregroundColor(AppTheme.textColor)
//                        
//                        HStack(spacing: 6) {
//                            // Status indicator
//                            Circle()
//                                .fill(statusColor)
//                                .frame(width: 6, height: 6)
//                            
//                            Text("Spent: $\(Int(spent)) of $\(Int(category.amount))")
//                                .font(.caption)
//                                .foregroundColor(AppTheme.textColor.opacity(0.7))
//                        }
//                    }
//                    
//                    Spacer()
//                    
//                    // Amount with edit button
//                    if isEditing {
//                        HStack {
//                            Text("$")
//                                .foregroundColor(AppTheme.textColor.opacity(0.8))
//                            
//                            TextField("Amount", text: $editedAmount, onCommit: {
//                                if let amount = Double(editedAmount) {
//                                    onAmountChange(amount)
//                                }
//                                isEditing = false
//                            })
//                            .keyboardType(.decimalPad)
//                            .foregroundColor(AppTheme.textColor)
//                            .frame(width: 80)
//                            .multilineTextAlignment(.trailing)
//                        }
//                        .padding(.horizontal, 10)
//                        .padding(.vertical, 5)
//                        .background(AppTheme.primaryGreen.opacity(0.2))
//                        .cornerRadius(8)
//                    } else {
//                        HStack(spacing: 10) {
//                            VStack(alignment: .trailing, spacing: 2) {
//                                Text("$\(Int(category.amount))")
//                                    .font(.headline)
//                                    .foregroundColor(AppTheme.textColor)
//                                
//                                Text("\(Int(category.amount > 0 ? (spent / category.amount * 100) : 0))%")
//                                    .font(.caption)
//                                    .foregroundColor(statusColor)
//                            }
//                            
//                            Button(action: {
//                                editedAmount = String(format: "%.0f", category.amount)
//                                isEditing = true
//                            }) {
//                                Image(systemName: "pencil")
//                                    .font(.system(size: 14))
//                                    .foregroundColor(AppTheme.textColor.opacity(0.6))
//                                    .padding(6)
//                                    .background(Circle().fill(AppTheme.cardBackground))
//                            }
//                        }
//                    }
//                }
//                
//                // Progress bar
//                VStack(alignment: .leading, spacing: 6) {
//                    // Progress bar
//                    ZStack(alignment: .leading) {
//                        // Background
//                        RoundedRectangle(cornerRadius: 6)
//                            .fill(AppTheme.cardStroke)
//                            .frame(height: 8)
//                        
//                        // Progress
//                        RoundedRectangle(cornerRadius: 6)
//                            .fill(statusColor)
//                            .frame(width: max(CGFloat(progress) * UIScreen.main.bounds.width * 0.8, 4), height: 8)
//                    }
//                    
//                    // Info row
//                    HStack {
//                        // Delete button
//                        Button(action: onDelete) {
//                            Image(systemName: "trash")
//                                .font(.system(size: 12))
//                                .foregroundColor(Color(hex: "#FF5757"))
//                        }
//                        
//                        Spacer()
//                        
//                        // Remaining
//                        Text("Remaining: $\(Int(max(0, category.amount - spent)))")
//                            .font(.caption)
//                            .foregroundColor(AppTheme.textColor.opacity(0.7))
//                    }
//                }
//            }
//            .padding(16)
//        }
//        .buttonStyle(PlainButtonStyle())
//        .background(AppTheme.cardBackground)
//        .cornerRadius(16)
//        .overlay(
//            RoundedRectangle(cornerRadius: 16)
//                .stroke(AppTheme.cardStroke, lineWidth: 1)
//        )
//    }
//}
//
//struct SecondaryActionButton: View {
//    let icon: String
//    let title: String
//    let action: () -> Void
//    
//    var body: some View {
//        Button(action: action) {
//            VStack(spacing: 8) {
//                Image(systemName: icon)
//                    .font(.system(size: 20))
//                    .foregroundColor(AppTheme.accentPurple)
//                
//                Text(title)
//                    .font(.subheadline)
//                    .foregroundColor(AppTheme.textColor)
//            }
//            .frame(maxWidth: .infinity)
//            .padding(.vertical, 12)
//            .background(AppTheme.cardBackground)
//            .cornerRadius(12)
//            .overlay(
//                RoundedRectangle(cornerRadius: 12)
//                    .stroke(AppTheme.cardStroke, lineWidth: 1)
//            )
//        }
//        .buttonStyle(ScaleButtonStyle())
//    }
//}
//
//struct CategoryDetailView: View {
//    let category: BudgetCategory
//    let onUpdate: (BudgetCategory) -> Void
//    let plaidManager: PlaidManager
//    
//    @Environment(\.presentationMode) var presentationMode
//    @State private var updatedName: String
//    @State private var updatedAmount: Double
//    @State private var updatedIcon: String
//    @State private var updatedColor: Color
//    @State private var isEssential: Bool
//    
//    init(category: BudgetCategory, onUpdate: @escaping (BudgetCategory) -> Void, plaidManager: PlaidManager) {
//        self.category = category
//        self.onUpdate = onUpdate
//        self.plaidManager = plaidManager
//        _updatedName = State(initialValue: category.name)
//        _updatedAmount = State(initialValue: category.amount)
//        _updatedIcon = State(initialValue: category.icon)
//        _updatedColor = State(initialValue: category.color)
//        _isEssential = State(initialValue: CategoryDetailView.isEssentialCategory(category.name))
//    }
//    
//    var body: some View {
//        NavigationView {
//            ZStack {
//                AppTheme.backgroundGradient
//                    .ignoresSafeArea()
//                
//                ScrollView {
//                    VStack(spacing: 24) {
//                        // Category header
//                        categoryHeader
//                        
//                        // Details form
//                        categoryDetailsForm
//                        
//                        // Settings
//                        categorySettingsForm
//                        
//                        // Spending breakdown
//                        spendingBreakdownSection
//                    }
//                    .padding()
//                }
//            }
//            .navigationTitle("Category Details")
//            .navigationBarTitleDisplayMode(.inline)
//            .toolbar {
//                ToolbarItem(placement: .navigationBarLeading) {
//                    Button("Cancel") {
//                        presentationMode.wrappedValue.dismiss()
//                    }
//                }
//                
//                ToolbarItem(placement: .navigationBarTrailing) {
//                    Button("Save") {
//                        let updatedCategory = BudgetCategory(
//                            name: updatedName,
//                            amount: updatedAmount,
//                            icon: updatedIcon,
//                            color: updatedColor
//                        )
//                        onUpdate(updatedCategory)
//                        presentationMode.wrappedValue.dismiss()
//                    }
//                    .fontWeight(.semibold)
//                    .foregroundColor(AppTheme.primaryGreen)
//                }
//            }
//        }
//    }
//    
//    private var categoryHeader: some View {
//        VStack(spacing: 24) {
//            // Category icon
//            ZStack {
//                Circle()
//                    .fill(updatedColor.opacity(0.2))
//                    .frame(width: 80, height: 80)
//                
//                Image(systemName: updatedIcon)
//                    .font(.system(size: 36))
//                    .foregroundColor(updatedColor)
//            }
//            
//            // Category name
//            Text(updatedName)
//                .font(.title2)
//                .fontWeight(.bold)
//                .foregroundColor(AppTheme.textColor)
//                .multilineTextAlignment(.center)
//                .padding(.horizontal)
//        }
//        .padding(.vertical)
//    }
//    
//    private var categoryDetailsForm: some View {
//        VStack(alignment: .leading, spacing: 16) {
//            Text("Details")
//                .font(.headline)
//                .foregroundColor(AppTheme.textColor)
//            
//            FormField(title: "Name", isRequired: true) {
//                TextField("Category Name", text: $updatedName)
//                    .foregroundColor(AppTheme.textColor)
//                    .padding()
//                    .background(AppTheme.cardBackground)
//                    .cornerRadius(12)
//                    .overlay(
//                        RoundedRectangle(cornerRadius: 12)
//                            .stroke(AppTheme.cardStroke, lineWidth: 1)
//                    )
//            }
//            
//            FormField(title: "Budget Amount", isRequired: true) {
//                HStack {
//                    Text("$")
//                        .foregroundColor(AppTheme.textColor)
//                    
//                    TextField("Amount", value: $updatedAmount, formatter: NumberFormatter())
//                        .keyboardType(.decimalPad)
//                        .foregroundColor(AppTheme.textColor)
//                }
//                .padding()
//                .background(AppTheme.cardBackground)
//                .cornerRadius(12)
//                .overlay(
//                    RoundedRectangle(cornerRadius: 12)
//                        .stroke(AppTheme.cardStroke, lineWidth: 1)
//                )
//            }
//            
//            Toggle("Essential Expense", isOn: $isEssential)
//                .foregroundColor(AppTheme.textColor)
//                .padding()
//                .background(AppTheme.cardBackground)
//                .cornerRadius(12)
//                .toggleStyle(SwitchToggleStyle(tint: AppTheme.primaryGreen))
//                .overlay(
//                    RoundedRectangle(cornerRadius: 12)
//                        .stroke(AppTheme.cardStroke, lineWidth: 1)
//                )
//        }
//        .padding()
//        .background(AppTheme.cardBackground.opacity(0.5))
//        .cornerRadius(16)
//    }
//    
//    private var categorySettingsForm: some View {
//        VStack(alignment: .leading, spacing: 16) {
//            Text("Appearance")
//                .font(.headline)
//                .foregroundColor(AppTheme.textColor)
//            
//            FormField(title: "Icon", isRequired: false) {
//                // Icon selector (simplified for this example)
//                ScrollView(.horizontal, showsIndicators: false) {
//                    HStack(spacing: 12) {
//                        ForEach(commonIcons, id: \.self) { icon in
//                            Button(action: {
//                                updatedIcon = icon
//                            }) {
//                                ZStack {
//                                    Circle()
//                                        .fill(updatedIcon == icon ? updatedColor.opacity(0.2) : AppTheme.cardBackground)
//                                        .frame(width: 50, height: 50)
//                                    
//                                    Image(systemName: icon)
//                                        .font(.system(size: 20))
//                                        .foregroundColor(updatedIcon == icon ? updatedColor : AppTheme.textColor.opacity(0.7))
//                                }
//                            }
//                        }
//                    }
//                    .padding(.vertical, 8)
//                }
//            }
//            
//            FormField(title: "Color", isRequired: false) {
//                // Color selector (simplified for this example)
//                ScrollView(.horizontal, showsIndicators: false) {
//                    HStack(spacing: 12) {
//                        ForEach(themeColors, id: \.self) { color in
//                            Button(action: {
//                                updatedColor = color
//                            }) {
//                                ZStack {
//                                    Circle()
//                                        .fill(color)
//                                        .frame(width: 40, height: 40)
//                                    
//                                    if color == updatedColor {
//                                        Circle()
//                                            .stroke(Color.white, lineWidth: 2)
//                                            .frame(width: 46, height: 46)
//                                    }
//                                }
//                            }
//                        }
//                    }
//                    .padding(.vertical, 8)
//                }
//            }
//        }
//        .padding()
//        .background(AppTheme.cardBackground.opacity(0.5))
//        .cornerRadius(16)
//    }
//    
//    private var spendingBreakdownSection: some View {
//        VStack(alignment: .leading, spacing: 16) {
//            Text("Spending Breakdown")
//                .font(.headline)
//                .foregroundColor(AppTheme.textColor)
//            
//            // Get spending data for this category from PlaidManager
//            let transactions = getTransactionsForCategory(category.name)
//            
//            if transactions.isEmpty {
//                // Show empty state
//                VStack(alignment: .center, spacing: 16) {
//                    Text("No transaction data available for this category")
//                        .foregroundColor(AppTheme.textColor.opacity(0.6))
//                        .multilineTextAlignment(.center)
//                        .padding()
//                }
//                .frame(maxWidth: .infinity)
//                .padding()
//                .background(AppTheme.cardBackground)
//                .cornerRadius(12)
//                .overlay(
//                    RoundedRectangle(cornerRadius: 12)
//                        .stroke(AppTheme.cardStroke, lineWidth: 1)
//                )
//            } else {
//                // Show transactions
//                VStack(spacing: 12) {
//                    ForEach(transactions.prefix(5), id: \.id) { transaction in
//                        HStack {
//                            VStack(alignment: .leading, spacing: 4) {
//                                Text(transaction.name)
//                                    .font(.subheadline)
//                                    .foregroundColor(AppTheme.textColor)
//                                
//                                Text(formatDate(transaction.date))
//                                    .font(.caption)
//                                    .foregroundColor(AppTheme.textColor.opacity(0.6))
//                            }
//                            
//                            Spacer()
//                            
//                            Text("$\(String(format: "%.2f", transaction.amount))")
//                                .font(.subheadline)
//                                .foregroundColor(transaction.amount > 0 ?
//                                              AppTheme.expenseColor :
//                                              AppTheme.primaryGreen)
//                        }
//                        .padding()
//                        .background(AppTheme.cardBackground)
//                        .cornerRadius(10)
//                    }
//                    
//                    if transactions.count > 5 {
//                        Text("+ \(transactions.count - 5) more transactions")
//                            .font(.caption)
//                            .foregroundColor(AppTheme.accentBlue)
//                            .padding(.top, 8)
//                    }
//                }
//            }
//        }
//        .padding()
//        .background(AppTheme.cardBackground.opacity(0.5))
//        .cornerRadius(16)
//    }
//    
//    private var commonIcons: [String] {
//        ["house.fill", "cart.fill", "car.fill", "fork.knife", "medical.thermometer",
//         "wifi", "tv.fill", "gamecontroller.fill", "airplane", "gift.fill",
//         "dollarsign.circle.fill", "creditcard.fill", "book.fill", "graduationcap.fill"]
//    }
//    
//    private var themeColors: [Color] {
//        [AppTheme.primaryGreen, AppTheme.accentBlue, AppTheme.accentPurple,
//         Color(hex: "#FF5757"), Color(hex: "#FFD700"), Color(hex: "#50C878"),
//         Color(hex: "#FF8C00"), Color(hex: "#9370DB")]
//    }
//    
//    static func isEssentialCategory(_ name: String) -> Bool {
//        let essentialCategories = ["Groceries", "Rent", "Utilities", "Transportation", "Healthcare", "Insurance", "Housing"]
//        
//        return essentialCategories.contains { essential in
//            name.lowercased().contains(essential.lowercased())
//        }
//    }
//    
//    // Helper function to get transactions for a specific category
//    private func getTransactionsForCategory(_ categoryName: String) -> [PlaidTransaction] {
//        // Get current month and year
//        let calendar = Calendar.current
//        let currentMonth = calendar.component(.month, from: Date())
//        let currentYear = calendar.component(.year, from: Date())
//        
//        // Filter transactions for the current month that match this category
//        return plaidManager.transactions.filter { transaction in
//            let transactionMonth = calendar.component(.month, from: transaction.date)
//            let transactionYear = calendar.component(.year, from: transaction.date)
//            return transactionMonth == currentMonth &&
//                   transactionYear == currentYear &&
//                   transaction.category.lowercased() == categoryName.lowercased()
//        }
//    }
//    
//    private func formatDate(_ date: Date) -> String {
//        let formatter = DateFormatter()
//        formatter.dateStyle = .medium
//        formatter.timeStyle = .none
//        return formatter.string(from: date)
//    }
//}
//
//struct BudgetAnalysisView: View {
//    let insights: [String]
//    @Binding var presentationMode: Bool
//    
//    var body: some View {
//        NavigationView {
//            ZStack {
//                AppTheme.backgroundGradient
//                    .ignoresSafeArea()
//                
//                VStack(spacing: 25) {
//                    // Header
//                    HStack {
//                        Image(systemName: "chart.bar.xaxis")
//                            .font(.system(size: 24))
//                            .foregroundColor(AppTheme.primaryGreen)
//                        
//                        Text("Budget Analysis")
//                            .font(.title2)
//                            .fontWeight(.bold)
//                            .foregroundColor(AppTheme.textColor)
//                    }
//                    .padding(.top, 20)
//                    
//                    // Insights
//                    ScrollView {
//                        VStack(alignment: .leading, spacing: 20) {
//                            ForEach(insights.indices, id: \.self) { index in
//                                insightCard(text: insights[index], index: index)
//                            }
//                        }
//                        .padding(.horizontal)
//                    }
//                    
//                    // Action button
//                    Button(action: {
//                        presentationMode = false
//                    }) {
//                        Text("Close Analysis")
//                            .font(.headline)
//                            .foregroundColor(.white)
//                            .frame(maxWidth: .infinity)
//                            .padding()
//                            .background(AppTheme.primaryGreen)
//                            .cornerRadius(12)
//                            .shadow(color: AppTheme.primaryGreen.opacity(0.3), radius: 5, x: 0, y: 2)
//                    }
//                    .buttonStyle(ScaleButtonStyle())
//                    .padding(.horizontal)
//                    .padding(.bottom, 20)
//                }
//                .padding()
//            }
//            .navigationBarHidden(true)
//        }
//    }
//    
//    private func insightCard(text: String, index: Int) -> some View {
//        VStack(alignment: .leading, spacing: 10) {
//            if text.starts(with: "-") {
//                // List item
//                HStack(alignment: .top, spacing: 10) {
//                    Circle()
//                        .fill(AppTheme.accentBlue)
//                        .frame(width: 8, height: 8)
//                        .padding(.top, 6)
//                    
//                    Text(text.dropFirst(2))
//                        .foregroundColor(AppTheme.textColor)
//                }
//                .padding(.leading, 20)
//            } else {
//                // Regular insight
//                HStack(alignment: .top, spacing: 15) {
//                    // Icon based on insight type
//                    ZStack {
//                        Circle()
//                            .fill(insightColor(for: index).opacity(0.2))
//                            .frame(width: 36, height: 36)
//                        
//                        Image(systemName: insightIcon(for: index))
//                            .font(.system(size: 16))
//                            .foregroundColor(insightColor(for: index))
//                    }
//                    
//                    VStack(alignment: .leading, spacing: 4) {
//                        Text(text)
//                            .foregroundColor(AppTheme.textColor)
//                            .fixedSize(horizontal: false, vertical: true)
//                    }
//                }
//            }
//        }
//        .padding()
//        .background(AppTheme.cardBackground)
//        .cornerRadius(12)
//        .overlay(
//            RoundedRectangle(cornerRadius: 12)
//                .stroke(AppTheme.cardStroke, lineWidth: 1)
//        )
//    }
//    
//    private func insightIcon(for index: Int) -> String {
//        switch index {
//        case 0:
//            return "percent"
//        case 1:
//            return "chart.bar.fill"
//        case 2:
//            return "exclamationmark.triangle"
//        case 3:
//            return "arrow.down.circle"
//        case 4:
//            return "dollarsign.circle"
//        default:
//            return "lightbulb.fill"
//        }
//    }
//    
//    private func insightColor(for index: Int) -> Color {
//        switch index {
//        case 0:
//            return AppTheme.primaryGreen
//        case 1:
//            return AppTheme.accentBlue
//        case 2:
//            return Color(hex: "#FF5757")
//        case 3:
//            return Color(hex: "#FFD700")
//        case 4:
//            return AppTheme.accentPurple
//        default:
//            return AppTheme.primaryGreen
//        }
//    }
//}

struct BudgetSettingsView: View {
    @Environment(\.presentationMode) var presentationMode
    @State var showNotifications: Bool
    @State var enableReminders: Bool
    @State var defaultCurrency: String
    
    var currencies = ["USD", "EUR", "GBP", "CAD", "AUD", "JPY"]
    
    var body: some View {
        NavigationView {
            ZStack {
                AppTheme.backgroundGradient
                    .ignoresSafeArea()
                                    
                Form {
                    Section(header: Text("Notifications").foregroundColor(AppTheme.textColor)) {
                        Toggle("Show Budget Notifications", isOn: $showNotifications)
                            .toggleStyle(SwitchToggleStyle(tint: AppTheme.primaryGreen))
                        
                        if showNotifications {
                            Toggle("Enable Spending Alerts", isOn: $enableReminders)
                                .toggleStyle(SwitchToggleStyle(tint: AppTheme.primaryGreen))
                        }
                    }
                    
                    Section(header: Text("Preferences").foregroundColor(AppTheme.textColor)) {
                        Picker("Default Currency", selection: $defaultCurrency) {
                            ForEach(currencies, id: \.self) { currency in
                                Text(currency).tag(currency)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        
                        NavigationLink(destination: Text("Budget Reset Rules")
                            .foregroundColor(AppTheme.textColor)) {
                            Text("Budget Reset Rules")
                        }
                        
                        NavigationLink(destination: Text("Category Defaults")
                            .foregroundColor(AppTheme.textColor)) {
                            Text("Category Defaults")
                        }
                    }
                    
                    Section(header: Text("Data Management").foregroundColor(AppTheme.textColor)) {
                        Button(action: {
                            // Export data action
                            exportBudgetData()
                        }) {
                            Text("Export All Budget Data")
                                .foregroundColor(AppTheme.accentBlue)
                        }
                        
                        Button(action: {
                            // Reset data action
                            showResetConfirmation()
                        }) {
                            Text("Reset Budget Data")
                                .foregroundColor(Color(hex: "#FF5757"))
                        }
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Budget Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        saveBudgetSettings()
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(AppTheme.primaryGreen)
                }
            }
        }
    }
    
    private func saveBudgetSettings() {
        // Save settings to UserDefaults
        UserDefaults.standard.set(showNotifications, forKey: "budget_notifications_enabled")
        UserDefaults.standard.set(enableReminders, forKey: "budget_reminders_enabled")
        UserDefaults.standard.set(defaultCurrency, forKey: "default_currency")
    }
    
    private func exportBudgetData() {
        // This would be handled by a service in a real app
        let alert = UIAlertController(
            title: "Export Budget Data",
            message: "Your budget data would be exported as a CSV file here",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            rootViewController.present(alert, animated: true)
        }
    }
    
    private func showResetConfirmation() {
        let alert = UIAlertController(
            title: "Reset Budget Data",
            message: "This will delete all your budget categories and settings. This action cannot be undone.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Reset", style: .destructive) { _ in
            resetBudgetData()
        })
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            rootViewController.present(alert, animated: true)
        }
    }
    
    private func resetBudgetData() {
        // This would clear all budget data in a real app
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMMM"
        let months = (1...12).map { month in
            let date = Calendar.current.date(from: DateComponents(month: month))!
            return dateFormatter.string(from: date)
        }
        
        // Remove all budget data
        for month in months {
            UserDefaults.standard.removeObject(forKey: "budget_categories_\(month)")
            UserDefaults.standard.removeObject(forKey: "budget_metadata_\(month)")
        }
        
        // Reset settings
        UserDefaults.standard.set(true, forKey: "budget_notifications_enabled")
        UserDefaults.standard.set(true, forKey: "budget_reminders_enabled")
        UserDefaults.standard.set("USD", forKey: "default_currency")
        
        // Show confirmation
        let alert = UIAlertController(
            title: "Budget Data Reset",
            message: "All budget data has been reset successfully",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
            self.presentationMode.wrappedValue.dismiss()
        })
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            rootViewController.present(alert, animated: true)
        }
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

// Supporting enums
enum BudgetTimeframe: String {
    case week = "weekly"
    case month = "monthly"
    case year = "yearly"
}

enum BudgetStatus {
    case overBudget
    case warning
    case onTrack
    case underBudget
}

struct AddBudgetCategoryView: View {
    let onAdd: (BudgetCategory) -> Void
    
    @Environment(\.presentationMode) var presentationMode
    @State private var categoryName: String = ""
    @State private var categoryAmount: String = ""
    @State private var selectedColor: Color = AppTheme.primaryGreen
    @State private var selectedIcon: String = "dollarsign.circle.fill"
    @State private var isEssential: Bool = false
    
    private let commonIcons = [
        "house.fill", "cart.fill", "car.fill", "fork.knife",
        "heart.fill", "bolt.fill", "wifi", "tv.fill",
        "gift.fill", "dollarsign.circle.fill", "creditcard.fill",
        "book.fill", "graduationcap.fill"
    ]
    
    private let colorOptions: [Color] = [
        AppTheme.primaryGreen, AppTheme.accentBlue, AppTheme.accentPurple,
        Color(hex: "#FF5757"), Color(hex: "#FFD700"), Color(hex: "#50C878"),
        Color(hex: "#FF8C00"), Color(hex: "#9370DB")
    ]
    
    private var isValidCategory: Bool {
        !categoryName.isEmpty && !categoryAmount.isEmpty && Double(categoryAmount) ?? 0 > 0
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                AppTheme.backgroundGradient
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Category preview
                        categoryPreview
                        
                        // Category details
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Category Details")
                                .font(.headline)
                                .foregroundColor(AppTheme.textColor)
                            
                            // Name
                            FormField(title: "Name", isRequired: true) {
                                TextField("Category Name", text: $categoryName)
                                    .foregroundColor(AppTheme.textColor)
                                    .padding()
                                    .background(AppTheme.cardBackground)
                                    .cornerRadius(12)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(AppTheme.cardStroke, lineWidth: 1)
                                    )
                            }
                            
                            // Amount
                            FormField(title: "Budget Amount", isRequired: true) {
                                HStack {
                                    Text("$")
                                        .foregroundColor(AppTheme.textColor)
                                    
                                    TextField("Amount", text: $categoryAmount)
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
                            
                            // Essential toggle
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
                        
                        // Icon selector
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Select Icon")
                                .font(.headline)
                                .foregroundColor(AppTheme.textColor)
                            
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 60))], spacing: 16) {
                                ForEach(commonIcons, id: \.self) { icon in
                                    Button(action: {
                                        selectedIcon = icon
                                    }) {
                                        ZStack {
                                            Circle()
                                                .fill(selectedIcon == icon ? selectedColor.opacity(0.2) : AppTheme.cardBackground)
                                                .frame(width: 60, height: 60)
                                            
                                            Image(systemName: icon)
                                                .font(.system(size: 24))
                                                .foregroundColor(selectedIcon == icon ? selectedColor : AppTheme.textColor.opacity(0.7))
                                        }
                                    }
                                }
                            }
                        }
                        .padding()
                        .background(AppTheme.cardBackground.opacity(0.5))
                        .cornerRadius(16)
                        
                        // Color selector
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Select Color")
                                .font(.headline)
                                .foregroundColor(AppTheme.textColor)
                            
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 50))], spacing: 16) {
                                ForEach(colorOptions, id: \.self) { color in
                                    Button(action: {
                                        selectedColor = color
                                    }) {
                                        ZStack {
                                            Circle()
                                                .fill(color)
                                                .frame(width: 50, height: 50)
                                            
                                            if color == selectedColor {
                                                Circle()
                                                    .stroke(Color.white, lineWidth: 2)
                                                    .frame(width: 56, height: 56)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        .padding()
                        .background(AppTheme.cardBackground.opacity(0.5))
                        .cornerRadius(16)
                        
                        // Add button
                        Button(action: addCategory) {
                            Text("Add Category")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(isValidCategory ? AppTheme.primaryGreen : AppTheme.primaryGreen.opacity(0.5))
                                .cornerRadius(12)
                                .shadow(color: isValidCategory ? AppTheme.primaryGreen.opacity(0.3) : Color.clear, radius: 5, x: 0, y: 2)
                        }
                        .disabled(!isValidCategory)
                        .padding(.top, 10)
                    }
                    .padding()
                }
            }
            .navigationTitle("Add Category")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
    
    private var categoryPreview: some View {
        HStack(spacing: 16) {
            // Icon preview
            ZStack {
                Circle()
                    .fill(selectedColor.opacity(0.2))
                    .frame(width: 70, height: 70)
                
                Image(systemName: selectedIcon)
                    .font(.system(size: 34))
                    .foregroundColor(selectedColor)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(categoryName.isEmpty ? "Category Preview" : categoryName)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(AppTheme.textColor)
                
                if let amount = Double(categoryAmount), amount > 0 {
                    Text("$\(amount, specifier: "%.2f") budget")
                        .font(.subheadline)
                        .foregroundColor(AppTheme.textColor.opacity(0.7))
                } else {
                    Text("$0.00 budget")
                        .font(.subheadline)
                        .foregroundColor(AppTheme.textColor.opacity(0.7))
                }
                
                Text(isEssential ? "Essential" : "Non-Essential")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(isEssential ? AppTheme.primaryGreen.opacity(0.2) : AppTheme.accentPurple.opacity(0.2))
                    .foregroundColor(isEssential ? AppTheme.primaryGreen : AppTheme.accentPurple)
                    .cornerRadius(4)
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
    }
    
    private func addCategory() {
        guard let amount = Double(categoryAmount), amount > 0 else { return }
        
        let newCategory = BudgetCategory(
            name: categoryName,
            amount: amount,
            icon: selectedIcon,
            color: selectedColor
        )
        
        onAdd(newCategory)
        presentationMode.wrappedValue.dismiss()
    }
}

// MARK: - Scale Button Style for button animations
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .opacity(configuration.isPressed ? 0.9 : 1)
            .animation(.spring(response: 0.2, dampingFraction: 0.7), value: configuration.isPressed)
    }
}
