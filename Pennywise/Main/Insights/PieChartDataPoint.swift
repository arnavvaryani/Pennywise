//
//  PieChartDataPoint.swift
//  Pennywise
//

import SwiftUI

struct PieChartDataPoint: Identifiable {
    var id = UUID()
    let category: String
    let amount: Double
    let color: Color
}

