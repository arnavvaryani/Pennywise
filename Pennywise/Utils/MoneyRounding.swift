//
//  MoneyRounding.swift
//  Pennywise
//
//  Currency amounts are stored as Double for compatibility with Firestore,
//  SwiftUI format specifiers, and Charts geometry. Double is exact well beyond
//  cent precision for realistic transaction volumes, so the only place sub-cent
//  values sneak in is multiplication/division (budget = spending * 1.1, income *
//  percentage, savings rates, etc.). Normalize those results to whole cents at
//  the point of computation so persisted/displayed money is always cent-accurate.
//

import Foundation

extension Double {
    /// Rounds a monetary value to the nearest cent (2 decimal places) using
    /// banker's-safe half-up rounding via Decimal to avoid binary artifacts.
    var roundedToCents: Double {
        let decimal = Decimal(self)
        var rounded = Decimal()
        var source = decimal
        NSDecimalRound(&rounded, &source, 2, .plain)
        return NSDecimalNumber(decimal: rounded).doubleValue
    }
}
