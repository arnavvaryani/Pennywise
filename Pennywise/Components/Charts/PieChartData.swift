//
//  PieChartData.swift
//  Pennywise
//
//  Created by Arnav Varyani on 4/8/25.
//

import SwiftUI
import Charts

// MARK: - Data Model for Chart
struct PieChartData: Identifiable {
    let id = UUID()
    let category: String
    let value: Double
    let color: Color
}

// MARK: - Pie Chart View (Updated with Swift Charts)
struct PieChartView: View {
    let data: [(String, Double)]
    @State private var selectedSlice: Int? = nil
    
    var totalValue: Double {
        data.reduce(0) { $0 + $1.1 }
    }
    
    // Convert data to PieChartData format for Swift Charts
    var chartData: [PieChartData] {
        data.enumerated().map { index, item in
            PieChartData(
                category: item.0,
                value: item.1,
                color: categoryColor(for: item.0)
            )
        }
    }
    
    var body: some View {
        // Only keep the pie chart portion, remove the legend HStack
        ZStack {
            Chart(chartData) { item in
                SectorMark(
                    angle: .value("Value", item.value),
                    innerRadius: .ratio(0.6),
                    outerRadius: .ratio(selectedSlice == chartData.firstIndex(where: { $0.category == item.category }) ? 1.0 : 0.9),
                    angularInset: 1.5
                )
                .foregroundStyle(item.color)
                .cornerRadius(4)
            }
            .chartBackground { _ in
                Color.clear
            }
            // Remove the chartAnimate modifier
            .frame(height: 200)
            // Use proper legend modifier with .hidden to remove the right-side legend
            .chartLegend(.hidden)
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        let centerPoint = CGPoint(x: 100, y: 100) // Approximate chart center
                        let touchPoint = value.location
                        let deltaX = touchPoint.x - centerPoint.x
                        let deltaY = touchPoint.y - centerPoint.y
                        let distance = sqrt(deltaX * deltaX + deltaY * deltaY)
                        
                        // Only detect touches outside center circle but within chart
                        if distance > 40 && distance < 100 {
                            // Calculate angle to determine sector
                            let angle = atan2(deltaY, deltaX) * 180 / .pi
                            let normalizedAngle = angle < 0 ? angle + 360 : angle
                            
                            // Find which slice was touched
                            var accumulatedAngle: Double = -90 // Start at 12 o'clock
                            for (index, item) in data.enumerated() {
                                let sliceAngle = (item.1 / totalValue) * 360
                                let nextAngle = accumulatedAngle + sliceAngle
                                
                                if normalizedAngle >= accumulatedAngle.truncatingRemainder(dividingBy: 360) &&
                                   normalizedAngle <= nextAngle.truncatingRemainder(dividingBy: 360) {
                                    withAnimation(.spring()) {
                                        selectedSlice = index
                                    }
                                    break
                                }
                                
                                accumulatedAngle += sliceAngle
                            }
                        }
                    }
                    .onEnded { _ in
                        withAnimation(.spring()) {
                            selectedSlice = nil
                        }
                    }
            )
            
            // Center circle
            Circle()
                .fill(AppTheme.backgroundSecondary)
                .frame(width: 80, height: 80)
            
            // Display center content based on selection
            if let selected = selectedSlice {
                // Display selected category value
                VStack {
                    Text("\(Int(data[selected].1))")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("$")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
            } else {
                // Display total
                VStack {
                    Text("\(Int(totalValue))")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("Total")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
            }
        }
    }
    
    // Helper function to determine color based on category name
    private func categoryColor(for category: String) -> Color {
        let c = category.lowercased()
        if c.contains("food") || c.contains("restaurant") || c.contains("dining") {
            return AppTheme.primaryGreen
        } else if c.contains("shop") || c.contains("store") {
            return AppTheme.accentBlue
        } else if c.contains("transport") || c.contains("travel") {
            return AppTheme.accentPurple
        } else if c.contains("entertainment") {
            return Color(hex: "#FFD700")
        } else if c.contains("health") || c.contains("medical") {
            return Color(hex: "#FF5757")
        } else if c.contains("utility") || c.contains("bill") {
            return Color(hex: "#9370DB")
        } else if c.contains("housing") || c.contains("rent") || c.contains("mortgage") {
            return Color(hex: "#CD853F")
        } else if c.contains("education") {
            return Color(hex: "#4682B4")
        } else if c.contains("personal") {
            return Color(hex: "#FF7F50")
        } else if c.contains("subscription") {
            return Color(hex: "#BA55D3")
        } else {
            // Use a deterministic color based on the category name
            let hash = category.hashValue
            return Color(
                hue: Double(abs(hash % 256)) / 256.0,
                saturation: 0.7,
                brightness: 0.8
            )
        }
    }
}
