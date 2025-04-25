//
//  BudgetPieChart.swift
//  Pennywise
//
//  Created by Arnav Varyani on 4/8/25.
//

//import SwiftUI
//
//struct BudgetPieChart: View {
//    let categories: [BudgetCategory]
//    
//    var totalBudget: Double {
//        categories.reduce(0) { $0 + $1.amount }
//    }
//    
//    var body: some View {
//        ZStack {
//            ForEach(0..<categories.count, id: \.self) { index in
//                let startAngle = self.startAngle(at: index)
//                let endAngle = self.endAngle(at: index)
//                
//                PieSlice(startAngle: startAngle, endAngle: endAngle)
//                    .fill(categories[index].color)
//            }
//            
//            // Center circle - Fixed reference to backgroundSecondary
//            Circle()
//                .fill(AppTheme.backgroundSecondary)
//                .frame(width: 60, height: 60)
//            
//            // Total amount
//            VStack {
//                Text("$\(Int(totalBudget))")
//                    .font(.headline)
//                    .fontWeight(.bold)
//                    .foregroundColor(.white)
//                
//                Text("Total")
//                    .font(.caption2)
//                    .foregroundColor(.white.opacity(0.7))
//            }
//        }
//    }
//    
//    private func startAngle(at index: Int) -> Angle {
//        let preceding = categories.prefix(index).reduce(0) { $0 + $1.amount }
//        return .degrees(preceding / totalBudget * 360 - 90)
//    }
//    
//    private func endAngle(at index: Int) -> Angle {
//        let value = categories[index].amount
//        let starting = startAngle(at: index).degrees
//        return .degrees(starting + (value / totalBudget * 360))
//    }
//}
