
//
//  TransactionDetailView.swift
//  Pennywise
//
//  Created by Arnav Varyani on 4/15/25.
//

import SwiftUI

// MARK: - Transaction Detail View

struct TransactionDetailView: View {
    let transaction: PlaidTransaction
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var plaidManager: PlaidManager

    // State variables
    @State private var relatedTransactions: [PlaidTransaction] = []
    @State private var showingCategoryEditor = false
    @State private var isAddingNote = false
    @State private var noteText = ""
    @State private var transactionNote: String = ""

    // Computed properties
    private var accountInfo: PlaidAccount? {
        plaidManager.accounts.first { $0.id == transaction.accountId }
    }

    var body: some View {
        NavigationView {
            ZStack {
                AppTheme.backgroundGradient
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 25) {
                        transactionHeader
                        actionButtonsRow
                        transactionDetails
                        categorySection
                        notesSection
                        paymentMethodSection

                        if !transaction.pending {
                            additionalInfo
                        }

                        if !relatedTransactions.isEmpty {
                            similarTransactionsSection
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Transaction Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button { presentationMode.wrappedValue.dismiss() }
                    label: {
                        Image(systemName: "chevron.left")
                            .foregroundColor(AppTheme.primaryGreen)
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button {
                            let info = """
                                Transaction: \(transaction.merchantName)
                                Amount: $\(String(format: "%.2f", abs(transaction.amount)))
                                Date: \(formatDate(transaction.date))
                                Category: \(transaction.category)
                                """
                            shareTransaction(info)
                        } label: {
                            Label("Share", systemImage: "square.and.arrow.up")
                        }
                        Button {
                            // TODO: Report flow
                        } label: {
                            Label("Report an Issue", systemImage: "exclamationmark.triangle")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .foregroundColor(AppTheme.primaryGreen)
                    }
                }
            }
            .sheet(isPresented: $showingCategoryEditor) {
                CategoryEditorView(
                    initialCategory: transaction.category,
                    onSave: { newCat in
                        print("Category changed to: \(newCat)")
                        // TODO: persist change
                    }
                )
            }
            .onAppear(perform: loadTransactionData)
        }
    }

    // MARK: - Data Loading

    private func loadTransactionData() {
        transactionNote = ""  // TODO: load from DB
        relatedTransactions = plaidManager.transactions
            .filter { $0.id != transaction.id
                   && $0.merchantName.lowercased() == transaction.merchantName.lowercased() }
            .prefix(3)
            .map { $0 }
    }

    // MARK: - UI Sections

    private var transactionHeader: some View {
        VStack(spacing: 16) {
            Text(formatDate(transaction.date))
                .font(.subheadline)
                .foregroundColor(AppTheme.textColor.opacity(0.7))
                .padding(.vertical, 5).padding(.horizontal, 12)
                .background(AppTheme.cardBackground).cornerRadius(12)

            HStack(spacing: 20) {
                ZStack {
                    Circle()
                        .fill(transaction.amount < 0
                              ? AppTheme.primaryGreen.opacity(0.2)
                              : AppTheme.accentPurple.opacity(0.3))
                        .frame(width: 70, height: 70)

                    Image(systemName: getCategoryIcon(for: transaction.category))
                        .font(.system(size: 30))
                        .foregroundColor(transaction.amount < 0
                                         ? AppTheme.primaryGreen
                                         : AppTheme.accentPurple)
                }

                VStack(alignment: .leading, spacing: 5) {
                    Text(transaction.merchantName)
                        .font(.title3).fontWeight(.bold)
                        .foregroundColor(AppTheme.textColor)
                    Text(transaction.category)
                        .font(.subheadline)
                        .foregroundColor(AppTheme.textColor.opacity(0.7))
                    if transaction.pending {
                        Text("Pending")
                            .font(.caption)
                            .padding(.horizontal, 8).padding(.vertical, 3)
                            .background(AppTheme.accentBlue.opacity(0.2))
                            .foregroundColor(AppTheme.accentBlue)
                            .cornerRadius(4)
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 5) {
                    Text(transaction.amount < 0
                         ? "+$\(String(format: "%.2f", abs(transaction.amount)))"
                         : "-$\(String(format: "%.2f", abs(transaction.amount)))")
                        .font(.title2).fontWeight(.bold)
                        .foregroundColor(transaction.amount < 0
                                         ? AppTheme.primaryGreen
                                         : AppTheme.expenseColor)
                    Text(formatTimeOnly(transaction.date))
                        .font(.caption)
                        .foregroundColor(AppTheme.textColor.opacity(0.5))
                }
            }
            .padding().background(AppTheme.cardBackground)
            .cornerRadius(16)
            .overlay(RoundedRectangle(cornerRadius: 16)
                        .stroke(AppTheme.cardStroke, lineWidth: 1))
        }
    }

    private var actionButtonsRow: some View {
        HStack(spacing: 20) {
            Spacer()
            actionButton(icon: "tag", title: "Categorize") {
                showingCategoryEditor = true
            }
            actionButton(icon: "square.and.pencil", title: "Add Note") {
                isAddingNote = true
            }
            Spacer()
        }
        .padding(.vertical, 10)
    }

    private var transactionDetails: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Details")
                .font(.headline)
                .foregroundColor(AppTheme.textColor)
                .padding(.bottom, 5)

            detailRow(title: "Date",
                     value: formatDate(transaction.date, includeWeekday: true),
                     icon: "calendar")
            Divider().background(AppTheme.textColor.opacity(0.1))
            detailRow(title: "Account",
                     value: accountInfo?.name ?? "Account ending in \(transaction.accountId.suffix(4))",
                     icon: "creditcard")
            Divider().background(AppTheme.textColor.opacity(0.1))
            detailRow(title: "Status",
                     value: transaction.pending ? "Pending" : "Completed",
                     icon: "checkmark.circle")
            Divider().background(AppTheme.textColor.opacity(0.1))
            detailRow(title: "Transaction ID",
                     value: formatTransactionId(transaction.id),
                     icon: "number")
        }
        .padding().background(AppTheme.cardBackground)
        .cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16)
                    .stroke(AppTheme.cardStroke, lineWidth: 1))
    }

    private var categorySection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Category")
                .font(.headline)
                .foregroundColor(AppTheme.textColor)

            HStack {
                ZStack {
                    Circle()
                        .fill(categoryColor(for: transaction.category).opacity(0.2))
                        .frame(width: 40, height: 40)
                    Image(systemName: getCategoryIcon(for: transaction.category))
                        .font(.system(size: 20))
                        .foregroundColor(categoryColor(for: transaction.category))
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(transaction.category)
                        .font(.body)
                        .foregroundColor(AppTheme.textColor)
                    Text("\(calculateCategoryPercentage())% of monthly \(transaction.category.lowercased()) spending")
                        .font(.caption)
                        .foregroundColor(AppTheme.textColor.opacity(0.6))
                }
                Spacer()
                Button("Change") {
                    showingCategoryEditor = true
                }
                .padding(.horizontal, 12).padding(.vertical, 6)
                .background(AppTheme.primaryGreen.opacity(0.2))
                .cornerRadius(12)
                .buttonStyle(ScaleButtonStyle())
            }
            .padding().background(AppTheme.cardBackground)
            .cornerRadius(16)
            .overlay(RoundedRectangle(cornerRadius: 16)
                        .stroke(AppTheme.cardStroke, lineWidth: 1))
        }
    }

    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Notes")
                .font(.headline)
                .foregroundColor(AppTheme.textColor)

            if isAddingNote {
                VStack(spacing: 10) {
                    TextField("Add a note…", text: $noteText)
                        .padding().background(AppTheme.cardBackground).cornerRadius(8)
                        .overlay(RoundedRectangle(cornerRadius: 8)
                                    .stroke(AppTheme.cardStroke, lineWidth: 1))

                    HStack {
                        Button("Cancel") {
                            isAddingNote = false
                            noteText = transactionNote
                        }
                        .foregroundColor(AppTheme.textColor.opacity(0.7))
                        Spacer()
                        Button("Save") {
                            transactionNote = noteText
                            isAddingNote = false
                            // TODO: save to DB
                        }
                        .foregroundColor(AppTheme.primaryGreen)
                        .fontWeight(.semibold)
                    }
                }
                .padding().background(AppTheme.cardBackground).cornerRadius(16)
                .overlay(RoundedRectangle(cornerRadius: 16)
                            .stroke(AppTheme.cardStroke, lineWidth: 1))
            } else if !transactionNote.isEmpty {
                HStack {
                    Text(transactionNote)
                        .font(.body)
                        .foregroundColor(AppTheme.textColor)
                    Spacer()
                    Button {
                        noteText = transactionNote
                        isAddingNote = true
                    } label: {
                        Image(systemName: "pencil")
                            .foregroundColor(AppTheme.primaryGreen)
                    }
                }
                .padding().background(AppTheme.cardBackground).cornerRadius(16)
                .overlay(RoundedRectangle(cornerRadius: 16)
                            .stroke(AppTheme.cardStroke, lineWidth: 1))
            } else {
                Button {
                    noteText = ""
                    isAddingNote = true
                } label: {
                    HStack {
                        Image(systemName: "square.and.pencil")
                            .font(.system(size: 20))
                            .foregroundColor(AppTheme.primaryGreen)
                        Text("Add a note")
                            .font(.body)
                            .foregroundColor(AppTheme.primaryGreen)
                        Spacer()
                    }
                    .padding().background(AppTheme.cardBackground).cornerRadius(16)
                    .overlay(RoundedRectangle(cornerRadius: 16)
                                .stroke(AppTheme.cardStroke, lineWidth: 1))
                }
            }
        }
    }

    private var paymentMethodSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Payment Method")
                .font(.headline)
                .foregroundColor(AppTheme.textColor)

            HStack(spacing: 15) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(AppTheme.accentBlue.opacity(0.2))
                        .frame(width: 50, height: 35)
                    Image(systemName: "creditcard.fill")
                        .font(.system(size: 20))
                        .foregroundColor(AppTheme.accentBlue)
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text(accountInfo?.type ?? "Debit Card")
                        .font(.body)
                        .foregroundColor(AppTheme.textColor)
                    Text(accountInfo?.institutionName ?? "**** \(transaction.accountId.suffix(4))")
                        .font(.caption)
                        .foregroundColor(AppTheme.textColor.opacity(0.6))
                }
                Spacer()
            }
            .padding().background(AppTheme.cardBackground).cornerRadius(16)
            .overlay(RoundedRectangle(cornerRadius: 16)
                        .stroke(AppTheme.cardStroke, lineWidth: 1))
        }
    }

    private var additionalInfo: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Additional Information")
                .font(.headline)
                .foregroundColor(AppTheme.textColor)
            VStack(alignment: .leading, spacing: 12) {
                Text("Processed on \(formatDate(transaction.date, includeTime: true))")
                    .font(.body)
                    .foregroundColor(AppTheme.textColor.opacity(0.7))
                Divider().background(AppTheme.textColor.opacity(0.1))
                detailRow(title: "Type",
                          value: transaction.amount < 0 ? "Income" : "Expense",
                          icon: "arrow.right.circle")
                Divider().background(AppTheme.textColor.opacity(0.1))
                HStack {
                    Text("Reference Number:")
                        .font(.subheadline)
                        .foregroundColor(AppTheme.textColor.opacity(0.7))
                    Spacer()
                    Text("REF-\(transaction.id.prefixString(6))")
                        .font(.subheadline)
                        .foregroundColor(AppTheme.textColor)
                }
                Button {
                    // TODO: dispute flow
                } label: {
                    HStack {
                        Image(systemName: "exclamationmark.triangle")
                            .foregroundColor(AppTheme.expenseColor)
                        Text("Report an issue")
                            .font(.subheadline)
                            .foregroundColor(AppTheme.expenseColor)
                    }
                }
                .padding(.top, 10)
            }
            .padding().background(AppTheme.cardBackground).cornerRadius(16)
            .overlay(RoundedRectangle(cornerRadius: 16)
                        .stroke(AppTheme.cardStroke, lineWidth: 1))
        }
    }

    private var similarTransactionsSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Similar Transactions")
                .font(.headline)
                .foregroundColor(AppTheme.textColor)
            VStack(spacing: 12) {
                ForEach(relatedTransactions) { tx in
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(tx.merchantName)
                                .font(.body)
                                .foregroundColor(AppTheme.textColor)
                            Text(formatDate(tx.date, shortFormat: true))
                                .font(.caption)
                                .foregroundColor(AppTheme.textColor.opacity(0.6))
                        }
                        Spacer()
                        Text(tx.amount < 0
                             ? "+$\(String(format: "%.2f", abs(tx.amount)))"
                             : "-$\(String(format: "%.2f", abs(tx.amount)))")
                            .font(.body)
                            .foregroundColor(tx.amount < 0
                                             ? AppTheme.primaryGreen
                                             : AppTheme.expenseColor)
                    }
                    if tx.id != relatedTransactions.last?.id {
                        Divider().background(AppTheme.textColor.opacity(0.1))
                    }
                }
                Button("View All \(transaction.merchantName) Transactions") {
                    // TODO: navigate
                }
                .font(.subheadline)
                .foregroundColor(AppTheme.accentBlue)
                .padding(.top, 5)
            }
            .padding().background(AppTheme.cardBackground).cornerRadius(16)
            .overlay(RoundedRectangle(cornerRadius: 16)
                        .stroke(AppTheme.cardStroke, lineWidth: 1))
        }
    }

    // MARK: - Helpers

    private func actionButton(icon: String, title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 22))
                    .foregroundColor(AppTheme.primaryGreen)
                Text(title)
                    .font(.caption)
                    .foregroundColor(AppTheme.textColor)
            }
            .frame(width: 100)
            .padding(.vertical, 12)
            .background(AppTheme.cardBackground)
            .cornerRadius(12)
            .overlay(RoundedRectangle(cornerRadius: 12)
                        .stroke(AppTheme.cardStroke, lineWidth: 1))
        }
        .buttonStyle(ScaleButtonStyle())
    }

    private func detailRow(title: String, value: String, icon: String) -> some View {
        HStack(spacing: 15) {
            Image(systemName: icon)
                .foregroundColor(AppTheme.accentBlue)
                .frame(width: 20)
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(AppTheme.textColor.opacity(0.7))
                Text(value)
                    .font(.body)
                    .foregroundColor(AppTheme.textColor)
            }
            Spacer()
        }
    }

    private func calculateCategoryPercentage() -> Int {
        let cal = Calendar.current
        let m = cal.component(.month, from: Date())
        let y = cal.component(.year, from: Date())
        let txs = plaidManager.transactions.filter {
            $0.category == transaction.category &&
            cal.component(.month, from: $0.date) == m &&
            cal.component(.year, from: $0.date) == y &&
            $0.amount > 0
        }
        let total = txs.reduce(0) { $0 + abs($1.amount) }
        guard total > 0 else { return 100 }
        return Int((abs(transaction.amount) / total) * 100)
    }

    private func formatDate(_ date: Date,
                            includeTime: Bool = false,
                            includeWeekday: Bool = false,
                            shortFormat: Bool = false) -> String {
        let f = DateFormatter()
        if shortFormat {
            f.dateFormat = "MMM d, yyyy"
        } else if includeTime {
            f.dateFormat = "MMM d, yyyy 'at' h:mm a"
        } else if includeWeekday {
            f.dateFormat = "EEEE, MMMM d, yyyy"
        } else {
            f.dateFormat = "MMMM d, yyyy"
        }
        return f.string(from: date)
    }

    private func formatTimeOnly(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "h:mm a"
        return f.string(from: date)
    }

    private func formatTransactionId(_ id: String) -> String {
        return id.count > 8 ? "..." + id.suffixString(8) : id
    }

    private func getCategoryIcon(for cat: String) -> String {
        let lc = cat.lowercased()
        switch true {
        case lc.contains("food"), lc.contains("restaurant"): return "fork.knife"
        case lc.contains("shop"), lc.contains("store"):     return "cart"
        case lc.contains("transport"), lc.contains("travel"):return "car.fill"
        case lc.contains("entertainment"), lc.contains("recreation"): return "play.tv"
        case lc.contains("health"), lc.contains("medical"): return "heart.fill"
        case lc.contains("utility"), lc.contains("bill"):   return "bolt.fill"
        case lc.contains("income"), lc.contains("deposit"): return "arrow.down.circle.fill"
        default:                                           return "dollarsign.circle"
        }
    }

    private func categoryColor(for cat: String) -> Color {
        let lc = cat.lowercased()
        switch true {
        case lc.contains("food"), lc.contains("restaurant"): return AppTheme.primaryGreen
        case lc.contains("shop"), lc.contains("retail"):     return AppTheme.accentBlue
        case lc.contains("transport"), lc.contains("travel"):return AppTheme.accentPurple
        case lc.contains("entertainment"), lc.contains("leisure"): return Color(hex: "#FFD700").opacity(0.8)
        case lc.contains("health"), lc.contains("medical"): return Color(hex: "#FF5757")
        case lc.contains("utility"), lc.contains("bill"):   return Color(hex: "#9370DB")
        case lc.contains("income"), lc.contains("deposit"): return AppTheme.primaryGreen
        default:                                           return AppTheme.accentBlue
        }
    }

    private func shareTransaction(_ content: String) {
        guard let data = content.data(using: .utf8) else { return }
        let av = UIActivityViewController(activityItems: [data], applicationActivities: nil)
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let root = scene.windows.first?.rootViewController {
            root.present(av, animated: true)
        }
    }
}

// MARK: - String Helpers

extension String {
    func prefixString(_ len: Int) -> String {
        String(self.prefix(min(len, count)))
    }
    func suffixString(_ len: Int) -> String {
        String(self.suffix(min(len, count)))
    }
}

// MARK: - Category Editor View

struct CategoryEditorView: View {
    @Environment(\.presentationMode) var presentationMode
    let initialCategory: String
    let onSave: (String) -> Void
    @State private var selectedCategory: String

    let categories = [
        "Food", "Shopping", "Transportation", "Entertainment",
        "Health", "Utilities", "Housing", "Education",
        "Travel", "Income", "Subscriptions", "Personal Care",
        "Gifts", "Business", "Other"
    ]

    init(initialCategory: String, onSave: @escaping (String) -> Void) {
        self.initialCategory = initialCategory
        self.onSave = onSave
        self._selectedCategory = State(initialValue: initialCategory)
    }

    var body: some View {
        NavigationView {
            ZStack {
                AppTheme.backgroundGradient.ignoresSafeArea()
                ScrollView {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 140))], spacing: 16) {
                        ForEach(categories, id: \.self) { cat in
                            Button {
                                selectedCategory = cat
                            } label: {
                                VStack(spacing: 10) {
                                    ZStack {
                                        Circle()
                                            .fill(categoryColor(for: cat)
                                                    .opacity(selectedCategory == cat ? 0.5 : 0.2))
                                            .frame(width: 50, height: 50)
                                        Image(systemName: getCategoryIcon(for: cat))
                                            .font(.system(size: 20))
                                            .foregroundColor(selectedCategory == cat
                                                             ? AppTheme.backgroundColor
                                                             : categoryColor(for: cat))
                                    }
                                    Text(cat)
                                        .font(.subheadline)
                                        .fontWeight(selectedCategory == cat ? .semibold : .regular)
                                        .foregroundColor(AppTheme.textColor)
                                }
                                .padding()
                                .background(RoundedRectangle(cornerRadius: 16)
                                                .fill(selectedCategory == cat
                                                      ? categoryColor(for: cat).opacity(0.2)
                                                      : AppTheme.cardBackground))
                                .overlay(RoundedRectangle(cornerRadius: 16)
                                            .stroke(selectedCategory == cat
                                                    ? categoryColor(for: cat)
                                                    : AppTheme.cardStroke,
                                                    lineWidth: 1))
                            }
                            .buttonStyle(ScaleButtonStyle())
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Change Category")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { presentationMode.wrappedValue.dismiss() }
                        .foregroundColor(AppTheme.primaryGreen)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        onSave(selectedCategory)
                        presentationMode.wrappedValue.dismiss()
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(AppTheme.primaryGreen)
                }
            }
        }
    }

    private func getCategoryIcon(for cat: String) -> String {
        let lc = cat.lowercased()
        switch true {
        case lc.contains("food"), lc.contains("restaurant"): return "fork.knife"
        case lc.contains("shop"), lc.contains("store"):     return "cart"
        case lc.contains("transport"), lc.contains("travel"):return "car.fill"
        case lc.contains("entertain"), lc.contains("recreation"):return "play.tv"
        case lc.contains("health"), lc.contains("medical"): return "heart.fill"
        case lc.contains("utility"), lc.contains("bill"):   return "bolt.fill"
        case lc.contains("home"), lc.contains("house"), lc.contains("rent"): return "house.fill"
        case lc.contains("education"), lc.contains("school"): return "book.fill"
        case lc.contains("income"), lc.contains("deposit"): return "arrow.down.circle.fill"
        case lc.contains("subscription"):                   return "repeat"
        case lc.contains("gift"):                           return "gift.fill"
        case lc.contains("personal"):                       return "person.fill"
        case lc.contains("business"):                       return "briefcase.fill"
        default:                                            return "dollarsign.circle"
        }
    }

    private func categoryColor(for cat: String) -> Color {
        let lc = cat.lowercased()
        switch true {
        case lc.contains("food"), lc.contains("restaurant"): return AppTheme.primaryGreen
        case lc.contains("shop"), lc.contains("store"):     return AppTheme.accentBlue
        case lc.contains("transport"), lc.contains("travel"):return AppTheme.accentPurple
        case lc.contains("entertain"), lc.contains("leisure"):return Color(hex: "#FFD700").opacity(0.8)
        case lc.contains("health"), lc.contains("medical"): return Color(hex: "#FF5757")
        case lc.contains("utility"), lc.contains("bill"):   return Color(hex: "#9370DB")
        case lc.contains("house"), lc.contains("home"), lc.contains("rent"): return Color(hex: "#CD853F")
        case lc.contains("education"), lc.contains("school"): return Color(hex: "#4682B4")
        case lc.contains("income"), lc.contains("deposit"): return AppTheme.primaryGreen
        case lc.contains("subscription"):                   return Color(hex: "#BA55D3")
        case lc.contains("personal"):                       return Color(hex: "#FF7F50")
        case lc.contains("gift"):                           return Color(hex: "#FF69B4")
        case lc.contains("business"):                       return Color(hex: "#2E8B57")
        default:                                            return AppTheme.accentBlue
        }
    }
}

