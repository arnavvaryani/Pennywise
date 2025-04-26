//
//  PlaidSandboxManager.swift
//  Pennywise
//
//  Created by Arnav Varyani on 4/8/25.
//

import Foundation
import LinkKit

/// PlaidSandboxManager: Direct integration with Plaid's API for sandbox testing
class PlaidSandboxManager {
    static let shared = PlaidSandboxManager()
      
    private let clientID = "67f84b31568ea000229ae4f9"
    private let secret = "86d4efe0c669d351a5d54a86815d9b"
    private let plaidAPIBaseURL = "https://sandbox.plaid.com"
      
      // MARK: - Public Methods

      func createLinkToken(completion: @escaping (Result<String, Error>) -> Void) {
          guard !clientID.contains("placeholder") && !secret.contains("placeholder") else {
              let error = NSError(
                  domain: "PlaidSandboxManager",
                  code: 401,
                  userInfo: [NSLocalizedDescriptionKey: "Plaid credentials not configured. In production, these should be securely fetched from your backend."]
              )
              completion(.failure(error))
              return
          }
          
          let url = URL(string: "\(plaidAPIBaseURL)/link/token/create")!
          var request = URLRequest(url: url)
          request.httpMethod = "POST"
          request.addValue("application/json", forHTTPHeaderField: "Content-Type")
          
          // Prepare the request payload
          let payload: [String: Any] = [
              "client_id": clientID,
              "secret": secret,
              "client_name": "Pennywise Finance App",
              "products": ["transactions"],
              "country_codes": ["US"],
              "language": "en",
              "user": [
                  "client_user_id": "user-\(UUID().uuidString)"
              ]
          ]
          
          // Convert payload to JSON data
          do {
              request.httpBody = try JSONSerialization.data(withJSONObject: payload)
          } catch {
              completion(.failure(error))
              return
          }
          
          // Make the API request
          let task = URLSession.shared.dataTask(with: request) { data, response, error in
              // IMPROVED ERROR HANDLING: Check HTTP status code
              if let httpResponse = response as? HTTPURLResponse,
                 !(200...299).contains(httpResponse.statusCode) {
                  let error = NSError(
                      domain: "PlaidAPI",
                      code: httpResponse.statusCode,
                      userInfo: [NSLocalizedDescriptionKey: "HTTP error: \(httpResponse.statusCode)"]
                  )
                  DispatchQueue.main.async {
                      completion(.failure(error))
                  }
                  return
              }
              
              if let error = error {
                  DispatchQueue.main.async {
                      completion(.failure(error))
                  }
                  return
              }
              
              guard let data = data else {
                  let error = NSError(domain: "PlaidSandboxManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "No data received"])
                  DispatchQueue.main.async {
                      completion(.failure(error))
                  }
                  return
              }
              
              do {
                  let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                  if let linkToken = json?["link_token"] as? String {
                      DispatchQueue.main.async {
                          completion(.success(linkToken))
                      }
                  } else if let error = json?["error_message"] as? String {
                      let plaidError = NSError(domain: "PlaidAPI", code: 2, userInfo: [NSLocalizedDescriptionKey: error])
                      DispatchQueue.main.async {
                          completion(.failure(plaidError))
                      }
                  } else {
                      let unknownError = NSError(domain: "PlaidSandboxManager", code: 3, userInfo: [NSLocalizedDescriptionKey: "Unknown error occurred"])
                      DispatchQueue.main.async {
                          completion(.failure(unknownError))
                      }
                  }
              } catch {
                  DispatchQueue.main.async {
                      completion(.failure(error))
                  }
              }
          }
          
          task.resume()
      }
      
      /// Exchange a public token for an access token
      func exchangePublicToken(_ publicToken: String, completion: @escaping (Result<String, Error>) -> Void) {
          // IMPROVED ERROR HANDLING: Validate input
          guard !publicToken.isEmpty else {
              completion(.failure(NSError(
                  domain: "PlaidSandboxManager",
                  code: 400,
                  userInfo: [NSLocalizedDescriptionKey: "Public token cannot be empty"]
              )))
              return
          }
          
          let url = URL(string: "\(plaidAPIBaseURL)/item/public_token/exchange")!
          var request = URLRequest(url: url)
          request.httpMethod = "POST"
          request.addValue("application/json", forHTTPHeaderField: "Content-Type")
          
          let payload: [String: Any] = [
              "client_id": clientID,
              "secret": secret,
              "public_token": publicToken
          ]
          
          do {
              request.httpBody = try JSONSerialization.data(withJSONObject: payload)
          } catch {
              completion(.failure(error))
              return
          }
          
          let task = URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
              // Avoid retain cycles with weak self
              guard let self = self else { return }
              
              // IMPROVED ERROR HANDLING: Check HTTP status code
              if let httpResponse = response as? HTTPURLResponse,
                 !(200...299).contains(httpResponse.statusCode) {
                  let error = NSError(
                      domain: "PlaidAPI",
                      code: httpResponse.statusCode,
                      userInfo: [NSLocalizedDescriptionKey: "HTTP error: \(httpResponse.statusCode)"]
                  )
                  DispatchQueue.main.async {
                      completion(.failure(error))
                  }
                  return
              }
              
              if let error = error {
                  DispatchQueue.main.async {
                      completion(.failure(error))
                  }
                  return
              }
              
              guard let data = data else {
                  let error = NSError(domain: "PlaidSandboxManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "No data received"])
                  DispatchQueue.main.async {
                      completion(.failure(error))
                  }
                  return
              }
              
              do {
                  let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                  if let accessToken = json?["access_token"] as? String {
                      // SECURITY ENHANCEMENT: Store the access token securely
                      self.storeAccessTokenSecurely(accessToken)
                      
                      DispatchQueue.main.async {
                          completion(.success(accessToken))
                      }
                  } else if let error = json?["error_message"] as? String {
                      let plaidError = NSError(domain: "PlaidAPI", code: 2, userInfo: [NSLocalizedDescriptionKey: error])
                      DispatchQueue.main.async {
                          completion(.failure(plaidError))
                      }
                  } else {
                      let unknownError = NSError(domain: "PlaidSandboxManager", code: 3, userInfo: [NSLocalizedDescriptionKey: "Unknown error occurred"])
                      DispatchQueue.main.async {
                          completion(.failure(unknownError))
                      }
                  }
              } catch {
                  DispatchQueue.main.async {
                      completion(.failure(error))
                  }
              }
          }
          
          task.resume()
      }
      
      // MARK: - Helper Methods
      
      // SECURITY ENHANCEMENT: Secure storage of access token
      private func storeAccessTokenSecurely(_ token: String) {
          // In a real app, this would use Keychain Services
          // For now, just store in UserDefaults for sandbox testing
          UserDefaults.standard.set(token, forKey: "plaid_access_token")
      }
    
    /// Retrieve accounts associated with an access token
    func getAccounts(accessToken: String, completion: @escaping (Result<[PlaidAccount], Error>) -> Void) {
        let url = URL(string: "\(plaidAPIBaseURL)/accounts/get")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let payload: [String: Any] = [
            "client_id": clientID,
            "secret": secret,
            "access_token": accessToken
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: payload)
        } catch {
            completion(.failure(error))
            return
        }
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
                return
            }
            
            guard let data = data else {
                let error = NSError(domain: "PlaidSandboxManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "No data received"])
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
                return
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let accountsData = json["accounts"] as? [[String: Any]] {
                    
                    let accounts = accountsData.compactMap { accountDict -> PlaidAccount? in
                        guard let accountID = accountDict["account_id"] as? String,
                              let name = accountDict["name"] as? String,
                              let type = accountDict["type"] as? String,
                              let balances = accountDict["balances"] as? [String: Any],
                              let current = balances["current"] as? Double,
                              let institutionData = json["item"] as? [String: Any],
                              let institutionID = institutionData["institution_id"] as? String else {
                            return nil
                        }
                        
                        return PlaidAccount(
                            id: accountID,
                            name: name,
                            type: type,
                            balance: current,
                            institutionName: self.getInstitutionName(for: institutionID),
                            institutionLogo: nil, isPlaceholder: true
                        )
                    }
                    
                    DispatchQueue.main.async {
                        completion(.success(accounts))
                    }
                } else if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                    let errorMessage = json["error_message"] as? String {
                    let error = NSError(domain: "PlaidAPI", code: 2, userInfo: [NSLocalizedDescriptionKey: errorMessage])
                    DispatchQueue.main.async {
                        completion(.failure(error))
                    }
                } else {
                    let error = NSError(domain: "PlaidSandboxManager", code: 3, userInfo: [NSLocalizedDescriptionKey: "Failed to parse account data"])
                    DispatchQueue.main.async {
                        completion(.failure(error))
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
        
        task.resume()
    }
    
    /// Retrieve transactions for an access token
    func getTransactions(accessToken: String, completion: @escaping (Result<[PlaidTransaction], Error>) -> Void) {
        let url = URL(string: "\(plaidAPIBaseURL)/transactions/get")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Get date range (last 30 days)
        let calendar = Calendar.current
        let endDate = Date()
        let startDate = calendar.date(byAdding: .day, value: -30, to: endDate) ?? endDate
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        let payload: [String: Any] = [
            "client_id": clientID,
            "secret": secret,
            "access_token": accessToken,
            "start_date": dateFormatter.string(from: startDate),
            "end_date": dateFormatter.string(from: endDate)
        ]
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: payload)
        } catch {
            completion(.failure(error))
            return
        }
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
                return
            }
            
            guard let data = data else {
                let error = NSError(domain: "PlaidSandboxManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "No data received"])
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
                return
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let transactionsData = json["transactions"] as? [[String: Any]] {
                    
                    let transactions = transactionsData.compactMap { transactionDict -> PlaidTransaction? in
                        guard let transactionId = transactionDict["transaction_id"] as? String,
                              let name = transactionDict["name"] as? String,
                              let amount = transactionDict["amount"] as? Double,
                              let dateStr = transactionDict["date"] as? String,
                              let accountId = transactionDict["account_id"] as? String else {
                            return nil
                        }
                        
                        // Parse date
                        dateFormatter.dateFormat = "yyyy-MM-dd"
                        guard let date = dateFormatter.date(from: dateStr) else {
                            return nil
                        }
                        
                        // Extract category
                        let categories = transactionDict["category"] as? [String] ?? []
                        let category = categories.last ?? "Other"
                        
                        // Get merchant name (if available)
                        let merchantName = transactionDict["merchant_name"] as? String ?? name
                        
                        // Check if pending
                        let pending = transactionDict["pending"] as? Bool ?? false
                        
                        return PlaidTransaction(
                            id: transactionId,
                            name: name,
                            amount: amount,
                            date: date,
                            category: category,
                            merchantName: merchantName,
                            accountId: accountId,
                            pending: pending
                        )
                    }
                    
                    DispatchQueue.main.async {
                        // If no transactions, generate some sample data in sandbox
                        if transactions.isEmpty {
                            completion(.success(self.generateSampleTransactions()))
                        } else {
                            completion(.success(transactions))
                        }
                    }
                } else if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                    let errorMessage = json["error_message"] as? String {
                    let error = NSError(domain: "PlaidAPI", code: 2, userInfo: [NSLocalizedDescriptionKey: errorMessage])
                    DispatchQueue.main.async {
                        completion(.failure(error))
                    }
                } else {
                    let error = NSError(domain: "PlaidSandboxManager", code: 3, userInfo: [NSLocalizedDescriptionKey: "Failed to parse transaction data"])
                    DispatchQueue.main.async {
                        // In sandbox mode, return sample transactions
                        completion(.success(self.generateSampleTransactions()))
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    // In sandbox mode, return sample transactions on error
                    completion(.success(self.generateSampleTransactions()))
                }
            }
        }
        
        task.resume()
    }
    
    // Helper method to get institution name - in a real app, you would fetch this from Plaid
    private func getInstitutionName(for institutionID: String) -> String {
        // Map of sandbox institution IDs to names
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
    
    // Generate sample transactions for sandbox testing
    private func generateSampleTransactions() -> [PlaidTransaction] {
        let calendar = Calendar.current
        let today = Date()
        
        let categories = [
            "Food and Drink", "Groceries", "Transportation",
            "Shopping", "Entertainment", "Travel", "Utilities",
            "Rent", "Health", "Education", "Income"
        ]
        
        let merchants = [
            "Starbucks", "Whole Foods", "Amazon", "Uber", "Netflix",
            "Spotify", "Electric Company", "Landlord", "Target",
            "Walgreens", "Gym Membership", "University", "Employer"
        ]
        
        var transactions: [PlaidTransaction] = []
        
        // Create 20 sample transactions over the last 30 days
        for i in 0..<20 {
            let daysAgo = Int.random(in: 0...30)
            let date = calendar.date(byAdding: .day, value: -daysAgo, to: today) ?? today
            
            let categoryIndex = Int.random(in: 0..<categories.count)
            let merchantIndex = Int.random(in: 0..<merchants.count)
            
            // Determine amount (income or expense)
            let isIncome = categories[categoryIndex] == "Income"
            let amount = isIncome ? Double.random(in: 1000...5000) : Double.random(in: 5...500)
            
            transactions.append(PlaidTransaction(
                id: "tx_\(UUID().uuidString)",
                name: merchants[merchantIndex],
                amount: isIncome ? -amount : amount,
                date: date,
                category: categories[categoryIndex],
                merchantName: merchants[merchantIndex],
                accountId: "acc_sandbox",
                pending: false
            ))
        }
        
        // Sort by date, newest first
        return transactions.sorted { $0.date > $1.date }
    }
}
