//
//  AccountDeletionManager.swift
//  Pennywise
//
//  Updated 2025-04-25
//

import Foundation
import FirebaseAuth
import FirebaseFirestore

/// Handles irreversible deletion of the user’s FirebaseAuth account
/// **and** all `/users/{uid}` data in Firestore. No password prompt.
final class AccountDeletionManager {

    // MARK: Singleton
    static let shared = AccountDeletionManager()
    private init() {}

    // MARK: Public API -------------------------------------------------------

    /// Deletes every trace of the signed-in user.
    ///
    /// Call this only after your UI has asked the user to type
    /// `DELETE` (or similar) and they confirmed.
    func deleteAccount(completion: @escaping (Result<Void, Error>) -> Void) {

        guard let user = Auth.auth().currentUser else {
            completion(.failure(DeleteError.noSignedInUser))
            return
        }

        // 1. Purge Firestore user data first
        deleteUserData(uid: user.uid) { [weak self] dataResult in
            guard let self = self else { return }

            switch dataResult {
            case .failure(let error):
                completion(.failure(error))

            case .success:
                // 2. Delete the Auth account
                user.delete { deleteError in
                    if let deleteError = deleteError {
                        completion(.failure(deleteError)) // may be .requiresRecentLogin
                        return
                    }

                    // 3. Sign out locally
                    do {
                        try Auth.auth().signOut()
                        completion(.success(()))
                    } catch {
                        completion(.failure(error))
                    }
                }
            }
        }
    }

    // MARK: Firestore purge (same as previous version) ----------------------

    private func deleteUserData(uid: String,
                                completion: @escaping (Result<Void, Error>) -> Void) {

        let db  = Firestore.firestore()
        let doc = db.collection("users").document(uid)

        // Keep this list in sync with your schema
        let subCollections = [
            "accounts",
            "transactions",
            "budgetCategories",
            "budget",
            "insights",
            "notifications",
            "monthlySummaries"
        ]

        let group = DispatchGroup()
        var firstError: Error?

        // Delete root document
        group.enter()
        doc.delete { error in
            if firstError == nil { firstError = error }
            group.leave()
        }

        // Delete each sub-collection in pages of 500
        for name in subCollections {
            purge(collection: doc.collection(name), batchSize: 500, group: group) { error in
                if firstError == nil { firstError = error }
            }
        }

        group.notify(queue: .main) {
            if let error = firstError {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }

    private func purge(collection: CollectionReference,
                       batchSize: Int,
                       group: DispatchGroup,
                       onError: @escaping (Error?) -> Void) {

        group.enter()
        collection.limit(to: batchSize).getDocuments { [weak self] snapshot, error in
            guard let self = self else { return }

            if let error = error {
                onError(error)
                group.leave()
                return
            }

            guard let snapshot = snapshot, !snapshot.isEmpty else {
                group.leave()
                return
            }

            let batch = collection.firestore.batch()
            snapshot.documents.forEach { batch.deleteDocument($0.reference) }

            batch.commit { commitError in
                if let commitError = commitError {
                    onError(commitError)
                    group.leave()
                } else {
                    // Recurse for next page
                    self.purge(collection: collection,
                               batchSize: batchSize,
                               group: group,
                               onError: onError)
                }
            }
        }
    }

    // MARK: Error type -------------------------------------------------------

    enum DeleteError: LocalizedError {
        case noSignedInUser

        var errorDescription: String? {
            switch self {
            case .noSignedInUser:
                return "No Firebase user is currently signed in."
            }
        }
    }
}
