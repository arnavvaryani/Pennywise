//
//  AppCoordinator.swift
//  Pennywise
//
//  Created by Arnav Varyani on 4/10/25.
//

import SwiftUI
import FirebaseFirestore
import Combine

// Changed to class to support weak self and cancellables
class AppCoordinatorViewModel: ObservableObject {
    @Published var showMigrationProgress = false
    @Published var migrationProgress: Double = 0
    @Published var showMigrationError = false
    
    var cancellables = Set<AnyCancellable>()
    let authService = AuthenticationService.shared
    let plaidManager = PlaidManager.shared
    
    init() {
        initializeFirestoreSync()
    }
    
    func initializeFirestoreSync() {
        // Set up Firestore settings
        let firestoreSettings = FirestoreSettings()
        firestoreSettings.isPersistenceEnabled = true
        Firestore.firestore().settings = firestoreSettings
        
        // Initialize the syncing system
        let _ = PlaidFirestoreSync.shared
        
        // Set up observers
        setupFirestoreObservers()
    }
    
    /// Sets up observers for Firestore sync status
    private func setupFirestoreObservers() {
        // Setup observer for authentication state
        authService.$isAuthenticated
            .sink { [weak self] isAuthenticated in
                if isAuthenticated {
                    // Check if we need to migrate data
                    self?.checkForDataMigration()
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Data Migration
    
    /// Checks if data migration is needed and performs it if necessary
    func checkForDataMigration() {
        let hasMigratedToFirestore = UserDefaults.standard.bool(forKey: "hasMigratedToFirestore")
        
        if !hasMigratedToFirestore {
            migrateDataToFirestore()
        } else {
            // No migration needed, just perform normal sync
            PlaidFirestoreSync.shared.performFullSync()
        }
    }
    
    /// Migrates existing data to Firestore
    func migrateDataToFirestore() {
        // Show migration progress
        showMigrationProgress = true
        
        let firestoreManager = FirestoreManager.shared
        
        // First, sync accounts
        firestoreManager.syncAccounts(plaidManager.accounts) { [weak self] accountSuccess in
            guard let self = self else { return }
            
            if accountSuccess {
                // Update migration progress
                self.migrationProgress = 0.3
                
                // Next, sync transactions
                firestoreManager.syncTransactions(self.plaidManager.transactions) { transactionSuccess in
                    if transactionSuccess {
                        // Update migration progress
                        self.migrationProgress = 0.7
                        
                        // Get budget categories from Plaid Manager
                        let categories = self.plaidManager.getBudgetCategories()
                        
                        // Sync each category
                        let group = DispatchGroup()
                        
                        for category in categories {
                            group.enter()
                            
                            firestoreManager.saveBudgetCategory(category) { _ in
                                group.leave()
                            }
                        }
                        
                        // Update budget usage when all categories are synced
                        group.notify(queue: .main) {
                            firestoreManager.updateBudgetUsage { _ in
                                // Migration complete
                                self.migrationProgress = 1.0
                                
                                // Mark migration as complete
                                UserDefaults.standard.set(true, forKey: "hasMigratedToFirestore")
                                
                                // Hide migration progress after a short delay
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                                    self.showMigrationProgress = false
                                }
                            }
                        }
                    } else {
                        // Handle migration failure
                        self.handleMigrationFailure()
                    }
                }
            } else {
                // Handle migration failure
                self.handleMigrationFailure()
            }
        }
    }
    
    /// Handles migration failure
    func handleMigrationFailure() {
        // Reset migration state
        showMigrationProgress = false
        migrationProgress = 0
        
        // Show error alert
        showMigrationError = true
    }
}

// The view struct that uses the class above
struct AppCoordinator: View {
    
    @StateObject private var viewModel = AppCoordinatorViewModel()
    @StateObject private var authService = AuthenticationService.shared
    @StateObject private var plaidManager = PlaidManager.shared
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage("hasLinkedPlaidAccount") private var hasLinkedPlaidAccount = false
    @State private var showBiometricAuth = false
    @State private var hasCheckedAuth = false
    @State private var showPlaidOnboarding = false
    
    var body: some View {
        Group {
            if !hasCompletedOnboarding {
                FinanceOnboardingView()
            } else if !authService.isAuthenticated {
                FinanceLoginView()
            } else if showBiometricAuth {
                BiometricAuthenticationView(isAuthenticated: $showBiometricAuth)
            } else if !hasLinkedPlaidAccount && plaidManager.accounts.isEmpty {
 
                PlaidOnboardingView(isPresented: $showPlaidOnboarding)
                    .onAppear {
                        showPlaidOnboarding = true
                    }
                    .onChange(of: plaidManager.accounts) { accounts in
                        if !accounts.isEmpty {
                            hasLinkedPlaidAccount = true
                        }
                    }
            } else {
                FinanceRootView()
                    .environmentObject(plaidManager)
            }
        }
        .onAppear {
            // Always reset the biometric check when the app appears
            if authService.isAuthenticated && authService.biometricAuthEnabled && authService.requireBiometricsOnOpen {
                UserDefaults.standard.set(false, forKey: "hasPassedBiometricCheck")
            }
            
            checkBiometricAuthRequirement()
            
            if !plaidManager.accounts.isEmpty {
                hasLinkedPlaidAccount = true
            }
            
            if authService.isAuthenticated {
                plaidManager.prepareLinkController()
            }
        }
        .onChange(of: authService.isAuthenticated) { isAuthenticated in
            if isAuthenticated {
                checkBiometricAuthRequirement()
            }
        }
        // Add overlay for migration progress
        .overlay(
            ZStack {
                if viewModel.showMigrationProgress {
                    Color.black.opacity(0.7)
                        .edgesIgnoringSafeArea(.all)
                    
                    DataMigrationView(progress: $viewModel.migrationProgress)
                }
            }
        )
        .alert(isPresented: $viewModel.showMigrationError) {
            Alert(
                title: Text("Migration Failed"),
                message: Text("There was an error migrating your data. Please try again later."),
                dismissButton: .default(Text("OK"))
            )
        }
    }

    private var mainAppContent: some View {
        FinanceRootView()
            .environmentObject(plaidManager)
    }
    
    private func checkBiometricAuthRequirement() {
        // Check if user is authenticated and biometric auth is required
        if authService.isAuthenticated && authService.requireBiometricsOnOpen && authService.biometricAuthEnabled {
            // Always check if user has passed the biometric check in this session
            let hasPassedBiometricCheck = UserDefaults.standard.bool(forKey: "hasPassedBiometricCheck")
            
            if !hasPassedBiometricCheck {
                let biometricType = authService.getBiometricType()
                if biometricType != .none {
                    showBiometricAuth = true
                } else {
                    // If biometrics is not available, mark as passed
                    UserDefaults.standard.set(true, forKey: "hasPassedBiometricCheck")
                }
            }
        }
        
        hasCheckedAuth = true
    }
}

/// Progress view for data migration
struct DataMigrationView: View {
    @Binding var progress: Double
    
    var body: some View {
        VStack(spacing: 20) {
            ProgressView(value: progress)
                .progressViewStyle(LinearProgressViewStyle(tint: AppTheme.primaryGreen))
                .frame(width: 250)
            
            Text("Migrating your financial data")
                .font(.headline)
                .foregroundColor(AppTheme.textColor)
            
            Text("Please wait while we securely update your data storage system")
                .font(.subheadline)
                .foregroundColor(AppTheme.textColor.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 30)
            
            // Progress percentage
            Text("\(Int(progress * 100))%")
                .font(.caption)
                .foregroundColor(AppTheme.primaryGreen)
                .padding(.top, 5)
        }
        .padding(30)
        .background(AppTheme.cardBackground)
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
    }
}

struct EnhancedAppCoordinator_Previews: PreviewProvider {
    static var previews: some View {
        AppCoordinator()
    }
}


