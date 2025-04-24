//
//  LaunchScreenView.swift
//  Pennywise
//
//  Created by Arnav Varyani on 4/24/25.
//

import SwiftUI

struct LaunchScreenView: View {
    @EnvironmentObject private var launchScreenManager: LaunchScreenManager
    
    var body: some View {
        ZStack {
            // Background color matching app theme
            AppTheme.backgroundPrimary
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 20) {
                // App icon
                Image(systemName: "dollarsign.circle.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 150, height: 150)
                    .foregroundColor(AppTheme.primaryGreen)
                    .scaleEffect(launchScreenManager.animate ? 1.1 : 1.0)
                    .opacity(launchScreenManager.animate ? 0 : 1)
                    .accessibilityHidden(true)
                
                // App name
                Text("Pennywise")
                    .font(.system(size: 42, weight: .bold))
                    .foregroundColor(.white)
                    .opacity(launchScreenManager.animate ? 0 : 1)
                    .offset(y: launchScreenManager.animate ? -20 : 0)
                    .accessibilityAddTraits(.isHeader)
                
                // Tagline
                Text("Smart. Simple. Secure.")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(AppTheme.accentBlue)
                    .opacity(launchScreenManager.animate ? 0 : 1)
                    .offset(y: launchScreenManager.animate ? -20 : 0)
                
                // Loading indicator
                if !launchScreenManager.appReady {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: AppTheme.primaryGreen))
                        .scaleEffect(1.5)
                        .padding(.top, 40)
                        .opacity(launchScreenManager.animate ? 0 : 1)
                }
            }
        }
        .opacity(launchScreenManager.showLaunchScreen ? 1 : 0)
        .animation(.easeOut(duration: 0.4), value: launchScreenManager.animate)
        .onAppear {
            // Start app initialization
            launchScreenManager.setupApp()
        }
    }
}
