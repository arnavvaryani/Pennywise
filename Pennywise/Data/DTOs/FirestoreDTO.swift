//
//  FirestoreDTO.swift
//  Pennywise
//
//  Data Transfer Objects for Firestore
//

import Foundation
import FirebaseFirestore

/// DTO for Firestore transaction document.
/// `@unchecked Sendable`: Firebase's `@DocumentID` (`DocumentID<String>`) is not
/// annotated `Sendable`, but it wraps an immutable optional value and these DTOs
/// are used as read-only snapshots, so crossing actor boundaries is safe.
public struct FirestoreTransactionDTO: Codable, @unchecked Sendable {
    @DocumentID public var id: String?
    public let name: String
    public let amount: Double
    public let date: Date
    public let category: String
    public let merchantName: String
    public let accountId: String
    public let pending: Bool
    public let isManual: Bool
    public let createdAt: Date?
    public let updatedAt: Date?
    
    public init(
        id: String? = nil,
        name: String,
        amount: Double,
        date: Date,
        category: String,
        merchantName: String,
        accountId: String,
        pending: Bool,
        isManual: Bool,
        createdAt: Date? = nil,
        updatedAt: Date? = nil
    ) {
        self.id = id
        self.name = name
        self.amount = amount
        self.date = date
        self.category = category
        self.merchantName = merchantName
        self.accountId = accountId
        self.pending = pending
        self.isManual = isManual
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    // Mapping from Entity to DTO
    public init(from transaction: Transaction) {
        self.id = transaction.id
        self.name = transaction.name
        self.amount = transaction.amount
        self.date = transaction.date
        self.category = transaction.category
        self.merchantName = transaction.merchantName
        self.accountId = transaction.accountId
        self.pending = transaction.isPending
        self.isManual = transaction.isManual
        self.createdAt = nil
        self.updatedAt = nil
    }
    
    // Mapping from DTO to Entity
    public func toEntity() -> Transaction {
        Transaction(
            id: id ?? UUID().uuidString,
            name: name,
            amount: amount,
            date: date,
            category: category,
            merchantName: merchantName,
            accountId: accountId,
            isPending: pending,
            isManual: isManual
        )
    }
}

/// DTO for Firestore user document. See note on `FirestoreTransactionDTO`
/// for why this is `@unchecked Sendable`.
public struct FirestoreUserDTO: Codable, @unchecked Sendable {
    @DocumentID public var id: String?
    public let name: String?
    public let email: String
    public let currency: String
    public let monthlyIncome: Double
    public let notificationsEnabled: Bool
    public let biometricAuthEnabled: Bool
    public let createdAt: Date?
    public let updatedAt: Date?
    
    public init(
        id: String? = nil,
        name: String? = nil,
        email: String,
        currency: String,
        monthlyIncome: Double,
        notificationsEnabled: Bool,
        biometricAuthEnabled: Bool,
        createdAt: Date? = nil,
        updatedAt: Date? = nil
    ) {
        self.id = id
        self.name = name
        self.email = email
        self.currency = currency
        self.monthlyIncome = monthlyIncome
        self.notificationsEnabled = notificationsEnabled
        self.biometricAuthEnabled = biometricAuthEnabled
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    // Mapping from Entity to DTO
    public init(from user: User) {
        self.id = user.id
        self.name = user.displayName
        self.email = user.email
        self.currency = user.currency
        self.monthlyIncome = user.monthlyIncome
        self.notificationsEnabled = user.notificationsEnabled
        self.biometricAuthEnabled = user.biometricAuthEnabled
        self.createdAt = nil
        self.updatedAt = nil
    }
    
    // Mapping from DTO to Entity
    public func toEntity() -> User {
        User(
            id: id ?? "",
            email: email,
            displayName: name,
            photoURL: nil,
            monthlyIncome: monthlyIncome,
            currency: currency,
            notificationsEnabled: notificationsEnabled,
            biometricAuthEnabled: biometricAuthEnabled
        )
    }
}

/// DTO for Firestore budget category document. See note on
/// `FirestoreTransactionDTO` for why this is `@unchecked Sendable`.
public struct FirestoreBudgetCategoryDTO: Codable, @unchecked Sendable {
    @DocumentID public var id: String?
    public let name: String
    public let amount: Double
    public let icon: String
    public let colorHex: String
    public let isEssential: Bool
    public let updatedAt: Date?
    
    public init(
        id: String? = nil,
        name: String,
        amount: Double,
        icon: String,
        colorHex: String,
        isEssential: Bool,
        updatedAt: Date? = nil
    ) {
        self.id = id
        self.name = name
        self.amount = amount
        self.icon = icon
        self.colorHex = colorHex
        self.isEssential = isEssential
        self.updatedAt = updatedAt
    }
    
    // Mapping from Entity to DTO
    public init(from category: BudgetCategory) {
        self.id = category.id
        self.name = category.name
        self.amount = category.amount
        self.icon = category.icon
        self.colorHex = category.colorHex
        self.isEssential = category.isEssential
        self.updatedAt = nil
    }
    
    // Mapping from DTO to Entity
    public func toEntity() -> BudgetCategory {
        BudgetCategory(
            id: id ?? UUID().uuidString,
            name: name,
            amount: amount,
            icon: icon,
            colorHex: colorHex,
            isEssential: isEssential
        )
    }
}

