//
//  AuthenticationService.swift
//  Pennywise
//
//  Created by Arnav Varyani on 4/8/25.
//

import SwiftUI
import Firebase
import FirebaseAuth
import GoogleSignIn
import AuthenticationServices
import CryptoKit
import LocalAuthentication
import Combine

class AuthenticationService: ObservableObject {
    // MARK: - Published Properties
    @Published var user: FirebaseAuth.User?
    @Published var isAuthenticated = false
    @Published var authError: Error?
    @Published var isLoading = false
    
    // MARK: - User Preferences
    @AppStorage("biometricAuthEnabled") var biometricAuthEnabled = false
    @AppStorage("requireBiometricsOnOpen") var requireBiometricsOnOpen = false
    @AppStorage("requireBiometricsForTransactions") var requireBiometricsForTransactions = false
    
    // MARK: - Private Properties
    private var authStateListener: AuthStateDidChangeListenerHandle?
    private var cancellables = Set<AnyCancellable>()
    
    // For Apple Sign In
    var currentNonce: String?
    
    // MARK: - Singleton Instance
    static let shared = AuthenticationService()
    
    // MARK: - Initialization
    private init() {
        setupFirebaseAuthStateListener()
    }
    
    deinit {
        // Clean up auth state listener
        if let listener = authStateListener {
            Auth.auth().removeStateDidChangeListener(listener)
        }
    }
    
    // MARK: - Setup Methods
    private func setupFirebaseAuthStateListener() {
        authStateListener = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            DispatchQueue.main.async {
                self?.user = user
                self?.isAuthenticated = user != nil
                
                // If user just authenticated and biometric auth is enabled/required on open,
                // we need to make sure they'll be prompted for biometrics
                if user != nil && self?.requireBiometricsOnOpen == true && self?.biometricAuthEnabled == true {
                    UserDefaults.standard.set(false, forKey: "hasPassedBiometricCheck")
                }
            }
        }
    }
    
    // MARK: - Biometric Authentication
    
    func getBiometricType() -> BiometricType {
        let context = LAContext()
        var error: NSError?
        
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            switch context.biometryType {
            case .faceID:
                return .faceID
            case .touchID:
                return .touchID
            default:
                return .none
            }
        }
        return .none
    }
    
    func changePassword(currentPassword: String, newPassword: String, completion: @escaping (Result<Void, Error>) -> Void) {
        isLoading = true
        authError = nil
        
        guard let user = Auth.auth().currentUser, let email = user.email else {
            isLoading = false
            let error = NSError(domain: "AuthenticationService", code: 0, userInfo: [NSLocalizedDescriptionKey: "User not signed in"])
            authError = error
            completion(.failure(error))
            return
        }
        
        // Create credential with current password
        let credential = EmailAuthProvider.credential(withEmail: email, password: currentPassword)
        
        // Re-authenticate user first
        user.reauthenticate(with: credential) { [weak self] _, error in
            if let error = error {
                DispatchQueue.main.async {
                    self?.isLoading = false
                    self?.authError = error
                    completion(.failure(error))
                }
                return
            }
            
            // Now update the password
            user.updatePassword(to: newPassword) { error in
                DispatchQueue.main.async {
                    self?.isLoading = false
                    
                    if let error = error {
                        self?.authError = error
                        completion(.failure(error))
                    } else {
                        // Reset user defaults for biometric check since password has changed
                        UserDefaults.standard.set(false, forKey: "hasPassedBiometricCheck")
                        completion(.success(()))
                    }
                }
            }
        }
    }
    
    func authenticateWithBiometrics(reason: String = "Verify your identity", completion: @escaping (Bool, Error?) -> Void) {
        let context = LAContext()
        var error: NSError?
        
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, error in
                DispatchQueue.main.async {
                    if success {
                        // If successful, update our authentication flag
                        UserDefaults.standard.set(true, forKey: "hasPassedBiometricCheck")
                        completion(true, nil)
                    } else {
                        let authError: Error
                        if let error = error {
                            authError = AuthError.biometricAuthFailed(error.localizedDescription)
                        } else {
                            authError = AuthError.biometricAuthFailed("Unknown error")
                        }
                        completion(false, authError)
                    }
                }
            }
        } else {
            completion(false, AuthError.biometricNotAvailable)
        }
    }
    
    func shouldRequireBiometricAuth() -> Bool {
        // Check if biometrics are enabled in settings and the user hasn't passed the check yet
        if biometricAuthEnabled && requireBiometricsOnOpen {
            let hasPassedCheck = UserDefaults.standard.bool(forKey: "hasPassedBiometricCheck")
            return !hasPassedCheck
        }
        return false
    }
    
    func resetBiometricCheck() {
        if requireBiometricsOnOpen && biometricAuthEnabled {
            UserDefaults.standard.set(false, forKey: "hasPassedBiometricCheck")
        }
    }
        
    func canUseBiometrics() -> Bool {
        let context = LAContext()
        var error: NSError?
        return context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
    }
    
    // MARK: - Email Authentication
    
    func signInWithEmail(email: String, password: String, completion: @escaping (Result<FirebaseAuth.User, Error>) -> Void) {
        isLoading = true
        authError = nil
        
        Auth.auth().signIn(withEmail: email, password: password) { [weak self] authResult, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if let error = error {
                    self?.authError = error
                    completion(.failure(error))
                    return
                }
                
                if let user = authResult?.user {
                    self?.user = user
                    self?.isAuthenticated = true
                    
                    // Reset biometric check on sign in to force authentication on app launch
                    if self?.requireBiometricsOnOpen == true && self?.biometricAuthEnabled == true {
                        UserDefaults.standard.set(false, forKey: "hasPassedBiometricCheck")
                    }
                    
                    completion(.success(user))
                } else {
                    let error = AuthError.userNotFound
                    self?.authError = error
                    completion(.failure(error))
                }
            }
        }
    }
    
    func signUpWithEmail(email: String, password: String, completion: @escaping (Result<FirebaseAuth.User, Error>) -> Void) {
        isLoading = true
        authError = nil
        
        Auth.auth().createUser(withEmail: email, password: password) { [weak self] authResult, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if let error = error {
                    self?.authError = error
                    completion(.failure(error))
                    return
                }
                
                if let user = authResult?.user {
                    self?.user = user
                    self?.isAuthenticated = true
                    
                    // Create user profile in database
                    self?.createUserProfile(for: user)
                    
                    // Reset biometric check for new users
                    if self?.biometricAuthEnabled == true && self?.requireBiometricsOnOpen == true {
                        UserDefaults.standard.set(false, forKey: "hasPassedBiometricCheck")
                    }
                    
                    completion(.success(user))
                } else {
                    let error = AuthError.signUpFailed("Failed to create user")
                    self?.authError = error
                    completion(.failure(error))
                }
            }
        }
    }
    
    // MARK: - Google Sign In
    
    func signInWithGoogle(from viewController: UIViewController, completion: @escaping (Result<FirebaseAuth.User, Error>) -> Void) {
        isLoading = true
        authError = nil
        
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            let error = AuthError.signInFailed("Google Sign In configuration error")
            authError = error
            completion(.failure(error))
            return
        }
        
        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config
        
        GIDSignIn.sharedInstance.signIn(withPresenting: viewController) { [weak self] result, error in
            if let error = error {
                DispatchQueue.main.async {
                    self?.isLoading = false
                    self?.authError = error
                    completion(.failure(error))
                }
                return
            }
            
            guard
                let user = result?.user,
                let idToken = user.idToken?.tokenString
            else {
                let error = AuthError.signInFailed("Google Sign In failed to get user token")
                DispatchQueue.main.async {
                    self?.isLoading = false
                    self?.authError = error
                    completion(.failure(error))
                }
                return
            }
            
            let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: user.accessToken.tokenString)
            
            Auth.auth().signIn(with: credential) { authResult, error in
                DispatchQueue.main.async {
                    self?.isLoading = false
                    
                    if let error = error {
                        self?.authError = error
                        completion(.failure(error))
                        return
                    }
                    
                    if let firebaseUser = authResult?.user {
                        self?.user = firebaseUser
                        self?.isAuthenticated = true
                        
                        // Create user profile in database if this is their first login
                        self?.createUserProfile(for: firebaseUser)
                        
                        // Reset biometric check on sign in
                        if self?.requireBiometricsOnOpen == true && self?.biometricAuthEnabled == true {
                            UserDefaults.standard.set(false, forKey: "hasPassedBiometricCheck")
                        }
                        
                        completion(.success(firebaseUser))
                    } else {
                        let error = AuthError.userNotFound
                        self?.authError = error
                        completion(.failure(error))
                    }
                }
            }
        }
    }
        
    // MARK: - Sign Out
    
    func signOut() {
        do {
            try Auth.auth().signOut()
            user = nil
            isAuthenticated = false
            resetBiometricCheck() // Reset biometric check on sign out
        } catch let error {
            DispatchQueue.main.async {
                self.authError = error
            }
        }
    }
    
    // MARK: - User Profile
    
    private func createUserProfile(for user: FirebaseAuth.User) {
        let db = Firestore.firestore()
        
        // Check if user profile already exists
        db.collection("users").document(user.uid).getDocument { [weak self] document, error in
            if let document = document, document.exists {
                // User profile already exists
                return
            } else {
                // Create new user profile with default values
                let userData: [String: Any] = [
                    "name": user.displayName ?? "",
                    "email": user.email ?? "",
                    "currency": "USD",
                    "monthlyIncome": 0.0,
                    "notificationsEnabled": true,
                    "biometricAuthEnabled": true,
                    "createdAt": Timestamp(date: Date())
                ]
                
                db.collection("users").document(user.uid).setData(userData) { error in
                    if let error = error {
                        DispatchQueue.main.async {
                            self?.authError = error
                        }
                    }
                }
            }
        }
    }
    
    func updateUserProfile(name: String? = nil,
                          monthlyIncome: Double? = nil,
                          currency: String? = nil,
                          notificationsEnabled: Bool? = nil,
                          completion: @escaping (Bool) -> Void) {
        guard let user = user else {
            completion(false)
            return
        }
        
        let db = Firestore.firestore()
        var updateData: [String: Any] = [:]
        
        if let name = name {
            updateData["name"] = name
            
            // Also update display name in Firebase Auth
            let changeRequest = user.createProfileChangeRequest()
            changeRequest.displayName = name
            changeRequest.commitChanges { _ in }
        }
        
        if let monthlyIncome = monthlyIncome {
            updateData["monthlyIncome"] = monthlyIncome
        }
        
        if let currency = currency {
            updateData["currency"] = currency
        }
        
        if let notificationsEnabled = notificationsEnabled {
            updateData["notificationsEnabled"] = notificationsEnabled
        }
        
        if !updateData.isEmpty {
            updateData["updatedAt"] = Timestamp(date: Date())
            
            db.collection("users").document(user.uid).updateData(updateData) { error in
                if let error = error {
                    DispatchQueue.main.async {
                        self.authError = error
                        completion(false)
                    }
                } else {
                    completion(true)
                }
            }
        } else {
            completion(true)
        }
    }

    
    func isPasswordValid(_ password: String) -> Bool {
        // Password should be at least 8 characters with at least one uppercase, one lowercase, and one number
        let passwordRegEx = "^(?=.*[a-z])(?=.*[A-Z])(?=.*\\d)[a-zA-Z\\d]{8,}$"
        let passwordPred = NSPredicate(format: "SELF MATCHES %@", passwordRegEx)
        return passwordPred.evaluate(with: password)
    }
    
    func isEmailValid(_ email: String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPred = NSPredicate(format: "SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: email)
    }
}
