//
//  PennywiseTests.swift
//  PennywiseTests
//
//  Created by Arnav Varyani on 4/8/25.
//

import XCTest
@testable import Pennywise
import SwiftUI

class AuthenticationServiceTests: XCTestCase {
    
    var authService: AuthenticationService!
    
    override func setUp() {
        super.setUp()
        authService = AuthenticationService.shared
    }
    
    override func tearDown() {
        authService = nil
        super.tearDown()
    }
    
    func testPasswordValidation() {
        // Valid password
        XCTAssertTrue(authService.isPasswordValid("Password123"), "Valid password should pass validation")
        
        // Invalid passwords
        XCTAssertFalse(authService.isPasswordValid("password"), "Password without uppercase should fail")
        XCTAssertFalse(authService.isPasswordValid("PASSWORD"), "Password without lowercase should fail")
        XCTAssertFalse(authService.isPasswordValid("Password"), "Password without number should fail")
        XCTAssertFalse(authService.isPasswordValid("Pass1"), "Password with insufficient length should fail")
    }
    
    func testEmailValidation() {
        // Valid emails
        XCTAssertTrue(authService.isEmailValid("user@example.com"), "Valid email should pass validation")
        XCTAssertTrue(authService.isEmailValid("user.name+tag@example.co.uk"), "Valid complex email should pass validation")
        
        // Invalid emails
        XCTAssertFalse(authService.isEmailValid("user@"), "Incomplete email should fail validation")
        XCTAssertFalse(authService.isEmailValid("user@example"), "Email without proper TLD should fail validation")
        XCTAssertFalse(authService.isEmailValid("user.example.com"), "Email without @ should fail validation")
    }
    
    func testBiometricAuthRequirement() {
        // Test when biometrics are enabled and required on open
        authService.biometricAuthEnabled = true
        authService.requireBiometricsOnOpen = true
        UserDefaults.standard.set(false, forKey: "hasPassedBiometricCheck")
        
        XCTAssertTrue(authService.shouldRequireBiometricAuth(), "Should require biometric auth")
        
        // Test when user already passed check
        UserDefaults.standard.set(true, forKey: "hasPassedBiometricCheck")
        XCTAssertFalse(authService.shouldRequireBiometricAuth(), "Should not require biometric auth when already passed")
        
        // Test when biometrics are disabled
        authService.biometricAuthEnabled = false
        authService.requireBiometricsOnOpen = true
        UserDefaults.standard.set(false, forKey: "hasPassedBiometricCheck")
        XCTAssertFalse(authService.shouldRequireBiometricAuth(), "Should not require biometric auth when disabled")
    }
}

class TransactionViewModelTests: XCTestCase {
    
    var viewModel: TransactionViewModel!
    
    override func setUp() {
        super.setUp()
        viewModel = TransactionViewModel()
    }
    
    override func tearDown() {
        viewModel = nil
        super.tearDown()
    }
    
    func testValidation() {
        // Test empty title
        viewModel.title = ""
        viewModel.amount = "100"
        viewModel.merchant = "Test Merchant"
        XCTAssertFalse(viewModel.validateInputs(), "Empty title should fail validation")
        
        // Test empty merchant
        viewModel.title = "Test Transaction"
        viewModel.amount = "100"
        viewModel.merchant = ""
        XCTAssertFalse(viewModel.validateInputs(), "Empty merchant should fail validation")
        
        // Test empty amount
        viewModel.title = "Test Transaction"
        viewModel.amount = ""
        viewModel.merchant = "Test Merchant"
        XCTAssertFalse(viewModel.validateInputs(), "Empty amount should fail validation")
        
        // Test invalid amount
        viewModel.title = "Test Transaction"
        viewModel.amount = "abc"
        viewModel.merchant = "Test Merchant"
        XCTAssertFalse(viewModel.validateInputs(), "Non-numeric amount should fail validation")
        
        // Test zero amount
        viewModel.title = "Test Transaction"
        viewModel.amount = "0"
        viewModel.merchant = "Test Merchant"
        XCTAssertFalse(viewModel.validateInputs(), "Zero amount should fail validation")
        
        // Test negative amount
        viewModel.title = "Test Transaction"
        viewModel.amount = "-10"
        viewModel.merchant = "Test Merchant"
        XCTAssertFalse(viewModel.validateInputs(), "Negative amount should fail validation")
        
        // Test valid inputs
        viewModel.title = "Test Transaction"
        viewModel.amount = "100"
        viewModel.merchant = "Test Merchant"
        XCTAssertTrue(viewModel.validateInputs(), "Valid inputs should pass validation")
    }
    
    func testGetIconForCategory() {
        // Test known categories
        XCTAssertEqual(viewModel.getIconForCategory("Food"), "fork.knife", "Should return correct icon for Food")
        XCTAssertEqual(viewModel.getIconForCategory("Shopping"), "cart", "Should return correct icon for Shopping")
        XCTAssertEqual(viewModel.getIconForCategory("Transportation"), "car.fill", "Should return correct icon for Transportation")
        
        // Test partial matches
        XCTAssertEqual(viewModel.getIconForCategory("Dining out"), "fork.knife", "Should match 'food' in different categories")
        XCTAssertEqual(viewModel.getIconForCategory("Online Shopping"), "cart", "Should match 'shop' in different categories")
        
        // Test fallback icon
        XCTAssertEqual(viewModel.getIconForCategory("Miscellaneous"), "ellipsis.circle.fill", "Should return fallback icon for unknown category")
    }
    
    func testCreateTransaction() {
        // Setup transaction data
        viewModel.title = "Test Expense"
        viewModel.amount = "100"
        viewModel.merchant = "Test Merchant"
        viewModel.selectedCategory = "Food"
        viewModel.isExpense = true
        viewModel.date = Date()
        
        // Create expense transaction
        let expenseTransaction = viewModel.createTransaction()
        XCTAssertEqual(expenseTransaction.title, "Test Expense", "Transaction title should match")
        XCTAssertEqual(expenseTransaction.merchant, "Test Merchant", "Transaction merchant should match")
        XCTAssertEqual(expenseTransaction.category, "Food", "Transaction category should match")
        XCTAssertEqual(expenseTransaction.amount, -100, "Expense amount should be negative")
        
        // Test income transaction
        viewModel.isExpense = false
        let incomeTransaction = viewModel.createTransaction()
        XCTAssertEqual(incomeTransaction.category, "Income", "Income transaction should have 'Income' category")
        XCTAssertEqual(incomeTransaction.amount, 100, "Income amount should be positive")
    }
}

// MARK: - Budget Category Tests

class BudgetCategoryTests: XCTestCase {
    
    func testEssentialCategoryDetection() {
        // Test essential categories
        XCTAssertTrue(CategoryDetailView.isEssentialCategory("Groceries"), "Groceries should be detected as essential")
        XCTAssertTrue(CategoryDetailView.isEssentialCategory("Monthly Rent"), "Rent should be detected as essential")
        XCTAssertTrue(CategoryDetailView.isEssentialCategory("Healthcare Expenses"), "Healthcare should be detected as essential")
        XCTAssertTrue(CategoryDetailView.isEssentialCategory("Car Insurance"), "Insurance should be detected as essential")
        
        // Test non-essential categories
        XCTAssertFalse(CategoryDetailView.isEssentialCategory("Entertainment"), "Entertainment should not be essential")
        XCTAssertFalse(CategoryDetailView.isEssentialCategory("Dining Out"), "Dining Out should not be essential")
        XCTAssertFalse(CategoryDetailView.isEssentialCategory("Hobbies"), "Hobbies should not be essential")
    }
}

// MARK: - Plaid Integration Tests

class PlaidManagerTests: XCTestCase {
    
    var plaidManager: PlaidManager!
    var mockTransactions: [PlaidTransaction]!
    
    override func setUp() {
        super.setUp()
        plaidManager = PlaidManager.shared
        
        // Create mock transactions
        mockTransactions = [
            PlaidTransaction(id: "tx1", name: "Grocery Store", amount: 75.50, date: Date(), category: "Groceries", merchantName: "Whole Foods", accountId: "acc1", pending: false),
            PlaidTransaction(id: "tx2", name: "Monthly Spotify", amount: 9.99, date: Date(), category: "Entertainment", merchantName: "Spotify", accountId: "acc1", pending: false),
            PlaidTransaction(id: "tx3", name: "Gas Station", amount: 45.25, date: Date(), category: "Transportation", merchantName: "Shell", accountId: "acc1", pending: false),
            PlaidTransaction(id: "tx4", name: "Salary Deposit", amount: -2500.00, date: Date(), category: "Income", merchantName: "Employer", accountId: "acc1", pending: false)
        ]
    }
    
    override func tearDown() {
        plaidManager = nil
        mockTransactions = nil
        super.tearDown()
    }
    
    func testMonthlyFinancialDataCalculation() {
        // Setup test data
        plaidManager.transactions = mockTransactions
        
        // Get monthly financial data
        let financialData = plaidManager.getMonthlyFinancialData()
        
        // There should be data for the current month
        XCTAssertTrue(financialData.count > 0, "Should generate monthly financial data")
        
        // Test data for current month
        if let currentMonth = financialData.last {
            // Income calculation (negative transactions)
            XCTAssertEqual(currentMonth.income, 2500.0, "Income should be the sum of negative transactions")
            
            // Expense calculation (positive transactions)
            let expectedExpenses = 75.50 + 9.99 + 45.25
            XCTAssertEqual(currentMonth.expenses, expectedExpenses, accuracy: 0.01, "Expenses should be the sum of positive transactions")
        }
    }
    
    func testBudgetCategoriesGeneration() {
        // Setup test data
        plaidManager.transactions = mockTransactions
        
        // Calculate budget categories
        var budgetCategories: [String: Double] = [:]
        mockTransactions.forEach { transaction in
            if transaction.amount > 0 { // Only include expenses
                budgetCategories[transaction.category, default: 0] += transaction.amount
            }
        }
        plaidManager.budgetCategories = budgetCategories
        
        // Get budget categories
        let categories = plaidManager.getBudgetCategories()
        
        // Verify categories were created correctly
        XCTAssertEqual(categories.count, 3, "Should create a budget category for each expense category")
        
        // Check category amounts
        let groceriesCategory = categories.first { $0.name == "Groceries" }
        XCTAssertNotNil(groceriesCategory, "Should have a Groceries category")
        XCTAssertEqual(groceriesCategory?.amount, 75.50, "Groceries amount should match transaction")
        
        let entertainmentCategory = categories.first { $0.name == "Entertainment" }
        XCTAssertNotNil(entertainmentCategory, "Should have an Entertainment category")
        XCTAssertEqual(entertainmentCategory?.amount, 9.99, "Entertainment amount should match transaction")
    }
    
    func testTransactionFiltering() {
        // Setup test data
        plaidManager.accounts = [
            PlaidAccount(id: "acc1", name: "Checking", type: "depository", balance: 1000.0, institutionName: "Test Bank", institutionLogo: nil, isPlaceholder: false),
            PlaidAccount(id: "acc2", name: "Savings", type: "depository", balance: 5000.0, institutionName: "Test Bank", institutionLogo: nil, isPlaceholder: false)
        ]
        plaidManager.transactions = mockTransactions
        
        // Test filtering by account
        let accountTransactions = plaidManager.transactions(for: "acc1")
        XCTAssertEqual(accountTransactions.count, 4, "Should return all transactions for account")
        
        // Add transaction for another account
        let otherAccountTransaction = PlaidTransaction(id: "tx5", name: "Other Account", amount: 100.0, date: Date(), category: "Miscellaneous", merchantName: "Other", accountId: "acc2", pending: false)
        plaidManager.transactions.append(otherAccountTransaction)
        
        // Test filtering again
        let updatedAccountTransactions = plaidManager.transactions(for: "acc1")
        XCTAssertEqual(updatedAccountTransactions.count, 4, "Should only return transactions for specified account")
        
        let otherAccountTransactions = plaidManager.transactions(for: "acc2")
        XCTAssertEqual(otherAccountTransactions.count, 1, "Should return transactions for other account")
    }
}

// MARK: - Color Extension Tests

class ColorExtensionTests: XCTestCase {
    
    func testHexInitialization() {
        // Test basic hex colors
        let redColor = Color(hex: "#FF0000")
        let greenColor = Color(hex: "#00FF00")
        let blueColor = Color(hex: "#0000FF")
        
        // Testing hex string conversion
        XCTAssertEqual(redColor.hexString.uppercased(), "#FF0000", "Red color hex string should match")
        XCTAssertEqual(greenColor.hexString.uppercased(), "#00FF00", "Green color hex string should match")
        XCTAssertEqual(blueColor.hexString.uppercased(), "#0000FF", "Blue color hex string should match")
        
        // Test short hex format
        let shortRedColor = Color(hex: "#F00")
        XCTAssertEqual(shortRedColor.hexString.uppercased(), "#FF0000", "Short hex format should be expanded correctly")
        
        // Test with alpha
        let transparentBlue = Color(hex: "#0000FF80") // 50% transparent blue
        XCTAssertTrue(transparentBlue.hexString.contains("80"), "Alpha value should be preserved")
    }
}

// MARK: - Helper Tests

class DateFormattingTests: XCTestCase {
    
    func testFormatDate() {
        // Create a test date - January 15, 2025
        let calendar = Calendar.current
        var components = DateComponents()
        components.year = 2025
        components.month = 1
        components.day = 15
        components.hour = 14
        components.minute = 30
        
        let testDate = calendar.date(from: components)!
        
        // Test default format
        let defaultFormat = formatDate(testDate)
        XCTAssertTrue(defaultFormat.contains("January 15, 2025"), "Default format should include full date")
        
        // Test with time
        let timeFormat = formatDate(testDate, includeTime: true)
        XCTAssertTrue(timeFormat.contains("2025") && timeFormat.contains("2:30"), "Time format should include date and time")
        
        // Test with weekday
        let weekdayFormat = formatDate(testDate, includeWeekday: true)
        XCTAssertTrue(weekdayFormat.contains("Wednesday"), "Weekday format should include day of week")
        
        // Test short format
        let shortFormat = formatDate(testDate, shortFormat: true)
        XCTAssertTrue(shortFormat.contains("Jan"), "Short format should use abbreviated month")
    }
    
    // Helper function mimicking the one in the app
    private func formatDate(_ date: Date, includeTime: Bool = false, includeWeekday: Bool = false, shortFormat: Bool = false) -> String {
        let formatter = DateFormatter()
        
        if shortFormat {
            formatter.dateFormat = "MMM d, yyyy"
            return formatter.string(from: date)
        }
        
        if includeTime {
            formatter.dateFormat = "MMM d, yyyy 'at' h:mm a"
            return formatter.string(from: date)
        }
        
        if includeWeekday {
            formatter.dateFormat = "EEEE, MMMM d, yyyy"
            return formatter.string(from: date)
        }
        
        formatter.dateFormat = "MMMM d, yyyy"
        return formatter.string(from: date)
    }
}
