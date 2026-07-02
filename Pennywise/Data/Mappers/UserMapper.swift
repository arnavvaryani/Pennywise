//
//  UserMapper.swift
//  Pennywise
//
//  Mappers for User entities
//

import Foundation

/// Mapper for User entities
public struct UserMapper {
    /// Convert Firestore DTO to Domain Entity
    public static func toDomain(_ dto: FirestoreUserDTO) -> User {
        User(
            id: dto.id ?? "",
            email: dto.email,
            displayName: dto.name,
            photoURL: nil,
            monthlyIncome: dto.monthlyIncome,
            currency: dto.currency,
            notificationsEnabled: dto.notificationsEnabled,
            biometricAuthEnabled: dto.biometricAuthEnabled
        )
    }
    
    /// Convert Domain Entity to Firestore DTO
    public static func toFirestoreDTO(_ entity: User) -> FirestoreUserDTO {
        FirestoreUserDTO(
            id: entity.id,
            name: entity.displayName,
            email: entity.email,
            currency: entity.currency,
            monthlyIncome: entity.monthlyIncome,
            notificationsEnabled: entity.notificationsEnabled,
            biometricAuthEnabled: entity.biometricAuthEnabled,
            createdAt: Date(),
            updatedAt: Date()
        )
    }
}

