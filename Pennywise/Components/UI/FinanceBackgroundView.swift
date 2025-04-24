//
//  FinanceBackgroundView.swift
//  Pennywise
//
//  Created by Arnav Varyani on 4/8/25.
//

import SwiftUI

struct FinanceBackgroundView: View {
    @State private var animateGradient = false
    
    var body: some View {
        ZStack {
            // Base gradient background
            LinearGradient(
                gradient: Gradient(colors: [AppTheme.primary, Color(hex:"072E5F")]),
                startPoint: .top,
                endPoint: .bottom
            )
            
            // Financial symbols (small icons)
            ForEach(0..<30, id: \.self) { i in
                Image(systemName: financeSymbols.randomElement() ?? "dollarsign.circle")
                    .font(.system(size: CGFloat.random(in: 8...16)))
                    .foregroundColor(.white.opacity(Double.random(in: 0.05...0.15)))
                    .position(
                        x: Double.random(in: 0...UIScreen.main.bounds.width),
                        y: Double.random(in: 0...UIScreen.main.bounds.height)
                    )
                    .rotationEffect(.degrees(Double.random(in: 0...360)))
                    .animation(
                        Animation.linear(duration: Double.random(in: 5...10))
                            .repeatForever(autoreverses: true)
                            .delay(Double.random(in: 0...3)),
                        value: animateGradient
                    )
            }
            
            // Animated gradient overlay
            ZStack {
                RadialGradient(
                    gradient: Gradient(colors: [
                        AppTheme.primary.opacity(0.0),
                        AppTheme.secondary.opacity(0.2),
                        AppTheme.primary.opacity(0.0)
                    ]),
                    center: animateGradient ? .bottomTrailing : .topLeading,
                    startRadius: 100,
                    endRadius: UIScreen.main.bounds.width * 1.5
                )
                
                RadialGradient(
                    gradient: Gradient(colors: [
                        AppTheme.primary.opacity(0.0),
                        AppTheme.primary.opacity(0.3),
                        AppTheme.primary.opacity(0.0)
                    ]),
                    center: animateGradient ? .topLeading : .bottomTrailing,
                    startRadius: 50,
                    endRadius: UIScreen.main.bounds.width
                )
            }
            .onAppear {
                withAnimation(Animation.linear(duration: 8).repeatForever(autoreverses: true)) {
                    animateGradient.toggle()
                }
            }
        }
    }
    
    // Financial symbols for the background
    private var financeSymbols: [String] = [
        "dollarsign.circle", "chart.line.uptrend.xyaxis", "creditcard", 
        "banknote", "chart.pie", "percent", "checkmark.seal", 
        "arrow.up.arrow.down.circle", "calendar", "building.columns"
    ]
}
