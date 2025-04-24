//
//  FinancialGoal.swift
//  Pennywise
//
//  Created by Arnav Varyani on 4/8/25.
//

import SwiftUI
import SwiftData
// MARK: - Financial Goal Model
@Model
final class FinancialGoal {
    var id: UUID
    var name: String
    var targetAmount: Double
    var currentAmount: Double
    var deadline: Date?
    var icon: String
    var colorHex: String
    var notes: String?
    var isCompleted: Bool
    var dateCreated: Date
    
    init(
        id: UUID = UUID(),
        name: String,
        targetAmount: Double,
        currentAmount: Double = 0.0,
        deadline: Date? = nil,
        icon: String = "target",
        colorHex: String = "0047AB",
        notes: String? = nil,
        isCompleted: Bool = false,
        dateCreated: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.targetAmount = targetAmount
        self.currentAmount = currentAmount
        self.deadline = deadline
        self.icon = icon
        self.colorHex = colorHex
        self.notes = notes
        self.isCompleted = isCompleted
        self.dateCreated = dateCreated
    }
    
    var color: Color {
        Color(colorHex)
    }
    
    var progressPercentage: Double {
        if targetAmount > 0 {
            return min(currentAmount / targetAmount, 1.0)
        }
        return 0
    }
    
    var remainingAmount: Double {
        max(targetAmount - currentAmount, 0)
    }
}
