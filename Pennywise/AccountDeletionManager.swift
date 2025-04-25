//
//  AccountDeletionManager.swift
//  Pennywise
//
//  Created by Arnav Varyani on 4/25/25.
//


import Foundation
import Firebase
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage

class AccountDeletionManager {
    static let shared = AccountDeletionManager()
    
    private init() {}
    
    /// Deletes the user's account and all associated data
    func deleteUserAccount(currentPassword: String, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let user = Auth.auth().currentUser, let email = user.email else {
            completion(.failure(NSError(domain: "AccountDeletionManager", code: 0, userInfo: [NSLocalizedDescriptionKey: "User not signed in"])))
            return
        }
        
        // Create credential with current password for re-authentication
        let credential = EmailAuthProvider.credential(withEmail: email, password: currentPassword)
        
        // Re-authenticate the user
        user.reauthenticate(with: credential) { [weak self] _, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            // User successfully re-authenticated, proceed with data deletion
            self?.deleteUserData(for: user.uid) { result in
                switch result {
                case .success:
                    // Now delete the Firebase Auth account
                    user.delete { error in
                        if let error = error {
                            completion(.failure(error))
                        } else {
                            completion(.success(()))
                        }
                    }
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        }
    }
    
    /// Delete all user data from Firestore and Storage
    private func deleteUserData(for userId: String, completion: @escaping (Result<Void, Error>) -> Void) {
        let db = Firestore.firestore()
        let storage = Storage.storage()
        let dispatchGroup = DispatchGroup()
        var deleteError: Error?
        
        // 1. Delete user's profile image from Storage
        dispatchGroup.enter()
        let profileImageRef = storage.reference().child("profile_images/\(userId).jpg")
        profileImageRef.delete { error in
            // We don't fail if the image doesn't exist, just continue
            dispatchGroup.leave()
        }
        
        // 2. Delete user data from Firestore collections
        // List of collections to check for user data
        let collections = [
            "users",
            "users/\(userId)/accounts",
            "users/\(userId)/transactions",
            "users/\(userId)/budgetCategories",
            "users/\(userId)/budget",
            "users/\(userId)/insights",
            "users/\(userId)/savingsTips"
        ]
        
        for collectionPath in collections {
            dispatchGroup.enter()
            
            if collectionPath == "users" {
                // For the users collection, delete only the user's document
                db.collection(collectionPath).document(userId).delete { error in
                    if let error = error {
                        deleteError = error
                    }
                    dispatchGroup.leave()
                }
            } else {
                // For subcollections, delete all documents
                db.collection(collectionPath).getDocuments { snapshot, error in
                    if let error = error {
                        deleteError = error
                        dispatchGroup.leave()
                        return
                    }
                    
                    // If there are no documents, just leave the group
                    guard let documents = snapshot?.documents, !documents.isEmpty else {
                        dispatchGroup.leave()
                        return
                    }
                    
                    // Delete documents in batches of 500 (Firestore limit)
                    let batches = stride(from: 0, to: documents.count, by: 500).map {
                        Array(documents[$0..<min($0 + 500, documents.count)])
                    }
                    
                    for batch in batches {
                        let batchOperation = db.batch()
                        
                        for document in batch {
                            batchOperation.deleteDocument(document.reference)
                        }
                        
                        batchOperation.commit { error in
                            if let error = error {
                                deleteError = error
                            }
                        }
                    }
                    
                    dispatchGroup.leave()
                }
            }
        }
        
        // Wait for all deletion operations to complete
        dispatchGroup.notify(queue: .main) {
            if let error = deleteError {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }
}
