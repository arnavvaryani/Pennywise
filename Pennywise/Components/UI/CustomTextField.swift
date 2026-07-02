//
//  CustomTextField.swift
//  Pennywise
//
//  Reusable styled text field with icon for settings and forms.
//

import SwiftUI
import UIKit

struct CustomTextField: View {
    let placeholder: String
    @Binding var text: String
    let icon: String
    var keyboardType: UIKeyboardType = .default

    var body: some View {
        PWTextFieldRow(
            placeholder: placeholder,
            text: $text,
            icon: icon,
            keyboardType: keyboardType,
            textContentType: nil,
            autocapitalization: .never,
            disableAutocorrection: true
        )
    }
}
