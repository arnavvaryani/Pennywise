import SwiftUI

struct EditProfileView: View {
    @Environment(\.dismiss) private var dismiss
    var viewModel: SettingsViewModel
    
    @State private var displayName: String = ""
    @State private var monthlyIncome: String = ""
    @State private var isSaving = false
    
    var body: some View {
        ZStack {
            AppTheme.enhancedBackgroundGradient
            
            ScrollView {
                VStack(spacing: 24) {
                    profileImageSection
                    
                    VStack(alignment: .leading, spacing: 16) {
                        PWSectionHeader("Personal Information")
                        
                        PWGlassCard {
                            VStack(spacing: 16) {
                            CustomTextField(
                                placeholder: "Display Name",
                                text: $displayName,
                                icon: "person.fill"
                            )
                            
                            CustomTextField(
                                placeholder: "Monthly Income",
                                text: $monthlyIncome,
                                icon: "dollarsign.circle.fill",
                                keyboardType: .decimalPad
                            )
                            }
                        }
                    }
                    
                    Spacer()
                    
                    saveButton
                        .padding(.top, 20)
                }
                .padding()
            }
        }
        .navigationTitle("Edit Profile")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") {
                    dismiss()
                }
                .foregroundColor(AppTheme.textColor.opacity(0.7))
            }
        }
        .onAppear {
            displayName = viewModel.user?.displayName ?? ""
            monthlyIncome = String(format: "%.0f", viewModel.user?.monthlyIncome ?? 0)
        }
    }
    
    private var profileImageSection: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(AppTheme.accentPurple.opacity(0.3))
                    .frame(width: 100, height: 100)
                
                if let photoURL = viewModel.user?.photoURL {
                    AsyncImage(url: URL(string: photoURL)) { image in
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: 100, height: 100)
                            .clipShape(Circle())
                    } placeholder: {
                        Image(systemName: "person.fill")
                            .font(.system(size: 40))
                            .foregroundColor(AppTheme.textColor)
                    }
                } else {
                    Image(systemName: "person.fill")
                        .font(.system(size: 40))
                        .foregroundColor(AppTheme.textColor)
                }
                
                // Edit overlay
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Circle()
                            .fill(AppTheme.primaryGreen)
                            .frame(width: 32, height: 32)
                            .overlay(
                                Image(systemName: "camera.fill")
                                    .font(.system(size: 14))
                                    .foregroundColor(.white)
                            )
                    }
                }
                .frame(width: 100, height: 100)
            }
            
            Button("Change Photo") {
                // Photo picker logic would go here
            }
            .font(.subheadline)
            .foregroundColor(AppTheme.primaryGreen)
        }
        .padding(.vertical, 20)
    }
    
    private var saveButton: some View {
        PWPrimaryButton(
            title: isSaving ? "Saving..." : "Save Changes",
            isLoading: isSaving,
            isDisabled: isSaving || displayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        ) {
            saveProfile()
        }
    }
    
    private func saveProfile() {
        guard !displayName.isEmpty else { return }
        
        isSaving = true
        let income = Double(monthlyIncome) ?? 0
        
        Task {
            do {
                try await viewModel.updateProfile(displayName: displayName, monthlyIncome: income)
                isSaving = false
                dismiss()
            } catch {
                viewModel.error = error
                isSaving = false
            }
        }
    }
}
