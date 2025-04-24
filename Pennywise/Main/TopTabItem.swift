//
//  TopTabItem.swift
//  Pennywise
//
//  Created by Arnav Varyani on 4/23/25.
//

import SwiftUI

struct TopTabItem {
    let title: String
    var icon: String? = nil
}

struct TopTabBar: View {
    @Binding var selectedTab: Int
    let tabs: [TopTabItem]
    var showIndicator: Bool = true
    var fontSize: CGFloat = 16
    var spacing: CGFloat = 20
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: spacing) {
                ForEach(0..<tabs.count, id: \.self) { index in
                    tabButton(for: index)
                }
            }
            .padding(.horizontal)
        }
        .background(
            ZStack(alignment: .bottom) {
                // Background with slight gradient
                LinearGradient(
                    gradient: Gradient(colors: [
                        AppTheme.backgroundPrimary.opacity(0.7),
                        AppTheme.backgroundPrimary.opacity(0.9)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                
                // Bottom separator line
                if showIndicator {
                    Rectangle()
                        .fill(AppTheme.cardStroke)
                        .frame(height: 1)
                }
            }
        )
    }
    
    private func tabButton(for index: Int) -> some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selectedTab = index
                let generator = UIImpactFeedbackGenerator(style: .light)
                generator.impactOccurred()
            }
        }) {
            VStack(spacing: 8) {
                // Display icon if available
                if let icon = tabs[index].icon {
                    Image(systemName: icon)
                        .font(.system(size: fontSize))
                        .foregroundColor(
                            selectedTab == index ?
                            AppTheme.primaryGreen :
                            AppTheme.textColor.opacity(0.5)
                        )
                }
                
                Text(tabs[index].title)
                    .font(.system(size: fontSize, weight: selectedTab == index ? .semibold : .regular))
                    .foregroundColor(
                        selectedTab == index ?
                        AppTheme.primaryGreen :
                        AppTheme.textColor.opacity(0.5)
                    )
                
                // Indicator dot or line
                if showIndicator {
                    Rectangle()
                        .fill(selectedTab == index ? AppTheme.primaryGreen : Color.clear)
                        .frame(width: selectedTab == index ? 20 : 0, height: 3)
                        .cornerRadius(1.5)
                        .padding(.top, 2)
                }
            }
            .padding(.vertical, 10)
        }
        .buttonStyle(ScaleButtonStyle())
    }
}


struct TopTabBar_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            AppTheme.backgroundGradient.ignoresSafeArea()
        }
        .preferredColorScheme(.dark)
    }
}
