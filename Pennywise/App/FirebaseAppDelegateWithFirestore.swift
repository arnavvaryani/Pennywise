//
//  FirebaseAppDelegateWithFirestore.swift
//  Pennywise
//
//  Created by Arnav Varyani on 4/24/25.
//


//
//  FirebaseAppDelegate+Firestore.swift
//  Pennywise
//
//  Created for Pennywise App
//

import SwiftUI
import Firebase
import FirebaseFirestore
import FirebaseAuth

extension FirebaseAppDelegate {
    /// Configures Firestore when the app launches
    func configureFirestore() {
        // Set up Firestore settings for better performance
        let db = Firestore.firestore()
        let settings = FirestoreSettings()
        
        // Enable offline persistence
        settings.isPersistenceEnabled = true
        
        // Set cache size to 100MB
        settings.cacheSizeBytes = FirestoreCacheSizeUnlimited
        
        // Apply settings
        db.settings = settings
        
        print("Firestore configured with persistence enabled")
    }
    
    /// Added to the existing application(_:didFinishLaunchingWithOptions:) method
    func setupFirestoreAfterLaunch() {
        // Configure Firestore after Firebase initialization
        configureFirestore()
        
        // Set up data migration check to run when user authenticates
        observeAuthStateForMigration()
    }
    
    /// Observe auth state for data migration
    private func observeAuthStateForMigration() {
        // Listen for auth state changes to trigger migration if needed
        Auth.auth().addStateDidChangeListener { (auth, user) in
            if let user = user {
                // User is signed in, check if we need to migrate data
                self.checkForDataMigration(userId: user.uid)
            }
        }
    }
    
    /// Check if data migration is needed and perform it
    private func checkForDataMigration(userId: String) {
        // Check if user data has been migrated to Firestore
        let hasMigratedKey = "user_\(userId)_migrated_to_firestore"
        
        if !UserDefaults.standard.bool(forKey: hasMigratedKey) {
            // Initialize the migration process
            print("Starting data migration for user: \(userId)")
            
            // Use PlaidFirestoreSync to handle the migration
            PlaidFirestoreSync.shared.forceSyncNow { success in
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

// MARK: - Updated FirebaseAppDelegate with Firestore Support

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
}
