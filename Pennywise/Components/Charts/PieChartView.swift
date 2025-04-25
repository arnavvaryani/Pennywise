////
////  PieChartView.swift
////  Pennywise
////
////  Created by Arnav Varyani on 4/8/25.
////
//
//import SwiftUI
//
//struct PieChartView: View {
//    let data: [(String, Double)]
//    @State private var selectedSlice: Int? = nil
//    
//    var totalValue: Double {
//        data.reduce(0) { $0 + $1.1 }
//    }
//    
//    // Fixed: Use AppTheme instead of Color.financeTheme
//    var colors: [Color] = [
//        AppTheme.primaryGreen,
//        AppTheme.accentBlue,
//        AppTheme.incomeGreen,
//        AppTheme.expenseColor,
//        AppTheme.savingsYellow,
//        AppTheme.investmentPurple,
//        AppTheme.alertOrange
//    ]
//    
//    var body: some View {
//        HStack {
//            // Pie chart
//            ZStack {
//                ForEach(0..<data.count, id: \.self) { index in
//                    let startAngle = self.startAngle(at: index)
//                    let endAngle = self.endAngle(at: index)
//                    
//                    PieSlice(startAngle: startAngle, endAngle: endAngle)
//                        .fill(colors[index % colors.count])
//                        .scaleEffect(selectedSlice == index ? 1.05 : 1.0)
//                        .onTapGesture {
//                            withAnimation(.spring()) {
//                                selectedSlice = selectedSlice == index ? nil : index
//                            }
//                        }
//                }
//                
//                // Center circle
//                Circle()
//                    .fill(AppTheme.backgroundSecondary)
//                    .frame(width: 80, height: 80)
//                
//                if let selected = selectedSlice {
//                    // Display selected category value
//                    VStack {
//                        Text("\(Int(data[selected].1))")
//                            .font(.title3)
//                            .fontWeight(.bold)
//                            .foregroundColor(.white)
//                        
//                        Text("$")
//                            .font(.caption)
//                            .foregroundColor(.white.opacity(0.7))
//                    }
//                } else {
//                    // Display total
//                    VStack {
//                        Text("\(Int(totalValue))")
//                            .font(.title3)
//                            .fontWeight(.bold)
//                            .foregroundColor(.white)
//                        
//                        Text("Total")
//                            .font(.caption)
//                            .foregroundColor(.white.opacity(0.7))
//                    }
//                }
//            }
//            .frame(width: 200, height: 200)
//            .padding(.trailing, 10)
//            
//            // Legend
//            VStack(alignment: .leading, spacing: 8) {
//                ForEach(0..<data.count, id: \.self) { index in
//                    HStack(spacing: 8) {
//                        RoundedRectangle(cornerRadius: 2)
//                            .fill(colors[index % colors.count])
//                            .frame(width: 12, height: 12)
//                        
//                        Text(data[index].0)
//                            .font(.caption)
//                            .foregroundColor(.white)
//                        
//                        Spacer()
//                        
//                        Text("$\(Int(data[index].1))")
//                            .font(.caption)
//                            .foregroundColor(.white.opacity(0.7))
//                        
//                        Text("(\(Int(data[index].1 / totalValue * 100))%)")
//                            .font(.caption2)
//                            .foregroundColor(.white.opacity(0.6))
//                    }
//                    .padding(.vertical, 2)
//                    .scaleEffect(selectedSlice == index ? 1.05 : 1.0)
//                    .opacity(selectedSlice == nil || selectedSlice == index ? 1.0 : 0.5)
//                }
//            }
//            .padding(.leading, 5)
//        }
//        .padding()
//    }
//    
//    private func startAngle(at index: Int) -> Angle {
//        let preceding = data.prefix(index).reduce(0) { $0 + $1.1 }
//        return .degrees(preceding / totalValue * 360 - 90)
//    }
//    
//    private func endAngle(at index: Int) -> Angle {
//        let value = data[index].1
//        let starting = startAngle(at: index).degrees
//        return .degrees(starting + (value / totalValue * 360))
//    }
//}
//
//struct PieChartViewPreview : PreviewProvider {
//    static var previews : some View {
//        PieChartView(data: [("String", 2.0)])
//    }
//}
