//
//  SettingsViewModel.swift
//  Pennywise
//
//  ViewModel for Settings screen - Clean Architecture
//

import Foundation
import SwiftUI
import Observation

@MainActor
@Observable
public final class SettingsViewModel {
    // MARK: - Dependencies
    private let authRepository: AuthRepository
    private let userRepository: UserRepository
    private let accountRepository: AccountRepository
    private let logoutUseCase: LogoutUseCase
    private let updateProfileUseCase: UpdateProfileUseCase
    private let exportDataUseCase: ExportDataUseCase
    
    // MARK: - Observable State
    public var user: User?
    public var preferences: UserPreferences?
    public var isLoading = false
    public var error: Error?
    public var showLogoutConfirmation = false
    public var showDeleteAccountConfirmation = false
    public var availableBiometrics: BiometricType = .none
    
    // MARK: - Computed Properties
    public var displayName: String {
        user?.displayNameOrEmail ?? "User"
    }
    
    public var email: String {
        user?.email ?? ""
    }
    
    // MARK: - Init
    public init(
        authRepository: AuthRepository,
        userRepository: UserRepository,
        accountRepository: AccountRepository,
        updateProfileUseCase: UpdateProfileUseCase,
        exportDataUseCase: ExportDataUseCase,
        logoutUseCase: LogoutUseCase
    ) {
        self.authRepository = authRepository
        self.userRepository = userRepository
        self.accountRepository = accountRepository
        self.updateProfileUseCase = updateProfileUseCase
        self.exportDataUseCase = exportDataUseCase
        self.logoutUseCase = logoutUseCase
    }
    
    // MARK: - Public Methods
    public func loadData() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            user = try await userRepository.getUserProfile()
            preferences = try await userRepository.getUserPreferences()
            loadBiometricInfo()
        } catch {
            self.error = error
        }
    }
    
    public func loadBiometricInfo() {
        availableBiometrics = authRepository.getBiometricType()
    }
    
    public func updateProfile(displayName: String?, monthlyIncome: Double?) async throws {
        try await updateProfileUseCase.execute(
            displayName: displayName,
            monthlyIncome: monthlyIncome
        )
        
        // Reload profile
        await loadData()
    }
    
    public func updatePreferences(_ preferences: UserPreferences) async {
        do {
            try await userRepository.saveUserPreferences(preferences)
            self.preferences = preferences
        } catch {
            self.error = error
        }
    }
    
    public func logout() {
        do {
            try logoutUseCase.execute()
        } catch {
            self.error = error
        }
    }
    
    public func signOut() throws {
        try logoutUseCase.execute()
    }
    
    public func deleteAccount(password: String?) async {
        do {
            try await authRepository.deleteAccount(password: password)
        } catch {
            self.error = error
        }
    }
    
    public func exportData(type: String) async throws -> URL {
        return try await exportDataUseCase.execute(type: type)
    }
    
    public func disconnectAllAccounts() async {
        do {
            try await accountRepository.disconnectAllAccounts()
        } catch {
            self.error = error
        }
    }
    
    public func changePassword(currentPassword: String, newPassword: String) async {
        do {
            try await authRepository.changePassword(
                currentPassword: currentPassword,
                newPassword: newPassword
            )
        } catch {
            self.error = error
        }
    }
    
    public func canUseBiometrics() -> Bool {
        authRepository.canUseBiometrics()
    }
    
    public func getBiometricType() -> BiometricType {
        authRepository.getBiometricType()
    }
}

