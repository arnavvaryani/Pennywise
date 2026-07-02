//
//  DependencyContainer.swift
//  Pennywise
//
//  Dependency Injection Container
//

import Foundation
import UIKit
import LinkKit

/// Dependency Injection Container
/// Creates and manages all dependencies for the application
@MainActor
public final class DependencyContainer {
    // MARK: - Singleton
    public static let shared = DependencyContainer()
    
    private init() {}
    
    // MARK: - Services (Created once, lazy)
    
    private lazy var firebaseAuthService: FirebaseAuthService = {
        FirebaseAuthService()
    }()
    
    private lazy var firestoreService: FirestoreService = {
        FirestoreService()
    }()
    
    private lazy var plaidAPIService: PlaidAPIService = {
        PlaidAPIService()
    }()
    
    /// Internal accessor for Plaid-specific features not exposed via the domain protocol
    internal var plaidService: PlaidAPIService { plaidAPIService }
    internal var firestore: FirestoreService { firestoreService }
    
    // MARK: - Repositories (Created once, lazy)
    
    public lazy var authRepository: AuthRepository = {
        AuthRepositoryImpl(
            authService: firebaseAuthService,
            firestoreService: firestoreService,
            plaidService: plaidAPIService
        )
    }()
    
    public lazy var userRepository: UserRepository = {
        UserRepositoryImpl(firestoreService: firestoreService)
    }()
    
    public lazy var transactionRepository: TransactionRepository = {
        TransactionRepositoryImpl(
            plaidService: plaidAPIService,
            firestoreService: firestoreService
        )
    }()
    
    public lazy var accountRepository: AccountRepository = {
        AccountRepositoryImpl(
            plaidService: plaidAPIService,
            firestoreService: firestoreService,
            transactionRepository: transactionRepository
        )
    }()
    
    public lazy var budgetRepository: BudgetRepository = {
        BudgetRepositoryImpl(firestoreService: firestoreService)
    }()
    
    public lazy var plaidRepository: PlaidRepository = {
        PlaidRepositoryImpl(plaidService: plaidAPIService)
    }()
    
    // MARK: - Use Cases (Created on demand)
    
    // Auth Use Cases
    public func makeLoginUseCase() -> LoginUseCase {
        LoginUseCase(authRepository: authRepository)
    }
    
    public func makeSignUpUseCase() -> SignUpUseCase {
        SignUpUseCase(authRepository: authRepository)
    }
    
    public func makeLogoutUseCase() -> LogoutUseCase {
        LogoutUseCase(authRepository: authRepository)
    }
    
    // Transaction Use Cases
    public func makeFetchTransactionsUseCase() -> FetchTransactionsUseCase {
        FetchTransactionsUseCase(
            transactionRepository: transactionRepository,
            accountRepository: accountRepository
        )
    }
    
    public func makeAddTransactionUseCase() -> AddTransactionUseCase {
        AddTransactionUseCase(transactionRepository: transactionRepository)
    }
    
    public func makeSyncTransactionsUseCase() -> SyncTransactionsUseCase {
        SyncTransactionsUseCase(
            transactionRepository: transactionRepository,
            accountRepository: accountRepository
        )
    }
    
    // Budget Use Cases
    public func makeFetchBudgetUseCase() -> FetchBudgetUseCase {
        FetchBudgetUseCase(
            budgetRepository: budgetRepository,
            transactionRepository: transactionRepository
        )
    }
    
    public func makeAddBudgetCategoryUseCase() -> AddBudgetCategoryUseCase {
        AddBudgetCategoryUseCase(budgetRepository: budgetRepository)
    }
    
    public func makeDeleteBudgetCategoryUseCase() -> DeleteBudgetCategoryUseCase {
        DeleteBudgetCategoryUseCase(budgetRepository: budgetRepository)
    }
    
    public func makeUpdateBudgetCategoryUseCase() -> UpdateBudgetCategoryUseCase {
        UpdateBudgetCategoryUseCase(budgetRepository: budgetRepository)
    }
    
    public func makeCreateAutoBudgetUseCase() -> CreateAutoBudgetUseCase {
        CreateAutoBudgetUseCase(budgetRepository: budgetRepository, userRepository: userRepository)
    }
    
    public func makeUpdateProfileUseCase() -> UpdateProfileUseCase {
        UpdateProfileUseCase(userRepository: userRepository)
    }
    
    public func makeExportDataUseCase() -> ExportDataUseCase {
        ExportDataUseCase(
            transactionRepository: transactionRepository,
            budgetRepository: budgetRepository,
            accountRepository: accountRepository
        )
    }
    
    // MARK: - ViewModels (Created on demand)
    
    // Auth ViewModels
    public func makeLoginViewModel() -> LoginViewModel {
        LoginViewModel(
            loginUseCase: makeLoginUseCase(),
            signUpUseCase: makeSignUpUseCase(),
            authRepository: authRepository
        )
    }
    
    public func makeBiometricViewModel() -> BiometricViewModel {
        BiometricViewModel(authRepository: authRepository)
    }
    
    // Home ViewModels
    public func makeHomeViewModel() -> HomeViewModel {
        HomeViewModel(
            fetchTransactionsUseCase: makeFetchTransactionsUseCase(),
            addTransactionUseCase: makeAddTransactionUseCase(),
            syncTransactionsUseCase: makeSyncTransactionsUseCase(),
            authRepository: authRepository,
            plaidRepository: plaidRepository
        )
    }
    
    // Budget ViewModels
    public func makeBudgetViewModel() -> BudgetViewModel {
        BudgetViewModel(
            fetchBudgetUseCase: makeFetchBudgetUseCase(),
            addBudgetCategoryUseCase: makeAddBudgetCategoryUseCase(),
            deleteBudgetCategoryUseCase: makeDeleteBudgetCategoryUseCase(),
            updateBudgetCategoryUseCase: makeUpdateBudgetCategoryUseCase(),
            createAutoBudgetUseCase: makeCreateAutoBudgetUseCase(),
            userRepository: userRepository
        )
    }
    
    // Insights ViewModels
    public func makeInsightsViewModel() -> InsightsViewModel {
        InsightsViewModel(
            fetchInsightsUseCase: FetchInsightsUseCase(
                transactionRepository: transactionRepository,
                budgetRepository: budgetRepository
            ),
            plaidRepository: plaidRepository
        )
    }
    
    // Settings ViewModels
    public func makeSettingsViewModel() -> SettingsViewModel {
        SettingsViewModel(
            authRepository: authRepository,
            userRepository: userRepository,
            accountRepository: accountRepository,
            updateProfileUseCase: makeUpdateProfileUseCase(),
            exportDataUseCase: makeExportDataUseCase(),
            logoutUseCase: makeLogoutUseCase()
        )
    }
    
    // MARK: - Helper Methods
    
    /// Get Plaid link controller for presentation
    internal func getPlaidLinkController() -> UIViewController? {
        // LinkKit Handler conforms to UIViewController, so this cast is safe
        guard let handler = plaidAPIService.linkController else { return nil }
        return handler as? UIViewController
    }
    
    /// Prepare Plaid link
    public func preparePlaidLink() async throws {
        try await plaidRepository.preparePlaidLink()
    }
}

