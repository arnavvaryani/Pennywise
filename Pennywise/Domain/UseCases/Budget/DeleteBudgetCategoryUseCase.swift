import Foundation

/// Use case for deleting a budget category
@MainActor
public final class DeleteBudgetCategoryUseCase {
    private let budgetRepository: BudgetRepository

    public init(budgetRepository: BudgetRepository) {
        self.budgetRepository = budgetRepository
    }

    public func execute(categoryId: String) async throws {
        try await budgetRepository.deleteBudgetCategory(id: categoryId)
    }
}

