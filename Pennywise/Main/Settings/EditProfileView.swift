//
//  EditProfileView.swift
//  Pennywise
//
//  Created by Arnav Varyani on 4/24/25.
//

import SwiftUI
import Firebase
import FirebaseStorage

struct EditProfileView: View {
    @Binding var isPresented: Bool
    @StateObject private var authService = AuthenticationService.shared
    
    @State private var displayName = ""
    @State private var email = ""
    @State private var isLoading = false
    @State private var showSuccessAlert = false
    @State private var errorMessage = ""
    @State private var showError = false
    @State private var showImagePicker = false
    @State private var inputImage: UIImage?
    @State private var profileImage: Image?
    @State private var isUploadingImage = false
    
    var body: some View {
        NavigationView {
            ZStack {
                AppTheme.backgroundGradient.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Profile image
                        ZStack {
                            if let profileImage = profileImage {
                                profileImage
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
                            
                            TextField("", text: $displayName)
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
            }
            .alert(isPresented: $showSuccessAlert) {
                Alert(
                    title: Text("Profile Updated"),
                    message: Text("Your profile has been updated successfully."),
                    dismissButton: .default(Text("OK")) {
                        isPresented = false
                    }
                )
            }
            .sheet(isPresented: $showImagePicker) {
                ImagePicker(image: $inputImage)
            }
            .onChange(of: inputImage) { _ in
                loadImage()
            }
        }
    }
    
    private func loadImage() {
        guard let inputImage = inputImage else { return }
        profileImage = Image(uiImage: inputImage)
    }
    
    private func loadUserData() {
        if let user = authService.user {
            displayName = user.displayName ?? ""
            email = user.email ?? ""
            
            // Load profile image from Firebase if available
            if let photoURL = user.photoURL {
                loadProfileImage(from: photoURL)
            }
        }
    }
    
    private func loadProfileImage(from url: URL) {
        URLSession.shared.dataTask(with: url) { data, _, _ in
            if let data = data, let uiImage = UIImage(data: data) {
                DispatchQueue.main.async {
                    self.profileImage = Image(uiImage: uiImage)
                }
            }
        }.resume()
    }
    
    private func updateProfile() {
        guard let user = authService.user else {
            errorMessage = "User not found"
            showError = true
            return
        }
        
        isLoading = true
        
        // Function to complete the profile update
        let completeProfileUpdate = {
            // Update user display name in Firebase Auth
            let changeRequest = user.createProfileChangeRequest()
            changeRequest.displayName = displayName
            
            changeRequest.commitChanges { error in
                if let error = error {
                    DispatchQueue.main.async {
                        isLoading = false
                        errorMessage = "Error updating profile: \(error.localizedDescription)"
                        showError = true
                    }
                } else {
                    // Update user data in Firestore
                    let db = Firestore.firestore()
                    db.collection("users").document(user.uid).updateData([
                        "name": displayName,
                        "updatedAt": FieldValue.serverTimestamp()
                    ]) { firestoreError in
                        DispatchQueue.main.async {
                            isLoading = false
                            
                            if let firestoreError = firestoreError {
                                errorMessage = "Error updating Firestore: \(firestoreError.localizedDescription)"
                                showError = true
                            } else {
                                showSuccessAlert = true
                            }
                        }
                    }
                }
            }
        }
        
        // If there's a new profile image, upload it first
        if let inputImage = inputImage {
            uploadProfileImage(inputImage) { result in
                switch result {
                case .success(let url):
                    // Update user photo URL in Firebase Auth
                    let changeRequest = user.createProfileChangeRequest()
                    changeRequest.photoURL = url
                    
                    changeRequest.commitChanges { error in
                        if let error = error {
                            DispatchQueue.main.async {
                                isLoading = false
                                errorMessage = "Error updating profile image: \(error.localizedDescription)"
                                showError = true
                            }
                        } else {
                            // Continue with profile update
                            completeProfileUpdate()
                        }
                    }
                    
                case .failure(let error):
                    DispatchQueue.main.async {
                        isLoading = false
                        errorMessage = "Error uploading image: \(error.localizedDescription)"
                        showError = true
                    }
                }
            }
        } else {
            // No new image, just update the profile
            completeProfileUpdate()
        }
    }
    
    private func uploadProfileImage(_ image: UIImage, completion: @escaping (Result<URL, Error>) -> Void) {
        guard let user = authService.user else {
            completion(.failure(NSError(domain: "EditProfileView", code: 0, userInfo: [NSLocalizedDescriptionKey: "User not logged in"])))
            return
        }
        
        // Resize image for storage efficiency
        guard let resizedImageData = image.jpegData(compressionQuality: 0.5) else {
            completion(.failure(NSError(domain: "EditProfileView", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to compress image"])))
            return
        }
        
        // Create a reference to the file you want to upload
        let storageRef = Storage.storage().reference()
        let profileRef = storageRef.child("profile_images/\(user.uid).jpg")
        
        // Upload the file
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        
        let uploadTask = profileRef.putData(resizedImageData, metadata: metadata) { metadata, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            // Get download URL
            profileRef.downloadURL { url, error in
                if let error = error {
                    completion(.failure(error))
                    return
                }
                
                guard let downloadURL = url else {
                    completion(.failure(NSError(domain: "EditProfileView", code: 2, userInfo: [NSLocalizedDescriptionKey: "Failed to get download URL"])))
                    return
                }
                
                completion(.success(downloadURL))
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
