//
//  CountingView.swift
//  Pennywise
//

import SwiftUI

struct CountingView: View {
    let value: Double
    let format: String
    let fontSize: CGFloat
    let textColor: Color
    
    var body: some View {
        Text(String(format: format, value))
            .font(.system(size: fontSize, weight: .bold))
            .foregroundColor(textColor)
    }
}
