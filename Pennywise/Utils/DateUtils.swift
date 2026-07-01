//
//  DateUtils.swift
//  Pennywise
//
//  Centralized, timezone-consistent date handling for financial bucketing.
//
//  Plaid transaction dates are date-only ("yyyy-MM-dd"). To decide *which month*
//  a transaction belongs to, the parser and every month-boundary computation must
//  agree on a single timezone. We standardize on UTC so month assignment is
//  deterministic and identical across devices and after a timezone change.
//
//  IMPORTANT: this is for BUCKETING/BOUNDARY math only. User-facing display
//  formatters should remain in the device's local timezone (that's correct UX)
//  and must NOT use these helpers.
//

import Foundation

enum DateUtils {
    /// The single timezone used for all financial bucketing.
    static let bucketingTimeZone = TimeZone(identifier: "UTC")!

    /// Calendar used for all month/day boundary math on financial data.
    static var calendar: Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = bucketingTimeZone
        return cal
    }

    /// Parses a Plaid "yyyy-MM-dd" date string to a deterministic UTC-midnight instant.
    static func parsePlaidDate(_ string: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = bucketingTimeZone
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter.date(from: string)
    }

    /// Formats a date as "yyyy-MM-dd" in UTC (for Plaid API request ranges, etc.).
    static func plaidDateString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = bucketingTimeZone
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter.string(from: date)
    }

    /// First instant of the month containing `date`, in the bucketing timezone.
    static func startOfMonth(for date: Date) -> Date {
        let cal = calendar
        return cal.date(from: cal.dateComponents([.year, .month], from: date)) ?? date
    }

    /// First instant of the month *after* the one containing `date`.
    static func startOfNextMonth(for date: Date) -> Date {
        let cal = calendar
        let start = startOfMonth(for: date)
        return cal.date(byAdding: .month, value: 1, to: start) ?? date
    }

    /// Normalizes a date the user picked in their LOCAL calendar (e.g. from a
    /// DatePicker) to UTC-midnight of that same calendar day, so manually-entered
    /// dates bucket into the same month as UTC-parsed Plaid transaction dates.
    static func utcDay(fromLocalPickedDate date: Date) -> Date {
        let localDay = Calendar.current.dateComponents([.year, .month, .day], from: date)
        return calendar.date(from: localDay) ?? date
    }
}
