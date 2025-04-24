//
//  InsightsTabView.swift
//  Pennywise
//
//  Created by Arnav Varyani on 4/14/25.
//

import SwiftUI

struct InsightsTabView: View {
    @State private var animateHeader = false
    
    var body: some View {
        NavigationView {
            InsightsView()
                .navigationTitle("Insights")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: {
                            // Action for refreshing insights data
                        }) {
                            Image(systemName: "arrow.clockwise")
                                .foregroundColor(AppTheme.primaryGreen)
                        }
                    }
                }
        }
    }
}

struct InsightsTabView_Previews: PreviewProvider {
    static var previews: some View {
        InsightsTabView()
            .environmentObject(PlaidManager.shared)
            .preferredColorScheme(.dark)
    }
}
