//
//  NewAppCoordinator.swift
//  Pennywise
//
//  Clean Architecture App Coordinator
//

import SwiftUI
import Combine

@MainActor
struct NewAppCoordinator: View {
    // Dependency container
    private let container = DependencyContainer.shared
    
    // State
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage("hasSkippedPlaidLink") private var hasSkippedPlaidLink = false
    @AppStorage("requireBiometricsOnOpen") private var requireBiometricsOnOpen = false
    @State private var showBiometricAuth = false
    @State private var isPlaidLinked = false
    @State private var showPlaidOnboarding = false
    /// Mirrors auth state so the view re-renders when Firebase auth changes (e.g. after sign up).
    @State private var isAuthenticated = false
    
    // ViewModels
    @State private var homeViewModel: HomeViewModel
    @State private var budgetViewModel: BudgetViewModel
    @State private var insightsViewModel: InsightsViewModel
    @State private var settingsViewModel: SettingsViewModel
    @State private var loginViewModel: LoginViewModel
    @State private var biometricViewModel: BiometricViewModel
    @StateObject private var navigationManager = NavigationManager()
    
    init() {
        let container = DependencyContainer.shared
        _homeViewModel = State(initialValue: container.makeHomeViewModel())
        _budgetViewModel = State(initialValue: container.makeBudgetViewModel())
        _insightsViewModel = State(initialValue: container.makeInsightsViewModel())
        _settingsViewModel = State(initialValue: container.makeSettingsViewModel())
        _loginViewModel = State(initialValue: container.makeLoginViewModel())
        _biometricViewModel = State(initialValue: container.makeBiometricViewModel())
    }
    
    var body: some View {
        Group {
            if !hasCompletedOnboarding {
                FinanceOnboardingView()
            } else if !isAuthenticated {
                FinanceLoginView(viewModel: loginViewModel)
            } else if showBiometricAuth {
                BiometricAuthenticationView(
                    viewModel: biometricViewModel,
                    isPresented: $showBiometricAuth,
                    onSignOut: {
                        do {
                            try container.authRepository.signOut()
                        } catch {
                            // Keep UI stable; auth publisher will drive the coordinator.
                            print("Sign out failed: \(error)")
                        }
                    }
                )
            } else if showPlaidOnboarding {
                PlaidOnboardingView(isPresented: $showPlaidOnboarding)
                    .task {
                        try? await container.preparePlaidLink()
                    }
            } else {
                mainTabView
                    .environmentObject(navigationManager)
            }
        }
        .onAppear {
            isAuthenticated = container.authRepository.isAuthenticated
            isPlaidLinked = container.plaidRepository.isPlaidLinked
            showPlaidOnboarding = container.authRepository.isAuthenticated && !isPlaidLinked && !hasSkippedPlaidLink
            checkBiometricRequirement()
        }
        .onReceive(container.authRepository.isAuthenticatedPublisher) { newValue in
            isAuthenticated = newValue
            isPlaidLinked = container.plaidRepository.isPlaidLinked
            showPlaidOnboarding = newValue && !isPlaidLinked && !hasSkippedPlaidLink
        }
        .onReceive(NotificationCenter.default.publisher(for: PlaidNotifications.linkedStateChanged)) { _ in
            isPlaidLinked = container.plaidRepository.isPlaidLinked
            showPlaidOnboarding = container.authRepository.isAuthenticated && !isPlaidLinked && !hasSkippedPlaidLink
        }
        .task {
            // Load initial data when authenticated
            if container.authRepository.isAuthenticated {
                // One-time cleanup: older builds accumulated duplicate sandbox
                // transactions in the remote cache, which made totals wrong.
                // Reset the sync once to purge them and re-fetch fresh.
                if !UserDefaults.standard.bool(forKey: "didResetLegacySync_v2") {
                    try? await container.transactionRepository.resetSync()
                    UserDefaults.standard.set(true, forKey: "didResetLegacySync_v2")
                }
                await homeViewModel.loadData()
                try? await container.preparePlaidLink()
            }
        }
    }
    
    private var mainTabView: some View {
        TabView(selection: $navigationManager.selectedTab) {
            // Home Tab
            NavigationStack(path: $navigationManager.homePath) {
                FinanceHomeView(viewModel: homeViewModel)
                    .navigationDestination(for: AppRoute.self) { route in
                        destinationView(for: route)
                    }
            }
            .tag(0)
            .tabItem {
                Label("Home", systemImage: "house.fill")
            }
            
            // Budget Tab
            NavigationStack(path: $navigationManager.budgetPath) {
                BudgetPlannerView(viewModel: budgetViewModel)
                    .navigationDestination(for: AppRoute.self) { route in
                        destinationView(for: route)
                    }
            }
            .tag(1)
            .tabItem {
                Label("Budget", systemImage: "chart.pie.fill")
            }
            
            // Insights Tab
            NavigationStack(path: $navigationManager.insightsPath) {
                InsightsView(viewModel: insightsViewModel)
                    .navigationDestination(for: AppRoute.self) { route in
                        destinationView(for: route)
                    }
            }
            .tag(2)
            .tabItem {
                Label("Insights", systemImage: "chart.bar.fill")
            }
            
            // Settings Tab
            NavigationStack(path: $navigationManager.settingsPath) {
                SettingsView(viewModel: settingsViewModel)
                    .navigationDestination(for: AppRoute.self) { route in
                        destinationView(for: route)
                    }
            }
            .tag(3)
            .tabItem {
                Label("Settings", systemImage: "gearshape.fill")
            }
        }
        .tint(AppTheme.primaryGreen)
        .environmentObject(navigationManager)
    }
    
    @ViewBuilder
    private func destinationView(for route: AppRoute) -> some View {
        switch route {
        case .profile:
            ProfileView(viewModel: settingsViewModel)
        case .transactionDetail(let transaction):
            TransactionDetailView(transaction: transaction)
        case .manualTransaction:
            ManualTransactionView(viewModel: homeViewModel)
        case .addBudgetCategory:
            AddBudgetCategoryView(onAdd: { category in
                Task {
                    await budgetViewModel.addCategory(
                        name: category.name.trimmingCharacters(in: .whitespacesAndNewlines),
                        amount: category.amount,
                        icon: category.icon,
                        colorHex: category.colorHex,
                        isEssential: category.isEssential
                    )
                }
            }, monthlyIncome: budgetViewModel.monthlyIncome)
        case .categoryInsights(let category):
            CategoryInsightsView(category: category)
        case .categoryMapping(let category):
            CategoryMappingEditorView(budgetCategory: category)
        case .budgetInsights(let category):
            CategoryInsightsView(
                category: category,
                insights: budgetViewModel.getInsights(for: category),
                spent: budgetViewModel.categorySpending[category.id] ?? 0.0,
                transactions: []
            )
            .navigationTitle("Insights")
            .navigationBarTitleDisplayMode(.inline)
            
        case .allTransactions(let transactions):
            AllTransactionsView(transactions: transactions)
                .navigationTitle("Transactions")
                .navigationBarTitleDisplayMode(.inline)
                
        case .accountDetail(let account):
            AccountDetailView(account: account)
                .navigationTitle(account.name)
                .navigationBarTitleDisplayMode(.inline)
        case .changePassword:
            ChangePasswordView(viewModel: settingsViewModel)
        case .deleteAccount:
            DeleteAccountView(viewModel: settingsViewModel)
        case .editProfile:
            EditProfileView(viewModel: settingsViewModel)
        case .about:
            AboutView()
        case .exportData:
            ExportDataView(viewModel: settingsViewModel)
        case .reportBug:
            ReportBugView()
        default:
            Text("Route not implemented")
        }
    }
    
    private func checkBiometricRequirement() {
        // Check if biometric authentication is required
        Task {
            if container.authRepository.isAuthenticated {
                guard requireBiometricsOnOpen else { return }
                let hasPassedCheck = UserDefaults.standard.bool(forKey: AppConstants.UserDefaults.hasPassedBiometricCheck)
                if !hasPassedCheck && container.authRepository.canUseBiometrics() {
                    showBiometricAuth = true
                }
            }
        }
    }
}
