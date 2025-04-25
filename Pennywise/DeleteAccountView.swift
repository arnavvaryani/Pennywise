//
//  DeleteAccountView.swift
//  Pennywise
//
//  Updated 2025-04-25 – no password prompt
//

import SwiftUI
import FirebaseAuth

struct DeleteAccountView: View {
    // MARK: - Environment
    @Environment(\.presentationMode) private var presentationMode

    // MARK: - State
    @State private var confirmText   = ""
    @State private var isLoading     = false
    @State private var errorMessage  = ""
    @State private var showSuccess   = false

    // MARK: - View
    var body: some View {
        ZStack {
            AppTheme.backgroundGradient.ignoresSafeArea()

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

                    // Warning box
                    warningBox

                    // “DELETE” confirmation field
                    confirmationField

                    // Error banner (if any)
                    if !errorMessage.isEmpty { errorBanner }

                    // Delete button
                    deleteButton
                        .padding(.top, 10)

                    // Cancel button
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
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
        .navigationBarBackButtonHidden(isLoading)
        .alert("Account Deleted",
               isPresented: $showSuccess,
               actions: {
                   Button("OK", role: .cancel) {
                       presentationMode.wrappedValue.dismiss()
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

    private var errorBanner: some View {
        HStack {
            Image(systemName: "exclamationmark.triangle")
                .foregroundColor(AppTheme.expenseColor)

            Text(errorMessage)
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
            if isLoading {
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
        .disabled(!isDeleteButtonEnabled || isLoading)
    }

    // MARK: - Helpers --------------------------------------------------------

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
        isLoading  = true
        errorMessage = ""

        AccountDeletionManager.shared.deleteAccount { result in
            DispatchQueue.main.async {
                isLoading = false
                switch result {
                case .success:
                    showSuccess = true
                case .failure(let error):
                    handleError(error)
                }
            }
        }
    }

    private func handleError(_ error: Error) {
        let ns = error as NSError
        if ns.domain == AuthErrorDomain,
           ns.code == AuthErrorCode.requiresRecentLogin.rawValue {
            errorMessage = "For security reasons, please sign out and sign back in before deleting your account."
        } else {
            errorMessage = "Error: \(error.localizedDescription)"
        }
    }
}

// MARK: - Preview
struct DeleteAccountView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            DeleteAccountView()
        }
        .preferredColorScheme(.dark)
    }
}
