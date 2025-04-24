//
//  TransactionItem.swift
//  Pennywise
//
//  Created by Arnav Varyani on 4/8/25.
//

import SwiftUI
import SwiftData

// MARK: - Transaction Model
@Model
final class TransactionItem {
    var id: UUID
    var title: String
    var amount: Double
    var category: String
    var date: Date
    var notes: String?
    var isIncome: Bool
    var isRecurring: Bool
    
    init(
        id: UUID = UUID(),
        title: String,
        amount: Double,
        category: String,
        date: Date = Date(),
        notes: String? = nil,
        isIncome: Bool = false,
        isRecurring: Bool = false
    ) {
        self.id = id
        self.title = title
        self.amount = amount
        self.category = category
        self.date = date
        self.notes = notes
        self.isIncome = isIncome
        self.isRecurring = isRecurring
    }
}





