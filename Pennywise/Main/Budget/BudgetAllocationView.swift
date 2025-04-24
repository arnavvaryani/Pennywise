//
//  BudgetAllocationView.swift
//  Pennywise
//
//  Created by Arnav Varyani on 4/8/25.
//

import SwiftUI

struct BudgetAllocationView: View {
    let categories: [BudgetCategory]
    
    var totalBudget: Double {
        categories.reduce(0) { $0 + $1.amount }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Budget Allocation")
                .font(.headline)
                .foregroundColor(.white)
            
            if totalBudget > 0 {
                // Pie chart visualization
                HStack {
                    // Chart
                    BudgetPieChart(categories: categories)
                        .frame(width: 150, height: 150)
                    
                    // Legend
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(categories.prefix(5)) { category in
                            HStack(spacing: 8) {
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(category.color)
                                    .frame(width: 12, height: 12)
                                
                                Text(category.name)
                                    .font(.caption)
                                    .foregroundColor(.white)
                                
                                Spacer()
                                
                                Text("\(Int(category.amount / totalBudget * 100))%")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.7))
                            }
                        }
                        
                        if categories.count > 5 {
                            Text("+ \(categories.count - 5) more categories")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.6))
                        }
                    }
                }
            } else {
                Text("Add budget categories to see your allocation")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .padding()
    }
}
