//
//  SettingsView.swift
//  Pennywise
//
//  Created by Arnav Varyani on 4/10/25.
//

import SwiftUI
import LocalAuthentication

struct SettingsView: View {
    // MARK: - Properties
    @StateObject private var authService = AuthenticationService.shared
    @EnvironmentObject var plaidManager: PlaidManager
    
    // User preferences
    @AppStorage("biometricAuthEnabled") private var biometricAuthEnabled = true
    @AppStorage("requireBiometricsOnOpen") private var requireBiometricsOnOpen = true
    @AppStorage("requireBiometricsForTransactions") private var requireBiometricsForTransactions = true
    
    // Notifications
    @AppStorage("notificationsEnabled") private var notificationsEnabled = true
    @AppStorage("budgetAlertNotifications") private var budgetAlertNotifications = true
    @AppStorage("transactionNotifications") private var transactionNotifications = true
    @AppStorage("weeklyReportNotifications") private var weeklyReportNotifications = true
    
    // Display preferences
    @AppStorage("defaultCurrency") private var currency = "USD"
    @AppStorage("showBalanceOnHomeScreen") private var showBalanceOnHomeScreen = true
    
    // Budget preferences
    @AppStorage("budgetCycleStartDay") private var budgetCycleStartDay = 1
    @AppStorage("savingsGoalPercentage") private var savingsGoalPercentage = 20.0
    
    // States
    @State private var showingSignOutAlert = false
    @State private var showingAboutSheet = false
    @State private var showingBiometricSetupError = false
    @State private var biometricErrorMessage = ""
    @State private var showingDeleteAccountAlert = false
    @State private var showingExportDataSheet = false
    @State private var showingReportBugSheet = false
    @State private var showingEditProfileSheet = false
    
    // Lists for pickers
    let currencies = ["USD", "EUR", "GBP", "CAD", "AUD", "JPY", "CNY", "INR"]
    let availableBiometrics: BiometricType = AuthenticationService.shared.getBiometricType()
    let monthDays = Array(1...31).map { String($0) }
    
    var body: some View {
        ZStack {
            // Background gradient
            AppTheme.backgroundGradient
                .edgesIgnoringSafeArea(.all)
            
            // Main content
            ScrollView {
                VStack(spacing: 24) {
                    // Profile section
                    profileSection
                    
                    // Account section
                    accountSection
                    
                    // Plaid accounts section
                    plaidAccountsSection
                    
                    // Security section (with fixed biometrics)
                    securitySection
                    
                    // Notifications section
                    notificationsSection
                    
                    // Display preferences section
                    displayPreferencesSection
                    
                    // Budget preferences section
                    budgetPreferencesSection
                    
                    // Data management section
                    dataManagementSection
                    
                    // Application section
                    applicationSection
                    
                    // Sign out button
                    signOutButton
                        .padding(.top, 20)
                        .padding(.bottom, 50)
                }
                .padding()
            }
        }
        .alert("Sign Out", isPresented: $showingSignOutAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Sign Out", role: .destructive) {
                authService.signOut()
            }
        } message: {
            Text("Are you sure you want to sign out?")
        }
        .alert("Delete Account", isPresented: $showingDeleteAccountAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                // Handle account deletion
            }
        } message: {
            Text("This will permanently delete your account and all associated data. This action cannot be undone.")
        }
        .alert("Biometric Authentication Error", isPresented: $showingBiometricSetupError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(biometricErrorMessage)
        }
        .sheet(isPresented: $showingAboutSheet) {
            aboutView
        }
        .sheet(isPresented: $showingExportDataSheet) {
            exportDataView
        }
        .sheet(isPresented: $showingReportBugSheet) {
            ReportBugView(isPresented: $showingReportBugSheet)
        }
        .sheet(isPresented: $showingEditProfileSheet) {
            EditProfileView(isPresented: $showingEditProfileSheet)
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            checkBiometricAvailability()
        }
    }
    
    // MARK: - Profile Section
    private var profileSection: some View {
        VStack(spacing: 16) {
            sectionHeader("Profile")
            
            Button(action: {
                showingEditProfileSheet = true
            }) {
                HStack(spacing: 20) {
                    // Profile image
                    ZStack {
                        Circle()
                            .fill(AppTheme.accentPurple.opacity(0.3))
                            .frame(width: 75, height: 75)
                        
                        Image(systemName: "person.fill")
                            .font(.system(size: 32))
                            .foregroundColor(AppTheme.textColor)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(authService.user?.displayName ?? "User")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(AppTheme.textColor)
                        
                        Text(authService.user?.email ?? "email@example.com")
                            .font(.subheadline)
                            .foregroundColor(AppTheme.textColor.opacity(0.7))
                        
                        // Added since last login text
                        if let lastLogin = authService.user?.metadata.lastSignInDate {
                            Text("Last login: \(formatDate(lastLogin))")
                                .font(.caption)
                                .foregroundColor(AppTheme.textColor.opacity(0.6))
                        }
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .foregroundColor(AppTheme.textColor.opacity(0.5))
                        .font(.system(size: 14))
                }
                .padding()
                .background(AppTheme.cardBackground)
                .cornerRadius(20)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(AppTheme.cardStroke, lineWidth: 1)
                )
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
    
    // MARK: - Account Section
    private var accountSection: some View {
        VStack(spacing: 16) {
            sectionHeader("Account")
            
            settingsCard {
                Button(action: {
                    showingEditProfileSheet = true
                }) {
                    HStack {
                        Image(systemName: "person.fill")
                            .font(.system(size: 22))
                            .foregroundColor(AppTheme.primaryGreen)
                            .frame(width: 36)
                        
                        Text("Edit Profile")
                            .foregroundColor(AppTheme.textColor)
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .foregroundColor(AppTheme.textColor.opacity(0.5))
                            .font(.system(size: 14))
                    }
                    .padding(.vertical, 12)
                }
                
                Divider()
                    .background(AppTheme.textColor.opacity(0.1))
                
                // NavigationLink for Change Password
                NavigationLink(destination: ChangePasswordView()) {
                    HStack {
                        Image(systemName: "lock.rotation")
                            .font(.system(size: 22))
                            .foregroundColor(AppTheme.primaryGreen)
                            .frame(width: 36)
                        
                        Text("Change Password")
                            .foregroundColor(AppTheme.textColor)
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .foregroundColor(AppTheme.textColor.opacity(0.5))
                            .font(.system(size: 14))
                    }
                    .padding(.vertical, 12)
                }
                
                Divider()
                    .background(AppTheme.textColor.opacity(0.1))
                
                settingsButton(
                    title: "Linked Accounts",
                    icon: "link",
                    detailText: "\(plaidManager.accounts.count) accounts"
                ) {
                    // Show linked accounts
                }
                
                Divider()
                    .background(AppTheme.textColor.opacity(0.1))
                
                Button(action: {
                    showingDeleteAccountAlert = true
                }) {
                    HStack {
                        Image(systemName: "person.crop.circle.badge.minus")
                            .font(.system(size: 22))
                            .foregroundColor(AppTheme.expenseColor)
                            .frame(width: 36)
                        
                        Text("Delete Account")
                            .foregroundColor(AppTheme.expenseColor)
                        
                        Spacer()
                    }
                    .padding(.vertical, 12)
                }
            }
        }
    }
    
    // MARK: - Plaid Accounts Section
    private var plaidAccountsSection: some View {
        VStack(spacing: 16) {
            sectionHeader("Linked Financial Accounts")
            
            if plaidManager.accounts.isEmpty {
                settingsCard {
                    HStack {
                        Image(systemName: "building.columns")
                            .font(.system(size: 22))
                            .foregroundColor(AppTheme.accentBlue)
                            .frame(width: 36)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("No accounts connected")
                                .foregroundColor(AppTheme.textColor)
                            
                            Text("Link your bank accounts to track transactions automatically")
                                .font(.caption)
                                .foregroundColor(AppTheme.textColor.opacity(0.6))
                        }
                        
                        Spacer()
                    }
                    .padding(.vertical, 12)
                    
                    Button(action: {
                        plaidManager.presentLink()
                    }) {
                        Text("Connect Account")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(AppTheme.backgroundColor)
                            .padding(.vertical, 10)
                            .frame(maxWidth: .infinity)
                            .background(AppTheme.primaryGreen)
                            .cornerRadius(10)
                    }
                    .buttonStyle(ScaleButtonStyle())
                    .padding(.top, 8)
                }
            } else {
                VStack(spacing: 12) {
                    ForEach(plaidManager.accounts) { account in
                        HStack(spacing: 15) {
                            // Bank icon
                            ZStack {
                                Circle()
                                    .fill(AppTheme.accentBlue.opacity(0.2))
                                    .frame(width: 40, height: 40)
                                
                                if let logo = account.institutionLogo {
                                    Image(uiImage: logo)
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 25, height: 25)
                                } else {
                                    Image(systemName: "building.columns")
                                        .font(.system(size: 20))
                                        .foregroundColor(AppTheme.accentBlue)
                                }
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(account.name)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(AppTheme.textColor)
                                
                                Text(account.institutionName)
                                    .font(.caption)
                                    .foregroundColor(AppTheme.textColor.opacity(0.7))
                            }
                            
                            Spacer()
                            
                            Text("$\(String(format: "%.2f", account.balance))")
                                .font(.headline)
                                .foregroundColor(account.balance >= 0 ? AppTheme.primaryGreen : AppTheme.expenseColor)
                        }
                        .padding()
                        .background(AppTheme.cardBackground)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(AppTheme.cardStroke, lineWidth: 1)
                        )
                    }
                    
                    Button(action: {
                        plaidManager.presentLink()
                    }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(AppTheme.primaryGreen)
                            
                            Text("Add Account")
                                .foregroundColor(AppTheme.textColor)
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(AppTheme.primaryGreen.opacity(0.2))
                        .cornerRadius(12)
                    }
                    .buttonStyle(ScaleButtonStyle())
                }
            }
        }
    }
    
    // MARK: - Security Section
    private var securitySection: some View {
        VStack(spacing: 16) {
            sectionHeader("Security")
            
            settingsCard {
                if availableBiometrics != .none {
                    settingsToggle(
                        title: "Biometric Authentication",
                        subtitle: "Use \(availableBiometrics.name) to secure your account",
                        isOn: $biometricAuthEnabled,
                        icon: availableBiometrics == .faceID ? "faceid" : "touchid"
                    ) {
                        checkAndEnableBiometrics(isEnabled: biometricAuthEnabled)
                    }
                    
                    if biometricAuthEnabled {
                        Divider()
                            .background(AppTheme.textColor.opacity(0.1))
                        
                        settingsToggle(
                            title: "Require on App Launch",
                            subtitle: "Verify identity each time you open the app",
                            isOn: $requireBiometricsOnOpen,
                            icon: "app.fill"
                        )
                        
                        Divider()
                            .background(AppTheme.textColor.opacity(0.1))
                        
                        settingsToggle(
                            title: "Require for Transactions",
                            subtitle: "Verify identity before making transactions",
                            isOn: $requireBiometricsForTransactions,
                            icon: "creditcard.fill"
                        )
                    }
                } else {
                    HStack {
                        Image(systemName: "exclamationmark.shield")
                            .font(.system(size: 22))
                            .foregroundColor(AppTheme.alertOrange)
                            .frame(width: 36)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Biometric Authentication Unavailable")
                                .foregroundColor(AppTheme.textColor)
                            
                            Text("Your device doesn't support biometric authentication or it's not set up in your device settings.")
                                .font(.caption)
                                .foregroundColor(AppTheme.textColor.opacity(0.7))
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        
                        Spacer()
                    }
                    .padding(.vertical, 12)
                }
            }
        }
    }
    
    // MARK: - Notifications Section
    private var notificationsSection: some View {
        VStack(spacing: 16) {
            sectionHeader("Notifications")
            
            settingsCard {
                settingsToggle(
                    title: "Allow Notifications",
                    subtitle: "Enable or disable all app notifications",
                    isOn: $notificationsEnabled,
                    icon: "bell.fill"
                )
                
                if notificationsEnabled {
                    Divider()
                        .background(AppTheme.textColor.opacity(0.1))
                    
                    settingsToggle(
                        title: "Budget Alerts",
                        subtitle: "Get notified when you're close to budget limits",
                        isOn: $budgetAlertNotifications,
                        icon: "chart.pie.fill"
                    )
                    
                    Divider()
                        .background(AppTheme.textColor.opacity(0.1))
                    
                    settingsToggle(
                        title: "Transaction Alerts",
                        subtitle: "Get notified about new transactions",
                        isOn: $transactionNotifications,
                        icon: "creditcard.fill"
                    )
                    
                    Divider()
                        .background(AppTheme.textColor.opacity(0.1))
                    
                    settingsToggle(
                        title: "Weekly Reports",
                        subtitle: "Get weekly spending and saving reports",
                        isOn: $weeklyReportNotifications,
                        icon: "doc.text.fill"
                    )
                }
            }
        }
    }
    
    // MARK: - Display Preferences Section
    private var displayPreferencesSection: some View {
        VStack(spacing: 16) {
            sectionHeader("Display Preferences")
            
            settingsCard {
                // Currency selector
                HStack {
                    Image(systemName: "dollarsign.circle.fill")
                        .font(.system(size: 22))
                        .foregroundColor(AppTheme.primaryGreen)
                        .frame(width: 36)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Default Currency")
                            .foregroundColor(AppTheme.textColor)
                        
                        Text("Used throughout the app")
                            .font(.caption)
                            .foregroundColor(AppTheme.textColor.opacity(0.6))
                    }
                    
                    Spacer()
                    
                    Menu {
                        ForEach(currencies, id: \.self) { currencyOption in
                            Button {
                                currency = currencyOption
                            } label: {
                                Text(currencyOption)
                            }
                        }
                    } label: {
                        HStack {
                            Text(currency)
                                .foregroundColor(AppTheme.textColor.opacity(0.7))
                            
                            Image(systemName: "chevron.down")
                                .foregroundColor(AppTheme.textColor.opacity(0.7))
                                .font(.system(size: 14))
                        }
                        .padding(.vertical, 6)
                        .padding(.horizontal, 12)
                        .background(AppTheme.accentPurple.opacity(0.2))
                        .cornerRadius(8)
                    }
                }
                .padding(.vertical, 12)
                
                Divider()
                    .background(AppTheme.textColor.opacity(0.1))
                
                // Show balance on home screen
                settingsToggle(
                    title: "Show Balance on Home Screen",
                    subtitle: "Display your account balance in the home view",
                    isOn: $showBalanceOnHomeScreen,
                    icon: "eye.fill"
                )
            }
        }
    }
    
    // MARK: - Budget Preferences Section
    private var budgetPreferencesSection: some View {
        VStack(spacing: 16) {
            sectionHeader("Budget Preferences")
            
            settingsCard {
                // Budget cycle start day
                HStack {
                    Image(systemName: "calendar")
                        .font(.system(size: 22))
                        .foregroundColor(AppTheme.primaryGreen)
                        .frame(width: 36)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Budget Cycle Start Day")
                            .foregroundColor(AppTheme.textColor)
                        
                        Text("Monthly budgets will reset on this day")
                            .font(.caption)
                            .foregroundColor(AppTheme.textColor.opacity(0.6))
                    }
                    
                    Spacer()
                    
                    Menu {
                        ForEach(monthDays, id: \.self) { day in
                            Button {
                                budgetCycleStartDay = Int(day) ?? 1
                            } label: {
                                Text(day)
                            }
                        }
                    } label: {
                        HStack {
                            Text("\(budgetCycleStartDay)")
                                .foregroundColor(AppTheme.textColor.opacity(0.7))
                            
                            Image(systemName: "chevron.down")
                                .foregroundColor(AppTheme.textColor.opacity(0.7))
                                .font(.system(size: 14))
                        }
                        .padding(.vertical, 6)
                        .padding(.horizontal, 12)
                        .background(AppTheme.accentPurple.opacity(0.2))
                        .cornerRadius(8)
                    }
                }
                .padding(.vertical, 12)
                
                Divider()
                    .background(AppTheme.textColor.opacity(0.1))
                
                // Savings goal percentage
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Image(systemName: "chart.bar.fill")
                            .font(.system(size: 22))
                            .foregroundColor(AppTheme.primaryGreen)
                            .frame(width: 36)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Savings Goal")
                                .foregroundColor(AppTheme.textColor)
                            
                            Text("Percentage of income to save each month")
                                .font(.caption)
                                .foregroundColor(AppTheme.textColor.opacity(0.6))
                        }
                    }
                    
                    HStack {
                        Slider(value: $savingsGoalPercentage, in: 5...50, step: 1)
                            .accentColor(AppTheme.primaryGreen)
                        
                        Text("\(Int(savingsGoalPercentage))%")
                            .foregroundColor(AppTheme.textColor)
                            .frame(width: 50)
                    }
                    .padding(.leading, 36)
                }
                .padding(.vertical, 12)
            }
        }
    }
    
    // MARK: - Data Management Section
    private var dataManagementSection: some View {
        VStack(spacing: 16) {
            sectionHeader("Data Management")
            
            settingsCard {
                settingsButton(
                    title: "Export Data",
                    subtitle: "Export your financial data as CSV",
                    icon: "arrow.down.doc.fill"
                ) {
                    showingExportDataSheet = true
                }
                
                Divider()
                    .background(AppTheme.textColor.opacity(0.1))
                
                Button(action: {
                    plaidManager.disconnectAllAccounts()
                }) {
                    HStack {
                        Image(systemName: "link.badge.minus")
                            .font(.system(size: 22))
                            .foregroundColor(AppTheme.alertOrange)
                            .frame(width: 36)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Disconnect All Accounts")
                                .foregroundColor(AppTheme.alertOrange)
                            
                            Text("Remove all linked financial accounts")
                                .font(.caption)
                                .foregroundColor(AppTheme.textColor.opacity(0.6))
                        }
                        
                        Spacer()
                    }
                    .padding(.vertical, 12)
                }
                .buttonStyle(ScaleButtonStyle())
            }
        }
    }
    
    // MARK: - Application Section
    private var applicationSection: some View {
        VStack(spacing: 16) {
            sectionHeader("Application")
            
            settingsCard {
                Button(action: {
                    showingReportBugSheet = true
                }) {
                    HStack {
                        Image(systemName: "ant.fill")
                            .font(.system(size: 22))
                            .foregroundColor(AppTheme.primaryGreen)
                            .frame(width: 36)
                        
                        Text("Report a Bug")
                            .foregroundColor(AppTheme.textColor)
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .foregroundColor(AppTheme.textColor.opacity(0.5))
                            .font(.system(size: 14))
                    }
                    .padding(.vertical, 12)
                }
                
                Divider()
                    .background(AppTheme.textColor.opacity(0.1))
                
                Button(action: {
                    showingAboutSheet = true
                }) {
                    HStack {
                        Image(systemName: "info.circle.fill")
                            .font(.system(size: 22))
                            .foregroundColor(AppTheme.primaryGreen)
                            .frame(width: 36)
                        
                        Text("About Pennywise")
                            .foregroundColor(AppTheme.textColor)
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .foregroundColor(AppTheme.textColor.opacity(0.5))
                            .font(.system(size: 14))
                    }
                    .padding(.vertical, 12)
                }
                .buttonStyle(ScaleButtonStyle())
            }
        }
    }
    
    // MARK: - Export Data View
    private var exportDataView: some View {
        NavigationView {
            ZStack {
                AppTheme.backgroundGradient.ignoresSafeArea()
                
                VStack(spacing: 20) {
                    Image(systemName: "arrow.down.doc.fill")
                        .font(.system(size: 60))
                        .foregroundColor(AppTheme.primaryGreen)
                        .padding(.top, 30)
                    
                    Text("Export Your Data")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(AppTheme.textColor)
                    
                    Text("Choose what data you would like to export. The data will be exported as CSV files.")
                        .multilineTextAlignment(.center)
                        .font(.body)
                        .foregroundColor(AppTheme.textColor.opacity(0.7))
                        .padding(.horizontal, 20)
                    
                    VStack(spacing: 15) {
                        exportOptionButton(title: "Transactions", icon: "list.bullet.rectangle")
                        exportOptionButton(title: "Budget Categories", icon: "chart.pie")
                        exportOptionButton(title: "Accounts Summary", icon: "building.columns")
                        exportOptionButton(title: "Export All Data", icon: "square.and.arrow.down")
                    }
                    .padding(.top, 20)
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Export Data")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        showingExportDataSheet = false
                    }
                    .foregroundColor(AppTheme.primaryGreen)
                }
            }
        }
    }
    
    // MARK: - About View
    private var aboutView: some View {
        NavigationView {
            ZStack {
                // Background
                AppTheme.backgroundGradient.ignoresSafeArea(.all)
                
                VStack(spacing: 25) {
                    // App logo
                    Image(systemName: "dollarsign.circle.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 100, height: 100)
                        .foregroundColor(AppTheme.primaryGreen)
                        .padding(.top, 40)
                    
                    Text("Pennywise")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(AppTheme.textColor)
                    
                    Text("Version 1.1.0")
                        .font(.subheadline)
                        .foregroundColor(AppTheme.textColor.opacity(0.7))
                    
                    Spacer(minLength: 30)
                    
                    VStack(alignment: .leading, spacing: 20) {
                        aboutSectionTitle("About")
                        
                        Text("Pennywise is a comprehensive financial tracking and budget planning app designed to help you take control of your finances and achieve your financial goals.")
                            .foregroundColor(AppTheme.textColor.opacity(0.7))
                            .font(.body)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.bottom, 10)
                        
                        aboutSectionTitle("Team")
                        
                        Text("Developed by Arnav Varyani and the talented team at FinTech Solutions.")
                            .foregroundColor(AppTheme.textColor.opacity(0.7))
                            .font(.body)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.bottom, 10)
                        
                        aboutSectionTitle("Contact")
                        
                        Text("support@pennywiseapp.com\nsupport.pennywiseapp.com")
                            .foregroundColor(AppTheme.textColor.opacity(0.7))
                            .font(.body)
                    }
                    .padding()
                    .background(AppTheme.cardBackground)
                    .cornerRadius(20)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(AppTheme.cardStroke, lineWidth: 1)
                    )
                    .padding(.horizontal)
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("About")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        showingAboutSheet = false
                    }
                    .foregroundColor(AppTheme.primaryGreen)
                }
            }
        }
    }
    
    // MARK: - Sign Out Button
    private var signOutButton: some View {
        Button(action: {
            showingSignOutAlert = true
        }) {
            Text("Sign Out")
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(AppTheme.expenseColor) // Using expenseColor for the sign out button
                .cornerRadius(15)
                .shadow(color: AppTheme.expenseColor.opacity(0.3), radius: 10, x: 0, y: 5)
        }
        .buttonStyle(ScaleButtonStyle())
    }
    
    // MARK: - Helper Views
    private func sectionHeader(_ title: String) -> some View {
        HStack {
            Text(title)
                .font(AppTheme.headlineFont())
                .foregroundColor(AppTheme.textColor)
                .padding(.vertical, 8)
            
            Spacer()
        }
    }
    
    private func settingsCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(spacing: 0) {
            content()
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 16)
        .background(AppTheme.cardBackground)
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(AppTheme.cardStroke, lineWidth: 1)
        )
    }
    
    private func settingsToggle(title: String, isOn: Binding<Bool>, icon: String, action: (() -> Void)? = nil) -> some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 22))
                .foregroundColor(AppTheme.primaryGreen)
                .frame(width: 36)
            
            Text(title)
                .foregroundColor(AppTheme.textColor)
            
            Spacer()
            
            Toggle("", isOn: isOn)
                .toggleStyle(SwitchToggleStyle(tint: AppTheme.primaryGreen))
                .onChange(of: isOn.wrappedValue) { _ in
                    if let action = action {
                        action()
                    }
                }
        }
        .padding(.vertical, 12)
    }
    
    private func settingsToggle(title: String, subtitle: String, isOn: Binding<Bool>, icon: String, action: (() -> Void)? = nil) -> some View {
        HStack(alignment: .center) {
            Image(systemName: icon)
                .font(.system(size: 22))
                .foregroundColor(AppTheme.primaryGreen)
                .frame(width: 36)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .foregroundColor(AppTheme.textColor)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(AppTheme.textColor.opacity(0.6))
            }
            
            Spacer()
            
            Toggle("", isOn: isOn)
                .toggleStyle(SwitchToggleStyle(tint: AppTheme.primaryGreen))
                .onChange(of: isOn.wrappedValue) { _ in
                    if let action = action {
                        action()
                    }
                }
        }
        .padding(.vertical, 12)
    }
    
    private func settingsButton(title: String, icon: String, detailText: String? = nil, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 22))
                    .foregroundColor(AppTheme.primaryGreen)
                    .frame(width: 36)
                
                Text(title)
                    .foregroundColor(AppTheme.textColor)
                
                Spacer()
                
                if let detailText = detailText {
                    Text(detailText)
                        .font(.subheadline)
                        .foregroundColor(AppTheme.textColor.opacity(0.7))
                }
                
                Image(systemName: "chevron.right")
                    .foregroundColor(AppTheme.textColor.opacity(0.5))
                    .font(.system(size: 14))
            }
            .padding(.vertical, 12)
        }
        .buttonStyle(ScaleButtonStyle())
    }
    
    private func settingsButton(title: String, subtitle: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 22))
                    .foregroundColor(AppTheme.primaryGreen)
                    .frame(width: 36)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .foregroundColor(AppTheme.textColor)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(AppTheme.textColor.opacity(0.6))
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(AppTheme.textColor.opacity(0.5))
                    .font(.system(size: 14))
            }
            .padding(.vertical, 12)
        }
        .buttonStyle(ScaleButtonStyle())
    }
    
    private func exportOptionButton(title: String, icon: String) -> some View {
        Button(action: {
            // Export data action
        }) {
            HStack(spacing: 15) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(AppTheme.primaryGreen)
                    .frame(width: 36, height: 36)
                    .background(AppTheme.primaryGreen.opacity(0.2))
                    .clipShape(Circle())
                
                Text(title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(AppTheme.textColor)
                
                Spacer()
                
                Image(systemName: "arrow.down.circle")
                    .font(.system(size: 24))
                    .foregroundColor(AppTheme.primaryGreen)
            }
            .padding()
            .background(AppTheme.cardBackground)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(AppTheme.cardStroke, lineWidth: 1)
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }
    
    private func aboutSectionTitle(_ title: String) -> some View {
        HStack {
            Text(title)
                .font(.headline)
                .foregroundColor(AppTheme.primaryGreen)
            
            Spacer()
        }
    }
    
    // MARK: - Helper Methods
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func checkBiometricAvailability() {
        let context = LAContext()
        var error: NSError?
        
        if !context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            if let error = error {
                biometricErrorMessage = "Biometric authentication is not available: \(error.localizedDescription)"
                biometricAuthEnabled = false
                requireBiometricsOnOpen = false
                requireBiometricsForTransactions = false
            }
        }
    }
    
    private func checkAndEnableBiometrics(isEnabled: Bool) {
        if isEnabled {
            let context = LAContext()
            var error: NSError?
            
            if !context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
                biometricErrorMessage = "Cannot enable biometric authentication: \(error?.localizedDescription ?? "Unknown error")"
                showingBiometricSetupError = true
                biometricAuthEnabled = false
                return
            }
            
            // Test authentication to make sure it's working
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: "Verify your identity to enable biometric authentication") { success, error in
                DispatchQueue.main.async {
                    if !success {
                        biometricErrorMessage = "Authentication failed: \(error?.localizedDescription ?? "Unknown error")"
                        showingBiometricSetupError = true
                        biometricAuthEnabled = false
                    }
                }
            }
        }
    }
}

