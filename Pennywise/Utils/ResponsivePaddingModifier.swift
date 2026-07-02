//
//  ResponsivePaddingModifier.swift
//  Pennywise
//

import SwiftUI

struct ResponsivePaddingModifier: ViewModifier {
    @Environment(\.horizontalSizeClass) var sizeClass
    
    func body(content: Content) -> some View {
        content.padding(.horizontal, sizeClass == .regular ? AppTheme.horizontalPaddingRegular : AppTheme.horizontalPaddingCompact)
    }
}
