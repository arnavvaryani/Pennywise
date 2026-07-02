//
//  FetchInsightsUseCaseTests.swift
//  PennywiseTests
//
//  Verifies that Insights aggregation (moved out of the View layer) is correct.
//

import XCTest
import Combine
@testable import Pennywise

// MARK: - Mocks

@MainActor
private final class MockTransactionRepository: TransactionRepository {
    var transactions: [Transaction] = []
    var transactionsPublisher: AnyPublisher<[Transaction], Never> {
        Just(transactions).eraseToAnyPublisher()
    }
    func fetchTransactions() async throws -> [Transaction] { transactions }
    func fetchTransactions(for accountId: String) async throws -> [Transaction] {
        transactions.filter { $0.accountId == accountId }
    }
    func fetchCurrentMonthTransactions() async throws -> [Transaction] {
        transactions.filter { $0.isInCurrentMonth }
    }
    func addTransaction(_ transaction: Transaction) async throws {}
    func updateTransaction(_ transaction: Transaction) async throws {}
    func deleteTransaction(id: String) async throws {}
    func updateTransactionCategory(transactionId: String, category: String) async throws {}
    func syncTransactions() async throws {}
    func resetSync() async throws {}
}

@MainActor
private final class MockBudgetRepository: BudgetRepository {
    func fetchBudgetCategories() async throws -> [BudgetCategory] { [] }
    func addBudgetCategory(_ category: BudgetCategory) async throws {}
    func updateBudgetCategory(_ category: BudgetCategory) async throws {}
    func updateCategoryAmount(categoryId: String, amount: Double) async throws {}
    func deleteBudgetCategory(id: String) async throws {}
    func calculateCategorySpending(categoryName: String, transactions: [Transaction]) -> Double { 0 }
    func updateBudgetUsage() async throws {}
    func getMonthlyFinancialData(transactions: [Transaction]) -> [MonthlyFinancialData] { [] }
}

// MARK: - Tests

final class FetchInsightsUseCaseTests: XCTestCase {

    @MainActor
    private func makeTransaction(amount: Double, category: String, merchant: String, daysAgo: Int) -> Transaction {
        let date = Calendar.current.date(byAdding: .day, value: -daysAgo, to: Date()) ?? Date()
        return Transaction(
            id: "\(category)-\(merchant)-\(amount)-\(daysAgo)",
            name: merchant,
            amount: amount,           // >0 expense, <0 income
            date: date,
            category: category,
            merchantName: merchant,
            accountId: "acc-1",
            isPending: false,
            isManual: false
        )
    }

    @MainActor
    func testAggregatesForWeek() async throws {
        let txRepo = MockTransactionRepository()
        txRepo.transactions = [
            makeTransaction(amount: 100, category: "Food", merchant: "A", daysAgo: 2),
            makeTransaction(amount: 50, category: "Food", merchant: "B", daysAgo: 2),
            makeTransaction(amount: 30, category: "Travel", merchant: "A", daysAgo: 1),
            makeTransaction(amount: -200, category: "Income", merchant: "Employer", daysAgo: 3),
        ]
        let useCase = FetchInsightsUseCase(transactionRepository: txRepo, budgetRepository: MockBudgetRepository())

        let s = try await useCase.execute(timeframe: .week)

        XCTAssertEqual(s.totalSpending, 180, accuracy: 0.001)
        XCTAssertEqual(s.totalIncome, 200, accuracy: 0.001)
        XCTAssertEqual(s.netCashflow, 20, accuracy: 0.001)
        XCTAssertEqual(s.spendingVsIncomePercent, 90)

        // Category breakdown sorted desc: Food (150) then Travel (30).
        XCTAssertEqual(s.categoryBreakdown.map { $0.name }, ["Food", "Travel"])
        XCTAssertEqual(s.categoryBreakdown.first?.amount ?? 0, 150, accuracy: 0.001)

        // Top vendors: A (100+30=130) then B (50).
        XCTAssertEqual(s.topVendors.first?.name, "A")
        XCTAssertEqual(s.topVendors.first?.amount ?? 0, 130, accuracy: 0.001)

        // Income sources: Employer 200.
        XCTAssertEqual(s.incomeSources.first?.name, "Employer")
        XCTAssertEqual(s.incomeSources.first?.amount ?? 0, 200, accuracy: 0.001)

        // Week chart has 7 daily bars.
        XCTAssertEqual(s.bars.count, 7)
        XCTAssertFalse(s.isEmpty)
    }

    @MainActor
    func testEmptyWhenNoTransactionsInWindow() async throws {
        let txRepo = MockTransactionRepository()
        // Only an old transaction, outside the 7-day week window.
        txRepo.transactions = [makeTransaction(amount: 100, category: "Food", merchant: "A", daysAgo: 400)]
        let useCase = FetchInsightsUseCase(transactionRepository: txRepo, budgetRepository: MockBudgetRepository())

        let week = try await useCase.execute(timeframe: .week)
        XCTAssertTrue(week.isEmpty)
        XCTAssertEqual(week.totalSpending, 0, accuracy: 0.001)

        // But within the year window it should appear... 400 days is outside a year too.
        let year = try await useCase.execute(timeframe: .year)
        XCTAssertTrue(year.isEmpty)
    }

    @MainActor
    func testMonthAndYearBarCounts() async throws {
        let txRepo = MockTransactionRepository()
        txRepo.transactions = [makeTransaction(amount: 100, category: "Food", merchant: "A", daysAgo: 2)]
        let useCase = FetchInsightsUseCase(transactionRepository: txRepo, budgetRepository: MockBudgetRepository())

        let month = try await useCase.execute(timeframe: .month)
        XCTAssertEqual(month.bars.count, 8)   // last 8 months

        let year = try await useCase.execute(timeframe: .year)
        XCTAssertEqual(year.bars.count, 12)   // last 12 months
    }
}
