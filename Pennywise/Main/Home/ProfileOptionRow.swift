//
//  ProfileOptionRow.swift
//  Pennywise
//

import SwiftUI

struct ProfileOptionRow: View {
    let icon: String
    let title: String
    
    var body: some View {
        Button(action: {}) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(AppTheme.textColor)
                    .frame(width: 30)
                
                Text(title)
                    .foregroundColor(AppTheme.textColor)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(AppTheme.textColor.opacity(0.5))
            }
            .padding()
            .background(AppTheme.accentPurple.opacity(0.2))
            .cornerRadius(12)
        }
    }
}
