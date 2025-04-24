//
//  PlaidManager.swift
//  Pennywise
//
//  Updated for Sandbox Mode with robust error handling and thread safety
//

import SwiftUI
import LinkKit
import Combine
import Security

// MARK: - Custom Error Types
enum PlaidError: LocalizedError {
    case linkTokenCreationFailed
    case exchangeTokenFailed(String)
    case accountFetchFailed(String)
    case transactionFetchFailed(String)
    case invalidAccessToken
    case networkError(Error)
    case keychainError(OSStatus)

    var errorDescription: String? {
        switch self {
        
        case .linkTokenCreationFailed:
            return "Failed to initialize Plaid Link. Please try again."
        case .exchangeTokenFailed(let message):
            return "Could not exchange public token: \(message)"
        case .accountFetchFailed(let message):
            return "Could not retrieve accounts: \(message)"
        case .transactionFetchFailed(let message):
            return "Could not retrieve transactions: \(message)"
        case .invalidAccessToken:
            return "Connection expired. Please reconnect your accounts."
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .keychainError(let status):
            return "Security error (Keychain): \(status)"
        }
    }
}

// MARK: - Plaid Models
struct PlaidTransaction: Identifiable, Equatable, Hashable {
    let id: String
    let name: String
    let amount: Double
    let date: Date
    let category: String
    let merchantName: String
    let accountId: String
    let pending: Bool

    // Convert to app's Transaction model
    func toTransaction() -> Transaction {
        let stableId = abs(id.hashValue)
        return Transaction(
            id: stableId,
            title: name,
            amount: amount,
            category: category,
            date: date,
            merchant: merchantName,
            icon: getCategoryIcon(for: category)
        )
    }

    private func getCategoryIcon(for category: String) -> String {
        let c = category.lowercased()
        if c.contains("food") || c.contains("restaurant") { return "fork.knife" }
        if c.contains("shop") || c.contains("store")     { return "cart" }
        if c.contains("transport") || c.contains("travel"){ return "car.fill" }
        if c.contains("entertainment") { return "play.tv" }
        if c.contains("health") || c.contains("medical"){ return "heart.fill" }
        if c.contains("utility") || c.contains("bill") { return "bolt.fill" }
        if c.contains("income") || c.contains("deposit"){ return "arrow.down.circle.fill" }
        return "dollarsign.circle"
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

struct PlaidAccount: Identifiable, Equatable, Hashable {
    let id: String
    let name: String
    let type: String
    let balance: Double
    let institutionName: String
    let institutionLogo: UIImage?
    let isPlaceholder: Bool

    func hash(into hasher: inout Hasher) { hasher.combine(id) }
    static func == (lhs: PlaidAccount, rhs: PlaidAccount) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Plaid Manager


// MARK: - SwiftUI Link Controller
struct LinkController: UIViewControllerRepresentable {
    let handler: Handler

    final class Coordinator: NSObject {
        var parent: LinkController
        init(parent: LinkController) { self.parent = parent }
    }

    func makeCoordinator() -> Coordinator { Coordinator(parent: self) }

    func makeUIViewController(context: Context) -> UIViewController {
        let vc = UIViewController()
        handler.open(presentUsing: .custom { linkVC in
            vc.addChild(linkVC); vc.view.addSubview(linkVC.view)
            linkVC.view.frame = vc.view.bounds; linkVC.didMove(toParent: vc)
        })
        return vc
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        // No-op: SwiftUI handles view updates automatically
    }
}
