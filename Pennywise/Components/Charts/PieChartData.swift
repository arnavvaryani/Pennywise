import SwiftUI
import Charts

// MARK: - Data Model for Chart
struct PieChartData: Identifiable {
    let id = UUID()
    let category: String
    let value: Double
    let color: Color
}

// MARK: - Swift Charts Pie Chart
struct SwiftChartsPieChart: View {
    let categories: [BudgetCategory]
    @State private var selectedSlice: String? = nil
    
    var totalBudget: Double {
        categories.reduce(0) { $0 + $1.amount }
    }
    
    // Convert BudgetCategory to PieChartData
    var chartData: [PieChartData] {
        categories.map { category in
            PieChartData(
                category: category.name,
                value: category.amount,
                color: category.color
            )
        }
    }
    
    var body: some View {
        ZStack {
            // Swift Charts Pie Chart
            Chart(chartData) { item in
                SectorMark(
                    angle: .value("Budget", item.value),
                    innerRadius: .ratio(selectedSlice == item.category ? 0.5 : 0.6),
                    outerRadius: .ratio(selectedSlice == item.category ? 1.0 : 0.9),
                    angularInset: 1.5
                )
                .foregroundStyle(item.color)
                .cornerRadius(4)
                .annotation(position: .overlay) {
                    if selectedSlice == item.category && item.value / totalBudget > 0.1 {
                        Text("\(Int(item.value / totalBudget * 100))%")
                            .font(.caption)
                            .foregroundColor(.white)
                            .fontWeight(.bold)
                    }
                }
            }
            .chartBackground { _ in
                Color.clear
            }
            // Remove the chartAnimate modifier - it's not available
            .frame(height: 200)
            // Use proper legend modifier
            .chartLegend(.visible)
            .padding()
            
            // Center circle to match original design
            Circle()
                .fill(AppTheme.backgroundSecondary)
                .frame(width: 60, height: 60)
                .zIndex(2)
            
            // Total amount in center
            VStack {
                Text("$\(Int(totalBudget))")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text("Total")
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.7))
            }
            .zIndex(3)
            
            // Add touch interaction
            Color.clear
                .contentShape(Circle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            let centerPoint = CGPoint(x: 100, y: 100) // Approximate chart center
                            let touchPoint = value.location
                            let deltaX = touchPoint.x - centerPoint.x
                            let deltaY = touchPoint.y - centerPoint.y
                            let distance = sqrt(deltaX * deltaX + deltaY * deltaY)
                            
                            // Only detect touches outside center circle but within chart
                            if distance > 35 && distance < 100 {
                                // Calculate angle to determine sector
                                let angle = atan2(deltaY, deltaX) * 180 / .pi
                                let normalizedAngle = angle < 0 ? angle + 360 : angle
                                
                                // Find which slice was touched
                                var accumulatedAngle: Double = -90 // Start at 12 o'clock
                                for category in categories {
                                    let sliceAngle = (category.amount / totalBudget) * 360
                                    let nextAngle = accumulatedAngle + sliceAngle
                                    
                                    // Check if normalized angle is within this slice
                                    // We account for full 360 rotation with modulo
                                    let normalizedStart = accumulatedAngle < 0 ? accumulatedAngle + 360 : accumulatedAngle
                                    let normalizedEnd = nextAngle < 0 ? nextAngle + 360 : nextAngle
                                    
                                    if normalizedAngle >= normalizedStart.truncatingRemainder(dividingBy: 360) &&
                                       normalizedAngle <= normalizedEnd.truncatingRemainder(dividingBy: 360) {
                                        withAnimation(.spring()) {
                                            selectedSlice = category.name
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
        }
    }
}

// MARK: - Budget Pie Chart (Updated with Swift Charts)
struct BudgetPieChart: View {
    let categories: [BudgetCategory]
    
    var totalBudget: Double {
        categories.reduce(0) { $0 + $1.amount }
    }
    
    var body: some View {
        ZStack {
            // Use the new Swift Charts implementation
            SwiftChartsPieChart(categories: categories)
        }
    }
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
                color: colors[index % colors.count]
            )
        }
    }
    
    // Colors from AppTheme
    var colors: [Color] = [
        AppTheme.primaryGreen,
        AppTheme.accentBlue,
        AppTheme.incomeGreen,
        AppTheme.expenseColor,
        AppTheme.savingsYellow,
        AppTheme.investmentPurple,
        AppTheme.alertOrange
    ]
    
    var body: some View {
        HStack {
            // Pie chart using Swift Charts
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
                .frame(width: 200, height: 200)
                // Use proper legend modifier
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
            .padding(.trailing, 10)
            
            // Legend
            VStack(alignment: .leading, spacing: 8) {
                ForEach(0..<data.count, id: \.self) { index in
                    HStack(spacing: 8) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(colors[index % colors.count])
                            .frame(width: 12, height: 12)
                        
                        Text(data[index].0)
                            .font(.caption)
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        Text("$\(Int(data[index].1))")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                        
                        Text("(\(Int(data[index].1 / totalValue * 100))%)")
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.6))
                    }
                    .padding(.vertical, 2)
                    .scaleEffect(selectedSlice == index ? 1.05 : 1.0)
                    .opacity(selectedSlice == nil || selectedSlice == index ? 1.0 : 0.5)
                }
            }
            .padding(.leading, 5)
        }
        .padding()
    }
}

// MARK: - Preview
struct SwiftChartsPieChart_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            
            VStack {
                // Example with BudgetCategory
                BudgetPieChart(categories: [
                    BudgetCategory(name: "Food", amount: 400, icon: "fork.knife", color: AppTheme.primaryGreen),
                    BudgetCategory(name: "Transport", amount: 200, icon: "car.fill", color: AppTheme.accentBlue),
                    BudgetCategory(name: "Shopping", amount: 300, icon: "cart.fill", color: AppTheme.savingsYellow)
                ])
                .frame(height: 200)
                .padding()
                
                // Example with tuple data
                PieChartView(data: [
                    ("Food", 400.0),
                    ("Transport", 200.0),
                    ("Shopping", 300.0),
                    ("Entertainment", 150.0)
                ])
                .frame(height: 250)
                .padding()
            }
        }
        .preferredColorScheme(.dark)
    }
}
