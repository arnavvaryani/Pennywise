//
//  AppCoordinator.swift
//  Pennywise
//
//  Created by Arnav Varyani on 4/10/25.
//

import SwiftUI
import FirebaseFirestore
import Combine

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
        let firestoreSettings = FirestoreSettings()
        firestoreSettings.isPersistenceEnabled = true
        Firestore.firestore().settings = firestoreSettings
        
        let _ = PlaidFirestoreSync.shared
        
        setupFirestoreObservers()
    }
    
    private func setupFirestoreObservers() {
        authService.$isAuthenticated
            .sink { [weak self] isAuthenticated in
                if isAuthenticated {
                    self?.checkForDataMigration()
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Data Migration
    
    func checkForDataMigration() {
        let hasMigratedToFirestore = UserDefaults.standard.bool(forKey: "hasMigratedToFirestore")
        
        if !hasMigratedToFirestore {
            migrateDataToFirestore()
        } else {
            PlaidFirestoreSync.shared.performFullSync()
        }
    }
    
    func migrateDataToFirestore() {
        showMigrationProgress = true
        
        let firestoreManager = FirestoreManager.shared
        

        firestoreManager.syncAccounts(plaidManager.accounts) { [weak self] accountSuccess in
            guard let self = self else { return }
            
            if accountSuccess {

                self.migrationProgress = 0.3
                

                firestoreManager.syncTransactions(self.plaidManager.transactions) { transactionSuccess in
                    if transactionSuccess {
                        self.migrationProgress = 0.7
                        
                        let categories = self.plaidManager.getBudgetCategories()
                        
                        let group = DispatchGroup()
                        
                        for category in categories {
                            group.enter()
                            
                            firestoreManager.saveBudgetCategory(category) { _ in
                                group.leave()
                            }
                        }
                        
                        group.notify(queue: .main) {
                            firestoreManager.updateBudgetUsage { _ in
                                self.migrationProgress = 1.0
                                
                                UserDefaults.standard.set(true, forKey: "hasMigratedToFirestore")
                                
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                                    self.showMigrationProgress = false
                                }
                            }
                        }
                    } else {
                        self.handleMigrationFailure()
                    }
                }
            } else {
                self.handleMigrationFailure()
            }
        }
    }
    
    /// Handles migration failure
    func handleMigrationFailure() {
        showMigrationProgress = false
        migrationProgress = 0
        
        showMigrationError = true
    }
}

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
        if authService.isAuthenticated && authService.requireBiometricsOnOpen && authService.biometricAuthEnabled {
            let hasPassedBiometricCheck = UserDefaults.standard.bool(forKey: "hasPassedBiometricCheck")
            
            if !hasPassedBiometricCheck {
                let biometricType = authService.getBiometricType()
                if biometricType != .none {
                    showBiometricAuth = true
                } else {
                    UserDefaults.standard.set(true, forKey: "hasPassedBiometricCheck")
                }
            }
        }
        
        hasCheckedAuth = true
    }
}

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


