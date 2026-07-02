//
//  AppDelegate.swift
//  Pennywise
//
//  Created by Arnav Varyani on 4/24/25.
//

import SwiftUI
import UIKit
import Firebase

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
        
        // Windows access is handled per-window-scene in modern iOS
        // Use windowScene.windows instead of UIApplication.shared.windows
        
        return true
    }
}
