//
//  ReportBugView.swift
//  Pennywise
//
//  Created by Arnav Varyani on 4/24/25.
//

import SwiftUI

struct ReportBugView: View {
    @Binding var isPresented: Bool
    @State private var bugDescription = ""
    @State private var email = ""
    @State private var includeDeviceInfo = true
    @State private var includeAppLogs = true
    @State private var bugCategory = "General"
    @State private var isSubmitting = false
    @State private var showSuccessAlert = false
    
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
    
    private func submitBugReport() {
        isSubmitting = true
        
        // Simulate network request
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            isSubmitting = false
            showSuccessAlert = true
        }
    }
}
