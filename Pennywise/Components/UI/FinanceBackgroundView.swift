//
//  FinanceBackgroundView.swift
//  Pennywise
//
//  Created by Arnav Varyani on 4/8/25.
//

import SwiftUI

struct FinanceBackgroundView: View {
    @State private var animateGradient = false
    
    var body: some View {
        Color(AppTheme.backgroundPrimary)
    }
    
    // Financial symbols for the background
    private var financeSymbols: [String] = [
        "dollarsign.circle", "chart.line.uptrend.xyaxis", "creditcard", 
        "banknote", "chart.pie", "percent", "checkmark.seal", 
        "arrow.up.arrow.down.circle", "calendar", "building.columns"
    ]
}
