//
//  EditProfileView.swift
//  Pennywise
//
//  Created by Arnav Varyani on 4/24/25.
//

import SwiftUI
import Firebase
import FirebaseFirestore
import Combine
import FirebaseAuth

struct EditProfileView: View {
    @Binding var isPresented: Bool
    @StateObject private var authService = AuthenticationService.shared
    @Environment(\.presentationMode) var presentationMode
    
    @State private var displayName = ""
    @State private var email = ""
    @State private var isLoading = false
    @State private var showSuccessAlert = false
    @State private var errorMessage = ""
    @State private var showError = false
    @State private var showImagePicker = false
    @State private var inputImage: UIImage?
    @State private var profileImage: UIImage?
    @State private var displayProfileImage: Image?
    
    // UserDefaults keys for storing profile image
    private let profileImageKey = "userProfileImageData"
    
    var body: some View {
        NavigationView {
            ZStack {
                AppTheme.backgroundGradient.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Profile image
                        ZStack {
                            if let displayProfileImage = displayProfileImage {
                                displayProfileImage
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 120, height: 120)
                                    .clipShape(Circle())
                            } else {
                                Circle()
                                    .fill(AppTheme.accentPurple.opacity(0.3))
                                    .frame(width: 120, height: 120)
                                
                                Image(systemName: "person.fill")
                                    .font(.system(size: 60))
                                    .foregroundColor(AppTheme.textColor)
                            }
                                
                            // Edit button overlay
                            Button(action: {
                                showImagePicker = true
                            }) {
                                Circle()
                                    .fill(AppTheme.primaryGreen)
                                    .frame(width: 36, height: 36)
                                    .overlay(
                                        Image(systemName: "camera.fill")
                                            .font(.system(size: 16))
                                            .foregroundColor(.white)
                                    )
                                    .offset(x: 42, y: 42)
                            }
                        }
                        .padding(.top, 20)
                        
                        // Display name field
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Display Name")
                                .font(.headline)
                                .foregroundColor(AppTheme.textColor)
                            
                            TextField("Enter your name", text: $displayName)
                                .foregroundColor(AppTheme.textColor)
                                .padding()
                                .background(AppTheme.cardBackground)
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(AppTheme.cardStroke, lineWidth: 1)
                                )
                        }
                        
                        // Email field (read-only)
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Email Address")
                                .font(.headline)
                                .foregroundColor(AppTheme.textColor)
                            
                            TextField("", text: $email)
                                .foregroundColor(AppTheme.textColor.opacity(0.7))
                                .disabled(true)
                                .padding()
                                .background(AppTheme.cardBackground.opacity(0.7))
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(AppTheme.cardStroke, lineWidth: 1)
                                )
                            
                            Text("Email cannot be changed")
                                .font(.caption)
                                .foregroundColor(AppTheme.textColor.opacity(0.6))
                        }
                        
                        // Save button
                        Button(action: {
                            updateProfile()
                        }) {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Text("Save Changes")
                                    .font(.headline)
                                    .foregroundColor(.white)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(displayName.isEmpty ? AppTheme.primaryGreen.opacity(0.5) : AppTheme.primaryGreen)
                        .cornerRadius(12)
                        .disabled(displayName.isEmpty || isLoading)
                        .padding(.top, 20)
                        
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
                    }
                    .padding()
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        isPresented = false
                    }
                    .foregroundColor(AppTheme.primaryGreen)
                }
            }
            .onAppear {
                loadUserData()
                loadProfileImageFromLocalStorage()
            }
            .alert(isPresented: $showSuccessAlert) {
                Alert(
                    title: Text("Profile Updated"),
                    message: Text("Your profile has been updated successfully."),
                    dismissButton: .default(Text("OK")) {
                        // Dismiss the view
                        isPresented = false
                    }
                )
            }
            .sheet(isPresented: $showImagePicker) {
                ImagePicker(image: $inputImage)
            }
            .onChange(of: inputImage) { newImage in
                if let newImage = newImage {
                    // Store the UIImage for saving
                    profileImage = newImage
                    // Convert to SwiftUI Image for display
                    displayProfileImage = Image(uiImage: newImage)
                }
            }
        }
    }
    
    private func loadUserData() {
        if let user = authService.user {
            displayName = user.displayName ?? ""
            email = user.email ?? ""
        }
    }
    
    private func loadProfileImageFromLocalStorage() {
        if let imageData = UserDefaults.standard.data(forKey: profileImageKey),
           let uiImage = UIImage(data: imageData) {
            profileImage = uiImage
            displayProfileImage = Image(uiImage: uiImage)
        }
    }
    
    private func saveProfileImageToLocalStorage(_ image: UIImage) {
        if let imageData = image.jpegData(compressionQuality: 0.7) {
            UserDefaults.standard.set(imageData, forKey: profileImageKey)
        }
    }
    
    private func updateProfile() {
        guard let user = authService.user else {
            errorMessage = "User not found"
            showError = true
            return
        }
        
        isLoading = true
        
        // If we have a profile image, save it to local storage
        if let profileImage = profileImage {
            saveProfileImageToLocalStorage(profileImage)
        }
        
        // Update user display name in Firebase Auth
        let changeRequest = user.createProfileChangeRequest()
        changeRequest.displayName = displayName
        
        changeRequest.commitChanges { error in
            
            if let error = error {
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.errorMessage = "Error updating profile: \(error.localizedDescription)"
                    self.showError = true
                }
            } else {
                // Create or update user record in Firestore
                let db = Firestore.firestore()
                
                // Prepare the user data
                var userData: [String: Any] = [
                    "name": self.displayName,
                    "email": user.email ?? "",
                    "updatedAt": FieldValue.serverTimestamp()
                ]
                
                // Use setData with merge option to ensure document is created if it doesn't exist
                db.collection("users").document(user.uid).setData(userData, merge: true) { error in
    
                    
                    DispatchQueue.main.async {
                        self.isLoading = false
                        
                        if let error = error {
                            self.errorMessage = "Error updating Firestore: \(error.localizedDescription)"
                            self.showError = true
                            print("Firestore error: \(error.localizedDescription)")
                        } else {
                            // Manually synchronize the Auth Service's user object
                            // This ensures changes are visible in Settings screen
                            Auth.auth().currentUser?.reload { _ in
                                DispatchQueue.main.async {
                                    self.authService.user = Auth.auth().currentUser
                                    self.showSuccessAlert = true
                                    print("Profile updated successfully!")
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

// Image Picker to handle photo selection
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.presentationMode) private var presentationMode
    
    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.image = image
            }
            
            parent.presentationMode.wrappedValue.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIViewController(context: UIViewControllerRepresentableContext<ImagePicker>) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.allowsEditing = false
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: UIViewControllerRepresentableContext<ImagePicker>) {}
}
