//
//  PennywiseApp 2.swift
//  Pennywise
//
//  Created by Arnav Varyani on 4/24/25.
//

import SwiftUI

@main
struct PennywiseApp: App {
    // Firebase setup
    @UIApplicationDelegateAdaptor(FirebaseAppDelegate.self) var delegate
    
    // State objects
    @StateObject private var launchScreenManager = LaunchScreenManager()
    @StateObject private var authService = AuthenticationService.shared
    @StateObject private var plaidManager = PlaidManager.shared
    
    // App state observers
    @Environment(\.scenePhase) private var scenePhase
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                AppCoordinator()
                    .environmentObject(launchScreenManager)
                    .environmentObject(authService)
                    .environmentObject(plaidManager)
                    .preferredColorScheme(.dark) // Force dark mode for consistency
                    .onAppear {
                        // App configuration
                        configureAppAppearance()
                    }
                    .onChange(of: scenePhase) { newPhase in
                        handleScenePhaseChange(newPhase)
                    }
                
                if launchScreenManager.showLaunchScreen {
                    LaunchScreenView()
                        .environmentObject(launchScreenManager)
                        .transition(.opacity)
                        .zIndex(1)
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func configureAppAppearance() {
        // Force dark mode for the entire app
        UIApplication.shared.windows.forEach { window in
            window.overrideUserInterfaceStyle = .dark
        }
        
        // Configure navigation bar appearance
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(AppTheme.backgroundPrimary)
        appearance.titleTextAttributes = [.foregroundColor: UIColor(AppTheme.textColor)]
        appearance.largeTitleTextAttributes = [.foregroundColor: UIColor(AppTheme.textColor)]
        
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        UINavigationBar.appearance().tintColor = UIColor(AppTheme.primaryGreen)
        
        // Configure tab bar appearance
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithOpaqueBackground()
        tabBarAppearance.backgroundColor = UIColor(AppTheme.backgroundPrimary)
        
        UITabBar.appearance().standardAppearance = tabBarAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
        UITabBar.appearance().tintColor = UIColor(AppTheme.primaryGreen)
    }
    
    private func handleScenePhaseChange(_ newPhase: ScenePhase) {
        switch newPhase {
        case .active:
            print("App became active")
            // Check if we need to refresh data
            if authService.isAuthenticated {
              //  plaidManager.refreshAllData()
            }
        case .inactive:
            print("App became inactive")
        case .background:
            print("App went to background")
            // Reset biometric check if needed
            if authService.requireBiometricsOnOpen {
                authService.resetBiometricCheck()
            }
        @unknown default:
            print("Unknown scene phase")
        }
    }
}
