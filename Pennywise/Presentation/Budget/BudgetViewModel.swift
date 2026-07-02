//
//  BudgetViewModel.swift
//  Pennywise
//
//  ViewModel for Budget screen - Clean Architecture
//

import Foundation
import SwiftUI
import Observation

@MainActor
@Observable
public final class BudgetViewModel {
    // MARK: - Dependencies
    private let fetchBudgetUseCase: FetchBudgetUseCase
    private let addBudgetCategoryUseCase: AddBudgetCategoryUseCase
    private let deleteBudgetCategoryUseCase: DeleteBudgetCategoryUseCase
    private let updateBudgetCategoryUseCase: UpdateBudgetCategoryUseCase
    private let createAutoBudgetUseCase: CreateAutoBudgetUseCase
    private let userRepository: UserRepository
    
    // MARK: - Observable State
    public var categories: [BudgetCategory] = []
    public var categorySpending: [String: Double] = [:]
    public var totalBudget: Double = 0
    public var totalSpent: Double = 0
    public var budgetStatus: BudgetStatus = .underBudget
    public var monthlyIncome: Double = 0
    public var isLoading = false
    public var isRefreshing = false
    public var error: Error?
    public var showAddCategory = false
    public var selectedCategory: BudgetCategory?
    public var animateCards = false
    
    // MARK: - Computed Properties
    public var remainingBudget: Double {
        totalBudget - totalSpent
    }
    
    public var spendingPercentage: Double {
        guard totalBudget > 0 else { return 0 }
        return min(totalSpent / totalBudget, 1.0)
    }
    
    public var formattedTotalBudget: String {
        CurrencyFormatter.format(totalBudget)
    }
    
    public var formattedTotalSpent: String {
        CurrencyFormatter.format(totalSpent)
    }
    
    public var formattedRemainingBudget: String {
        CurrencyFormatter.format(remainingBudget)
    }
    
    // MARK: - Init
    public init(
        fetchBudgetUseCase: FetchBudgetUseCase,
        addBudgetCategoryUseCase: AddBudgetCategoryUseCase,
        deleteBudgetCategoryUseCase: DeleteBudgetCategoryUseCase,
        updateBudgetCategoryUseCase: UpdateBudgetCategoryUseCase,
        createAutoBudgetUseCase: CreateAutoBudgetUseCase,
        userRepository: UserRepository
    ) {
        self.fetchBudgetUseCase = fetchBudgetUseCase
        self.addBudgetCategoryUseCase = addBudgetCategoryUseCase
        self.deleteBudgetCategoryUseCase = deleteBudgetCategoryUseCase
        self.updateBudgetCategoryUseCase = updateBudgetCategoryUseCase
        self.createAutoBudgetUseCase = createAutoBudgetUseCase
        self.userRepository = userRepository
    }
    
    // MARK: - Public Methods
    public func loadData() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            // Load monthly income
            monthlyIncome = try await userRepository.getMonthlyIncome()
            
            // Load budget data
            let summary = try await fetchBudgetUseCase.execute()
            
            categories = summary.categories
            categorySpending = summary.categorySpending
            totalBudget = summary.totalBudget
            totalSpent = summary.totalSpent
            budgetStatus = summary.status
        } catch {
            self.error = error
        }
    }
    
    public func refreshData() async {
        isRefreshing = true
        defer { isRefreshing = false }
        
        await loadData()
    }
    
    public func addCategory(
        name: String,
        amount: Double,
        icon: String,
        colorHex: String,
        isEssential: Bool = false
    ) async {
        do {
            let category = try await addBudgetCategoryUseCase.execute(
                name: name,
                amount: amount,
                icon: icon,
                colorHex: colorHex,
                isEssential: isEssential
            )
            
            // Update state
            categories.append(category)
            totalBudget += amount
            budgetStatus = BudgetStatus.calculate(spent: totalSpent, budgeted: totalBudget)
        } catch {
            self.error = error
        }
    }
    
    public func updateCategory(_ category: BudgetCategory) async {
        do {
            try await updateBudgetCategoryUseCase.execute(category)
            
            // Update state
            if let index = categories.firstIndex(where: { $0.id == category.id }) {
                let oldAmount = categories[index].amount
                categories[index] = category
                totalBudget = totalBudget - oldAmount + category.amount
            }
            budgetStatus = BudgetStatus.calculate(spent: totalSpent, budgeted: totalBudget)
        } catch {
            self.error = error
        }
    }
    
    public func updateCategoryAmount(_ category: BudgetCategory, newAmount: Double) async {
        do {
            try await updateBudgetCategoryUseCase.updateAmount(categoryId: category.id, amount: newAmount)
            
            // Update state
            if let index = categories.firstIndex(where: { $0.id == category.id }) {
                let oldAmount = categories[index].amount
                categories[index] = BudgetCategory(
                    id: category.id,
                    name: category.name,
                    amount: newAmount,
                    icon: category.icon,
                    colorHex: category.colorHex,
                    isEssential: category.isEssential
                )
                totalBudget = totalBudget - oldAmount + newAmount
            }
            budgetStatus = BudgetStatus.calculate(spent: totalSpent, budgeted: totalBudget)
        } catch {
            self.error = error
        }
    }
    
    public func initializeAnimations() {
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1)) {
            animateCards = true
        }
    }
    
    public func budgetStatusColor(for status: BudgetStatus) -> Color {
        switch status {
        case .overBudget: return AppTheme.expenseColor
        case .warning: return AppTheme.alertOrange
        case .onTrack: return AppTheme.primaryGreen
        case .underBudget: return AppTheme.accentBlue
        }
    }
    
    public func budgetStatusText(for status: BudgetStatus) -> String {
        switch status {
        case .overBudget: return "Over Budget"
        case .warning: return "Approaching Limit"
        case .onTrack: return "On Track"
        case .underBudget: return "Under Budget"
        }
    }
    
    // MARK: - Additional Helper Methods
    
    public func getInsights(for category: BudgetCategory) -> [String] {
        let spent = categorySpending[category.id] ?? 0.0
        let percentage = category.amount > 0 ? (spent / category.amount) * 100 : 0
        
        var insights: [String] = []
        
        if percentage > 100 {
            insights.append("⚠️ You've exceeded your budget by \(Int(percentage - 100))%")
        } else if percentage > 80 {
            insights.append("📊 You've used \(Int(percentage))% of your budget")
        } else {
            insights.append("✅ You're doing well! \(Int(100 - percentage))% remaining")
        }
        
        if spent > 0 {
            insights.append("💰 Total spent: \(CurrencyFormatter.format(spent))")
        }
        
        return insights
    }
    
    public func calculateSpentForCategory(_ category: BudgetCategory) -> Double {
        return categorySpending[category.id] ?? 0.0
    }
    
    public func updateCategoryAmount(category: BudgetCategory, newAmount: Double) async {
        var updatedCategory = category
        updatedCategory.amount = newAmount
        await updateCategory(updatedCategory)
    }
    
    public func deleteCategory(category: BudgetCategory) async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            try await deleteBudgetCategoryUseCase.execute(categoryId: category.id)
            withAnimation {
                categories.removeAll { $0.id == category.id }
            }
            totalBudget = categories.reduce(0) { $0 + $1.amount }
            budgetStatus = BudgetStatus.calculate(spent: totalSpent, budgeted: totalBudget)
        } catch {
            self.error = error
        }
    }
    
    public func generateAutoBudget() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let newCategories = try await createAutoBudgetUseCase.execute()
            categories = newCategories
            totalBudget = categories.reduce(0) { $0 + $1.amount }
            // Re-calculate status
            budgetStatus = BudgetStatus.calculate(spent: totalSpent, budgeted: totalBudget)
        } catch {
            self.error = error
        }
    }
}

