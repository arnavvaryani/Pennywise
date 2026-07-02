import SwiftUI

struct ReportBugView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var bugDescription: String = ""
    @State private var email: String = ""
    @State private var isSubmitting = false
    @State private var submissionSuccessful = false
    @State private var errorMessage: String? = nil
    private let container = DependencyContainer.shared
    
    var body: some View {
        ZStack {
            AppTheme.enhancedBackgroundGradient
            
            VStack(spacing: 24) {
                if let errorMessage {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundColor(AppTheme.expenseColor)
                        .padding(.horizontal)
                }
                if submissionSuccessful {
                    successView
                } else {
                    formView
                }
            }
            .padding()
        }
        .navigationTitle("Report a Bug")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Close") {
                    dismiss()
                }
                .foregroundColor(AppTheme.primaryGreen)
            }
        }
    }
    
    private var formView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("We're sorry you're having trouble. Please describe the issue below.")
                .font(.body)
                .foregroundColor(AppTheme.textColor.opacity(0.8))
            
            PWGlassCard {
                VStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Description")
                            .font(.caption)
                            .foregroundColor(AppTheme.textColor.opacity(0.6))
                        
                        TextEditor(text: $bugDescription)
                            .frame(height: 150)
                            .padding(8)
                            .background(AppTheme.accentPurple.opacity(0.10))
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .stroke(AppTheme.cardStroke, lineWidth: 1)
                            )
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Your Email (Optional)")
                            .font(.caption)
                            .foregroundColor(AppTheme.textColor.opacity(0.6))
                        
                        CustomTextField(
                            placeholder: "email@example.com",
                            text: $email,
                            icon: "envelope.fill",
                            keyboardType: .emailAddress
                        )
                    }
                }
            }
            
            Spacer()
            
            submitButton
        }
    }
    
    private var successView: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(AppTheme.primaryGreen)
            
            Text("Thank You!")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(AppTheme.textColor)
            
            Text("Your bug report has been submitted. Our team will look into it as soon as possible.")
                .multilineTextAlignment(.center)
                .foregroundColor(AppTheme.textColor.opacity(0.7))
                .padding(.horizontal, 20)
            
            PWPrimaryButton(title: "Done") {
                dismiss()
            }
            .padding(.top, 20)
        }
    }
    
    private var submitButton: some View {
        PWPrimaryButton(
            title: isSubmitting ? "Submitting..." : "Submit Report",
            isLoading: isSubmitting,
            isDisabled: isSubmitting || bugDescription.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        ) {
            submitBug()
        }
    }
    
    private func submitBug() {
        isSubmitting = true
        errorMessage = nil
        
        Task {
            do {
                try await container.firestore.submitBugReport(
                    description: bugDescription.trimmingCharacters(in: .whitespacesAndNewlines),
                    email: email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : email.trimmingCharacters(in: .whitespacesAndNewlines)
                )
                isSubmitting = false
                submissionSuccessful = true
            } catch {
                isSubmitting = false
                errorMessage = error.localizedDescription
            }
        }
    }
}
