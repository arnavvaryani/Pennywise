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
        // Windows access is handled per-window-scene in modern iOS
        // Use windowScene.windows instead of UIApplication.shared.windows
        
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
        
        // Use cacheSettings instead of deprecated properties
        settings.cacheSettings = PersistentCacheSettings(sizeBytes: FirestoreCacheSizeUnlimited as NSNumber)
        
        // Apply settings
        db.settings = settings
        
        print("Firestore configured with persistence enabled")
    }
}
