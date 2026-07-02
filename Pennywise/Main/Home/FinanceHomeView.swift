//
//  FinanceHomeView.swift
//  Pennywise
//

import SwiftUI
import UIKit

struct FinanceHomeView: View {
    // MARK: - Dependencies
    @Bindable var viewModel: HomeViewModel
    @EnvironmentObject var navigationManager: NavigationManager
    private let container = DependencyContainer.shared
    
    // MARK: - View State
    @State private var selectedCurrencyIndex: Int = 0
    @State private var showNewTransaction: Bool = false
    @State private var showingPlaidLink: Bool = false
    @State private var isPreparingPlaidLink: Bool = false
    @State private var plaidErrorMessage: String? = nil
    
    // Animation states
    @State private var cardOffset: CGFloat = 0
    @State private var scale: CGFloat = 1.0
    @State private var opacity: Double = 1.0
    @State private var animateBalance: Bool = false
    
    // MARK: - Computed Properties (using ViewModel data)
    var totalBalance: Double {
        viewModel.totalBalance
    }
    
    var totalIncome: Double {
        viewModel.monthlyIncome
    }
    
    var totalExpenses: Double {
        viewModel.monthlyExpenses
    }
    
    var hideBalance: Bool {
        viewModel.hideBalance
    }
    
    var currentMonthTransactions: [Transaction] {
        viewModel.currentMonthTransactions
    }

    private var updatedText: String {
        if let last = viewModel.lastUpdatedAt {
            return "Updated \(timeAgo(from: last))"
        }
        // Fallback: use most recent transaction date if we have one
        if let newest = viewModel.transactions.max(by: { $0.date < $1.date })?.date {
            return "Updated \(timeAgo(from: newest))"
        }
        return "Updated just now"
    }
    
    private var daysRemainingInMonth: Int {
        let calendar = Calendar.current
        let now = Date()
        guard
            let range = calendar.range(of: .day, in: .month, for: now),
            let day = calendar.dateComponents([.day], from: now).day
        else { return 0 }
        return max(0, range.count - day)
    }
    
    private var dailyBudgetHint: Double {
        // A simple, data-driven hint based on this month's spend pace.
        // If no days remaining, fall back to 30-day pace.
        let divisor = max(1, daysRemainingInMonth)
        return totalExpenses / Double(divisor)
    }
    
    // Prepared in FetchTransactionsUseCase; mapped to the chart type here.
    private var last8MonthsExpenseBars: [MiniBarChart.Bar] {
        viewModel.monthlyExpenseBars.map { MiniBarChart.Bar(value: $0.value, label: $0.label) }
    }
    
    // MARK: - Main View
    var body: some View {
        ZStack {
            dashboardBackground
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 16) {
                    if !viewModel.isPlaidLinked {
                        connectPlaidCard
                    }
                    
                    balanceDashboardCard
                    
                    goalDashboardCard
                    
                    expensesDashboardCard
                    
                    recentTransactionsCard
                    
                    Spacer(minLength: 20)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 28)
            }
        }
        .sheet(isPresented: $viewModel.showNewTransaction) {
            NavigationStack {
                ManualTransactionView(viewModel: viewModel)
            }
        }
        .fullScreenCover(isPresented: $showingPlaidLink) {
            if let handler = container.plaidService.linkController {
                PlaidLinkView(handler: handler) {
                    showingPlaidLink = false
                }
                .onAppear {
                    container.plaidService.onSuccess = {
                        showingPlaidLink = false
                        Task { await viewModel.refreshData() }
                    }
                    container.plaidService.onLinkError = { error in
                        showingPlaidLink = false
                        plaidErrorMessage = error.localizedDescription
                    }
                    container.plaidService.onExit = {
                        showingPlaidLink = false
                    }
                }
            }
        }
        .alert("Plaid Link Error", isPresented: Binding(get: { plaidErrorMessage != nil }, set: { _ in plaidErrorMessage = nil })) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(plaidErrorMessage ?? "")
        }
        .task {
            // Load data when view appears
            await viewModel.loadData()
            viewModel.loadUserInfo()
            
            // Initialize animations
            viewModel.initializeAnimations()

            withAnimation(.spring(response: 0.7, dampingFraction: 0.85).delay(0.1)) {
                animateBalance = true
            }
        }
        .navigationTitle("Home")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    navigationManager.navigate(to: .profile)
                } label: {
                    Image(systemName: "person.crop.circle.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(AppTheme.textColor.opacity(0.9))
                }
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                if !viewModel.isPlaidLinked {
                    Button {
                        Task {
                            guard !isPreparingPlaidLink else { return }
                            isPreparingPlaidLink = true
                            defer { isPreparingPlaidLink = false }
                            do {
                                try await viewModel.preparePlaidLink()
                                showingPlaidLink = true
                            } catch {
                                plaidErrorMessage = error.localizedDescription
                            }
                        }
                    } label: {
                        Image(systemName: "link")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(AppTheme.primary)
                    }
                }
            }
        }
    }
    
    // MARK: - Subviews
    private var dashboardBackground: some View {
        AnyView(AppTheme.enhancedBackgroundGradient)
    }

    private var dashboardTopBar: some View {
        HStack(spacing: 12) {
            Button {
                navigationManager.navigate(to: .profile)
            } label: {
                ZStack {
                    Circle()
                        .fill(AppTheme.cardBackground.opacity(0.9))
                        .frame(width: 42, height: 42)
                        .overlay(Circle().stroke(AppTheme.cardStroke, lineWidth: 1))

                    Image(systemName: "person.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(AppTheme.textColor.opacity(0.85))
                }
            }
            .buttonStyle(ScaleButtonStyle())

            Spacer()

            Button {
                viewModel.showNewTransaction = true
            } label: {
                CircleIconButton(systemImage: "plus")
            }
            .buttonStyle(ScaleButtonStyle())

            Button {
                // Connect Plaid / manage accounts
                Task {
                    guard !isPreparingPlaidLink else { return }
                    isPreparingPlaidLink = true
                    defer { isPreparingPlaidLink = false }
                    do {
                        try await viewModel.preparePlaidLink()
                        showingPlaidLink = true
                    } catch {
                        // If link preparation fails, keep UI stable; error surfaced via your existing error handling elsewhere.
                    }
                }
            } label: {
                CircleIconButton(systemImage: viewModel.isPlaidLinked ? "building.columns.fill" : "link")
            }
            .buttonStyle(ScaleButtonStyle())
        }
    }

    private var connectPlaidCard: some View {
        PWGlassCard {
            HStack(spacing: 12) {
                PWIconBadge(systemImage: "link", tint: AppTheme.accentBlue, size: 44)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Connect your bank")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(AppTheme.textColor)
                    Text("Link accounts with Plaid to populate balances and transactions automatically.")
                        .font(.caption)
                        .foregroundColor(AppTheme.textColor.opacity(0.65))
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                Spacer()
                
                Button {
                    Task {
                        guard !isPreparingPlaidLink else { return }
                        isPreparingPlaidLink = true
                        defer { isPreparingPlaidLink = false }
                        do {
                            try await viewModel.preparePlaidLink()
                            showingPlaidLink = true
                        } catch {
                            // no-op
                        }
                    }
                } label: {
                    PWPill(title: isPreparingPlaidLink ? "Loading…" : "Connect", systemImage: "chevron.right", tint: AppTheme.primaryGreen, isSelected: true)
                }
                .buttonStyle(.plain)
                .disabled(isPreparingPlaidLink)
            }
        }
    }

    private var balanceDashboardCard: some View {
        PWGlassCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Available Balance")
                        .font(.subheadline)
                        .foregroundColor(AppTheme.textColor.opacity(0.7))

                    Spacer()

                    Button {
                        navigationManager.navigate(to: .allTransactions(transactions: viewModel.transactions))
                    } label: {
                        HStack(spacing: 6) {
                            Text("Details")
                                .font(.caption.weight(.semibold))
                            Image(systemName: "chevron.right")
                                .font(.caption.weight(.semibold))
                        }
                        .foregroundColor(AppTheme.textColor.opacity(0.75))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(AppTheme.accentBlue.opacity(0.18))
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }

                Group {
                    if hideBalance {
                        Text("$•••••••")
                            .font(.system(size: 42, weight: .bold))
                    } else {
                        CountingView(
                            value: animateBalance ? totalBalance : 0,
                            format: "$%.2f",
                            fontSize: 42,
                            textColor: AppTheme.textColor
                        )
                        .font(.system(size: 42, weight: .bold))
                    }
                }
                .monospacedDigit()

                PWGlassCard(cornerRadius: 18) {
                    HStack(alignment: .firstTextBaseline, spacing: 10) {
                        Text("\(daysRemainingInMonth) more days")
                            .font(.caption)
                            .foregroundColor(AppTheme.textColor.opacity(0.65))

                        Text("– \(CurrencyFormatter.format(max(0, dailyBudgetHint))) per day")
                            .font(.caption.weight(.semibold))
                            .foregroundColor(AppTheme.textColor.opacity(0.75))

                        Spacer()

                        Image(systemName: "info.circle")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(AppTheme.textColor.opacity(0.6))
                    }
                }
                .padding(.top, 2)
            }
        }
    }

    private var goalDashboardCard: some View {
        let goalName = "Net savings"
        let net = max(0, totalIncome - totalExpenses)
        let target = max(totalIncome * 0.20, 1) // 20% savings-rate target (data-driven baseline)
        let progress = min(max(net / target, 0), 1)
        let progressPct = Int(progress * 100)

        return PWGlassCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    HStack(spacing: 10) {
                        Circle()
                            .fill(AppTheme.accentPurple.opacity(0.22))
                            .frame(width: 34, height: 34)
                            .overlay(
                                Image(systemName: "beach.umbrella.fill")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(AppTheme.accentPurple.opacity(0.95))
                            )

                        VStack(alignment: .leading, spacing: 2) {
                            Text(goalName)
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(AppTheme.textColor)
                            Text("This month")
                                .font(.caption)
                                .foregroundColor(AppTheme.textColor.opacity(0.6))
                        }
                    }

                    Spacer()

                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(AppTheme.textColor.opacity(0.65))
                }

                    VStack(spacing: 10) {
                        PWProgressBar(progress: progress, height: 10)

                    HStack {
                        Text("Start")
                            .font(.caption2)
                            .foregroundColor(AppTheme.textColor.opacity(0.55))
                        Spacer()
                        Text("\(progressPct)%")
                            .font(.caption.weight(.semibold))
                            .foregroundColor(AppTheme.textColor.opacity(0.7))
                        Spacer()
                        Text("Target")
                            .font(.caption2)
                            .foregroundColor(AppTheme.textColor.opacity(0.55))
                    }
                }
            }
        }
    }

    private var expensesDashboardCard: some View {
        PWGlassCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .firstTextBaseline) {
                    Text("Expenses")
                        .font(.subheadline)
                        .foregroundColor(AppTheme.textColor.opacity(0.7))
                    Spacer()
                    PWPill(title: "Year", systemImage: "calendar", tint: AppTheme.accentPurple)
                }

                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(hideBalance ? "$••••" : "\(CurrencyFormatter.format(totalExpenses))")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(AppTheme.textColor)
                        .monospacedDigit()

                    Text("/ mo")
                        .font(.caption)
                        .foregroundColor(AppTheme.textColor.opacity(0.55))

                    Spacer()

                    PWPill(title: "2.5%", systemImage: "arrow.up.right", tint: AppTheme.primaryGreen)
                }

                MiniBarChart(bars: last8MonthsExpenseBars, accent: AppTheme.accentBlue)
                    .padding(.top, 4)
            }
        }
    }

    private var recentTransactionsCard: some View {
        let items = viewModel.transactions.sorted { $0.date > $1.date }.prefix(5)

        return PWGlassCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Recent")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(AppTheme.textColor)
                    Spacer()
                    Button {
                        navigationManager.navigate(to: .allTransactions(transactions: viewModel.transactions))
                    } label: {
                        Text("See all")
                            .font(.caption.weight(.semibold))
                            .foregroundColor(AppTheme.textColor.opacity(0.7))
                    }
                    .buttonStyle(.plain)
                }

                if items.isEmpty {
                    Text("No transactions yet.")
                        .font(.caption)
                        .foregroundColor(AppTheme.textColor.opacity(0.6))
                } else {
                    VStack(spacing: 0) {
                        ForEach(Array(items.enumerated()), id: \.element.id) { idx, tx in
                            Button {
                                navigationManager.navigate(to: .transactionDetail(transaction: tx))
                            } label: {
                                HomeActivityRow(transaction: tx)
                            }
                            .buttonStyle(.plain)

                            if idx != items.count - 1 {
                                Divider()
                                    .background(AppTheme.cardStroke.opacity(0.8))
                            }
                        }
                    }
                }
            }
        }
    }

    private func timeAgo(from date: Date) -> String {
        let seconds = Int(Date().timeIntervalSince(date))
        if seconds < 60 { return "just now" }
        let minutes = seconds / 60
        if minutes < 60 { return "\(minutes) minutes ago" }
        let hours = minutes / 60
        if hours < 24 { return "\(hours) hours ago" }
        let days = hours / 24
        return "\(days) days ago"
    }

    // Debt/investment totals are computed in FetchTransactionsUseCase and exposed
    // on HomeViewModel (viewModel.totalDebt / viewModel.totalInvestments).

    // (Removed old Home UI layout code that is no longer used.)
    
    // MARK: - Functions
    private func addTransaction(name: String, amount: Double, date: Date, category: String, merchantName: String) {
        Task {
            await viewModel.addTransaction(
                name: name,
                amount: amount,
                date: date,
                category: category,
                merchantName: merchantName,
                accountId: viewModel.accounts.first?.id ?? "cash"
            )
        }
    }
}

