////
////  MockAuthenticationService.swift
////  Pennywise
////
////  Created by Arnav Varyani on 4/25/25.
////
//
//
//import Foundation
//import LocalAuthentication
//import Combine
//import SwiftUI
//import LinkKit
//// MARK: - Authentication Mocks
//
//class MockAuthenticationService: ObservableObject {
//    @Published var user: MockUser?
//    @Published var isAuthenticated = false
//    @Published var authError: Error?
//    @Published var isLoading = false
//    
//    // User preferences
//    @Published var biometricAuthEnabled = true
//    @Published var requireBiometricsOnOpen = true
//    @Published var requireBiometricsForTransactions = false
//    
//    // Mock authentication methods
//    func signInWithEmail(email: String, password: String, completion: @escaping (Result<MockUser, Error>) -> Void) {
//        isLoading = true
//        
//        // Simulate network delay
//        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
//            guard let self = self else { return }
//            self.isLoading = false
//            
//            // Valid credentials check
//            if email == "test@example.com" && password == "Password123" {
//                let user = MockUser(uid: "test_user_id", email: email, displayName: "Test User")
//                self.user = user
//                self.isAuthenticated = true
//                completion(.success(user))
//            } else {
//                let error = NSError(domain: "Authentication", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid email or password"])
//                self.authError = error
//                completion(.failure(error))
//            }
//        }
//    }
//    
//    func signUpWithEmail(email: String, password: String, completion: @escaping (Result<MockUser, Error>) -> Void) {
//        isLoading = true
//        
//        // Simulate network delay
//        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
//            guard let self = self else { return }
//            self.isLoading = false
//            
//            // Valid format check
//            if !self.isEmailValid(email) {
//                let error = NSError(domain: "Authentication", code: 2, userInfo: [NSLocalizedDescriptionKey: "Invalid email format"])
//                self.authError = error
//                completion(.failure(error))
//                return
//            }
//            
//            if !self.isPasswordValid(password) {
//                let error = NSError(domain: "Authentication", code: 3, userInfo: [NSLocalizedDescriptionKey: "Password must be at least 8 characters with uppercase, lowercase and numbers"])
//                self.authError = error
//                completion(.failure(error))
//                return
//            }
//            
//            // Create user
//            let user = MockUser(uid: "test_user_id", email: email, displayName: "New User")
//            self.user = user
//            self.isAuthenticated = true
//            completion(.success(user))
//        }
//    }
//    
//    func signOut() {
//        user = nil
//        isAuthenticated = false
//    }
//    
//    func authenticateWithBiometrics(reason: String = "Verify your identity", completion: @escaping (Bool, Error?) -> Void) {
//        // Simulate biometric authentication success
//        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
//            UserDefaults.standard.set(true, forKey: "hasPassedBiometricCheck")
//            completion(true, nil)
//        }
//    }
//    
//    
//    func shouldRequireBiometricAuth() -> Bool {
//        // Check if biometrics are enabled in settings and the user hasn't passed the check yet
//        if biometricAuthEnabled && requireBiometricsOnOpen {
//            let hasPassedCheck = UserDefaults.standard.bool(forKey: "hasPassedBiometricCheck")
//            return !hasPassedCheck
//        }
//        return false
//    }
//    
//    func resetBiometricCheck() {
//        if requireBiometricsOnOpen {
//            UserDefaults.standard.set(false, forKey: "hasPassedBiometricCheck")
//        }
//    }
//    
//    // Validation methods
//    func isPasswordValid(_ password: String) -> Bool {
//        // Password should be at least 8 characters with at least one uppercase, one lowercase, and one number
//        let passwordRegEx = "^(?=.*[a-z])(?=.*[A-Z])(?=.*\\d)[a-zA-Z\\d]{8,}$"
//        let passwordPred = NSPredicate(format: "SELF MATCHES %@", passwordRegEx)
//        return passwordPred.evaluate(with: password)
//    }
//    
//    func isEmailValid(_ email: String) -> Bool {
//        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
//        let emailPred = NSPredicate(format: "SELF MATCHES %@", emailRegEx)
//        return emailPred.evaluate(with: email)
//    }
//}
//
//// Mock Firebase User
//class MockUser {
//    let uid: String
//    let email: String?
//    var displayName: String?
//    var photoURL: URL?
//    let metadata: MockUserMetadata
//    
//    init(uid: String, email: String?, displayName: String? = nil, photoURL: URL? = nil) {
//        self.uid = uid
//        self.email = email
//        self.displayName = displayName
//        self.photoURL = photoURL
//        self.metadata = MockUserMetadata()
//    }
//    
//    func createProfileChangeRequest() -> MockUserProfileChangeRequest {
//        return MockUserProfileChangeRequest(user: self)
//    }
//}
//
//// Mock User Metadata
//class MockUserMetadata {
//    let creationDate: Date
//    let lastSignInDate: Date
//    
//    init() {
//        creationDate = Date().addingTimeInterval(-30 * 24 * 60 * 60) // 30 days ago
//        lastSignInDate = Date().addingTimeInterval(-24 * 60 * 60) // 1 day ago
//    }
//}
//
//// Mock Profile Change Request
//class MockUserProfileChangeRequest {
//    weak var user: MockUser?
//    var displayName: String?
//    var photoURL: URL?
//    
//    init(user: MockUser) {
//        self.user = user
//    }
//    
//    func commitChanges(completion: ((Error?) -> Void)?) {
//        // Apply changes
//        if let displayName = displayName {
//            user?.displayName = displayName
//        }
//        
//        if let photoURL = photoURL {
//            user?.photoURL = photoURL
//        }
//        
//        // Simulate async operation
//        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
//            completion?(nil)
//        }
//    }
//}
//
//// MARK: - Plaid Mocks
//
//class MockPlaidManager: ObservableObject {
//    @Published var isLinkPresented = false
//    @Published var accounts: [PlaidAccount] = []
//    @Published var transactions: [PlaidTransaction] = []
//    @Published var budgetCategories: [String: Double] = [:]
//    @Published var isLoading = false
//    @Published var error: Error?
//    @Published var lastRefreshDate: Date?
//    
//    var linkController: LinkController?
//    
//    init() {
//        // Initialize with sample data
//        loadSampleData()
//    }
//    
//    func loadSampleData() {
//        // Sample accounts
//        accounts = [
//            PlaidAccount(id: "acc1", name: "Checking", type: "depository", balance: 1250.65, institutionName: "Sample Bank", institutionLogo: nil, isPlaceholder: false),
//            PlaidAccount(id: "acc2", name: "Savings", type: "depository", balance: 5432.10, institutionName: "Sample Bank", institutionLogo: nil, isPlaceholder: false),
//            PlaidAccount(id: "acc3", name: "Credit Card", type: "credit", balance: -320.45, institutionName: "Sample Credit", institutionLogo: nil, isPlaceholder: false)
//        ]
//        
//        // Generate sample transactions
//        let calendar = Calendar.current
//        let today = Date()
//        
//        var sampleTransactions: [PlaidTransaction] = []
//        
//        for i in 0..<30 {
//            let daysAgo = i
//            let date = calendar.date(byAdding: .day, value: -daysAgo, to: today) ?? today
//            
//            let categories = ["Groceries", "Dining", "Transportation", "Entertainment", "Shopping", "Utilities", "Income"]
//            let merchants = ["Grocery Store", "Restaurant", "Gas Station", "Movie Theater", "Department Store", "Utility Company", "Employer"]
//            
//            let categoryIndex = Int.random(in: 0..<categories.count)
//            let category = categories[categoryIndex]
//            let merchant = merchants[categoryIndex]
//            
//            // Income or expense
//            let isIncome = category == "Income"
//            let amount = isIncome ? -Double.random(in: 1000...3000) : Double.random(in: 10...200)
//            
//            let transaction = PlaidTransaction(
//                id: "tx\(i)",
//                name: "\(merchant) Transaction",
//                amount: amount,
//                date: date,
//                category: category,
//                merchantName: merchant,
//                accountId: accounts[Int.random(in: 0..<accounts.count)].id,
//                pending: false
//            )
//            
//            sampleTransactions.append(transaction)
//        }
//        
//        transactions = sampleTransactions
//        
//        // Calculate budget categories
//        calculateBudgetCategories(from: transactions)
//    }
//    
//    private func calculateBudgetCategories(from txs: [PlaidTransaction]) {
//        var catTotals: [String: Double] = [:]
//        txs.forEach { t in
//            if t.amount > 0 { // Only expenses
//                catTotals[t.category, default: 0] += t.amount
//            }
//        }
//        budgetCategories = catTotals
//    }
//    
//    func getBudgetCategories() -> [BudgetCategory] {
//        var list: [BudgetCategory] = []
//        let colors: [Color] = [AppTheme.primaryGreen, AppTheme.accentBlue, AppTheme.accentPurple]
//        let icons = ["fork.knife", "cart.fill", "car.fill", "play.fill", "heart.fill", "bolt.fill"]
//        
//        for (idx, (cat, amt)) in budgetCategories.enumerated() {
//            list.append(BudgetCategory(
//                name: cat,
//                amount: amt,
//                icon: icons[idx % icons.count],
//                color: colors[idx % colors.count]
//            ))
//        }
//        return list
//    }
//    
//    func getMonthlyFinancialData() -> [MonthlyFinancialData] {
//        let calendar = Calendar.current
//        let now = Date()
//        var data: [MonthlyFinancialData] = []
//        
//        for offset in 0..<6 {
//            guard let monthStart = calendar.date(byAdding: .month, value: -offset, to: now) else { continue }
//            
//            let monthFormatter = DateFormatter()
//            monthFormatter.dateFormat = "MMM"
//            let month = monthFormatter.string(from: monthStart)
//            
//            let monthEnd = calendar.date(byAdding: .month, value: 1, to: monthStart)!
//                .addingTimeInterval(-1)
//            
//            let monthTransactions = transactions.filter { 
//                $0.date >= monthStart && $0.date <= monthEnd
//            }
//            
//            let income = abs(monthTransactions.filter { $0.amount < 0 }.reduce(0) { $0 + $1.amount })
//            let expenses = monthTransactions.filter { $0.amount > 0 }.reduce(0) { $0 + $1.amount }
//            
//            data.append(MonthlyFinancialData(month: month, income: income, expenses: expenses))
//        }
//        
//        return data.reversed()
//    }
//    
//    func transactions(for accountId: String) -> [PlaidTransaction] {
//        return transactions.filter { $0.accountId == accountId }
//    }
//    
//    func fetchTransactions(completion: ((Bool) -> Void)? = nil) {
//        isLoading = true
//        
//        // Simulate network request
//        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
//            guard let self = self else { return }
//            self.isLoading = false
//            
//            // We already have sample data from initialization
//            completion?(true)
//        }
//    }
//    
//    func presentLink() {
//        isLinkPresented = true
//    }
//    
//    func prepareLinkController() {
//        // Mock implementation does nothing, but would prepare link controller in real app
//    }
//    
//    func prepareLinkForPresentation(completion: @escaping (Bool) -> Void) {
//        // Simulate success
//        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
//            completion(true)
//        }
//    }
//    
//    func disconnectAllAccounts() {
//        accounts = []
//        transactions = []
//        budgetCategories = [:]
//    }
//    
//    func disconnectAccount(with id: String) {
//        accounts.removeAll { $0.id == id }
//        transactions.removeAll { $0.accountId == id }
//        calculateBudgetCategories(from: transactions)
//    }
//}
//
//// MARK: - Firestore Mocks
//
//class MockFirestoreManager: ObservableObject {
//    // Published properties for reactive updates
//    @Published var accounts: [PlaidAccount] = []
//    @Published var transactions: [PlaidTransaction] = []
//    @Published var budgetCategories: [BudgetCategory] = []
//    @Published var error: Error?
//    
//    // Current user ID
//    private var userId: String? = "mock_user_id"
//    
//    func syncAccounts(_ accounts: [PlaidAccount], completion: @escaping (Bool) -> Void) {
//        // Simulate network delay
//        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
//            guard let self = self else {
//                completion(false)
//                return
//            }
//            
//            self.accounts = accounts
//            completion(true)
//        }
//    }
//    
//    func syncTransactions(_ transactions: [PlaidTransaction], completion: @escaping (Bool) -> Void) {
//        // Simulate network delay
//        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) { [weak self] in
//            guard let self = self else {
//                completion(false)
//                return
//            }
//            
//            self.transactions = transactions
//            completion(true)
//        }
//    }
//    
//    func saveBudgetCategory(_ category: BudgetCategory, completion: @escaping (Bool) -> Void) {
//        // Simulate network delay
//        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
//            guard let self = self else {
//                completion(false)
//                return
//            }
//            
//            // Check if category exists
//            if let index = self.budgetCategories.firstIndex(where: { $0.name == category.name }) {
//                self.budgetCategories[index] = category
//            } else {
//                self.budgetCategories.append(category)
//            }
//            
//            completion(true)
//        }
//    }
//    
//    func loadBudgetCategories(completion: @escaping ([BudgetCategory]) -> Void) {
//        // Simulate network delay
//        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
//            guard let self = self else {
//                completion([])
//                return
//            }
//            
//            completion(self.budgetCategories)
//        }
//    }
//    
//    func updateBudgetUsage(completion: @escaping (Bool) -> Void) {
//        // Simulate success after delay
//        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
//            completion(true)
//        }
//    }
//}
//
//// MARK: - Mock PlaidFirestoreSync
//
//class MockPlaidFirestoreSync: ObservableObject {
//    static let shared = MockPlaidFirestoreSync()
//    
//    @Published var isSyncing = false
//    @Published var lastSyncTime: Date?
//    @Published var syncError: Error?
//    @Published var syncProgress: Float = 0
//    
//    private init() {}
//    
//    func startSyncTimer() {
//        // Does nothing in mock
//    }
//    
//    func stopSyncTimer() {
//        // Does nothing in mock
//    }
//    
//    func forceSyncNow(completion: ((Bool) -> Void)? = nil) {
//        isSyncing = true
//        syncProgress = 0
//        
//        // Simulate sync progress
//        let timer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { [weak self] timer in
//            guard let self = self else {
//                timer.invalidate()
//                return
//            }
//            
//            self.syncProgress += 0.1
//            
//            if self.syncProgress >= 1.0 {
//                timer.invalidate()
//                self.isSyncing = false
//                self.lastSyncTime = Date()
//                completion?(true)
//            }
//        }
//        timer.fire()
//    }
//    
//    func performFullSync(completion: ((Bool) -> Void)? = nil) {
//        forceSyncNow(completion: completion)
//    }
//    
//    func syncAccountsToFirestore(completion: ((Bool) -> Void)? = nil) {
//        // Simulate success
//        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
//            completion?(true)
//        }
//    }
//    
//    func syncTransactionsToFirestore(completion: ((Bool) -> Void)? = nil) {
//        // Simulate success
//        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
//            completion?(true)
//        }
//    }
//    
//    func updateTransactionDetails(transaction: PlaidTransaction, notes: String? = nil, tags: [String]? = nil, isHidden: Bool? = nil, completion: @escaping (Bool) -> Void) {
//        // Simulate success
//        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
//            completion(true)
//        }
//    }
//    
//    func updateTransactionCategory(transaction: PlaidTransaction, newCategory: String, completion: @escaping (Bool) -> Void) {
//        // Simulate success
//        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
//            completion(true)
//        }
//    }
//}
//
//// MARK: - UI Testing Support
//
//extension XCUIApplication {
//    // Login with test credentials
//    func loginWithTestCredentials() {
//        let emailField = self.textFields["Email"]
//        let passwordField = self.secureTextFields["Password"]
//        let loginButton = self.buttons["Login"]
//        
//        if emailField.exists && passwordField.exists && loginButton.exists {
//            emailField.tap()
//            emailField.typeText("test@example.com")
//            
//            passwordField.tap()
//            passwordField.typeText("Password123")
//            
//            loginButton.tap()
//        }
//    }
//    
//    // Skip onboarding
//    func skipOnboarding() {
//        let skipButton = self.buttons["Skip"]
//        let getStartedButton = self.buttons["Get Started"]
//        
//        if skipButton.exists {
//            skipButton.tap()
//        } else if getStartedButton.exists {
//            getStartedButton.tap()
//        }
//    }
//    
//    // Navigate to a specific tab
//    func navigateToTab(_ tabName: String) {
//        let tabBar = self.tabBars.firstMatch
//        if tabBar.exists {
//            tabBar.buttons[tabName].tap()
//        }
//    }
//}
