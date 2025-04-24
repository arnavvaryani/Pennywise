//
//  BudgetCategoryRow 2.swift
//  Pennywise
//
//  Created by Arnav Varyani on 4/24/25.
//

import SwiftUI

struct BudgetCategoryRow: View {
    let category: BudgetCategory
    let spent: Double
    let onTap: () -> Void
    let onAmountChange: (Double) -> Void
    let onDelete: () -> Void
    
    @State private var isEditing = false
    @State private var editedAmount: String = ""
    
    var progress: Double {
        category.amount > 0 ? min(spent / category.amount, 1.0) : 0
    }
    
    var statusColor: Color {
        if progress >= 1.0 {
            return Color(hex: "#FF5757") // Over budget - red
        } else if progress >= 0.9 {
            return Color(hex: "#FFD700") // Near limit - yellow
        } else if progress >= 0.25 {
            return AppTheme.primaryGreen // On track - green
        } else {
            return AppTheme.accentBlue // Just started - blue
        }
    }
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 12) {
                // Top row with category info and amount
                HStack(spacing: 15) {
                    // Category icon
                    ZStack {
                        Circle()
                            .fill(category.color.opacity(0.2))
                            .frame(width: 46, height: 46)
                        
                        Image(systemName: category.icon)
                            .font(.system(size: 20))
                            .foregroundColor(category.color)
                    }
                    
                    // Category name and details
                    VStack(alignment: .leading, spacing: 3) {
                        Text(category.name)
                            .font(.headline)
                            .foregroundColor(AppTheme.textColor)
                        
                        HStack(spacing: 6) {
                            // Status indicator
                            Circle()
                                .fill(statusColor)
                                .frame(width: 6, height: 6)
                            
                            Text("Spent: $\(Int(spent)) of $\(Int(category.amount))")
                                .font(.caption)
                                .foregroundColor(AppTheme.textColor.opacity(0.7))
                        }
                    }
                    
                    Spacer()
                    
                    // Amount with edit button
                    if isEditing {
                        HStack {
                            Text("$")
                                .foregroundColor(AppTheme.textColor.opacity(0.8))
                            
                            TextField("Amount", text: $editedAmount, onCommit: {
                                if let amount = Double(editedAmount) {
                                    onAmountChange(amount)
                                }
                                isEditing = false
                            })
                            .keyboardType(.decimalPad)
                            .foregroundColor(AppTheme.textColor)
                            .frame(width: 80)
                            .multilineTextAlignment(.trailing)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(AppTheme.primaryGreen.opacity(0.2))
                        .cornerRadius(8)
                    } else {
                        HStack(spacing: 10) {
                            VStack(alignment: .trailing, spacing: 2) {
                                Text("$\(Int(category.amount))")
                                    .font(.headline)
                                    .foregroundColor(AppTheme.textColor)
                                
                                Text("\(Int(category.amount > 0 ? (spent / category.amount * 100) : 0))%")
                                    .font(.caption)
                                    .foregroundColor(statusColor)
                            }
                            
                            Button(action: {
                                editedAmount = String(format: "%.0f", category.amount)
                                isEditing = true
                            }) {
                                Image(systemName: "pencil")
                                    .font(.system(size: 14))
                                    .foregroundColor(AppTheme.textColor.opacity(0.6))
                                    .padding(6)
                                    .background(Circle().fill(AppTheme.cardBackground))
                            }
                        }
                    }
                }
                
                // Progress bar
                VStack(alignment: .leading, spacing: 6) {
                    // Progress bar
                    ZStack(alignment: .leading) {
                        // Background
                        RoundedRectangle(cornerRadius: 6)
                            .fill(AppTheme.cardStroke)
                            .frame(height: 8)
                        
                        // Progress
                        RoundedRectangle(cornerRadius: 6)
                            .fill(statusColor)
                            .frame(width: max(CGFloat(progress) * UIScreen.main.bounds.width * 0.8, 4), height: 8)
                    }
                    
                    // Info row
                    HStack {
                        // Delete button
                        Button(action: onDelete) {
                            Image(systemName: "trash")
                                .font(.system(size: 12))
                                .foregroundColor(Color(hex: "#FF5757"))
                        }
                        
                        Spacer()
                        
                        // Remaining
                        Text("Remaining: $\(Int(max(0, category.amount - spent)))")
                            .font(.caption)
                            .foregroundColor(AppTheme.textColor.opacity(0.7))
                    }
                }
            }
            .padding(16)
        }
        .buttonStyle(PlainButtonStyle())
        .background(AppTheme.cardBackground)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(AppTheme.cardStroke, lineWidth: 1)
        )
    }
}
