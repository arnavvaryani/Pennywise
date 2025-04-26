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
    
    
    func configureFirestore() {
        let db = Firestore.firestore()
        let settings = FirestoreSettings()
        
        settings.isPersistenceEnabled = true
        
        settings.cacheSizeBytes = FirestoreCacheSizeUnlimited
        
        // Apply settings
        db.settings = settings
        
        print("Firestore configured with persistence enabled")
    }
}



class FirebaseAppDelegateWithFirestore: FirebaseAppDelegate {
    override func application(_ application: UIApplication,
                              didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        
        let result = super.application(application, didFinishLaunchingWithOptions: launchOptions)
        
        setupFirestoreAfterLaunch()
        
        return result
    }
    
    
    func setupFirestoreAfterLaunch() {
        configureFirestore()
        
        observeAuthStateForMigration()
    }
    
    private func observeAuthStateForMigration() {
        Auth.auth().addStateDidChangeListener { [weak self] (auth, user) in
            guard let self = self, let user = user else { return }
            
            self.checkForDataMigration(userId: user.uid)
        }
    }
    
    private func checkForDataMigration(userId: String) {
        let hasMigratedKey = "user_\(userId)_migrated_to_firestore"
        
        if !UserDefaults.standard.bool(forKey: hasMigratedKey) {
            print("Starting data migration for user: \(userId)")
            
            PlaidFirestoreSync.shared.forceSyncNow { [weak self] success in
                if success {
                    print("Data migration completed successfully")
                    UserDefaults.standard.set(true, forKey: hasMigratedKey)
                } else {
                    print("Data migration failed - will retry on next app launch")
                }
            }
        } else {
            PlaidFirestoreSync.shared.startSyncTimer()
        }
    }
}
