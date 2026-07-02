//
//  CardStyleModifier.swift
//  Pennywise
//

import SwiftUI

struct CardStyleModifier: ViewModifier {
    @Environment(\.horizontalSizeClass) var sizeClass
    var customPadding: EdgeInsets?
    
    func body(content: Content) -> some View {
        content.padding(customPadding ?? (sizeClass == .regular ? AppTheme.cardPaddingRegular : AppTheme.cardPaddingCompact))
            .background(AppTheme.cardBackground)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(AppTheme.cardStroke, lineWidth: 1)
            )
    }
}
