//
//  TransactionCategory.swift
//  Pennywise
//
//  Category resolution for Firestore transaction documents.
//

import Foundation

/// Returns the effective category for a Firestore transaction document.
///
/// A user's manual override is stored in the `category` field and always wins.
/// The category synced from Plaid is stored separately in `plaidCategory`, so a
/// full re-sync (which writes only `plaidCategory`) can never clobber a user edit.
/// Falls back to `"Other"` when neither field is present.
func effectiveTransactionCategory(_ data: [String: Any]?) -> String {
    guard let data = data else { return "Other" }
    if let userCategory = data["category"] as? String, !userCategory.isEmpty {
        return userCategory
    }
    if let plaidCategory = data["plaidCategory"] as? String, !plaidCategory.isEmpty {
        return plaidCategory
    }
    return "Other"
}
