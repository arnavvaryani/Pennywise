//
//  Transaction.swift
//  Pennywise
//
//  Created by Arnav Varyani on 4/11/25.
//

import Foundation
import LinkKit

struct Transaction: Identifiable {
    let id: Int
    let title: String
    let amount: Double
    let category: String
    let date: Date
    let merchant: String
    let icon: String
}
