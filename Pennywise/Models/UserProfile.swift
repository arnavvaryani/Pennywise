//
//  UserProfile.swift
//  Pennywise
//
//  Created by Arnav Varyani on 4/8/25.
//

import SwiftUI
import SwiftData
// MARK: - User Profile Model
@Model
final class UserProfile {
    var id: UUID
    var name: String
    var email: String
    var currency: String
    var monthlyIncome: Double
    var notificationsEnabled: Bool
    var biometricAuthEnabled: Bool
    var lastUpdated: Date
    
    init(
        id: UUID = UUID(),
        name: String,
        email: String,
        currency: String = "USD",
        monthlyIncome: Double = 0,
        notificationsEnabled: Bool = true,
        biometricAuthEnabled: Bool = true,
        lastUpdated: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.email = email
        self.currency = currency
        self.monthlyIncome = monthlyIncome
        self.notificationsEnabled = notificationsEnabled
        self.biometricAuthEnabled = biometricAuthEnabled
        self.lastUpdated = lastUpdated
    }
}
