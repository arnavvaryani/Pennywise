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
    
    @State private var launchScreenManager = LaunchScreenManager()
    
    @Environment(\.scenePhase) private var scenePhase
    
    // Dependency container
    private let container = DependencyContainer.shared
    
    init() {
        configureAppAppearance()
    }
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                NewAppCoordinator()
                    .preferredColorScheme(.dark)
                    .onChange(of: scenePhase) { oldPhase, newPhase in
                        handleScenePhaseChange(newPhase)
                    }
                
                if launchScreenManager.showLaunchScreen {
                    LaunchScreenView(launchScreenManager: launchScreenManager)
                        .transition(.opacity)
                        .zIndex(1)
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func configureAppAppearance() {
        // Windows access is handled per-window-scene in modern iOS
        // Use windowScene.windows instead of UIApplication.shared.windows
        
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
            // App is active
        case .inactive:
            print("App became inactive")
        case .background:
            print("App went to background")
            // Handle biometric reset if needed
            if container.authRepository.isAuthenticated {
                UserDefaults.standard.set(false, forKey: AppConstants.UserDefaults.hasPassedBiometricCheck)
            }
        @unknown default:
            print("Unknown scene phase")
        }
    }
}
