//
//  BudgetMapper.swift
//  Pennywise
//
//  Mappers for Budget entities
//

import Foundation

/// Mapper for BudgetCategory entities
public struct BudgetMapper {
    /// Convert Firestore DTO to Domain Entity
    public static func toDomain(_ dto: FirestoreBudgetCategoryDTO) -> BudgetCategory {
        BudgetCategory(
            id: dto.id ?? UUID().uuidString,
            name: dto.name,
            amount: dto.amount,
            icon: dto.icon,
            colorHex: dto.colorHex,
            isEssential: dto.isEssential
        )
    }
    
    /// Convert Domain Entity to Firestore DTO
    public static func toFirestoreDTO(_ entity: BudgetCategory) -> FirestoreBudgetCategoryDTO {
        FirestoreBudgetCategoryDTO(
            id: entity.id,
            name: entity.name,
            amount: entity.amount,
            icon: entity.icon,
            colorHex: entity.colorHex,
            isEssential: entity.isEssential,
            updatedAt: Date()
        )
    }
    
    /// Convert array of DTOs to Domain Entities
    public static func toDomainArray(_ dtos: [FirestoreBudgetCategoryDTO]) -> [BudgetCategory] {
        dtos.map { toDomain($0) }
    }
}

