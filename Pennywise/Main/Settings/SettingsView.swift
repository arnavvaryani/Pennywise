import SwiftUI
import LocalAuthentication

struct SettingsView: View {
    // MARK: - Properties
    @StateObject private var authService = AuthenticationService.shared
    @EnvironmentObject var plaidManager: PlaidManager
    
    // User preferences
    @AppStorage("biometricAuthEnabled") private var biometricAuthEnabled = true
    @AppStorage("requireBiometricsOnOpen") private var requireBiometricsOnOpen = true
    @AppStorage("requireBiometricsForTransactions") private var requireBiometricsForTransactions = false
    
    // Notifications
    @AppStorage("notificationsEnabled") private var notificationsEnabled = true
    @AppStorage("budgetAlertNotifications") private var budgetAlertNotifications = true
    
    // Display preferences
    @AppStorage("showBalanceOnHomeScreen") private var showBalanceOnHomeScreen = true
    
    // Budget preferences
    @AppStorage("budgetCycleStartDay") private var budgetCycleStartDay = 1
    
    // States
    @State private var showingSignOutAlert = false
    @State private var showingAboutSheet = false
    @State private var showingBiometricSetupError = false
    @State private var biometricErrorMessage = ""
    @State private var showingExportDataSheet = false
    @State private var showingReportBugSheet = false
    @State private var showingEditProfileSheet = false
    
    // Lists for pickers
    let monthDays = Array(1...31).map { String($0) }
    let availableBiometrics: BiometricType = AuthenticationService.shared.getBiometricType()
    
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
            
            // Non-clickable profile card
            HStack(spacing: 20) {
                // Profile image
                ZStack {
                    Circle()
                        .fill(AppTheme.accentPurple.opacity(0.3))
                        .frame(width: 75, height: 75)
                    
                    if let photoURL = authService.user?.photoURL, let url = URL(string: photoURL.absoluteString) {
                        AsyncImage(url: url) { image in
                            image
                                .resizable()
                                .scaledToFill()
                                .frame(width: 75, height: 75)
                                .clipShape(Circle())
                        } placeholder: {
                            Image(systemName: "person.fill")
                                .font(.system(size: 32))
                                .foregroundColor(AppTheme.textColor)
                        }
                    } else {
                        Image(systemName: "person.fill")
                            .font(.system(size: 32))
                            .foregroundColor(AppTheme.textColor)
                    }
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
                
                // NavigationLink for Delete Account
                NavigationLink(destination: DeleteAccountView()) {
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
                if availableBiometrics != .none {
                    settingsToggle(
                        title: "Biometric Authentication",
                        subtitle: "Use \(availableBiometrics.name) to secure your account",
                        isOn: $biometricAuthEnabled,
                        icon: availableBiometrics == .faceID ? "faceid" : "touchid"
                    ) {
                        checkAndEnableBiometrics(isEnabled: biometricAuthEnabled)
                        // If biometrics are disabled, also disable dependent options
                        if !biometricAuthEnabled {
                            requireBiometricsOnOpen = false
                            requireBiometricsForTransactions = false
                        }
                    }
                    
                    if biometricAuthEnabled {
                        Divider()
                            .background(AppTheme.textColor.opacity(0.1))
                        
                        settingsToggle(
                            title: "Require on App Launch",
                            subtitle: "Verify identity each time you open the app",
                            isOn: $requireBiometricsOnOpen,
                            icon: "app.fill"
                        ) {
                            // Reset the biometric check to force authentication on next app launch
                            if requireBiometricsOnOpen {
                                UserDefaults.standard.set(false, forKey: "hasPassedBiometricCheck")
                            }
                        }
                        
                        Divider()
                            .background(AppTheme.textColor.opacity(0.1))
                        
                        settingsToggle(
                            title: "Require for Transactions",
                            subtitle: "Verify identity for transactions over $50",
                            isOn: $requireBiometricsForTransactions,
                            icon: "dollarsign.circle.fill"
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
            exportData(type: title)
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
    
    // Export data to CSV function
    private func exportData(type: String) {
        // In a real implementation, this would generate and export CSV files
        // Here we're just simulating the export
        
        // Create a temporary activity indicator
        let activityIndicator = UIActivityIndicatorView(style: .large)
//        activityIndicator.center = UIScreen.main.bounds.center
        activityIndicator.startAnimating()
        
        if let window = UIApplication.shared.windows.first {
            window.addSubview(activityIndicator)
        }
        
        // Simulate export process
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            // Remove activity indicator
            activityIndicator.removeFromSuperview()
            
            // Simulate successful export
            let alertController = UIAlertController(
                title: "Export Complete",
                message: "\(type) data has been exported successfully.",
                preferredStyle: .alert
            )
            
            alertController.addAction(UIAlertAction(title: "OK", style: .default))
            
            if let window = UIApplication.shared.windows.first,
               let rootViewController = window.rootViewController {
                rootViewController.present(alertController, animated: true)
            }
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            SettingsView()
                .environmentObject(PlaidManager.shared)
        }
        .preferredColorScheme(.dark)
    }
}
