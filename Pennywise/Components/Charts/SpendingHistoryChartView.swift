//
//  SpendingHistoryChartView.swift
//  Pennywise
//
//  Created by Arnav Varyani on 4/8/25.
//

import SwiftUI
import Charts 

struct SpendingHistoryChartView: View {
    let data: [MonthlyFinancialData]
    
    // Colors from the provided palette - using AppTheme instead of direct hex values
    let incomeColor = AppTheme.primaryGreen // Green for income
    let expenseColor = AppTheme.accentPurple // Purple for expenses
    let accentColor = AppTheme.accentBlue // Light blue for accents
    let textColor = AppTheme.textColor // White for text
    
    var maxValue: Double {
        let maxIncome = data.map { $0.income }.max() ?? 0
        let maxExpense = data.map { $0.expenses }.max() ?? 0
        return max(maxIncome, maxExpense) * 1.1 // Add 10% padding
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header with animated underline
            headerView
            
            // Swift Charts implementation - simplified for compiler
            chartView
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 12)
        .background(AppTheme.cardBackground)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(accentColor.opacity(0.1), lineWidth: 1)
        )
    }
    
    // Breaking up the chart into smaller components
    private var headerView: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Income vs. Expenses")
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundColor(textColor)
            
            Rectangle()
                .fill(accentColor)
                .frame(width: 60, height: 3)
                .cornerRadius(1.5)
        }
    }
    
    private var chartView: some View {
        // The chart component broken down
        Chart {
            // Income data
            ForEach(data, id: \.month) { item in
                createIncomeBarMark(for: item)
            }
            
            // Expense data (separate loop to help with type checking)
            ForEach(data, id: \.month) { item in
                createExpenseBarMark(for: item)
            }
        }
        .chartXAxis {
            AxisMarks(preset: .aligned) { value in
                AxisValueLabel()
                    .foregroundStyle(textColor.opacity(0.7))
                    .font(.system(size: 10, weight: .medium))
            }
        }
        .chartYAxis {
            createYAxis()
        }
        .chartYScale(domain: 0...(maxValue))
        .frame(height: 220)
        .chartLegend(position: .bottom, alignment: .leading) {
            createLegend()
        }
    }
    
    // Helper functions to create chart components
    private func createIncomeBarMark(for item: MonthlyFinancialData) -> some ChartContent {
        let isHighestIncome = item.income == (data.map { $0.income }.max() ?? 0)
        
        return BarMark(
            x: .value("Month", item.month),
            y: .value("Amount", item.income)
        )
        .foregroundStyle(incomeColor)
        .position(by: .value("Type", "Income"))
        .cornerRadius(6)
        .annotation(position: .top, alignment: .center, spacing: 2) {
            if isHighestIncome {
                Text("$\(Int(item.income))")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(incomeColor)
            }
        }
    }
    
    private func createExpenseBarMark(for item: MonthlyFinancialData) -> some ChartContent {
        let isHighestExpense = item.expenses == (data.map { $0.expenses }.max() ?? 0)
        
        return BarMark(
            x: .value("Month", item.month),
            y: .value("Amount", item.expenses)
        )
        .foregroundStyle(expenseColor)
        .position(by: .value("Type", "Expenses"))
        .cornerRadius(6)
        .annotation(position: .top, alignment: .center, spacing: 2) {
            if isHighestExpense {
                Text("$\(Int(item.expenses))")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(expenseColor)
            }
        }
    }
    
    private func createYAxis() -> some AxisContent {
        AxisMarks(position: .leading) { value in
            AxisValueLabel {
                if let intValue = value.as(Int.self) {
                    Text("$\(intValue)")
                        .foregroundStyle(textColor.opacity(0.7))
                        .font(.system(size: 10, weight: .medium))
                }
            }
            AxisGridLine()
                .foregroundStyle(textColor.opacity(0.1))
        }
    }
    
    private func createLegend() -> some View {
        HStack(spacing: 24) {
            LegendItem(color: incomeColor, label: "Income")
            LegendItem(color: expenseColor, label: "Expenses")
        }
        .padding(.top, 8)
    }
}

// Helper view for legend items
struct LegendItem: View {
    let color: Color
    let label: String
    
    var body: some View {
        HStack(spacing: 8) {
            RoundedRectangle(cornerRadius: 3)
                .fill(color)
                .frame(width: 14, height: 14)
            
            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white.opacity(0.8))
        }
    }
}
