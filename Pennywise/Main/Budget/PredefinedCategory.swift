//
//  PredefinedCategory.swift
//  Pennywise
//

import SwiftUI

struct PredefinedCategory: Identifiable {
    let id = UUID()
    let name: String
    let icon: String
    let color: Color
    let isEssential: Bool
}
