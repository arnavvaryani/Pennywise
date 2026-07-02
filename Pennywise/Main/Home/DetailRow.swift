//
//  DetailRow.swift
//  Pennywise
//

import SwiftUI

struct DetailRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .foregroundColor(AppTheme.textColor.opacity(0.6))
            
            Spacer()
            
            Text(value)
                .foregroundColor(AppTheme.textColor)
                .fontWeight(.medium)
        }
    }
}
