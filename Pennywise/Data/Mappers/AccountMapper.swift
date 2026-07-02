//
//  AccountMapper.swift
//  Pennywise
//
//  Mappers for Account entities
//

import Foundation

/// Mapper for Account entities
public struct AccountMapper {
    /// Convert Plaid DTO to Domain Entity
    public static func toDomain(_ dto: PlaidAccountDTO) -> Account {
        Account(
            id: dto.id,
            name: dto.name,
            type: dto.type,
            balance: dto.balance,
            institutionName: dto.institutionName,
            institutionLogo: dto.institutionLogo,
            isPlaceholder: false
        )
    }
    
    /// Convert array of DTOs to Domain Entities
    public static func toDomainArray(_ dtos: [PlaidAccountDTO]) -> [Account] {
        dtos.map { toDomain($0) }
    }
}

