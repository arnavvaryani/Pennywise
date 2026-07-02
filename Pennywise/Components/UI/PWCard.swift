//
//  PWCard.swift
//  Pennywise
//

import SwiftUI

struct PWCard<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .padding(16)
            // Liquid Glass (iOS 26), keeping the same 16pt rounded card shape.
            .glassEffect(.regular, in: .rect(cornerRadius: 16, style: .continuous))
    }
}

