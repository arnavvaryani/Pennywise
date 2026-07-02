//
//  PWGlassSurface.swift
//  Pennywise
//
//  Shared Liquid Glass surface styling so cards render consistently app-wide.
//

import SwiftUI

extension View {
    /// Applies the app's standard Liquid Glass surface (iOS 26) using the given
    /// corner radius. Use this in place of ad-hoc
    /// `.background(AppTheme.cardBackground).cornerRadius(_)` card treatments.
    func pwGlassSurface(cornerRadius: CGFloat = 16) -> some View {
        glassEffect(.regular, in: .rect(cornerRadius: cornerRadius, style: .continuous))
    }
}
