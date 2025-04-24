//
//  RecurringTransaction.swift
//  Pennywise
//
//  Created by Arnav Varyani on 4/8/25.
//

import SwiftUI
import SwiftData

@Model
final class RecurringTransaction {
    var id: UUID
    var title: String
    var amount: Double
    var category: String
    var frequency: RecurringFrequency
    var startDate: Date
    var endDate: Date?
    var isIncome: Bool
    var isActive: Bool
    
    init(
        id: UUID = UUID(),
        title: String,
        amount: Double,
        category: String,
        frequency: RecurringFrequency,
        startDate: Date = Date(),
        endDate: Date? = nil,
        isIncome: Bool = false,
        isActive: Bool = true
    ) {
        self.id = id
        self.title = title
        self.amount = amount
        self.category = category
        self.frequency = frequency
        self.startDate = startDate
        self.endDate = endDate
        self.isIncome = isIncome
        self.isActive = isActive
    }
}

// Frequency of recurring transactions
enum RecurringFrequency: String, Codable {
    case daily
    case weekly
    case biweekly
    case monthly
    case quarterly
    case yearly
}
