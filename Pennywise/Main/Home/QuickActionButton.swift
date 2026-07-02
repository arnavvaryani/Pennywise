//
//  QuickActionButton.swift
//  Pennywise
//

import SwiftUI

struct QuickActionButton: View {
    let iconName: String
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            let impactLight = UIImpactFeedbackGenerator(style: .light)
            impactLight.impactOccurred()
            action()
        }) {
            VStack(spacing: 8) {
                Image(systemName: iconName)
                    .font(.system(size: 22))
                    .foregroundColor(AppTheme.textColor)
                
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(AppTheme.textColor)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(ScaleButtonStyle())
    }
}
