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
    @Published var user: FirebaseAuth.User?
    @Published var isAuthenticated = false
    @Published var authError: Error?
    @Published var isLoading = false
    
    @AppStorage("biometricAuthEnabled") var biometricAuthEnabled = false
    @AppStorage("requireBiometricsOnOpen") var requireBiometricsOnOpen = false
    @AppStorage("requireBiometricsForTransactions") var requireBiometricsForTransactions = false
    
    private var authStateListener: AuthStateDidChangeListenerHandle?
    private var cancellables = Set<AnyCancellable>()
    
    var currentNonce: String?
    
    static let shared = AuthenticationService()
    
    private init() {
        setupFirebaseAuthStateListener()
    }
    
    deinit {
        if let listener = authStateListener {
            Auth.auth().removeStateDidChangeListener(listener)
        }
    }
    
    private func setupFirebaseAuthStateListener() {
        authStateListener = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            DispatchQueue.main.async {
                self?.user = user
                self?.isAuthenticated = user != nil
                
                if user != nil && self?.requireBiometricsOnOpen == true && self?.biometricAuthEnabled == true {
                    UserDefaults.standard.set(false, forKey: "hasPassedBiometricCheck")
                }
            }
        }
    }
    
    
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
        
        let credential = EmailAuthProvider.credential(withEmail: email, password: currentPassword)
        
        user.reauthenticate(with: credential) { [weak self] _, error in
            if let error = error {
                DispatchQueue.main.async {
                    self?.isLoading = false
                    self?.authError = error
                    completion(.failure(error))
                }
                return
            }
            
            user.updatePassword(to: newPassword) { error in
                DispatchQueue.main.async {
                    self?.isLoading = false
                    
                    if let error = error {
                        self?.authError = error
                        completion(.failure(error))
                    } else {
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
                    

                    self?.createUserProfile(for: user)
                    
  
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
                        
                        self?.createUserProfile(for: firebaseUser)
                        
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
            resetBiometricCheck()
        } catch let error {
            DispatchQueue.main.async {
                self.authError = error
            }
        }
    }
    
    // MARK: - User Profile
    
    private func createUserProfile(for user: FirebaseAuth.User) {
        let db = Firestore.firestore()
        
        db.collection("users").document(user.uid).getDocument { [weak self] document, error in
            if let document = document, document.exists {
                return
            } else {
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
