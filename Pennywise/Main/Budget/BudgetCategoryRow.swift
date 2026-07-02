//
//  BudgetCategoryRow.swift
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
    
    // Remove isEditing since we no longer have the pencil icon
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
                            .fill(Color(hex: category.colorHex).opacity(0.2))
                            .frame(width: 46, height: 46)
                        
                        Image(systemName: category.icon)
                            .font(.system(size: 20))
                            .foregroundColor(Color(hex: category.colorHex))
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
                            
                            Text("Spent: \(CurrencyFormatter.format(spent)) of \(CurrencyFormatter.format(category.amount))")
                                .font(.caption)
                                .foregroundColor(AppTheme.textColor.opacity(0.7))
                        }
                    }
                    
                    Spacer()
                    
                    // Amount display without edit button
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("\(CurrencyFormatter.format(category.amount))")
                            .font(.headline)
                            .foregroundColor(AppTheme.textColor)
                        
                        Text("\(Int(category.amount > 0 ? (spent / category.amount * 100) : 0))%")
                            .font(.caption)
                            .foregroundColor(statusColor)
                    }
                }
                
                // Progress bar
                VStack(alignment: .leading, spacing: 6) {
                    // Progress bar
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            // Background
                            RoundedRectangle(cornerRadius: 6)
                                .fill(AppTheme.cardStroke)
                                .frame(height: 8)
                            
                            // Progress
                            RoundedRectangle(cornerRadius: 6)
                                .fill(statusColor)
                                .frame(width: max(CGFloat(progress) * geometry.size.width, 4), height: 8)
                        }
                    }
                    .frame(height: 8)
                    
                    // Info row
                    HStack {
                        // Delete button
                        Button(action: onDelete) {
                            Image(systemName: "trash")
                                .font(.system(size: 12))
                                .foregroundColor(Color(hex: "#FF5757"))
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        Spacer()
                        
                        // Remaining
                        Text("Remaining: \(CurrencyFormatter.format(max(0, category.amount - spent)))")
                            .font(.caption)
                            .foregroundColor(AppTheme.textColor.opacity(0.7))
                    }
                }
            }
            .padding(16)
        }
        .buttonStyle(PlainButtonStyle())
        .pwGlassSurface(cornerRadius: 16)
    }
}
