//
//  LaunchScreenManager.swift
//  Pennywise
//
//  Created by Arnav Varyani on 4/8/25.
//


import SwiftUI
import Firebase
import Observation

// MARK: - Launch Screen Manager
@Observable
@MainActor
class LaunchScreenManager {
    var showLaunchScreen: Bool = true
    var animate: Bool = false
    var appReady: Bool = false
    
    func dismissLaunchScreen() {
        // First animate the launch screen
        animate = true
        
        // After animation completes, dismiss the launch screen
        Task {
            try? await Task.sleep(nanoseconds: 800_000_000) // 0.8 seconds
            withAnimation {
                self.showLaunchScreen = false
            }
        }
    }
    
    func setupApp() {
        Task {
            let container = DependencyContainer.shared
            
            if container.authRepository.isAuthenticated,
               container.plaidRepository.isPlaidLinked {
                // Warm up Plaid-driven data before showing the main UI
                do {
                    let useCase = container.makeFetchTransactionsUseCase()
                    _ = try await useCase.execute()
                } catch {
                    // If Plaid or network fails, continue to avoid blocking app launch
                    print("Initial Plaid data load failed: \(error)")
                }
            }
            
            // Mark app as ready and dismiss launch screen
            self.appReady = true
            self.dismissLaunchScreen()
        }
    }
}

