//
//  PWSecureFieldRow.swift
//  Pennywise
//

import SwiftUI
import UIKit

struct PWSecureFieldRow: View {
    let placeholder: String
    @Binding var text: String
    let icon: String
    var textContentType: UITextContentType? = .password
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(AppTheme.textColor.opacity(0.6))
                .frame(width: 24, alignment: .center)
            
            SecureField("", text: $text)
                .placeholder(when: text.isEmpty) {
                    Text(placeholder)
                        .foregroundColor(AppTheme.textColor.opacity(0.5))
                }
                .foregroundColor(AppTheme.textColor)
                .textContentType(textContentType)
        }
        .padding()
        // Liquid Glass field container.
        .glassEffect(.regular, in: .rect(cornerRadius: 12, style: .continuous))
    }
}

