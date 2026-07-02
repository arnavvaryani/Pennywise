//
//  LoginViewModel.swift
//  Pennywise
//
//  ViewModel for Authentication operations - Clean Architecture
//

import Foundation
import Observation

@MainActor
@Observable
public final class LoginViewModel {
    // MARK: - Dependencies
    private let loginUseCase: LoginUseCase
    private let signUpUseCase: SignUpUseCase
    private let authRepository: AuthRepository
    
    // MARK: - Observable State
    public var email = ""
    public var password = ""
    public var isLoading = false
    public var error: Error?
    public var errorMessage: String = ""
    public var isAuthenticated = false
    public var isLoginMode = true
    
    // MARK: - Init
    public init(
        loginUseCase: LoginUseCase,
        signUpUseCase: SignUpUseCase,
        authRepository: AuthRepository
    ) {
        self.loginUseCase = loginUseCase
        self.signUpUseCase = signUpUseCase
        self.authRepository = authRepository
    }
    
    // MARK: - Public Methods
    public func signIn() async {
        isLoading = true
        errorMessage = ""
        defer { isLoading = false }
        
        do {
            _ = try await loginUseCase.execute(email: email, password: password)
            isAuthenticated = true
        } catch {
            self.error = error
            self.errorMessage = error.localizedDescription
        }
    }
    
    public func signUp() async {
        isLoading = true
        errorMessage = ""
        defer { isLoading = false }
        
        do {
            _ = try await signUpUseCase.execute(email: email, password: password)
            isAuthenticated = true
        } catch {
            self.error = error
            self.errorMessage = error.localizedDescription
        }
    }
    
    public func signInWithGoogle() async {
        isLoading = true
        errorMessage = ""
        defer { isLoading = false }
        
        do {
            _ = try await authRepository.signInWithGoogle()
            isAuthenticated = true
        } catch {
            self.error = error
            self.errorMessage = error.localizedDescription
        }
    }
    
    public func sendPasswordReset() async {
        guard !email.isEmpty else {
            errorMessage = "Please enter your email address first"
            return
        }
        
        isLoading = true
        errorMessage = ""
        defer { isLoading = false }
        
        do {
            try await authRepository.sendPasswordReset(email: email)
            errorMessage = "Check your email to reset your password"
        } catch {
            self.error = error
            self.errorMessage = error.localizedDescription
        }
        
    }
}

