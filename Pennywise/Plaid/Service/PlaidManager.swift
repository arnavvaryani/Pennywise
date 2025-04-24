//
//  PlaidManager.swift
//  Pennywise
//
//  Created by Arnav Varyani on 4/24/25.
//

import SwiftUI
import Combine
import LinkKit

class PlaidManager: ObservableObject {
    static let shared = PlaidManager()

    // Published state
    @Published var isLinkPresented = false
    @Published var accounts: [PlaidAccount] = []
    @Published var transactions: [PlaidTransaction] = []
    @Published var budgetCategories: [String: Double] = [:]
    @Published var isLoading = false
    @Published var error: PlaidError?
    @Published var lastRefreshDate: Date?

    // Private
    private let keychainAccessTokenKey = "plaid_access_token"
    private let keychainServiceName = "com.pennywise.plaid"
    private var cancellables = Set<AnyCancellable>()
    private let refreshInterval: TimeInterval = 3600 // 1 hour
    private var timerCancellable: AnyCancellable?

    // Link controller
    private(set) var linkController: LinkController?

    private init() {
        prepareLinkController()
        loadSavedAccounts()
        setupAutoRefresh()
    }

    // MARK: - Keychain Access Token
    private var accessToken: String? {
        get {
            var item: CFTypeRef?
            let query: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: keychainServiceName,
                kSecAttrAccount as String: keychainAccessTokenKey,
                kSecReturnData as String: true
            ]
            let status = SecItemCopyMatching(query as CFDictionary, &item)
            guard status == errSecSuccess,
                  let data = item as? Data,
                  let token = String(data: data, encoding: .utf8)
            else { return nil }
            return token
        }
        set {
            let deleteQuery: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: keychainServiceName,
                kSecAttrAccount as String: keychainAccessTokenKey
            ]
            let delStatus = SecItemDelete(deleteQuery as CFDictionary)
            if delStatus != errSecSuccess && delStatus != errSecItemNotFound {
                DispatchQueue.main.async {
                    self.error = .keychainError(delStatus)
                }
                return
            }
            if let newValue = newValue,
               let valueData = newValue.data(using: .utf8) {
                let addQuery: [String: Any] = [
                    kSecClass as String: kSecClassGenericPassword,
                    kSecAttrService as String: keychainServiceName,
                    kSecAttrAccount as String: keychainAccessTokenKey,
                    kSecValueData as String: valueData
                ]
                let addStatus = SecItemAdd(addQuery as CFDictionary, nil)
                if addStatus != errSecSuccess {
                    DispatchQueue.main.async {
                        self.error = .keychainError(addStatus)
                    }
                }
            }
        }
    }

    // MARK: - Load & Refresh
    private func loadSavedAccounts() {
        guard let token = accessToken else { return }
        fetchAccountDetails(token: token)
    }

    private func setupAutoRefresh() {
        timerCancellable = Timer.publish(every: refreshInterval, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in self?.refreshAllData() }
    }

    func stopAutoRefresh() {
        timerCancellable?.cancel()
    }

    func refreshAllData() {
        guard !isLoading, let token = accessToken else { return }
        fetchTransactions { [weak self] success in
            if success {
                DispatchQueue.main.async { self?.lastRefreshDate = Date() }
            }
        }
    }

    // MARK: - Public Methods
    func exchangePublicToken(publicToken: String) {
        DispatchQueue.main.async { self.isLoading = true; self.error = nil }
        PlaidSandboxManager.shared.exchangePublicToken(publicToken) { [weak self] result in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.isLoading = false
                switch result {
                case .success(let token):
                    self.accessToken = token
                    self.fetchAccountDetails(token: token)
                    self.fetchTransactions()
                case .failure(let err):
                    self.error = .exchangeTokenFailed(err.localizedDescription)
                    self.linkController = nil
                    self.isLinkPresented = false
                }
            }
        }
    }

    func prepareLinkController() {
        prepareLinkForPresentation { _ in }
    }

    func presentLink() {
        if linkController == nil { prepareLinkController() }
        DispatchQueue.main.async { self.isLinkPresented = true }
    }

    func fetchAccountDetails(token: String) {
        DispatchQueue.main.async { self.isLoading = true; self.error = nil }
        PlaidSandboxManager.shared.getAccounts(accessToken: token) { [weak self] result in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.isLoading = false
                switch result {
                case .success(let apiAccounts):
                    self.accounts.removeAll(where: { $0.isPlaceholder })
                    let wrapped = apiAccounts.map { acc in
                        PlaidAccount(id: acc.id,
                                     name: acc.name,
                                     type: acc.type,
                                     balance: acc.balance,
                                     institutionName: acc.institutionName,
                                     institutionLogo: acc.institutionLogo,
                                     isPlaceholder: false)
                    }
                    self.accounts.append(contentsOf: wrapped)
                    UserDefaults.standard.set(!wrapped.isEmpty, forKey: "hasLinkedPlaidAccount")
                case .failure(let err):
                    self.error = .accountFetchFailed(err.localizedDescription)
                }
            }
        }
    }

    func fetchTransactions(completion: ((Bool) -> Void)? = nil) {
        guard let token = accessToken else {
            DispatchQueue.main.async { self.error = .invalidAccessToken }
            completion?(false); return
        }
        DispatchQueue.main.async { self.isLoading = true }
        PlaidSandboxManager.shared.getTransactions(accessToken: token) { [weak self] result in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.isLoading = false
                switch result {
                case .success(let txs):
                    self.transactions = txs
                    self.calculateBudgetCategories(from: txs)
                    completion?(true)
                case .failure(let err):
                    self.error = .transactionFetchFailed(err.localizedDescription)
                    completion?(false)
                }
            }
        }
    }

    private func calculateBudgetCategories(from txs: [PlaidTransaction]) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            var catTotals: [String: Double] = [:]
            txs.forEach { t in
                catTotals[t.category, default: 0] += abs(t.amount)
            }
            DispatchQueue.main.async { self.budgetCategories = catTotals }
        }
    }

    func getMonthlyFinancialData() -> [MonthlyFinancialData] {
        let cal = Calendar.current
        let now = Date()
        var data: [MonthlyFinancialData] = []
        for offset in 0..<6 {
            guard let monthStart = cal.date(byAdding: .month, value: -offset, to: now) else { continue }
            let month = String(DateFormatter().shortMonthSymbols[cal.component(.month, from: monthStart)-1])
            let end = cal.date(byAdding: DateComponents(month: 1, day: -1), to: monthStart) ?? now
            let monthTx = transactions.filter { $0.date >= monthStart && $0.date <= end }
            let income = monthTx.filter { $0.amount < 0 }.reduce(0) { $0 + abs($1.amount) }
            let expenses = monthTx.filter { $0.amount > 0 }.reduce(0) { $0 + $1.amount }
            data.append(MonthlyFinancialData(month: month, income: income, expenses: expenses))
        }
        return data.reversed()
    }

    func transactions(for accountId: String) -> [PlaidTransaction] {
        transactions.filter { $0.accountId == accountId }
    }

    func getBudgetCategories() -> [BudgetCategory] {
        var list: [BudgetCategory] = []
        let colors: [Color] = [AppTheme.primaryGreen, AppTheme.accentBlue, AppTheme.accentPurple]
        let icons = ["fork.knife","cart.fill","car.fill","play.fill","heart.fill","bolt.fill"]
        for (idx, (cat, amt)) in budgetCategories.enumerated() {
            list.append(BudgetCategory(
                name: cat,
                amount: amt,
                icon: icons[idx % icons.count],
                color: colors[idx % colors.count]
            ))
        }
        return list
    }

    // MARK: - Link Presentation
    func prepareLinkForPresentation(completion: @escaping (Bool) -> Void) {
        DispatchQueue.main.async { self.isLoading = true; self.error = nil }
        PlaidSandboxManager.shared.createLinkToken { [weak self] result in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.isLoading = false
                switch result {
                case .success(let token):
                    UserDefaults.standard.set(token, forKey: "plaid_link_token")
                    let config = self.buildLinkConfig(token: token)
                    switch Plaid.create(config) {
                    case .success(let handler):
                        self.linkController = LinkController(handler: handler)
                        completion(true)
                    case .failure:
                        self.error = .linkTokenCreationFailed
                        completion(false)
                    }
                case .failure:
                    self.error = .linkTokenCreationFailed
                    completion(false)
                }
            }
        }
    }

    private func buildLinkConfig(token: String) -> LinkTokenConfiguration {
        var cfg = LinkTokenConfiguration(token: token) { [weak self] success in
            guard let self = self else { return }
            self.exchangePublicToken(publicToken: success.publicToken)
            let meta = success.metadata.institution
            let placeholder = PlaidAccount(id: UUID().uuidString,
                                           name: meta.name,
                                           type: "Bank",
                                           balance: 0,
                                           institutionName: meta.name,
                                           institutionLogo: nil,
                                           isPlaceholder: true)
            DispatchQueue.main.async {
                self.accounts.append(placeholder)
                self.isLinkPresented = false
            }
        }
        cfg.onExit = { [weak self] exit in
            DispatchQueue.main.async {
                if let err = exit.error { self?.error = .networkError(err) }
                self?.isLinkPresented = false
            }
        }
        cfg.onEvent = { evt in print("Plaid event: \(evt.eventName)") }
        return cfg
    }

    // MARK: - Disconnect
    func disconnectAllAccounts() {
        accessToken = nil
        accounts.removeAll(); transactions.removeAll(); budgetCategories.removeAll()
        UserDefaults.standard.set(false, forKey: "hasLinkedPlaidAccount")
    }

    func disconnectAccount(with id: String) {
        accounts.removeAll { $0.id == id }
        transactions.removeAll { $0.accountId == id }
        calculateBudgetCategories(from: transactions)
        if accounts.isEmpty { UserDefaults.standard.set(false, forKey: "hasLinkedPlaidAccount") }
    }
}
