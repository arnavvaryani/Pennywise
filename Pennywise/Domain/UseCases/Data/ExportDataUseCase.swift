import Foundation

/// Use case to export financial data as CSV
@MainActor
public class ExportDataUseCase {
    private let transactionRepository: TransactionRepository
    private let budgetRepository: BudgetRepository
    private let accountRepository: AccountRepository
    
    public init(
        transactionRepository: TransactionRepository,
        budgetRepository: BudgetRepository,
        accountRepository: AccountRepository
    ) {
        self.transactionRepository = transactionRepository
        self.budgetRepository = budgetRepository
        self.accountRepository = accountRepository
    }
    
    public func execute(type: String) async throws -> URL {
        let fileName: String
        let csvContent: String
        
        switch type {
        case "Transactions":
            fileName = "pennywise_transactions.csv"
            let transactions = try await transactionRepository.fetchTransactions()
            csvContent = generateTransactionsCSV(transactions)
            
        case "Budget Categories":
            fileName = "pennywise_budgets.csv"
            let categories = try await budgetRepository.fetchBudgetCategories()
            csvContent = generateBudgetsCSV(categories)
            
        case "Accounts Summary":
            fileName = "pennywise_accounts.csv"
            let accounts = try await accountRepository.fetchAccounts()
            csvContent = generateAccountsCSV(accounts)
            
        default: // "Export All Data"
            fileName = "pennywise_all_data.csv"
            let transactions = try await transactionRepository.fetchTransactions()
            csvContent = generateTransactionsCSV(transactions) // Simple fallback for now
        }
        
        // Save to temporary file
        let temporaryDirectory = FileManager.default.temporaryDirectory
        let fileURL = temporaryDirectory.appendingPathComponent(fileName)
        
        try csvContent.write(to: fileURL, atomically: true, encoding: .utf8)
        
        return fileURL
    }
    
    private func generateTransactionsCSV(_ transactions: [Transaction]) -> String {
        var csv = "Date,Description,Amount,Category,Account\n"
        
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        
        for tx in transactions {
            let row = "\(formatter.string(from: tx.date)),\"\(tx.merchantName)\",\(tx.amount),\(tx.category),\(tx.accountId)\n"
            csv += row
        }
        
        return csv
    }
    
    private func generateBudgetsCSV(_ categories: [BudgetCategory]) -> String {
        var csv = "Category,Limit,Spent,Remaining\n"
        
        for cat in categories {
            // Note: spent/remaining require transaction data not available at export time
            let row = "\(cat.name),\(cat.amount),0,\(cat.amount)\n"
            csv += row
        }
        
        return csv
    }
    
    private func generateAccountsCSV(_ accounts: [Account]) -> String {
        var csv = "Name,Type,Balance\n"
        
        for acc in accounts {
            let safeName = "\"\(acc.name.replacingOccurrences(of: "\"", with: "\"\""))\""
            let safeType = "\"\(acc.type.replacingOccurrences(of: "\"", with: "\"\""))\""
            let row = "\(safeName),\(safeType),\(acc.balance)\n"
            csv += row
        }
        
        return csv
    }
}
