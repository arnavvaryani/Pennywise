//
//  PWDestructiveButton.swift
//  Pennywise
//

import SwiftUI

struct PWDestructiveButton: View {
    let title: String
    var isDisabled: Bool = false
    let action: () -> Void
    
    var body: some View {
        Button(role: .destructive, action: action) {
            Text(title)
                .font(.headline)
                .frame(maxWidth: .infinity)
        }
        // Liquid Glass prominent, tinted with the destructive/expense color.
        .controlSize(.large)
        .buttonStyle(.glassProminent)
        .tint(AppTheme.expenseColor)
        .disabled(isDisabled)
        .opacity(isDisabled ? 0.7 : 1.0)
    }
}

