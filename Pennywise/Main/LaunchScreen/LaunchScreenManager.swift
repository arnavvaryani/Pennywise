//
//  PennywiseApp.swift
//  Pennywise
//
//  Created for Pennywise App
//

import SwiftUI
import Firebase
import Combine

// MARK: - Launch Screen Manager
class LaunchScreenManager: ObservableObject {
    @Published var showLaunchScreen: Bool = true
    @Published var animate: Bool = false
    @Published var appReady: Bool = false
    
    func dismissLaunchScreen() {
        // First animate the launch screen
        animate = true
        
        // After animation completes, dismiss the launch screen
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            withAnimation {
                self.showLaunchScreen = false
            }
        }
    }
    
    func setupApp() {
        // Initialize services and perform startup tasks
        let authService = AuthenticationService.shared
        let plaidManager = PlaidManager.shared
        
        // Initialize services in parallel
        let group = DispatchGroup()
        
        // Check auth state
        group.enter()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            // Simulate auth check completion
            group.leave()
        }
        
        // Prepare Plaid link
        group.enter()
        plaidManager.prepareLinkController()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            group.leave()
        }
        
        // When all initialization is complete
        group.notify(queue: .main) {
            // Allow sufficient time for splash screen animation before marking app as ready
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.appReady = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.dismissLaunchScreen()
                }
            }
        }
    }
}

