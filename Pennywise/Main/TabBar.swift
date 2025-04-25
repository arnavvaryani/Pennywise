//
//  TabBar.swift
//  Pennywise
//
//  Created for Pennywise Finance App
//

import SwiftUI

struct TabItem {
    let icon: String
    let title: String
}

struct TabBar: View {
    @Binding var selectedTab: Int
    @State private var previousTab = 0
    @Binding var showAddTransaction: Bool
    
    // Define tab items
    let tabItems = [
        TabItem(icon: "house.fill", title: "Home"),
        TabItem(icon: "chart.bar.xaxis", title: "Insights"),
        TabItem(icon: "plus.circle.fill", title: "Add"),
        TabItem(icon: "target", title: "Budget"),
        TabItem(icon: "gear", title: "Settings"),
    ]
    
    var body: some View {
        ZStack {
            // Main tab bar container
            HStack(spacing: 0) {
                ForEach(0..<tabItems.count, id: \.self) { index in
                    if index == 2 {
                        // Center "Add" button
                        addButton
                    } else {
                        // Regular tab button
                        tabButton(for: index)
                    }
                }
            }
            .padding(.horizontal, 8)
            .padding(.top, 10)
            .padding(.bottom, 30) // Extra padding at bottom for safe area
            .background(
                tabBarBackground
            )
        }
        .onChange(of: selectedTab) { newValue in
            // If the "Add" tab is selected, show the transaction sheet
            // and revert to the previous tab
            if newValue == 2 {
                showAddTransaction = true
                // Restore the previous tab selection
                selectedTab = previousTab
            } else {
                previousTab = newValue
            }
        }
    }
    
    // Add button (center)
    private var addButton: some View {
        Button(action: {
            // Trigger add transaction sheet
            showAddTransaction = true
        }) {
            ZStack {
                // Create a floating button
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                AppTheme.primaryGreen,
                                AppTheme.accentBlue
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 56, height: 56)
                    .shadow(color: AppTheme.primaryGreen.opacity(0.4), radius: 10, x: 0, y: 5)
                
                Image(systemName: "plus")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.white)
            }
            .offset(y: -20)
        }
        .buttonStyle(ScaleButtonStyle())
        .frame(maxWidth: .infinity)
    }
    
    // Tab button
    private func tabButton(for index: Int) -> some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                if selectedTab != index {
                    previousTab = selectedTab
                    selectedTab = index
                    let generator = UIImpactFeedbackGenerator(style: .light)
                    generator.impactOccurred()
                }
            }
        }) {
            VStack(spacing: 5) {
                ZStack {
                    if selectedTab == index {
                        Circle()
                            .fill(AppTheme.accentPurple.opacity(0.15))
                            .frame(width: 40, height: 40)
                    }
                    
                    Image(systemName: tabItems[index].icon)
                        .font(.system(size: 20))
                        .foregroundColor(
                            selectedTab == index ?
                            AppTheme.primaryGreen :
                            AppTheme.textColor.opacity(0.5)
                        )
                }
                
                Text(tabItems[index].title)
                    .font(.system(size: 11, weight: selectedTab == index ? .semibold : .medium))
                    .foregroundColor(
                        selectedTab == index ?
                        AppTheme.primaryGreen :
                        AppTheme.textColor.opacity(0.5)
                    )
                    .offset(y: selectedTab == index ? 0 : 1)
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(ScaleButtonStyle())
    }
    
    // Tab bar background with blur
    private var tabBarBackground: some View {
           ZStack {
               // Use the same color as the navigation bar
               AppTheme.backgroundPrimary
                   .opacity(1.0)
               
               // Top border line
               Rectangle()
                   .frame(height: 1)
                   .foregroundColor(AppTheme.accentPurple.opacity(0.2))
                   .position(x: UIScreen.main.bounds.width / 2, y: 0.5)
           }
           .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: -5)
           .edgesIgnoringSafeArea(.all)
       }
}


// Preview
struct FixedTabBar_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            
            VStack {
                Spacer()
                
                TabBar(selectedTab: .constant(0), showAddTransaction: .constant(false))
            }
        }
    }
}

