//
//  FirebaseAppDelegate.swift
//  Pennywise
//
//  Created by Arnav Varyani on 4/8/25.
//

import SwiftUI
import Firebase
import FirebaseFirestore
import FirebaseAuth
import GoogleSignIn

class FirebaseAppDelegate: NSObject, UIApplicationDelegate {
    // MARK: - Application Lifecycle
    
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        // Configure Firebase
        FirebaseApp.configure()
        
        // Force dark mode for consistency
        UIApplication.shared.windows.forEach { window in
            window.overrideUserInterfaceStyle = .dark
        }
        
        return true
    }
    
    func application(_ app: UIApplication,
                     open url: URL,
                     options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        return GIDSignIn.sharedInstance.handle(url)
    }
    
    // MARK: - Firestore Configuration
    
    func configureFirestore() {
        // Set up Firestore settings for better performance
        let db = Firestore.firestore()
        let settings = FirestoreSettings()
        
        // Enable offline persistence
        settings.isPersistenceEnabled = true
        
        // Set cache size to unlimited for better offline support
        settings.cacheSizeBytes = FirestoreCacheSizeUnlimited
        
        // Apply settings
        db.settings = settings
        
        print("Firestore configured with persistence enabled")
    }
}

// MARK: - Firestore-enhanced App Delegate
// Use this in your main app as:
// @UIApplicationDelegateAdaptor(FirebaseAppDelegateWithFirestore.self) var delegate

class FirebaseAppDelegateWithFirestore: FirebaseAppDelegate {
    override func application(_ application: UIApplication,
                              didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        
        // Call the original Firebase configuration
        let result = super.application(application, didFinishLaunchingWithOptions: launchOptions)
        
        // Set up Firestore
        setupFirestoreAfterLaunch()
        
        return result
    }
    
    // MARK: - Firestore Migration Setup
    
    func setupFirestoreAfterLaunch() {
        // Configure Firestore after Firebase initialization
        configureFirestore()
        
        // Set up data migration check to run when user authenticates
        observeAuthStateForMigration()
    }
    
    private func observeAuthStateForMigration() {
        // Listen for auth state changes to trigger migration if needed
        Auth.auth().addStateDidChangeListener { [weak self] (auth, user) in
            guard let self = self, let user = user else { return }
            
            // User is signed in, check if we need to migrate data
            self.checkForDataMigration(userId: user.uid)
        }
    }
    
    private func checkForDataMigration(userId: String) {
        // Check if user data has been migrated to Firestore
        let hasMigratedKey = "user_\(userId)_migrated_to_firestore"
        
        if !UserDefaults.standard.bool(forKey: hasMigratedKey) {
            // Initialize the migration process
            print("Starting data migration for user: \(userId)")
            
            // Use PlaidFirestoreSync to handle the migration
            PlaidFirestoreSync.shared.forceSyncNow { [weak self] success in
                if success {
                    print("Data migration completed successfully")
                    UserDefaults.standard.set(true, forKey: hasMigratedKey)
                } else {
                    print("Data migration failed - will retry on next app launch")
                }
            }
        } else {
            // Already migrated, just start the normal sync timer
            PlaidFirestoreSync.shared.startSyncTimer()
        }
    }
}
