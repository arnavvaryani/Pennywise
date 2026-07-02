//
//  CurrencyFormatter.swift
//  Pennywise
//
//  Utility for handling currency formatting based on user preferences
//

import Foundation

public struct CurrencyFormatter {
    private static let currencyDefaultsKey = "app_current_currency_code"

    /// The app-wide currency code used when a call doesn't pass one explicitly.
    /// Backed by UserDefaults so it is thread-safe (no shared mutable state /
    /// actor constraints) and persists across launches. Set this from the
    /// signed-in user's `currency` when the user loads.
    public static var currentCurrencyCode: String {
        get { UserDefaults.standard.string(forKey: currencyDefaultsKey) ?? "USD" }
        set { UserDefaults.standard.set(newValue, forKey: currencyDefaultsKey) }
    }

    /// Format an amount based on the user's preferred currency code.
    /// - Parameters:
    ///   - amount: The numeric amount to format
    ///   - currencyCode: The ISO 4217 currency code (e.g., "USD", "INR", "EUR").
    ///     When nil, the app-wide `currentCurrencyCode` is used.
    /// - Returns: A formatted string
    public static func format(_ amount: Double, currencyCode: String? = nil) -> String {
        // Build a formatter per call: NumberFormatter is not thread-safe to
        // share as mutable global state, and each call configures currencyCode.
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale.current // Default to current locale
        formatter.currencyCode = currencyCode ?? currentCurrencyCode

        return formatter.string(from: NSNumber(value: amount)) ?? "$\(String(format: "%.2f", amount))"
    }
    
    /// Format an amount for display, hiding it if required
    /// - Parameters:
    ///   - amount: The amount to format
    ///   - isHidden: Whether to mask the balance
    ///   - currencyCode: The currency code to use
    /// - Returns: Formatted or masked string
    public static func formatBalance(_ amount: Double, isHidden: Bool, currencyCode: String? = nil) -> String {
        if isHidden {
            return "•••••••"
        }
        return format(amount, currencyCode: currencyCode)
    }
}
