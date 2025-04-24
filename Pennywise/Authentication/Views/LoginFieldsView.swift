//
//  LoginFieldsView.swift
//  Pennywise
//
//  Created by Arnav Varyani on 4/11/25.
//

import SwiftUI

struct LoginFieldsView: View {
    @Binding var email: String
    @Binding var password: String
    @Binding var isLoginMode: Bool
    var forgotPasswordAction: () -> Void
    var authError: Error?
    
    var body: some View {
        VStack(spacing: 20) {
            // Email field
            HStack {
                Image(systemName: "envelope.fill")
                    .foregroundColor(.white.opacity(0.7))
                    .frame(width: 24)
                
                TextField("", text: $email)
                    .placeholder(when: email.isEmpty) {
                        Text("Email").foregroundColor(.white.opacity(0.7))
                    }
                    .foregroundColor(.white)
                    .keyboardType(.emailAddress)
                    .disableAutocorrection(true)
            }
            .padding()
            .background(Color.white.opacity(0.2))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
            )
            
            // Password field
            HStack {
                Image(systemName: "lock.fill")
                    .foregroundColor(.white.opacity(0.7))
                    .frame(width: 24)
                
                SecureField("", text: $password)
                    .placeholder(when: password.isEmpty) {
                        Text("Password").foregroundColor(.white.opacity(0.7))
                    }
                    .foregroundColor(.white)
            }
            .padding()
            .background(Color.white.opacity(0.2))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
            )
            
            // Error message
            if let error = authError {
                AuthErrorView(error: error)
            }
            
            // Forgot password
            HStack {
                Spacer()
                Button(action: forgotPasswordAction) {
                    Text("Forgot Password?")
                        .font(.footnote)
                        .foregroundColor(.white.opacity(0.8))
                }
            }
            .padding(.trailing, 8)
        }
        .padding(.horizontal, 24)
    }
}

extension View {
    func placeholder<Content: View>(
        when shouldShow: Bool,
        alignment: Alignment = .leading,
        @ViewBuilder placeholder: () -> Content
    ) -> some View {
        ZStack(alignment: alignment) {
            placeholder().opacity(shouldShow ? 1 : 0)
            self
        }
    }
}
