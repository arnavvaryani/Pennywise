//
//  HomeViewModel.swift
//  Pennywise
//
//  ViewModel for Home screen - Clean Architecture
//

import Foundation
import SwiftUI
import Observation
import UIKit

@MainActor
@Observable
public final class HomeViewModel {
    // MARK: - Dependencies
    private let fetchTransactionsUseCase: FetchTransactionsUseCase
    private let addTransactionUseCase: AddTransactionUseCase
    private let syncTransactionsUseCase: SyncTransactionsUseCase
    private let authRepository: AuthRepository
    private let plaidRepository: PlaidRepository
    
    // MARK: - Observable State
    public var transactions: [Transaction] = []
    public var accounts: [Account] = []
    public var totalBalance: Double = 0
    public var monthlyIncome: Double = 0
    public var monthlyExpenses: Double = 0
    public var monthlyExpenseBars: [SpendingBar] = []
    public var totalDebt: Double = 0
    public var totalInvestments: Double = 0
    public var isLoading = false
    public var isRefreshing = false
    public var error: Error?
    public var hideBalance = false
    public var selectedTransaction: Transaction?
    public var selectedAccount: Account?
    public var showNewTransaction = false
    public var currentUserName: String = "User"
    public var lastUpdatedAt: Date? = nil
    
    // Animation state
    public var cardOffset: CGFloat = 1000
    public var opacity: Double = 0
    public var scale: CGFloat = 0.8
    public var animateBalance = false
    
    // MARK: - Computed Properties
    public var currentMonthTransactions: [Transaction] {
        transactions.filter { $0.isInCurrentMonth }
    }
    
    public var formattedBalance: String {
        CurrencyFormatter.formatBalance(totalBalance, isHidden: hideBalance)
    }
    
    public var formattedMonthlyIncome: String {
        CurrencyFormatter.format(monthlyIncome)
    }
    
    public var formattedMonthlyExpenses: String {
        CurrencyFormatter.format(monthlyExpenses)
    }

    public var isPlaidLinked: Bool {
        plaidRepository.isPlaidLinked
    }
    
    // MARK: - Init
    public init(
        fetchTransactionsUseCase: FetchTransactionsUseCase,
        addTransactionUseCase: AddTransactionUseCase,
        syncTransactionsUseCase: SyncTransactionsUseCase,
        authRepository: AuthRepository,
        plaidRepository: PlaidRepository
    ) {
        self.fetchTransactionsUseCase = fetchTransactionsUseCase
        self.addTransactionUseCase = addTransactionUseCase
        self.syncTransactionsUseCase = syncTransactionsUseCase
        self.authRepository = authRepository
        self.plaidRepository = plaidRepository
    }
    
    // MARK: - Public Methods
    public func loadData() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let summary = try await fetchTransactionsUseCase.execute()
            
            // Update state
            transactions = summary.transactions
            accounts = summary.accounts
            totalBalance = summary.totalBalance
            monthlyIncome = summary.monthlyIncome
            monthlyExpenses = summary.monthlyExpenses
            monthlyExpenseBars = summary.monthlyExpenseBars
            totalDebt = summary.totalDebt
            totalInvestments = summary.totalInvestments
            lastUpdatedAt = Date()
        } catch {
            self.error = error
        }
    }
    
    public func refreshData() async {
        isRefreshing = true
        defer { isRefreshing = false }
        
        do {
            try await syncTransactionsUseCase.execute()
            await loadData()
            lastUpdatedAt = Date()
        } catch {
            self.error = error
        }
    }
    
    public func addTransaction(
        name: String,
        amount: Double,
        date: Date,
        category: String,
        merchantName: String,
        accountId: String = "cash"
    ) async {
        do {
            let transaction = try await addTransactionUseCase.execute(
                name: name,
                amount: amount,
                date: date,
                category: category,
                merchantName: merchantName,
                accountId: accountId
            )
            
            // Optimistically update UI
            transactions.insert(transaction, at: 0)
            
            // Recalculate totals
            if transaction.isInCurrentMonth {
                if transaction.isIncome {
                    monthlyIncome += transaction.absoluteAmount
                } else {
                    monthlyExpenses += transaction.amount
                }
            }
        } catch {
            self.error = error
        }
    }
    
    public func toggleBalanceVisibility() {
        withAnimation {
            hideBalance.toggle()
        }
    }
    
    public func selectTransaction(_ transaction: Transaction) {
        selectedTransaction = transaction
    }
    
    public func selectAccount(_ account: Account) {
        selectedAccount = account
    }
    
    public func initializeAnimations() {
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1)) {
            cardOffset = 0
            opacity = 1
            scale = 1
        }
        
        withAnimation(.spring(response: 0.8, dampingFraction: 0.8).delay(0.3)) {
            animateBalance = true
        }
    }
    
    // MARK: - User Info
    public func loadUserInfo() {
        if let user = authRepository.currentUser {
            currentUserName = user.displayName ?? user.email
        }
    }
    
    // MARK: - Plaid Link
    public func preparePlaidLink() async throws {
        try await plaidRepository.preparePlaidLink()
    }
}

