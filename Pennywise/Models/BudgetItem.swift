//
//  BudgetItem.swift
//  Pennywise
//
//  Created by Arnav Varyani on 4/8/25.
//

import SwiftUI
import SwiftData

@Model
final class BudgetItem {
    var id: UUID
    var name: String
    var amount: Double
    var icon: String
    var colorHex: String
    var month: Int
    var year: Int
    
    init(
        id: UUID = UUID(),
        name: String,
        amount: Double,
        icon: String,
        colorHex: String,
        month: Int = Calendar.current.component(.month, from: Date()),
        year: Int = Calendar.current.component(.year, from: Date())
    ) {
        self.id = id
        self.name = name
        self.amount = amount
        self.icon = icon
        self.colorHex = colorHex
        self.month = month
        self.year = year
    }
    
    var color: Color {
        Color(colorHex)
    }
}
