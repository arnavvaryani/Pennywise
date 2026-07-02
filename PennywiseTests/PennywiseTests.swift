//
//  PennywiseTests.swift
//  PennywiseTests
//
//  Created by Arnav Varyani on 4/8/25.
//

import XCTest
@testable import Pennywise

// MARK: - Clean Architecture Tests

class DependencyContainerTests: XCTestCase {
    
    @MainActor
    func testDependencyContainer() async {
        let container = DependencyContainer.shared
        XCTAssertNotNil(container)
        XCTAssertNotNil(container.authRepository)
        XCTAssertNotNil(container.transactionRepository)
        XCTAssertNotNil(container.userRepository)
        XCTAssertNotNil(container.budgetRepository)
    }
    
    @MainActor
    func testAuthRepository() async {
        let container = DependencyContainer.shared
        let authRepository = container.authRepository
        XCTAssertNotNil(authRepository)
        XCTAssertFalse(authRepository.isAuthenticated) // Should be false by default
    }
    
    @MainActor
    func testUseCaseCreation() {
        let container = DependencyContainer.shared
        
        let loginUseCase = container.makeLoginUseCase()
        XCTAssertNotNil(loginUseCase)
        
        let logoutUseCase = container.makeLogoutUseCase()
        XCTAssertNotNil(logoutUseCase)
    }
}

// MARK: - Entity Tests

class EntityTests: XCTestCase {
    
    func testTransactionEntity() {
        let transaction = Transaction(
            id: "test-123",
            name: "Test Transaction",
            amount: 100.0,
            date: Date(),
            category: "Food",
            merchantName: "Test Store",
            accountId: "acc-1",
            isPending: false,
            isManual: true
        )
        
        XCTAssertEqual(transaction.id, "test-123")
        XCTAssertEqual(transaction.name, "Test Transaction")
        XCTAssertEqual(transaction.amount, 100.0)
        XCTAssertTrue(transaction.isManual)
    }
    
    func testBudgetCategoryEntity() {
        let category = BudgetCategory(
            id: "cat-1",
            name: "Groceries",
            amount: 500.0,
            icon: "cart",
            colorHex: "#FF0000",
            isEssential: true
        )
        
        XCTAssertEqual(category.name, "Groceries")
        XCTAssertEqual(category.amount, 500.0)
        XCTAssertTrue(category.isEssential)
    }
}

// MARK: - ViewModel Tests

class ViewModelTests: XCTestCase {
    
    @MainActor
    func testHomeViewModel() {
        let container = DependencyContainer.shared
        let viewModel = container.makeHomeViewModel()
        
        XCTAssertNotNil(viewModel)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertEqual(viewModel.transactions.count, 0) // Should start empty
    }
    
    @MainActor
    func testSettingsViewModel() {
        let container = DependencyContainer.shared
        let viewModel = container.makeSettingsViewModel()
        
        XCTAssertNotNil(viewModel)
        XCTAssertNil(viewModel.user) // Should be nil before loading
    }
}

// TODO: Add more comprehensive tests for:
// - Repository implementations
// - Use cases
// - Data mappers
// - Service layer
