//
//  UserProfileView.swift
//  Pennywise
//
//  Created by Arnav Varyani on 4/23/25.
//


import SwiftUI
import Firebase

struct UserProfileView: View {
    @Binding var isPresented: Bool
    @StateObject private var authService = AuthenticationService.shared
    @State private var showingEditProfile = false
    
    // User stats
    @State private var totalAccounts = 0
    @State private var totalTransactions = 0
    @State private var accountSince = Date()
    @State private var savedAmount: Double = 0.0
    
    var body: some View {
        NavigationView {
            ZStack {
                AppTheme.backgroundGradient.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Profile header
                        profileHeader
                        
                        // User stats
                        userStatsSection
                        
                        // Account settings
                        accountSettingsSection
                        
                        // Other actions
                        Spacer(minLength: 20)
                    }
                    .padding()
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        isPresented = false
                    }
                    .foregroundColor(AppTheme.primaryGreen)
                }
            }
            .sheet(isPresented: $showingEditProfile) {
                EditProfileView(isPresented: $showingEditProfile)
            }
            .onAppear {
                loadUserStats()
            }
        }
    }
    
    // MARK: - Profile Header
    private var profileHeader: some View {
        VStack(spacing: 16) {
            // Profile image
            ZStack {
                Circle()
                    .fill(AppTheme.accentPurple.opacity(0.3))
                    .frame(width: 120, height: 120)
                
                if let photoURL = authService.user?.photoURL, let url = URL(string: photoURL.absoluteString) {
                    AsyncImage(url: url) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 120, height: 120)
                            .clipShape(Circle())
                    } placeholder: {
                        Image(systemName: "person.fill")
                            .font(.system(size: 60))
                            .foregroundColor(AppTheme.textColor)
                    }
                } else {
                    Image(systemName: "person.fill")
                        .font(.system(size: 60))
                        .foregroundColor(AppTheme.textColor)
                }
            }
            .padding(.top, 20)
            
            Text(authService.user?.displayName ?? "User")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(AppTheme.textColor)
            
            Text(authService.user?.email ?? "email@example.com")
                .font(.headline)
                .foregroundColor(AppTheme.textColor.opacity(0.7))
            
            // Edit profile button
            Button(action: {
                showingEditProfile = true
            }) {
                HStack {
                    Image(systemName: "pencil")
                        .font(.system(size: 14))
                    
                    Text("Edit Profile")
                        .font(.subheadline)
                }
                .foregroundColor(AppTheme.primaryGreen)
                .padding(.vertical, 8)
                .padding(.horizontal, 16)
                .background(AppTheme.primaryGreen.opacity(0.2))
                .cornerRadius(20)
            }
            .buttonStyle(ScaleButtonStyle())
            .padding(.top, 8)
        }
        .padding()
        .background(AppTheme.cardBackground)
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(AppTheme.cardStroke, lineWidth: 1)
        )
    }
    
    // MARK: - User Stats Section
    private var userStatsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Your Activity")
                .font(AppTheme.headlineFont())
                .foregroundColor(AppTheme.textColor)
                .padding(.horizontal)
            
            HStack(spacing: 20) {
                // Account stat
                statCard(
                    value: "\(totalAccounts)",
                    label: "Accounts",
                    icon: "building.columns.fill",
                    color: AppTheme.accentBlue
                )
                
                // Transactions stat
                statCard(
                    value: "\(totalTransactions)",
                    label: "Transactions",
                    icon: "arrow.left.arrow.right",
                    color: AppTheme.accentPurple
                )
            }
            
            HStack(spacing: 20) {
                // Money saved
                statCard(
                    value: "$\(Int(savedAmount))",
                    label: "Total Saved",
                    icon: "arrow.down.circle.fill",
                    color: AppTheme.primaryGreen
                )
                
                // Member since
                statCard(
                    value: formatDate(accountSince),
                    label: "Member Since",
                    icon: "calendar",
                    color: AppTheme.savingsYellow
                )
            }
        }
    }
    
    // MARK: - Account Settings Section
    private var accountSettingsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Account Settings")
                .font(AppTheme.headlineFont())
                .foregroundColor(AppTheme.textColor)
                .padding(.horizontal)
            
            VStack(spacing: 5) {
                settingsButton(
                    title: "Change Password",
                    icon: "lock.rotation",
                    destination: AnyView(ChangePasswordView())
                )
                
                settingsButton(
                    title: "Notification Preferences",
                    icon: "bell.fill",
                    action: {
                        // Open notification settings
                    }
                )
                
                settingsButton(
                    title: "Privacy Settings",
                    icon: "hand.raised.fill",
                    action: {
                        // Open privacy settings
                    }
                )
                
                settingsButton(
                    title: "Connected Accounts",
                    icon: "link",
                    action: {
                        // Show connected accounts
                    }
                )
            }
            .padding()
            .background(AppTheme.cardBackground)
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(AppTheme.cardStroke, lineWidth: 1)
            )
        }
    }
    
    // MARK: - Helper Views
    
    private func statCard(value: String, label: String, icon: String, color: Color) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(color)
                .frame(height: 30)
            
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(AppTheme.textColor)
            
            Text(label)
                .font(.caption)
                .foregroundColor(AppTheme.textColor.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(AppTheme.cardBackground)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(AppTheme.cardStroke, lineWidth: 1)
        )
    }
    
    private func settingsButton<Destination: View>(title: String, icon: String, destination: Destination) -> some View {
        NavigationLink(destination: destination) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(AppTheme.primaryGreen)
                    .frame(width: 30)
                
                Text(title)
                    .foregroundColor(AppTheme.textColor)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(AppTheme.textColor.opacity(0.5))
                    .font(.system(size: 14))
            }
            .padding(.vertical, 12)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func settingsButton(title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(AppTheme.primaryGreen)
                    .frame(width: 30)
                
                Text(title)
                    .foregroundColor(AppTheme.textColor)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(AppTheme.textColor.opacity(0.5))
                    .font(.system(size: 14))
            }
            .padding(.vertical, 12)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Helper Methods
    
    private func loadUserStats() {
        // Example data - in a real app, this would be loaded from a user service
        totalAccounts = Int.random(in: 1...5)
        totalTransactions = Int.random(in: 10...150)
        savedAmount = Double.random(in: 500...5000)
        
        // Set account creation date based on Firebase user
        if let creationDate = authService.user?.metadata.creationDate {
            accountSince = creationDate
        } else {
            // Fallback - 3 months ago
            accountSince = Calendar.current.date(byAdding: .month, value: -3, to: Date()) ?? Date()
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM yyyy"
        return formatter.string(from: date)
    }
}

struct UserProfileView_Previews: PreviewProvider {
    static var previews: some View {
        UserProfileView(isPresented: .constant(true))
            .environmentObject(AuthenticationService.shared)
            .preferredColorScheme(.dark)
    }
}
