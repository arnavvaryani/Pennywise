//
//  DeleteAccountView.swift
//  Pennywise
//
//  Created by Arnav Varyani on 4/8/25.
//

import SwiftUI

struct DeleteAccountView: View {
    // MARK: - Dependencies
    var viewModel: SettingsViewModel
    
    // MARK: - Environment
    @Environment(\.dismiss) private var dismiss

    // MARK: - State
    @State private var confirmText   = ""
    @State private var password      = ""
    @State private var showSuccess   = false

    // MARK: - View
    var body: some View {
        ZStack {
            Color(AppTheme.backgroundPrimary).ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    // ⚠️  Icon
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 70))
                        .foregroundColor(AppTheme.expenseColor)
                        .padding(.top, 30)

                    Text("Delete Your Account")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(AppTheme.textColor)

                    warningBox

                    confirmationField
                    
                    passwordField

                    if let error = viewModel.error, !error.localizedDescription.isEmpty {
                        errorBanner(error: error)
                    }

                    deleteButton
                        .padding(.top, 10)

                    Button("Cancel") {
                        dismiss()
                    }
                    .font(.headline)
                    .foregroundColor(AppTheme.textColor)
                    .padding()
                }
                .padding()
            }
        }
        .navigationTitle("Delete Account")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(viewModel.isLoading)
        .alert("Account Deleted",
               isPresented: $showSuccess,
               actions: {
                   Button("OK", role: .cancel) {
                       dismiss()
                   }
               },
               message: {
                   Text("Your account and all associated data have been permanently deleted.")
               })
    }

    // MARK: - Sub-views ------------------------------------------------------

    private var warningBox: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Warning")
                .font(.headline)
                .foregroundColor(AppTheme.expenseColor)

            Text("This action cannot be undone. All your data will be permanently deleted, including:")
                .foregroundColor(AppTheme.textColor)

            VStack(alignment: .leading, spacing: 8) {
                bulletPoint("Your account information and profile")
                bulletPoint("All transaction history")
                bulletPoint("Budget configurations and categories")
                bulletPoint("Financial insights and reports")
                bulletPoint("Connected bank accounts data")
            }
            .padding(.leading, 10)
        }
        .padding()
        .background(AppTheme.cardBackground)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(AppTheme.cardStroke, lineWidth: 1)
        )
    }

    private var confirmationField: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Type \"DELETE\" to confirm")
                .font(.headline)
                .foregroundColor(AppTheme.textColor)

            TextField("", text: $confirmText)
                .foregroundColor(AppTheme.textColor)
                .padding()
                .background(AppTheme.cardBackground)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(AppTheme.cardStroke, lineWidth: 1)
                )
        }
    }
    
    private var passwordField: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Password (required for email/password accounts)")
                .font(.headline)
                .foregroundColor(AppTheme.textColor)
            
            SecureField("", text: $password)
                .foregroundColor(AppTheme.textColor)
                .padding()
                .background(AppTheme.cardBackground)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(AppTheme.cardStroke, lineWidth: 1)
                )
        }
    }

    private func errorBanner(error: Error) -> some View {
        HStack {
            Image(systemName: "exclamationmark.triangle")
                .foregroundColor(AppTheme.expenseColor)

            Text(error.localizedDescription)
                .font(.caption)
                .foregroundColor(AppTheme.expenseColor)
                .multilineTextAlignment(.leading)
        }
        .padding()
        .background(AppTheme.expenseColor.opacity(0.1))
        .cornerRadius(8)
    }

    private var deleteButton: some View {
        Button {
            deleteAccount()
        } label: {
            if viewModel.isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
            } else {
                Text("Permanently Delete Account")
                    .font(.headline)
                    .foregroundColor(.white)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(isDeleteButtonEnabled ? AppTheme.expenseColor
                                          : AppTheme.expenseColor.opacity(0.5))
        .cornerRadius(12)
        .disabled(!isDeleteButtonEnabled || viewModel.isLoading)
    }


    private func bulletPoint(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Text("•")
                .foregroundColor(AppTheme.expenseColor)
            Text(text)
                .foregroundColor(AppTheme.textColor)
                .fixedSize(horizontal: false, vertical: true)
            Spacer()
        }
    }

    private var isDeleteButtonEnabled: Bool {
        confirmText.uppercased() == "DELETE"
    }

    private func deleteAccount() {
        guard isDeleteButtonEnabled else { return }
        
        viewModel.error = nil
        
        Task {
            await viewModel.deleteAccount(password: password.isEmpty ? nil : password)
            
            if viewModel.error == nil {
                showSuccess = true
            }
        }
    }
}
