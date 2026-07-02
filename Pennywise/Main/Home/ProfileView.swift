import SwiftUI

struct ProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var navigationManager: NavigationManager
    var viewModel: SettingsViewModel
    
    var body: some View {
        ZStack {
            Color(AppTheme.backgroundPrimary)
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    headerCard
                    
                    quickActionsCard
                    
                    preferencesSummaryCard
                    
                    Spacer(minLength: 32)
                    
                    signOutButton
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
            }
        }
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.loadData()
        }
    }
    
    private var headerCard: some View {
        PWGlassCard {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(AppTheme.accentPurple.opacity(0.18))
                        .frame(width: 72, height: 72)
                    
                    if let photoURL = viewModel.user?.photoURL,
                       let url = URL(string: photoURL) {
                        AsyncImage(url: url) { image in
                            image
                                .resizable()
                                .scaledToFill()
                                .frame(width: 72, height: 72)
                                .clipShape(Circle())
                        } placeholder: {
                            Image(systemName: "person.fill")
                                .font(.system(size: 30, weight: .semibold))
                                .foregroundColor(AppTheme.textColor.opacity(0.9))
                        }
                    } else {
                        Image(systemName: "person.fill")
                            .font(.system(size: 30, weight: .semibold))
                            .foregroundColor(AppTheme.textColor.opacity(0.9))
                    }
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(viewModel.displayName)
                        .font(.title3.weight(.semibold))
                        .foregroundColor(AppTheme.textColor)
                        .lineLimit(1)
                    
                    Text(viewModel.email)
                        .font(.subheadline)
                        .foregroundColor(AppTheme.textColor.opacity(0.65))
                        .lineLimit(1)
                }
                
                Spacer()
            }
        }
    }
    
    private var quickActionsCard: some View {
        PWGlassCard {
            VStack(spacing: 12) {
                PWSectionHeader("Account")
                
                Button {
                    navigationManager.navigate(to: .editProfile)
                } label: {
                    row(icon: "person.text.rectangle", title: "Edit Profile")
                }
                .buttonStyle(.plain)
                
                PWDivider(opacity: 0.4)
                
                Button {
                    navigationManager.navigate(to: .changePassword)
                } label: {
                    row(icon: "lock.rotation", title: "Change Password")
                }
                .buttonStyle(.plain)
                
                PWDivider(opacity: 0.4)
                
                Button {
                    navigationManager.selectedTab = 3
                } label: {
                    row(icon: "gearshape.fill", title: "Open Settings")
                }
                .buttonStyle(.plain)
            }
        }
    }
    
    private var preferencesSummaryCard: some View {
        PWGlassCard {
            VStack(alignment: .leading, spacing: 16) {
                PWSectionHeader("Summary")
                
                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Monthly Income")
                            .font(.caption)
                            .foregroundColor(AppTheme.textColor.opacity(0.7))
                        Text(viewModel.user?.monthlyIncome == 0 ? "Not set" : CurrencyFormatter.format(viewModel.user?.monthlyIncome ?? 0))
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(AppTheme.textColor)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Biometrics")
                            .font(.caption)
                            .foregroundColor(AppTheme.textColor.opacity(0.7))
                        Text(viewModel.availableBiometrics.displayName)
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(AppTheme.textColor)
                    }
                }
            }
        }
    }
    
    private var signOutButton: some View {
        Button {
            do {
                try viewModel.signOut()
                dismiss()
            } catch {
                // SettingsViewModel already captures errors; no-op here
            }
        } label: {
            Text("Sign Out")
                .font(.subheadline.weight(.semibold))
                .foregroundColor(AppTheme.expenseColor)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(AppTheme.expenseColor.opacity(0.7), lineWidth: 1)
                )
        }
        .padding(.horizontal, 4)
    }
    
    private func row(icon: String, title: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(AppTheme.primary)
                .frame(width: 28)
            
            Text(title)
                .foregroundColor(AppTheme.textColor)
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(AppTheme.textColor.opacity(0.4))
        }
        .padding(.vertical, 4)
    }
}

