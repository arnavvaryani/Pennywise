//
//  PennywiseApp.swift
//  Pennywise
//
//  Created by Arnav Varyani on 4/24/25.
//

import SwiftUI

@main
struct PennywiseApp: App {
    @UIApplicationDelegateAdaptor(FirebaseAppDelegate.self) var delegate
    
    @StateObject private var launchScreenManager = LaunchScreenManager()
    @StateObject private var authService = AuthenticationService.shared
    @StateObject private var plaidManager = PlaidManager.shared
    
    @Environment(\.scenePhase) private var scenePhase
    
    init() {
        configureAppAppearance()
    }
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                AppCoordinator()
                    .environmentObject(launchScreenManager)
                    .environmentObject(authService)
                    .environmentObject(plaidManager)
                    .preferredColorScheme(.dark)
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
        UIApplication.shared.windows.forEach { window in
            window.overrideUserInterfaceStyle = .dark
        }
        
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(AppTheme.backgroundPrimary)
        appearance.titleTextAttributes = [.foregroundColor: UIColor(AppTheme.textColor)]
        appearance.largeTitleTextAttributes = [.foregroundColor: UIColor(AppTheme.textColor)]
        
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        UINavigationBar.appearance().tintColor = UIColor(AppTheme.primaryGreen)
        
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
            if authService.isAuthenticated {
            }
        case .inactive:
            print("App became inactive")
        case .background:
            print("App went to background")
            if authService.requireBiometricsOnOpen {
                authService.resetBiometricCheck()
            }
        @unknown default:
            print("Unknown scene phase")
        }
    }
}
