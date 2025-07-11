//
//  AccountDeletionManager.swift
//  Pennywise
//
//  Created by Arnav Varyani on 4/8/25.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore


final class AccountDeletionManager {

    // MARK: Singleton
    static let shared = AccountDeletionManager()
    private init() {}

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
                        completion(.failure(deleteError))
                        return
                    }

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


    private func deleteUserData(uid: String,
                                completion: @escaping (Result<Void, Error>) -> Void) {

        let db  = Firestore.firestore()
        let doc = db.collection("users").document(uid)

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
