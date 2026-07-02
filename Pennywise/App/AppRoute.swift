//
//  AppRoute.swift
//  Pennywise
//

import SwiftUI

enum AppRoute: Hashable {
    case home
    case budget
    case insights
    case settings
    case profile
    case transactionDetail(transaction: Transaction)
    case manualTransaction
    case addBudgetCategory
    case categoryInsights(category: BudgetCategory)
    case budgetInsights(category: BudgetCategory)
    case allTransactions(transactions: [Transaction])
    case accountDetail(account: Account)
    case changePassword
    case deleteAccount
    case editProfile
    case about
    case exportData
    case reportBug
    case categoryMapping(budgetCategory: String)
}
