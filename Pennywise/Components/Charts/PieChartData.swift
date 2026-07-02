//
//  PieChartData.swift
//  Pennywise
//
//  Created by Arnav Varyani on 4/8/25.
//

import SwiftUI
import Charts

// MARK: - Data Model for Chart
struct PieChartData: Identifiable {
    let id = UUID()
    let category: String
    let value: Double
    let color: Color
}
