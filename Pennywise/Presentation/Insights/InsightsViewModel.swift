//
//  InsightsViewModel.swift
//  Pennywise
//
//  ViewModel for Insights screen - Clean Architecture
//

import Foundation
import SwiftUI
import Observation

@MainActor
@Observable
public final class InsightsViewModel {
    // MARK: - Dependencies
    private let fetchInsightsUseCase: FetchInsightsUseCase
    private let plaidRepository: PlaidRepository

    // MARK: - Observable State
    /// Prepared aggregation for the currently-selected timeframe. Nil until the
    /// first load completes. All finance math lives in FetchInsightsUseCase.
    public var summary: InsightsSummary?
    public var isLoading = false
    public var error: Error?

    // MARK: - Init
    public init(
        fetchInsightsUseCase: FetchInsightsUseCase,
        plaidRepository: PlaidRepository
    ) {
        self.fetchInsightsUseCase = fetchInsightsUseCase
        self.plaidRepository = plaidRepository
    }

    // MARK: - Public Methods

    /// Loads (or reloads) the insights summary for the given timeframe.
    public func load(timeframe: TimeFrame) async {
        isLoading = true
        defer { isLoading = false }
        do {
            summary = try await fetchInsightsUseCase.execute(timeframe: timeframe)
        } catch {
            self.error = error
        }
    }

    // MARK: - Plaid Link
    public func preparePlaidLink() async throws {
        try await plaidRepository.preparePlaidLink()
    }
}
