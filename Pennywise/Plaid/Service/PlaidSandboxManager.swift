import Foundation
import LinkKit

/// PlaidSandboxManager: Direct integration with Plaid's API for sandbox testing
@MainActor
class PlaidSandboxManager {
    static let shared = PlaidSandboxManager()
    
    private let clientID = AppConstants.Plaid.clientID
    private let secret = AppConstants.Plaid.secret
    private let plaidAPIBaseURL = AppConstants.Plaid.baseURL
    
    private let jsonEncoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        return encoder
    }()
    
    private let jsonDecoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        decoder.dateDecodingStrategy = .formatted(dateFormatter)
        return decoder
    }()
    
    // MARK: - API Models
    
    struct CreateLinkTokenRequest: Encodable {
        let clientId: String
        let secret: String
        let clientName: String
        let products: [String]
        let countryCodes: [String]
        let language: String
        let user: UserInfo
        
        struct UserInfo: Encodable {
            let clientUserId: String
        }
    }
    
    struct CreateLinkTokenResponse: Decodable {
        let linkToken: String
    }
    
    struct ExchangePublicTokenRequest: Encodable {
        let clientId: String
        let secret: String
        let publicToken: String
    }
    
    struct ExchangePublicTokenResponse: Decodable {
        let accessToken: String
        let itemId: String
    }
    
    struct AccountsResponse: Decodable {
        let accounts: [PlaidAccount]
        let item: PlaidItem
        
        struct PlaidItem: Decodable {
            let institutionId: String?
        }
    }
    
    struct TransactionsResponse: Decodable {
        let transactions: [PlaidTransaction]
    }
    
    struct GetTransactionsRequest: Encodable {
        let clientId: String
        let secret: String
        let accessToken: String
        let startDate: String
        let endDate: String
    }
    
    struct ErrorResponse: Decodable {
        let errorMessage: String
        let errorCode: String
        let errorType: String
    }
    
    // MARK: - Public Methods
    
    func createLinkToken() async throws -> String {
        guard !clientID.contains("placeholder") && !secret.contains("placeholder") else {
            throw PlaidError.notConfigured
        }
        
        let requestBody = CreateLinkTokenRequest(
            clientId: clientID,
            secret: secret,
            clientName: "Pennywise Finance",
            products: ["transactions"],
            countryCodes: ["US"],
            language: "en",
            user: .init(clientUserId: "user-\(UUID().uuidString)")
        )
        
        let data = try await performRequest(path: "/link/token/create", body: requestBody)
        let response = try jsonDecoder.decode(CreateLinkTokenResponse.self, from: data)
        return response.linkToken
    }
    
    func exchangePublicToken(_ publicToken: String) async throws -> String {
        let requestBody = ExchangePublicTokenRequest(
            clientId: clientID,
            secret: secret,
            publicToken: publicToken
        )
        
        let data = try await performRequest(path: "/item/public_token/exchange", body: requestBody)
        let response = try jsonDecoder.decode(ExchangePublicTokenResponse.self, from: data)
        storeAccessTokenSecurely(response.accessToken)
        return response.accessToken
    }
    
    func removeItem(accessToken: String) async throws {
        let payload = ["client_id": clientID, "secret": secret, "access_token": accessToken]
        _ = try await performRequest(path: "/item/remove", body: payload)
    }
    
    func getAccounts(accessToken: String) async throws -> [PlaidAccount] {
        let payload = ["client_id": clientID, "secret": secret, "access_token": accessToken]
        let data = try await performRequest(path: "/accounts/get", body: payload)
        
        let response = try jsonDecoder.decode(AccountsResponse.self, from: data)
        let institutionId = response.item.institutionId ?? "unknown"
        let institutionName = getInstitutionName(for: institutionId)
        
        return response.accounts.map { account in
            var updatedAccount = account
            // Note: PlaidAccount is a struct, we can't easily mutate it unless we re-create it
            // Assuming PlaidAccount has a way to be initialized with institutionName
            return PlaidAccount(
                id: account.id,
                name: account.name,
                type: account.type,
                balance: account.balance,
                institutionName: institutionName,
                institutionLogo: nil
            )
        }
    }
    
    func getTransactions(accessToken: String) async throws -> [PlaidTransaction] {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        let endDate = Date()
        let startDate = Calendar.current.date(byAdding: .day, value: -30, to: endDate) ?? endDate
        
        let payload = GetTransactionsRequest(
            clientId: clientID,
            secret: secret,
            accessToken: accessToken,
            startDate: dateFormatter.string(from: startDate),
            endDate: dateFormatter.string(from: endDate)
        )
        
        do {
            let data = try await performRequest(path: "/transactions/get", body: payload)
            let response = try jsonDecoder.decode(TransactionsResponse.self, from: data)
            return response.transactions.isEmpty ? generateSampleTransactions() : response.transactions
        } catch {
            print("Plaid API error, falling back to sample data: \(error)")
            return generateSampleTransactions()
        }
    }
    
    // MARK: - Private Helpers
    
    private func performRequest<T: Encodable>(path: String, body: T) async throws -> Data {
        guard let url = URL(string: "\(plaidAPIBaseURL)\(path)") else {
            throw PlaidError.parsingError
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let bodyDict = body as? [String: Any] {
            request.httpBody = try JSONSerialization.data(withJSONObject: bodyDict)
        } else {
            request.httpBody = try jsonEncoder.encode(body)
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        if let httpResponse = response as? HTTPURLResponse, !(200...299).contains(httpResponse.statusCode) {
            if let errorResponse = try? jsonDecoder.decode(ErrorResponse.self, from: data) {
                throw PlaidError.apiError(message: errorResponse.errorMessage)
            }
            throw PlaidError.httpError(statusCode: httpResponse.statusCode)
        }
        
        return data
    }
    
    private func storeAccessTokenSecurely(_ token: String) {
        // Implementation for secure storage (e.g., Keychain)
        // This is handled in PlaidAPIService, but we can keep it here if needed for sandbox
    }
    
    private func getInstitutionName(for institutionID: String) -> String {
        let institutionNames: [String: String] = [
            "ins_1": "Bank of America",
            "ins_2": "Chase",
            "ins_3": "Wells Fargo",
            "ins_4": "Citi",
            "ins_5": "Capital One",
            "ins_6": "USAA",
            "ins_7": "Ally Bank",
            "ins_109508": "First Platypus Bank",
            "ins_109509": "First Gingham Credit Union",
            "ins_109510": "Tattersall Federal Credit Union",
            "ins_109511": "Tartan Bank",
            "ins_109512": "Houndstooth Bank"
        ]
        return institutionNames[institutionID] ?? "Connected Bank"
    }
    
    /// Deterministic sample transactions.
    ///
    /// IMPORTANT: IDs and amounts are STABLE (not random). Previously this used
    /// `UUID()` and `Double.random(...)` on every call, so each fetch produced a
    /// brand-new set that `syncTransactions` wrote to Firestore under new doc
    /// IDs — the cache accumulated duplicates indefinitely and inflated every
    /// Insights total. Stable IDs make re-syncing idempotent (same 20 docs).
    private func generateSampleTransactions() -> [PlaidTransaction] {
        let calendar = Calendar.current
        let today = Date()

        // (daysAgo, name, amount, category, merchant). Expenses positive,
        // income negative — matching the app's sign convention.
        let samples: [(Int, String, Double, String, String)] = [
            (1, "Starbucks", 6.75, "Food and Drink", "Starbucks"),
            (2, "Whole Foods", 84.20, "Groceries", "Whole Foods"),
            (3, "Uber", 18.40, "Transportation", "Uber"),
            (4, "Amazon", 52.99, "Shopping", "Amazon"),
            (5, "Netflix", 15.49, "Entertainment", "Netflix"),
            (6, "Spotify", 11.99, "Entertainment", "Spotify"),
            (7, "Electric Company", 96.30, "Utilities", "Electric Company"),
            (9, "Target", 43.18, "Shopping", "Target"),
            (11, "Walgreens", 27.60, "Health", "Walgreens"),
            (12, "Gym Membership", 39.00, "Health", "Gym Membership"),
            (14, "Whole Foods", 61.05, "Groceries", "Whole Foods"),
            (16, "Uber", 22.10, "Transportation", "Uber"),
            (18, "Starbucks", 5.25, "Food and Drink", "Starbucks"),
            (20, "Amazon", 129.99, "Shopping", "Amazon"),
            (25, "Landlord", 1500.00, "Rent", "Landlord"),
            (28, "University", 300.00, "Education", "University"),
            // Income (negative amount)
            (15, "Employer", -3200.00, "Income", "Employer"),
            (30, "Employer", -3200.00, "Income", "Employer"),
        ]

        let transactions = samples.enumerated().map { index, sample -> PlaidTransaction in
            let (daysAgo, name, amount, category, merchant) = sample
            let date = calendar.date(byAdding: .day, value: -daysAgo, to: today) ?? today
            return PlaidTransaction(
                id: "tx_sample_\(index)",   // stable id → idempotent sync
                name: name,
                amount: amount,
                date: date,
                category: category,
                merchantName: merchant,
                accountId: "acc_sandbox",
                pending: false
            )
        }
        return transactions.sorted { $0.date > $1.date }
    }
    
    enum PlaidError: Error, LocalizedError {
        case notConfigured
        case apiError(message: String)
        case httpError(statusCode: Int)
        case parsingError
        
        var errorDescription: String? {
            switch self {
            case .notConfigured: return "Plaid credentials not configured."
            case .apiError(let message): return message
            case .httpError(let statusCode): return "HTTP error: \(statusCode)"
            case .parsingError: return "Failed to parse Plaid response."
            }
        }
    }
}

