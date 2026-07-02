//
//  TransactionMapper.swift
//  Pennywise
//
//  Mappers for converting between DTOs and Domain Entities
//

import Foundation

/// Mapper for Transaction entities
public struct TransactionMapper {
    /// Convert Plaid DTO to Domain Entity
    public static func toDomain(_ dto: PlaidTransactionDTO) -> Transaction {
        Transaction(
            id: dto.id,
            name: dto.name,
            amount: dto.amount,
            date: dto.date,
            // Normalize Plaid categories to budget categories so Budget math works.
            category: CategoryMappingService.mapPlaidCategoryToBudget(dto.category),
            merchantName: dto.merchantName,
            accountId: dto.accountId,
            isPending: dto.pending,
            isManual: false
        )
    }
    
    /// Convert Firestore DTO to Domain Entity
    public static func toDomain(_ dto: FirestoreTransactionDTO) -> Transaction {
        Transaction(
            id: dto.id ?? UUID().uuidString,
            name: dto.name,
            amount: dto.amount,
            date: dto.date,
            category: dto.category,
            merchantName: dto.merchantName,
            accountId: dto.accountId,
            isPending: dto.pending,
            isManual: dto.isManual
        )
    }
    
    /// Convert Domain Entity to Firestore DTO
    public static func toFirestoreDTO(_ entity: Transaction) -> FirestoreTransactionDTO {
        FirestoreTransactionDTO(
            id: entity.id,
            name: entity.name,
            amount: entity.amount,
            date: entity.date,
            category: entity.category,
            merchantName: entity.merchantName,
            accountId: entity.accountId,
            pending: entity.isPending,
            isManual: entity.isManual,
            createdAt: Date(),
            updatedAt: Date()
        )
    }
    
    /// Convert array of DTOs to Domain Entities
    public static func toDomainArray(_ dtos: [PlaidTransactionDTO]) -> [Transaction] {
        dtos.map { toDomain($0) }
    }
    
    public static func toDomainArray(_ dtos: [FirestoreTransactionDTO]) -> [Transaction] {
        dtos.map { toDomain($0) }
    }
}

