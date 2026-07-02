//
//  CategoryButton.swift
//  Pennywise
//

import SwiftUI

struct CategoryButton: View {
    let name: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(isSelected ? AppTheme.backgroundColor : AppTheme.textColor)
                
                Text(name)
                    .font(.caption)
                    .fontWeight(isSelected ? .semibold : .regular)
                    .foregroundColor(isSelected ? AppTheme.backgroundColor : AppTheme.textColor)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? AppTheme.accentBlue : AppTheme.cardBackground)
            )
        }
    }
}
