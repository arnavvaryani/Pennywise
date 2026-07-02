import SwiftUI
import LocalAuthentication

struct SettingsView: View {
    // MARK: - Dependencies
    var viewModel: SettingsViewModel
    @EnvironmentObject var navManager: NavigationManager
    
    // User preferences
    @AppStorage("biometricAuthEnabled") private var biometricAuthEnabled = true
    @AppStorage("requireBiometricsOnOpen") private var requireBiometricsOnOpen = true
    
    // Display preferences
    @AppStorage("showBalanceOnHomeScreen") private var showBalanceOnHomeScreen = true
    
    // Budget preferences
    @AppStorage("budgetCycleStartDay") private var budgetCycleStartDay = 1
    
    // States
    @State private var showingSignOutAlert = false
    @State private var showingBiometricSetupError = false
    @State private var biometricErrorMessage = ""
    
    // Lists for pickers
    let monthDays = Array(1...31).map { String($0) }
    
    var body: some View {
        ZStack {
            // Background gradient
            AppTheme.enhancedBackgroundGradient
            
            // Main content
            ScrollView {
                VStack(spacing: 24) {
                    // Profile section
                    profileSection
                    
                    // Account section
                    accountSection
                    
                    // Security section (with fixed biometrics)
                    securitySection
                    
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
                do {
                    try viewModel.signOut()
                } catch {
                    print("Sign out error: \(error)")
                }
            }
        } message: {
            Text("Are you sure you want to sign out?")
        }
        .alert("Biometric Authentication Error", isPresented: $showingBiometricSetupError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(biometricErrorMessage)
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.loadData() // This will also load biometric info
            checkBiometricAvailability()
        }
    }
    
    // MARK: - Profile Section
    private var profileSection: some View {
        VStack(spacing: 16) {
            sectionHeader("Profile")
            
            PWGlassCard {
                HStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(AppTheme.accentPurple.opacity(0.18))
                            .frame(width: 64, height: 64)
                        
                        if let photoURL = viewModel.user?.photoURL {
                            AsyncImage(url: URL(string: photoURL)) { image in
                                image
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 64, height: 64)
                                    .clipShape(Circle())
                            } placeholder: {
                                Image(systemName: "person.fill")
                                    .font(.system(size: 28, weight: .semibold))
                                    .foregroundColor(AppTheme.textColor.opacity(0.85))
                            }
                        } else {
                            Image(systemName: "person.fill")
                                .font(.system(size: 28, weight: .semibold))
                                .foregroundColor(AppTheme.textColor.opacity(0.85))
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(viewModel.user?.displayName ?? "User")
                            .font(.headline)
                            .foregroundColor(AppTheme.textColor)
                            .lineLimit(1)
                        
                        Text(viewModel.user?.email ?? "email@example.com")
                            .font(.subheadline)
                            .foregroundColor(AppTheme.textColor.opacity(0.65))
                            .lineLimit(1)
                    }
                    
                    Spacer()
                }
            }
        }
    }
    
    // MARK: - Account Section
    private var accountSection: some View {
        VStack(spacing: 16) {
            sectionHeader("Account")
            
            settingsCard {
                Button(action: {
                    navManager.navigate(to: .editProfile)
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
                
                PWDivider(opacity: 0.35)
                
                // NavigationLink for Change Password
                NavigationLink(value: AppRoute.changePassword) {
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
                
                PWDivider(opacity: 0.35)
                
                // NavigationLink for Delete Account
                NavigationLink(value: AppRoute.deleteAccount) {
                    HStack {
                        Image(systemName: "person.crop.circle.badge.minus")
                            .font(.system(size: 22))
                            .foregroundColor(AppTheme.expenseColor)
                            .frame(width: 36)
                        
                        Text("Delete Account")
                            .foregroundColor(AppTheme.expenseColor)
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .foregroundColor(AppTheme.textColor.opacity(0.5))
                            .font(.system(size: 14))
                    }
                    .padding(.vertical, 12)
                }
            }
        }
    }
    
    // MARK: - Security Section
    private var securitySection: some View {
        VStack(spacing: 16) {
            sectionHeader("Security")
            
            settingsCard {
                if viewModel.availableBiometrics != .none {
                    settingsToggle(
                        title: "Biometric Authentication",
                        subtitle: "Use \(viewModel.availableBiometrics.displayName) to secure your account",
                        isOn: $biometricAuthEnabled,
                        icon: viewModel.availableBiometrics == .faceID ? "faceid" : "touchid"
                    ) {
                        checkAndEnableBiometrics(isEnabled: biometricAuthEnabled)
                        // If biometrics are disabled, also disable dependent options
                        if !biometricAuthEnabled {
                            requireBiometricsOnOpen = false
                        }
                    }
                    
                    if biometricAuthEnabled {
                        PWDivider(opacity: 0.35)
                        
                        settingsToggle(
                            title: "Require on App Launch",
                            subtitle: "Verify identity each time you open the app",
                            isOn: $requireBiometricsOnOpen,
                            icon: "app.fill"
                        ) {
                            // Reset the biometric check to force authentication on next app launch
                            if requireBiometricsOnOpen {
                                UserDefaults.standard.set(false, forKey: AppConstants.UserDefaults.hasPassedBiometricCheck)
                            }
                        }
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
    
    
    // MARK: - Display Preferences Section
    private var displayPreferencesSection: some View {
        VStack(spacing: 16) {
            sectionHeader("Display Preferences")
            
            settingsCard {
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
                    navManager.navigate(to: .exportData)
                }
                
                Divider()
                    .background(AppTheme.textColor.opacity(0.1))
                
                Button(action: {
                    Task {
                        await viewModel.disconnectAllAccounts()
                    }
                }) {
                    HStack {
                        Image(systemName: "minus.circle")
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
                    navManager.navigate(to: .reportBug)
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
                    navManager.navigate(to: .about)
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
    
    // MARK: - Sign Out Button
    private var signOutButton: some View {
        PWDestructiveButton(title: "Sign Out") {
            showingSignOutAlert = true
        }
    }
    
    // MARK: - Helper Views
    private func sectionHeader(_ title: String) -> some View {
        PWSectionHeader(title)
            .padding(.vertical, 8)
    }
    
    private func settingsCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        PWGlassCard {
            VStack(spacing: 0) {
                content()
            }
            .padding(.vertical, 4)
            .padding(.horizontal, 4)
        }
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
                .onChange(of: isOn.wrappedValue) { oldValue, newValue in
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
                .onChange(of: isOn.wrappedValue) { oldValue, newValue in
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
    
    // MARK: - Biometric Helpers
    
    private func checkBiometricAvailability() {
        let context = LAContext()
        var error: NSError?
        
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            // Biometrics are available
        }
    }
    
    private func checkAndEnableBiometrics(isEnabled: Bool) {
        guard isEnabled else { return }
        
        let context = LAContext()
        var error: NSError?
        
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            let reason = "Enable biometric authentication to secure your account."
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, _ in
                if !success {
                    Task { @MainActor in
                        self.biometricAuthEnabled = false
                    }
                }
            }
        } else {
            self.biometricAuthEnabled = false
        }
    }
}
