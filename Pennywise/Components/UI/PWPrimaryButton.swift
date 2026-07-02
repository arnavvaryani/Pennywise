//
//  PWPrimaryButton.swift
//  Pennywise
//

import SwiftUI

struct PWPrimaryButton: View {
    let title: String
    var isLoading: Bool = false
    var isDisabled: Bool = false
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                }

                Text(title)
                    .font(.headline)
            }
            .frame(maxWidth: .infinity)
        }
        // Liquid Glass prominent CTA. Uses the emerald income green rather than
        // the neon mint `primaryGreen` (#00FFC2), which reads as neon when used
        // as a flat prominent-glass tint.
        .controlSize(.large)
        .buttonStyle(.glassProminent)
        .tint(AppTheme.incomeGreen)
        .disabled(isDisabled || isLoading)
        .opacity((isDisabled || isLoading) ? 0.7 : 1.0)
    }
}

