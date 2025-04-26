//
//  GeminiService.swift
//  Pennywise
//
//  Created by Arnav Varyani on 4/25/25.
//


import Foundation
import Combine

/// Service for handling communication with Google's Gemini API
class GeminiService: ObservableObject {
    // MARK: - Constants
    
    /// Base URL for Gemini API requests
    private let baseURL = "https://generativelanguage.googleapis.com/v1"
    
    /// Gemini model to use (Gemini 1.0 Pro is currently recommended)
    private let model = "models/gemini-1.0-pro"
    
    /// Error types specific to Gemini service
    enum GeminiServiceError: Error, LocalizedError {
        case invalidAPIKey
        case invalidRequest
        case networkError(Error)
        case parsingError
        case responseError(String)
        
        var errorDescription: String? {
            switch self {
            case .invalidAPIKey:
                return "Invalid API key. Please update your Gemini API key in settings."
            case .invalidRequest:
                return "Unable to create a valid request."
            case .networkError(let error):
                return "Network error: \(error.localizedDescription)"
            case .parsingError:
                return "Failed to parse response from Gemini."
            case .responseError(let message):
                return "API error: \(message)"
            }
        }
    }
    
    // MARK: - Published Properties
    
    /// Indicates if a request is in progress
    @Published var isLoading = false
    
    /// Stores any error that occurred during a request
    @Published var error: GeminiServiceError?
    
    // MARK: - Private Properties
    
    /// API key for Gemini (stored securely in the app)
    private var apiKey: String {
        // In a real app, this would be fetched from secure storage
        // For testing, you can define it here or use environment variables
        UserDefaults.standard.string(forKey: "geminiApiKey") ?? ""
    }
    
    /// Set to store active cancellables
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Public Methods
    
    /// Updates the API key in secure storage
    func updateAPIKey(_ key: String) {
        UserDefaults.standard.set(key, forKey: "geminiApiKey")
    }
    
    /// Generates a response to a chat based on the provided messages and financial context
    /// - Parameters:
    ///   - messages: Array of previous messages in the conversation
    ///   - financialContext: Context data about the user's financial situation
    ///   - completion: Callback with the result of the request
    func generateChatResponse(
        messages: [ChatMessage],
        financialContext: FinancialContext,
        completion: @escaping (Result<String, GeminiServiceError>) -> Void
    ) {
        guard !apiKey.isEmpty else {
            completion(.failure(.invalidAPIKey))
            return
        }
        
        isLoading = true
        error = nil
        
        // Create the request URL
        let urlString = "\(baseURL)/\(model):generateContent?key=\(apiKey)"
        guard let url = URL(string: urlString) else {
            isLoading = false
            completion(.failure(.invalidRequest))
            return
        }
        
        // Prepare the request
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Create the request body with both the conversation history and financial context
        let requestBody = buildRequestBody(
            messages: messages,
            financialContext: financialContext
        )
        
        do {
            request.httpBody = try JSONEncoder().encode(requestBody)
        } catch {
            isLoading = false
            completion(.failure(.invalidRequest))
            return
        }
        
        // Make the API request
        URLSession.shared.dataTaskPublisher(for: request)
            .tryMap { data, response -> Data in
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw GeminiServiceError.networkError(NSError(domain: "GeminiService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response"]))
                }
                
                if !(200...299).contains(httpResponse.statusCode) {
                    let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
                    throw GeminiServiceError.responseError("HTTP \(httpResponse.statusCode): \(errorMessage)")
                }
                
                return data
            }
            .decode(type: GeminiResponse.self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] result in
                    self?.isLoading = false
                    
                    switch result {
                    case .finished:
                        break
                    case .failure(let error):
                        if let geminiError = error as? GeminiServiceError {
                            self?.error = geminiError
                            completion(.failure(geminiError))
                        } else {
                            let mappedError = GeminiServiceError.networkError(error)
                            self?.error = mappedError
                            completion(.failure(mappedError))
                        }
                    }
                },
                receiveValue: { response in
                    if let content = response.candidates.first?.content.parts.first?.text {
                        completion(.success(content))
                    } else {
                        completion(.failure(.parsingError))
                    }
                }
            )
            .store(in: &cancellables)
    }
    
    // MARK: - Private Methods
    
    /// Builds the request body for the Gemini API
    private func buildRequestBody(
        messages: [ChatMessage],
        financialContext: FinancialContext
    ) -> RequestBody {
        // Start with the system instructions
        var contents: [Content] = [
            Content(
                role: "system",
                parts: [
                    Part(text: buildSystemPrompt(with: financialContext))
                ]
            )
        ]
        
        // Add the conversation history
        for message in messages {
            let role: String
            switch message.role {
            case .user:
                role = "user"
            case .assistant:
                role = "model"
            case .system:
                continue // System messages should be consolidated in the first prompt
            }
            
            contents.append(
                Content(
                    role: role,
                    parts: [
                        Part(text: message.text)
                    ]
                )
            )
        }
        
        return RequestBody(
            contents: contents,
            generationConfig: GenerationConfig(
                temperature: 0.7,
                maxOutputTokens: 1024,
                topP: 0.95,
                topK: 40
            )
        )
    }
    
    /// Builds the system prompt with financial context
    private func buildSystemPrompt(with context: FinancialContext) -> String {
        var systemPrompt = """
        You are PennyGPT, a personal financial assistant integrated within the Pennywise finance app. 
        Your goal is to provide helpful, personalized financial advice based on the user's actual financial data.
        
        Important guidelines:
        1. Be specific and actionable in your advice, referencing actual amounts and categories from the user's data.
        2. Be concise and clear - users may be viewing on mobile devices.
        3. Use a friendly, supportive tone but avoid unnecessary pleasantries.
        4. Never recommend high-risk financial activities like day trading or borrowing money at high interest rates.
        5. Respect privacy - don't ask for additional personal information beyond what's shared in the context.
        6. Focus on practical advice that helps users achieve their financial goals.
        7. When referring to data, use precise figures (e.g., "$152.75 on dining out" rather than "money on dining").
        8. If asked about something outside your financial advisory role, gently redirect to financial topics.
        
        You have access to the following user financial data:
        """
        
        // Add account information
        systemPrompt += "\n\nACCOUNTS:"
        if context.accounts.isEmpty {
            systemPrompt += "\nNo accounts linked yet."
        } else {
            for account in context.accounts {
                systemPrompt += "\n- \(account.name) (\(account.institutionName)): $\(String(format: "%.2f", account.balance))"
            }
        }
        
        // Add budget information
        systemPrompt += "\n\nBUDGETS:"
        if context.budgetCategories.isEmpty {
            systemPrompt += "\nNo budget categories created yet."
        } else {
            for category in context.budgetCategories {
                let spentAmount = context.categorySpending[category.name] ?? 0
                let percentUsed = category.amount > 0 ? (spentAmount / category.amount) * 100 : 0
                systemPrompt += "\n- \(category.name): $\(String(format: "%.2f", spentAmount)) spent of $\(String(format: "%.2f", category.amount)) budgeted (\(String(format: "%.1f", percentUsed))%)"
            }
        }
        
        // Add transaction summary
        systemPrompt += "\n\nRECENT TRANSACTIONS:"
        if context.recentTransactions.isEmpty {
            systemPrompt += "\nNo recent transactions recorded."
        } else {
            for transaction in context.recentTransactions.prefix(10) {
                let amountPrefix = transaction.amount > 0 ? "-$" : "+$"
                let formattedDate = formatDate(transaction.date)
                systemPrompt += "\n- \(formattedDate): \(transaction.merchantName) - \(amountPrefix)\(String(format: "%.2f", abs(transaction.amount))) (\(transaction.category))"
            }
            if context.recentTransactions.count > 10 {
                systemPrompt += "\n- ... and \(context.recentTransactions.count - 10) more transactions"
            }
        }
        
        // Add financial summary
        systemPrompt += "\n\nFINANCIAL SUMMARY:"
        systemPrompt += "\n- Monthly Income: $\(String(format: "%.2f", context.monthlyIncome))"
        systemPrompt += "\n- Monthly Expenses: $\(String(format: "%.2f", context.monthlyExpenses))"
        systemPrompt += "\n- Total Balance: $\(String(format: "%.2f", context.totalBalance))"
        systemPrompt += "\n- Top Spending Category: \(context.topSpendingCategory.name) ($\(String(format: "%.2f", context.topSpendingCategory.amount)))"
        
        return systemPrompt
    }
    
    /// Formats a date to a readable string
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}

// MARK: - Supporting Models

/// Represents a message in a chat conversation
struct ChatMessage: Identifiable {
    var id = UUID()
    var text: String
    var role: MessageRole
    var timestamp = Date()
    
    enum MessageRole {
        case user
        case assistant
        case system
    }
}

/// Represents financial context to be provided to the Gemini API
struct FinancialContext {
    var accounts: [PlaidAccount] = []
    var budgetCategories: [BudgetCategory] = []
    var categorySpending: [String: Double] = [:]
    var recentTransactions: [PlaidTransaction] = []
    var monthlyIncome: Double = 0
    var monthlyExpenses: Double = 0
    var totalBalance: Double = 0
    var topSpendingCategory: (name: String, amount: Double) = ("", 0)
}

// MARK: - Gemini API Models

/// Main request body structure for Gemini API
struct RequestBody: Encodable {
    let contents: [Content]
    let generationConfig: GenerationConfig
}

/// Content part of the request
struct Content: Encodable {
    let role: String
    let parts: [Part]
}

/// Individual part within content (usually text)
struct Part: Encodable {
    let text: String
}

/// Generation configuration parameters
struct GenerationConfig: Encodable {
    let temperature: Double
    let maxOutputTokens: Int
    let topP: Double
    let topK: Int
}

/// Response structure from Gemini API
struct GeminiResponse: Decodable {
    let candidates: [Candidate]
}

/// Individual candidate response
struct Candidate: Decodable {
    let content: ContentResponse
}

/// Content part of response
struct ContentResponse: Decodable {
    let parts: [PartResponse]
}

/// Individual part of content response
struct PartResponse: Decodable {
    let text: String
}
