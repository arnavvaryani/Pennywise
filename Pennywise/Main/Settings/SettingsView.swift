struct ExportAlert: Identifiable {
    var id: String { message }
    let message: String
}

import SwiftUI
import LocalAuthentication
import FirebaseAuth
import FirebaseFirestore

struct SettingsView: View {
    // MARK: - Properties
    @StateObject private var authService = AuthenticationService.shared
    @EnvironmentObject var plaidManager: PlaidManager
    
    // User preferences
    @AppStorage("biometricAuthEnabled") private var biometricAuthEnabled = true
    @AppStorage("requireBiometricsOnOpen") private var requireBiometricsOnOpen = true
    
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
    @State private var isExporting = false
    @State private var exportCompleteMessage: String? = nil
    @State private var showingShareSheet = false
    @State private var fileURLToShare: URL? = nil
    
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
        .sheet(isPresented: $showingShareSheet) {
            if let fileURL = fileURLToShare {
                ShareSheet(items: [fileURL])
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            checkBiometricAvailability()
        }
        .alert(item: Binding<ExportAlert?>(
            get: {
                exportCompleteMessage != nil ? ExportAlert(message: exportCompleteMessage!) : nil
            },
            set: { _ in
                exportCompleteMessage = nil
            }
        )) { alert in
            Alert(
                title: Text("Export Complete"),
                message: Text(alert.message),
                dismissButton: .default(Text("OK"))
            )
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
                    
                    Text("Choose what data you would like to export. The data will be exported as CSV files that you can open in Excel or other spreadsheet applications.")
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
                    
                    if isExporting {
                        VStack(spacing: 12) {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: AppTheme.primaryGreen))
                                .scaleEffect(1.5)
                            
                            Text("Preparing your data...")
                                .foregroundColor(AppTheme.textColor)
                        }
                        .padding(.top, 20)
                    }
                    
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
            .disabled(isExporting)
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
            // First close the sheet to avoid presentation conflicts
            showingExportDataSheet = false
            
            // Then after a short delay, start the export process
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                // Export data action with enhanced functionality
                exportDataAsCSV(type: title)
            }
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
        .disabled(isExporting)
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
    
    // Enhanced export data function that handles CSV generation
    private func exportDataAsCSV(type: String) {
        isExporting = true
        
        // First ensure we're logged in
        guard let userId = Auth.auth().currentUser?.uid else {
            DispatchQueue.main.async {
                isExporting = false
                exportCompleteMessage = "You must be logged in to export data"
            }
            return
        }
        
        // Reference to Firestore database
        let db = Firestore.firestore()
        
        // Perform export based on type
        switch type {
        case "Transactions":
            // Fetch transactions from Firebase
            fetchTransactionsFromFirebase(userId: userId, db: db) { result in
                switch result {
                case .success(let csv):
                    self.saveAndShareCSV(csv: csv, fileName: "transactions_\(self.formattedCurrentDate()).csv", type: type)
                case .failure(let error):
                    DispatchQueue.main.async {
                        self.isExporting = false
                        self.exportCompleteMessage = "Failed to export transactions: \(error.localizedDescription)"
                    }
                }
            }
            
        case "Budget Categories":
            // Fetch budget categories from Firebase
            fetchBudgetCategoriesFromFirebase(userId: userId, db: db) { result in
                switch result {
                case .success(let csv):
                    self.saveAndShareCSV(csv: csv, fileName: "budget_categories_\(self.formattedCurrentDate()).csv", type: type)
                case .failure(let error):
                    DispatchQueue.main.async {
                        self.isExporting = false
                        self.exportCompleteMessage = "Failed to export budget categories: \(error.localizedDescription)"
                    }
                }
            }
            
        case "Accounts Summary":
            // Fetch accounts from Firebase
            fetchAccountsFromFirebase(userId: userId, db: db) { result in
                switch result {
                case .success(let csv):
                    self.saveAndShareCSV(csv: csv, fileName: "accounts_\(self.formattedCurrentDate()).csv", type: type)
                case .failure(let error):
                    DispatchQueue.main.async {
                        self.isExporting = false
                        self.exportCompleteMessage = "Failed to export accounts: \(error.localizedDescription)"
                    }
                }
            }
            
        case "Export All Data":
            // Fetch all data and combine into multiple files
            let group = DispatchGroup()
            var transactionsCSV = ""
            var budgetCategoriesCSV = ""
            var accountsCSV = ""
            var exportError: Error? = nil
            
            // Fetch transactions
            group.enter()
            fetchTransactionsFromFirebase(userId: userId, db: db) { result in
                switch result {
                case .success(let csv):
                    transactionsCSV = csv
                case .failure(let error):
                    exportError = error
                }
                group.leave()
            }
            
            // Fetch budget categories
            group.enter()
            fetchBudgetCategoriesFromFirebase(userId: userId, db: db) { result in
                switch result {
                case .success(let csv):
                    budgetCategoriesCSV = csv
                case .failure(let error):
                    if exportError == nil {
                        exportError = error
                    }
                }
                group.leave()
            }
            
            // Fetch accounts
            group.enter()
            fetchAccountsFromFirebase(userId: userId, db: db) { result in
                switch result {
                case .success(let csv):
                    accountsCSV = csv
                case .failure(let error):
                    if exportError == nil {
                        exportError = error
                    }
                }
                group.leave()
            }
            
            // When all fetches complete
            group.notify(queue: .main) {
                if let error = exportError {
                    self.isExporting = false
                    self.exportCompleteMessage = "Failed to export all data: \(error.localizedDescription)"
                    return
                }
                
                // Create a directory for the exports
                let exportDirectoryName = "pennywise_export_\(self.formattedCurrentDate())"
                
                // Get the documents directory URL
                if let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
                    let exportDirectory = documentsDirectory.appendingPathComponent(exportDirectoryName)
                    
                    do {
                        // Create the directory
                        try FileManager.default.createDirectory(at: exportDirectory, withIntermediateDirectories: true)
                        
                        // Save each CSV file
                        try transactionsCSV.write(to: exportDirectory.appendingPathComponent("transactions.csv"), atomically: true, encoding: .utf8)
                        try budgetCategoriesCSV.write(to: exportDirectory.appendingPathComponent("budget_categories.csv"), atomically: true, encoding: .utf8)
                        try accountsCSV.write(to: exportDirectory.appendingPathComponent("accounts.csv"), atomically: true, encoding: .utf8)
                        
                        // Create a README file
                        let readme = """
                        Pennywise Data Export
                        Date: \(self.formatReadableDate(Date()))
                        
                        This folder contains the following files:
                        - transactions.csv: All your financial transactions
                        - budget_categories.csv: Your budget categories and spending
                        - accounts.csv: Your linked financial accounts
                        
                        You can open these files in any spreadsheet application like Excel or Google Sheets.
                        """
                        
                        try readme.write(to: exportDirectory.appendingPathComponent("README.txt"), atomically: true, encoding: .utf8)
                        
                        // Share the directory or inform the user
                        self.isExporting = false
                        self.exportCompleteMessage = "All data has been exported successfully to \(exportDirectoryName) in your Documents folder"
                    } catch {
                        self.isExporting = false
                        self.exportCompleteMessage = "Failed to save export files: \(error.localizedDescription)"
                    }
                } else {
                    self.isExporting = false
                    self.exportCompleteMessage = "Failed to access documents directory"
                }
            }
            
        default:
            DispatchQueue.main.async {
                isExporting = false
                exportCompleteMessage = "Invalid export type selected"
            }
        }
    }
    
    // Save and share a CSV file
    private func saveAndShareCSV(csv: String, fileName: String, type: String) {
        // Get the documents directory URL
        if let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            let fileURL = documentsDirectory.appendingPathComponent(fileName)
            
            do {
                try csv.write(to: fileURL, atomically: true, encoding: .utf8)
                
                // Share the file
                DispatchQueue.main.async {
                    self.isExporting = false
                    
                    // Create activity view controller to share the file
                    self.shareCSVFile(fileURL: fileURL, type: type)
                }
            } catch {
                DispatchQueue.main.async {
                    self.isExporting = false
                    self.exportCompleteMessage = "Failed to save data: \(error.localizedDescription)"
                }
            }
        } else {
            DispatchQueue.main.async {
                self.isExporting = false
                self.exportCompleteMessage = "Failed to access documents directory"
            }
        }
    }
    
    // Fetch transactions from Firebase
    private func fetchTransactionsFromFirebase(userId: String, db: Firestore, completion: @escaping (Result<String, Error>) -> Void) {
        // CSV header
        var csv = "Transaction ID,Date,Merchant,Category,Amount,Status\n"
        
        // Query transactions collection
        db.collection("users/\(userId)/transactions")
            .getDocuments { snapshot, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    completion(.success(csv)) // Return just the header if no transactions
                    return
                }
                
                // Process each transaction document
                for document in documents {
                    let data = document.data()
                    
                    // Extract transaction data
                    let transactionId = document.documentID
                    
                    guard let dateTimestamp = data["date"] as? Timestamp,
                          let merchant = data["merchantName"] as? String,
                          let category = data["category"] as? String,
                          let amount = data["amount"] as? Double else {
                        continue // Skip if missing required fields
                    }
                    
                    let date = dateTimestamp.dateValue()
                    let pending = data["pending"] as? Bool ?? false
                    
                    // Format data for CSV
                    let formattedDate = self.formatCSVDate(date)
                    let formattedAmount = String(format: "%.2f", amount)
                    let status = pending ? "Pending" : "Completed"
                    
                    // Sanitize fields to avoid CSV issues
                    let merchantName = self.sanitizeCSVField(merchant)
                    let categoryName = self.sanitizeCSVField(category)
                    
                    // Add the transaction row
                    csv += "\(transactionId),\(formattedDate),\(merchantName),\(categoryName),\(formattedAmount),\(status)\n"
                }
                
                completion(.success(csv))
            }
    }
    
    // Fetch budget categories from Firebase
    private func fetchBudgetCategoriesFromFirebase(userId: String, db: Firestore, completion: @escaping (Result<String, Error>) -> Void) {
        // CSV header
        var csv = "Category ID,Category Name,Budget Amount,Icon,Color,Is Essential\n"
        
        // Query budget categories collection
        db.collection("users/\(userId)/budgetCategories")
            .getDocuments { snapshot, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    completion(.success(csv)) // Return just the header if no categories
                    return
                }
                
                // Process each budget category document
                for document in documents {
                    let data = document.data()
                    
                    // Extract category data
                    let categoryId = document.documentID
                    
                    guard let name = data["name"] as? String,
                          let amount = data["amount"] as? Double,
                          let icon = data["icon"] as? String,
                          let colorHex = data["color"] as? String else {
                        continue // Skip if missing required fields
                    }
                    
                    let isEssential = data["isEssential"] as? Bool ?? false
                    
                    // Format data for CSV
                    let formattedAmount = String(format: "%.2f", amount)
                    
                    // Sanitize fields to avoid CSV issues
                    let categoryName = self.sanitizeCSVField(name)
                    let iconName = self.sanitizeCSVField(icon)
                    
                    // Add the category row
                    csv += "\(categoryId),\(categoryName),\(formattedAmount),\(iconName),\(colorHex),\(isEssential)\n"
                }
                
                // After getting the categories, also fetch the monthly budget usage
                self.fetchMonthlyBudgetUsage(userId: userId, db: db) { result in
                    switch result {
                    case .success(let usageCSV):
                        // Combine the category data with the usage data
                        csv += "\n\nMonthly Budget Usage\n" + usageCSV
                        completion(.success(csv))
                    case .failure:
                        // If we fail to get usage data, just return the categories
                        completion(.success(csv))
                    }
                }
            }
    }
    
    // Fetch monthly budget usage from Firebase
    private func fetchMonthlyBudgetUsage(userId: String, db: Firestore, completion: @escaping (Result<String, Error>) -> Void) {
        // Get current month and year
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM"
        let currentYearMonth = dateFormatter.string(from: Date())
        
        // CSV header
        var csv = "Month,Category,Budget Amount,Spent Amount,Remaining\n"
        
        // Query monthly budget document
        db.collection("users/\(userId)/budget").document(currentYearMonth)
            .getDocument { document, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                guard let document = document, document.exists,
                      let data = document.data() else {
                    completion(.success(csv)) // Return just the header if no usage data
                    return
                }
                
                // Get categories usage data
                if let categories = data["categories"] as? [String: [String: Double]] {
                    // Fetch category names
                    db.collection("users/\(userId)/budgetCategories").getDocuments { snapshot, error in
                        var categoryNames: [String: String] = [:]
                        
                        if let documents = snapshot?.documents {
                            for doc in documents {
                                if let name = doc.data()["name"] as? String {
                                    categoryNames[doc.documentID] = name
                                }
                            }
                        }
                        
                        // Process budget usage data
                        for (categoryId, usageData) in categories {
                            let budget = usageData["budget"] ?? 0.0
                            let spent = usageData["spent"] ?? 0.0
                            let remaining = max(0, budget - spent)
                            
                            // Get category name or use ID if not found
                            let categoryName = self.sanitizeCSVField(categoryNames[categoryId] ?? "Category \(categoryId)")
                            
                            // Add the usage row
                            csv += "\(currentYearMonth),\(categoryName),\(String(format: "%.2f", budget)),\(String(format: "%.2f", spent)),\(String(format: "%.2f", remaining))\n"
                        }
                        
                        completion(.success(csv))
                    }
                } else {
                    // No categories usage data
                    completion(.success(csv))
                }
            }
    }
    
    // Fetch accounts from Firebase
    private func fetchAccountsFromFirebase(userId: String, db: Firestore, completion: @escaping (Result<String, Error>) -> Void) {
        // CSV header
        var csv = "Account ID,Account Name,Institution,Type,Balance,Last Updated\n"
        
        // Query accounts collection
        db.collection("users/\(userId)/accounts")
            .getDocuments { snapshot, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    completion(.success(csv)) // Return just the header if no accounts
                    return
                }
                
                // Process each account document
                for document in documents {
                    let data = document.data()
                    
                    // Extract account data
                    let accountId = document.documentID
                    
                    guard let name = data["name"] as? String,
                          let type = data["type"] as? String,
                          let balance = data["balance"] as? Double,
                          let institutionName = data["institutionName"] as? String else {
                        continue // Skip if missing required fields
                    }
                    
                    // Get last updated timestamp
                    let lastUpdated: Date
                    if let lastUpdatedTimestamp = data["lastUpdated"] as? Timestamp {
                        lastUpdated = lastUpdatedTimestamp.dateValue()
                    } else {
                        lastUpdated = Date()
                    }
                    
                    // Format data for CSV
                    let formattedBalance = String(format: "%.2f", balance)
                    let formattedLastUpdated = self.formatCSVDate(lastUpdated)
                    
                    // Sanitize fields to avoid CSV issues
                    let accountName = self.sanitizeCSVField(name)
                    let institution = self.sanitizeCSVField(institutionName)
                    let accountType = self.sanitizeCSVField(type)
                    
                    // Add the account row
                    csv += "\(accountId),\(accountName),\(institution),\(accountType),\(formattedBalance),\(formattedLastUpdated)\n"
                }
                
                completion(.success(csv))
            }
    }
    
    // Helper method to share CSV file
    private func shareCSVFile(fileURL: URL, type: String) {
        self.fileURLToShare = fileURL
        
        DispatchQueue.main.async {
            self.isExporting = false
            self.showingExportDataSheet = false
            
            // Show share sheet after a short delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                self.showingShareSheet = true
            }
        }
    }
    
    // These methods are no longer used as we fetch directly from Firebase
    // They remain here as fallbacks if Firebase fetching fails
    
    // Format date for readable display
    private func formatReadableDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    // Helper to sanitize CSV fields
    private func sanitizeCSVField(_ field: String) -> String {
        // If the field contains commas, quotes, or newlines, enclose it in quotes
        // And escape any existing quotes by doubling them
        let needsQuotes = field.contains(",") || field.contains("\"") || field.contains("\n")
        let escapedField = field.replacingOccurrences(of: "\"", with: "\"\"")
        
        return needsQuotes ? "\"\(escapedField)\"" : escapedField
    }
    
    // Format date for CSV
    private func formatCSVDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
    
    // Get formatted current date string for filenames
    private func formattedCurrentDate() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd_HHmmss"
        return formatter.string(from: Date())
    }
    
    // Calculate spent amount for a specific category
    private func calculateSpentForCategory(_ category: BudgetCategory) -> Double {
        // Filter transactions for the current month and this category
        let calendar = Calendar.current
        let now = Date()
        let components = calendar.dateComponents([.year, .month], from: now)
        
        guard let startOfMonth = calendar.date(from: components),
              let nextMonth = calendar.date(byAdding: .month, value: 1, to: startOfMonth),
              let startOfNextMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: nextMonth)) else {
            return 0.0
        }
        
        // Sum up the spending for this category
        return plaidManager.transactions
            .filter { transaction in
                transaction.date >= startOfMonth &&
                transaction.date < startOfNextMonth &&
                transaction.category.lowercased() == category.name.lowercased() &&
                transaction.amount > 0 // Only expenses
            }
            .reduce(0) { $0 + $1.amount }
    }
}

// Alert type for export completion
// MARK: - Share Sheet for CSV Files
struct ShareSheet: UIViewControllerRepresentable {
    var items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: items,
            applicationActivities: nil
        )
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
        // Nothing to do here
    }
}
