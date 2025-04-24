//
//  MonthlyFinancialData.swift
//  Pennywise
//
//  Created by Arnav Varyani on 4/8/25.
//


struct MonthlyFinancialData {
    let month: String
    let income: Double
    let expenses: Double
}

enum TimeFrame {
    case week, month, year
}