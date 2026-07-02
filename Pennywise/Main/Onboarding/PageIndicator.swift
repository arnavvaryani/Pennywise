//
//  PageIndicator.swift
//  Pennywise
//

import SwiftUI

struct PageIndicator: View {
    let numberOfPages: Int
    let currentPage: Int
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<numberOfPages, id: \.self) { page in
                Circle()
                    .fill(currentPage == page ? AppTheme.primaryGreen : AppTheme.textColor.opacity(0.3))
                    .frame(width: 8, height: 8)
                    .scaleEffect(currentPage == page ? 1.2 : 1.0)
                    .animation(.spring(), value: currentPage)
            }
        }
    }
}

