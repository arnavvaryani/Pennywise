//
//  FinanceLoginView.swift
//  Pennywise
//
//  Created by Arnav Varyani on 4/8/25.
//

import SwiftUI
import Firebase
import GoogleSignIn
import AuthenticationServices
import FirebaseAuth
import GoogleSignInSwift

// MARK: - Helper Views
struct LogoView: View {
    @Binding var animationAmount: CGFloat
    
    var body: some View {
        VStack(spacing: 15) {
            Image(systemName: "dollarsign.circle.fill")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 80, height: 80)
                .foregroundColor(.white)
                .scaleEffect(animationAmount)
                .opacity(2 - animationAmount)
                .animation(
                    Animation.easeInOut(duration: 2)
                        .repeatForever(autoreverses: true),
                    value: animationAmount
                )
            
            Text("FinanceTracker")
                .font(.system(size: 38, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            
            Text("Take Control of Your Money")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.8))
        }
        .padding(.bottom, 30)
    }
}



struct LoginButtonView: View {
    var isLoading: Bool
    var isLoginMode: Bool
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.0, anchor: .center)
                        .padding(.trailing, 5)
                }
                
                Text(isLoginMode ? "Login" : "Create Account")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
            }
            .background(AppTheme.primary.opacity(0.8))
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 5)
        }
        .padding(.horizontal, 24)
        .padding(.top, 10)
        .disabled(isLoading)
    }
}

struct SocialLoginView: View {
    var googleAction: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Or continue with")
                .font(.footnote)
                .foregroundColor(.white.opacity(0.7))
            
            VStack(spacing: 12) {
                GoogleSignInButton(action: googleAction)
                    .padding(.horizontal, 24)
            }
        }
        .padding(.top, 15)
    }
}

