//
//  BudgetAnalysisView.swift
//  Pennywise
//
//  Created by Arnav Varyani on 4/24/25.
//

import SwiftUI

struct BudgetAnalysisView: View {
    let insights: [String]
    @Binding var presentationMode: Bool
    
    var body: some View {
        NavigationView {
            ZStack {
                AppTheme.backgroundGradient
                    .ignoresSafeArea()
                
                VStack(spacing: 25) {
                    // Header
                    HStack {
                        Image(systemName: "chart.bar.xaxis")
                            .font(.system(size: 24))
                            .foregroundColor(AppTheme.primaryGreen)
                        
                        Text("Budget Analysis")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(AppTheme.textColor)
                    }
                    .padding(.top, 20)
                    
                    // Insights
                    ScrollView {
                        VStack(alignment: .leading, spacing: 20) {
                            ForEach(insights.indices, id: \.self) { index in
                                insightCard(text: insights[index], index: index)
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    // Action button
                    Button(action: {
                        presentationMode = false
                    }) {
                        Text("Close Analysis")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(AppTheme.primaryGreen)
                            .cornerRadius(12)
                            .shadow(color: AppTheme.primaryGreen.opacity(0.3), radius: 5, x: 0, y: 2)
                    }
                    .buttonStyle(ScaleButtonStyle())
                    .padding(.horizontal)
                    .padding(.bottom, 20)
                }
                .padding()
            }
            .navigationBarHidden(true)
        }
    }
    
    private func insightCard(text: String, index: Int) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            if text.starts(with: "-") {
                // List item
                HStack(alignment: .top, spacing: 10) {
                    Circle()
                        .fill(AppTheme.accentBlue)
                        .frame(width: 8, height: 8)
                        .padding(.top, 6)
                    
                    Text(text.dropFirst(2))
                        .foregroundColor(AppTheme.textColor)
                }
                .padding(.leading, 20)
            } else {
                // Regular insight
                HStack(alignment: .top, spacing: 15) {
                    // Icon based on insight type
                    ZStack {
                        Circle()
                            .fill(insightColor(for: index).opacity(0.2))
                            .frame(width: 36, height: 36)
                        
                        Image(systemName: insightIcon(for: index))
                            .font(.system(size: 16))
                            .foregroundColor(insightColor(for: index))
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(text)
                            .foregroundColor(AppTheme.textColor)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
        .padding()
        .background(AppTheme.cardBackground)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(AppTheme.cardStroke, lineWidth: 1)
        )
    }
    
    private func insightIcon(for index: Int) -> String {
        switch index {
        case 0:
            return "percent"
        case 1:
            return "chart.bar.fill"
        case 2:
            return "exclamationmark.triangle"
        case 3:
            return "arrow.down.circle"
        case 4:
            return "dollarsign.circle"
        default:
            return "lightbulb.fill"
        }
    }
    
    private func insightColor(for index: Int) -> Color {
        switch index {
        case 0:
            return AppTheme.primaryGreen
        case 1:
            return AppTheme.accentBlue
        case 2:
            return Color(hex: "#FF5757")
        case 3:
            return Color(hex: "#FFD700")
        case 4:
            return AppTheme.accentPurple
        default:
            return AppTheme.primaryGreen
        }
    }
}
