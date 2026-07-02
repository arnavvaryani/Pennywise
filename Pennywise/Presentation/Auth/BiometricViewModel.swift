//
//  BiometricViewModel.swift
//  Pennywise
//
//  ViewModel for Biometric Authentication operations - Clean Architecture
//

import Foundation
import Observation

@MainActor
@Observable
public final class BiometricViewModel {
    // MARK: - Dependencies
    private let authRepository: AuthRepository
    
    // MARK: - Observable State
    public var isLoading = false
    public var error: Error?
    public var errorMessage: String = ""
    public var isAuthenticated = false
    public var biometricType: BiometricType = .none
    
    // MARK: - Computed Properties
    public var biometricDisplayName: String {
        biometricType.displayName
    }
    
    public var isBiometricAvailable: Bool {
        biometricType != .none
    }
    
    public var biometricIcon: String {
        switch biometricType {
        case .faceID: return "faceid"
        case .touchID: return "touchid"
        case .none: return "lock.shield"
        }
    }
    
    // MARK: - Init
    public init(authRepository: AuthRepository) {
        self.authRepository = authRepository
        loadBiometricType()
    }
    
    // MARK: - Public Methods
    public func loadBiometricType() {
        biometricType = authRepository.getBiometricType()
    }
    
    public func authenticate(reason: String? = nil) async -> Bool {
        isLoading = true
        errorMessage = ""
        defer { isLoading = false }
        
        let authReason = reason ?? "Log in to your Pennywise account using \(biometricDisplayName)"
        
        do {
            let success = try await authRepository.authenticateWithBiometrics(reason: authReason)
            if success {
                isAuthenticated = true
            }
            return success
        } catch {
            self.error = error
            self.errorMessage = error.localizedDescription
            return false
        }
    }
    
    public func canUseBiometrics() -> Bool {
        authRepository.canUseBiometrics()
    }
}

