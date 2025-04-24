//
//  Currency.swift
//  Pennywise
//
//  Created by Arnav Varyani on 4/11/25.
//


struct Currency: Identifiable {
    let symbol: String
    let code: String
    let name: String
    let rate: Double
    
    var id: String { code }
}
