//
//  FinancialSuggestionsView.swift
//  Pennywise
//
//  Created by Arnav Varyani on 4/8/25.
//

import SwiftUI

struct FinancialSuggestionsView: View {
    // Sample suggestions
    let suggestions = [
        "Reduce dining out to save $100 this month",
        "Your entertainment spending is 25% over budget",
        "You could save $15K for retirement by increasing contributions 2%",
        "Set up an emergency fund of $5K with your surplus income"
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Suggestions for You")
                .font(.headline)
                .foregroundColor(.white)
            
            ForEach(suggestions, id: \.self) { suggestion in
                HStack(spacing: 12) {
                    Image(systemName: "lightbulb.fill")
                        .foregroundColor(AppTheme.savingsYellow)
                    
                    Text(suggestion)
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.leading)
                    
                    Spacer()
                }
                .padding(.vertical, 5)
            }
        }
        .padding()
    }
}
