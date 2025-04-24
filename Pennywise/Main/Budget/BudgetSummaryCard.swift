//
//  BudgetSummaryCard.swift
//  Pennywise
//
//  Created by Arnav Varyani on 4/8/25.
//

import SwiftUI

struct BudgetSummaryCard: View {
    let monthlyIncome: Double
    let totalBudget: Double
    let remainingBudget: Double
    
    var body: some View {
        VStack(spacing: 15) {
            // Budget allocation info
            HStack(spacing: 20) {
                // Income circle
                VStack {
                    ZStack {
                        Circle()
                            .stroke(AppTheme.primary.opacity(0.3), lineWidth: 10)
                            .frame(width: 100, height: 100)
                        
                        Circle()
                            .trim(from: 0, to: totalBudget / monthlyIncome < 1 ? CGFloat(totalBudget / monthlyIncome) : 1)
                            .stroke(
                                budgetGradient(),
                                style: StrokeStyle(lineWidth: 10, lineCap: .round)
                            )
                            .frame(width: 100, height: 100)
                            .rotationEffect(.degrees(-90))
                        
                        VStack {
                            Text("\(Int(totalBudget / monthlyIncome * 100))%")
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            
                            Text("Allocated")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.7))
                        }
                    }
                    .padding(.trailing, 10)
                }
                
                VStack(alignment: .leading, spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Monthly Income")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                        
                        Text("$\(String(format: "%.0f", monthlyIncome))")
                            .font(.headline)
                            .foregroundColor(.white)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Total Budgeted")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                        
                        Text("$\(String(format: "%.0f", totalBudget))")
                            .font(.headline)
                            .foregroundColor(.white)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Remaining")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                        
                        Text("$\(String(format: "%.0f", remainingBudget))")
                            .font(.headline)
                            .foregroundColor(remainingBudget >= 0 ? AppTheme.incomeGreen : AppTheme.expenseRed)
                    }
                }
                
                Spacer()
            }
        }
        .padding()
        .background(AppTheme.backgroundSecondary)
        .cornerRadius(15)
        .padding(.horizontal)
    }
    
    private func budgetGradient() -> LinearGradient {
        let ratio = totalBudget / monthlyIncome
        
        if ratio > 1.0 {
            // Over budget - red gradient
            return LinearGradient(
                gradient: Gradient(colors: [AppTheme.expenseRed, AppTheme.expenseRed.opacity(0.7)]),
                startPoint: .leading,
                endPoint: .trailing
            )
        } else if ratio > 0.9 {
            // Near budget limit - yellow gradient
            return LinearGradient(
                gradient: Gradient(colors: [AppTheme.savingsYellow, AppTheme.savingsYellow.opacity(0.7)]),
                startPoint: .leading,
                endPoint: .trailing
            )
        } else {
            // Healthy budget - blue gradient
            return LinearGradient(
                gradient: Gradient(colors: [AppTheme.primary, AppTheme.secondary]),
                startPoint: .leading,
                endPoint: .trailing
            )
        }
    }
}
