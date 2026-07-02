//
//  PWTextFieldRow.swift
//  Pennywise
//

import SwiftUI
import UIKit

struct PWTextFieldRow: View {
    let placeholder: String
    @Binding var text: String
    let icon: String
    var keyboardType: UIKeyboardType = .default
    var textContentType: UITextContentType? = nil
    var autocapitalization: TextInputAutocapitalization = .never
    var disableAutocorrection: Bool = true
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(AppTheme.textColor.opacity(0.6))
                .frame(width: 24, alignment: .center)
            
            TextField("", text: $text)
                .placeholder(when: text.isEmpty) {
                    Text(placeholder)
                        .foregroundColor(AppTheme.textColor.opacity(0.5))
                }
                .foregroundColor(AppTheme.textColor)
                .keyboardType(keyboardType)
                .textContentType(textContentType)
                .textInputAutocapitalization(autocapitalization)
                .disableAutocorrection(disableAutocorrection)
        }
        .padding()
        // Liquid Glass field container.
        .glassEffect(.regular, in: .rect(cornerRadius: 12, style: .continuous))
    }
}

