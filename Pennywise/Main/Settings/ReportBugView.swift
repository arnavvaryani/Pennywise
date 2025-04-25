//
//  ReportBugView.swift
//  Pennywise
//
//  Created by Arnav Varyani on 4/24/25.
//

import SwiftUI
import Firebase
import FirebaseFirestore

struct ReportBugView: View {
    @Binding var isPresented: Bool
    @StateObject private var authService = AuthenticationService.shared
    
    @State private var bugDescription = ""
    @State private var email = ""
    @State private var includeDeviceInfo = true
    @State private var includeAppLogs = true
    @State private var bugCategory = "General"
    @State private var isSubmitting = false
    @State private var showSuccessAlert = false
    @State private var errorMessage = ""
    @State private var showError = false
    
    let categories = ["General", "Transaction Issues", "Budget Issues", "Account Issues", "UI/Display Issues", "Other"]
    
    var body: some View {
        NavigationView {
            ZStack {
                AppTheme.backgroundGradient.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Bug description
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Describe the issue")
                                .font(.headline)
                                .foregroundColor(AppTheme.textColor)
                            
                            TextEditor(text: $bugDescription)
                                .foregroundColor(AppTheme.textColor)
                                .frame(minHeight: 150)
                                .background(AppTheme.cardBackground)
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(AppTheme.cardStroke, lineWidth: 1)
                                )
                                .padding(.bottom, 4)
                            
                            Text("Please be as specific as possible and include any steps to reproduce the issue")
                                .font(.caption)
                                .foregroundColor(AppTheme.textColor.opacity(0.6))
                        }
                        
                        // Bug category
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Bug Category")
                                .font(.headline)
                                .foregroundColor(AppTheme.textColor)
                            
                            Menu {
                                ForEach(categories, id: \.self) { category in
                                    Button(category) {
                                        bugCategory = category
                                    }
                                }
                            } label: {
                                HStack {
                                    Text(bugCategory)
                                        .foregroundColor(AppTheme.textColor)
                                    Spacer()
                                    Image(systemName: "chevron.down")
                                        .foregroundColor(AppTheme.textColor.opacity(0.5))
                                }
                                .padding()
                                .background(AppTheme.cardBackground)
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(AppTheme.cardStroke, lineWidth: 1)
                                )
                            }
                        }
                        
                        // Email
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Your Email (optional)")
                                .font(.headline)
                                .foregroundColor(AppTheme.textColor)
                            
                            TextField("email@example.com", text: $email)
                                .foregroundColor(AppTheme.textColor)
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                                .padding()
                                .background(AppTheme.cardBackground)
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(AppTheme.cardStroke, lineWidth: 1)
                                )
                            
                            Text("We'll only use this to follow up about this specific issue")
                                .font(.caption)
                                .foregroundColor(AppTheme.textColor.opacity(0.6))
                        }
                        
                        // Include device info toggle
                        Toggle(isOn: $includeDeviceInfo) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Include Device Information")
                                    .font(.headline)
                                    .foregroundColor(AppTheme.textColor)
                                
                                Text("Helps us understand your environment")
                                    .font(.caption)
                                    .foregroundColor(AppTheme.textColor.opacity(0.6))
                            }
                        }
                        .toggleStyle(SwitchToggleStyle(tint: AppTheme.primaryGreen))
                        .padding()
                        .background(AppTheme.cardBackground)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(AppTheme.cardStroke, lineWidth: 1)
                        )
                        
                        // Include logs toggle
                        Toggle(isOn: $includeAppLogs) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Include App Logs")
                                    .font(.headline)
                                    .foregroundColor(AppTheme.textColor)
                                
                                Text("Helps us diagnose technical issues")
                                    .font(.caption)
                                    .foregroundColor(AppTheme.textColor.opacity(0.6))
                            }
                        }
                        .toggleStyle(SwitchToggleStyle(tint: AppTheme.primaryGreen))
                        .padding()
                        .background(AppTheme.cardBackground)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(AppTheme.cardStroke, lineWidth: 1)
                        )
                        
                        // Error message (if any)
                        if !errorMessage.isEmpty {
                            HStack {
                                Image(systemName: "exclamationmark.triangle")
                                    .foregroundColor(AppTheme.expenseColor)
                                
                                Text(errorMessage)
                                    .font(.caption)
                                    .foregroundColor(AppTheme.expenseColor)
                            }
                            .padding()
                            .background(AppTheme.expenseColor.opacity(0.1))
                            .cornerRadius(8)
                        }
                        
                        // Submit button
                        Button(action: {
                            submitBugReport()
                        }) {
                            if isSubmitting {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Text("Submit Bug Report")
                                    .font(.headline)
                                    .foregroundColor(.white)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(bugDescription.isEmpty ? AppTheme.primaryGreen.opacity(0.5) : AppTheme.primaryGreen)
                        .cornerRadius(12)
                        .disabled(bugDescription.isEmpty || isSubmitting)
                        .padding(.top, 10)
                    }
                    .padding()
                }
            }
            .navigationTitle("Report a Bug")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        isPresented = false
                    }
                    .foregroundColor(AppTheme.primaryGreen)
                }
            }
            .alert(isPresented: $showSuccessAlert) {
                Alert(
                    title: Text("Thank You"),
                    message: Text("Your bug report has been submitted successfully. We appreciate your feedback!"),
                    dismissButton: .default(Text("OK")) {
                        isPresented = false
                    }
                )
            }
        }
    }
    
    private func getDeviceInfo() -> [String: Any] {
        let device = UIDevice.current
        let screenSize = UIScreen.main.bounds.size
        
        let deviceInfo: [String: Any] = [
            "model": device.model,
            "systemName": device.systemName,
            "systemVersion": device.systemVersion,
            "screenWidth": screenSize.width,
            "screenHeight": screenSize.height,
            "batteryLevel": device.batteryLevel >= 0 ? Int(device.batteryLevel * 100) : "Unknown",
            "batteryState": getBatteryStateString(device.batteryState),
            "appVersion": Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown",
            "buildNumber": Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"
        ]
        
        return deviceInfo
    }
    
    private func getBatteryStateString(_ state: UIDevice.BatteryState) -> String {
        switch state {
        case .charging:
            return "Charging"
        case .full:
            return "Full"
        case .unplugged:
            return "Unplugged"
        case .unknown:
            return "Unknown"
        @unknown default:
            return "Unknown"
        }
    }
    
    private func submitBugReport() {
        guard !bugDescription.isEmpty else { return }
        
        // Enable battery monitoring to get battery info
        UIDevice.current.isBatteryMonitoringEnabled = true
        
        isSubmitting = true
        errorMessage = ""
        
        // Prepare bug report data
        var bugReportData: [String: Any] = [
            "description": bugDescription,
            "category": bugCategory,
            "timestamp": FieldValue.serverTimestamp()
        ]
        
        // Add optional email if provided
        if !email.isEmpty {
            bugReportData["email"] = email
        }
        
        // Add user ID if signed in
        if let userId = authService.user?.uid {
            bugReportData["userId"] = userId
        }
        
        // Add device info if requested
        if includeDeviceInfo {
            bugReportData["deviceInfo"] = getDeviceInfo()
        }
        
        // Add app logs if requested
        if includeAppLogs {
            // In a real app, you would collect and add actual app logs
            bugReportData["appLogs"] = "App logs would be included here in production"
        }
        
        // Use Firebase to save the bug report
        let db = Firestore.firestore()
        db.collection("bugReports").addDocument(data: bugReportData) { error in
            // Disable battery monitoring when done
            UIDevice.current.isBatteryMonitoringEnabled = false
            
            DispatchQueue.main.async {
                isSubmitting = false
                
                if let error = error {
                    errorMessage = "Failed to submit bug report: \(error.localizedDescription)"
                    showError = true
                } else {
                    showSuccessAlert = true
                }
            }
        }
    }
}

// Helper struct to allow previews
struct ReportBugView_Previews: PreviewProvider {
    static var previews: some View {
        ReportBugView(isPresented: .constant(true))
            .environmentObject(AuthenticationService.shared)
    }
}
