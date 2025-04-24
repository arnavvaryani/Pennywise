//
//  FormField.swift
//  Pennywise
//
//  Created by Arnav Varyani on 4/24/25.
//

import SwiftUI

//struct FormField<Content: View>: View {
//    let title: String
//    let isRequired: Bool
//    let content: Content
//    
//    init(title: String, isRequired: Bool = false, @ViewBuilder content: () -> Content) {
//        self.title = title
//        self.isRequired = isRequired
//        self.content = content()
//    }
//    
//    var body: some View {
//        VStack(alignment: .leading, spacing: 8) {
//            HStack(spacing: 4) {
//                Text(title)
//                    .font(.subheadline)
//                    .foregroundColor(AppTheme.textColor.opacity(0.8))
//                
//                if isRequired {
//                    Text("*")
//                        .foregroundColor(Color(hex: "#FF5757"))
//                }
//            }
//            
//            content
//        }
//    }
//}
