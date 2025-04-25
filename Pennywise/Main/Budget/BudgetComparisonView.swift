//
//  BudgetComparisonView.swift
//  Pennywise
//
//  Created by Arnav Varyani on 4/8/25.
//

//import SwiftUI
//
//struct BudgetComparisonView: View {
//
//    let budgetCategories = [
//        ("Food", 600.0, 550.0),
//        ("Housing", 1200.0, 1200.0),
//        ("Transport", 400.0, 350.0),
//        ("Utilities", 200.0, 180.0),
//        ("Entertainment", 200.0, 250.0)
//    ]
//    
//    var body: some View {
//        VStack(alignment: .leading, spacing: 15) {
//            Text("Monthly Budget")
//                .font(.headline)
//                .foregroundColor(.white)
//            
//            VStack(spacing: 12) {
//                ForEach(0..<budgetCategories.count, id: \.self) { index in
//                    let category = budgetCategories[index]
//                    let budgetAmount = category.1
//                    let actualAmount = category.2
//                    let percentage = actualAmount / budgetAmount
//                    
//                    VStack(alignment: .leading, spacing: 5) {
//                        HStack {
//                            Text(category.0)
//                                .font(.caption)
//                                .foregroundColor(.white.opacity(0.8))
//                            
//                            Spacer()
//                            
//                            Text("$\(Int(actualAmount)) of $\(Int(budgetAmount))")
//                                .font(.caption)
//                                .foregroundColor(.white.opacity(0.6))
//                        }
//                        
//                        ZStack(alignment: .leading) {
//                            // Background bar
//                            RoundedRectangle(cornerRadius: 5)
//                                .fill(Color.gray.opacity(0.3))
//                                .frame(height: 10)
//                            
//                            // Progress bar
//                            RoundedRectangle(cornerRadius: 5)
//                                .fill(self.barColor(for: percentage))
//                                .frame(width: CGFloat(min(percentage, 1.0)) * (UIScreen.main.bounds.width - 70), height: 10)
//                        }
//                    }
//                }
//            }
//        }
//        .padding()
//    }
//    
//    private func barColor(for percentage: Double) -> Color {
//        if percentage > 1.0 {
//            return AppTheme.expenseRed // Over budget
//        } else if percentage > 0.9 {
//            return AppTheme.alertOrange // Near budget
//        } else {
//            return AppTheme.incomeGreen // Under budget
//        }
//    }
//}
//
//

