//
//  BudgetCategory.swift
//  Pennywise
//
//  Created by Arnav Varyani on 4/8/25.
//

import SwiftUI

struct BudgetCategory: Identifiable {
    var id: String = UUID().uuidString 
    let name: String
    var amount: Double
    let icon: String
    let color: Color
}

