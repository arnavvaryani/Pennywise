//
//  NewTransactionView.swift
//  Pennywise
//
//  Created by Arnav Varyani on 4/11/25.
//

import SwiftUI
import Combine

// MARK: - ViewModel
class TransactionViewModel: ObservableObject {
    // User inputs
    @Published var title: String = ""
    @Published var amount: String = ""
    @Published var isExpense: Bool = true
    @Published var selectedCategory: String = "Food"
    @Published var date: Date = Date()
    @Published var merchant: String = ""
    @Published var notes: String = ""
    
    // UI state
    @Published var isProcessing: Bool = false
    @Published var isAuthorized: Bool = false
    @Published var validationError: String? = nil
    
    // Categories with appropriate icons
    let categories: [(name: String, icon: String, color: Color)] = [
        ("Food", "fork.knife", AppTheme.primaryGreen),
        ("Shopping", "cart", AppTheme.accentBlue),
        ("Transportation", "car.fill", AppTheme.accentPurple),
        ("Entertainment", "play.tv", AppTheme.expenseColor),
        ("Health", "heart.fill", AppTheme.savingsYellow),
        ("Utilities", "bolt.fill", AppTheme.investmentPurple),
        ("Income", "arrow.down.circle.fill", AppTheme.primaryGreen),
        ("Other", "ellipsis.circle.fill", Color.gray)
    ]
    
    // Services
    private let authService = AuthenticationService.shared
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        // Set up data validation
       // setupValidation()
    }
    
    private func setupValidation() {
        // Watch for changes to validate in real-time
        Publishers.CombineLatest3($title, $amount, $merchant)
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] title, amount, merchant in
                self?.validateInputs()
            }
            .store(in: &cancellables)
    }
    
    func validateInputs() -> Bool {
        // Check if title is empty
        if title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            validationError = "Please enter a title"
            return false
        }
        
        // Check if merchant is empty
        if merchant.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            validationError = "Please enter a merchant"
            return false
        }
        
        // Check if amount is valid
        if amount.isEmpty {
            validationError = "Please enter an amount"
            return false
        }
        
        guard let amountValue = Double(amount) else {
            validationError = "Please enter a valid amount"
            return false
        }
        
        if amountValue <= 0 {
            validationError = "Amount must be greater than zero"
            return false
        }
        
        // All validations passed
        validationError = nil
        return true
    }
    
    func startTransactionProcess(completion: @escaping (Transaction?) -> Void) {
        // Validate inputs first
        guard validateInputs() else {
            completion(nil)
            return
        }
        
        // Only trigger biometric auth if it's enabled and required for transactions
        if authService.biometricAuthEnabled && authService.requireBiometricsForTransactions {
            isProcessing = true
            authenticateTransaction { [weak self] success in
                guard let self = self else { return }
                
                if success {
                    // Authentication successful, complete the transaction
                    let transaction = self.createTransaction()
                    completion(transaction)
                } else {
                    // Authentication failed
                    self.isProcessing = false
                    completion(nil)
                }
            }
        } else {
            // No authentication required, create transaction directly
            let transaction = createTransaction()
            completion(transaction)
        }
    }
    
    private func authenticateTransaction(completion: @escaping (Bool) -> Void) {
        guard let amountValue = Double(amount) else {
            completion(false)
            return
        }
        
        let reason = "Authorize \(isExpense ? "payment" : "deposit") of $\(String(format: "%.2f", amountValue))"
        
        authService.authenticateWithBiometrics(reason: reason) { success, error in
            DispatchQueue.main.async {
                if success {
                    self.isAuthorized = true
                    completion(true)
                } else {
                    if let error = error {
                        print("Authentication failed: \(error.localizedDescription)")
                    }
                    completion(false)
                }
            }
        }
    }
    
    func createTransaction() -> Transaction {
        guard let amountValue = Double(amount) else {
            return Transaction(
                id: 0,
                title: "",
                amount: 0,
                category: "",
                date: Date(),
                merchant: "",
                icon: ""
            )
        }
        
        let finalAmount = isExpense ? -amountValue : amountValue
        let transactionCategory = isExpense ? selectedCategory : "Income"
        
        return Transaction(
            id: Int.random(in: 10...1000),
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            amount: finalAmount,
            category: transactionCategory,
            date: date,
            merchant: merchant.trimmingCharacters(in: .whitespacesAndNewlines),
            icon: getIconForCategory(transactionCategory)
        )
    }
    
    func getIconForCategory(_ category: String) -> String {
        // Safely search for the category in the categories array
        if let categoryInfo = categories.first(where: { $0.name == category }) {
            return categoryInfo.icon
        }
        
        // Provide category-based fallbacks if category doesn't match predefined list
        let lowercaseCategory = category.lowercased()
        
        if lowercaseCategory.contains("food") || lowercaseCategory.contains("dining") {
            return "fork.knife"
        } else if lowercaseCategory.contains("shop") {
            return "cart"
        } else if lowercaseCategory.contains("transport") {
            return "car.fill"
        } else if lowercaseCategory.contains("entertainment") {
            return "play.tv"
        } else if lowercaseCategory.contains("health") {
            return "heart.fill"
        } else if lowercaseCategory.contains("utilities") {
            return "bolt.fill"
        } else if lowercaseCategory.contains("income") || lowercaseCategory.contains("deposit") {
            return "arrow.down.circle.fill"
        }
        
        return "ellipsis.circle.fill" // Default icon
    }
}

// MARK: - View
struct TransactionView: View {
    @Binding var isPresented: Bool
    let onSave: (Transaction) -> Void
    
    @StateObject private var viewModel = TransactionViewModel()
    @Environment(\.colorScheme) private var colorScheme
    @FocusState private var focusedField: Field?
    
    private enum Field: Hashable {
        case title, amount, merchant, notes
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                AppTheme.backgroundGradient.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Transaction details section
                        transactionDetailsSection
                        
                        // Transaction type section
                        transactionTypeSection
                        
                        // Categories grid section
                        categoriesSection
                        
                        // Date picker section
                        datePickerSection
                        
                        // Notes section
                        notesSection
                    }
                    .padding()
                }
                .scrollDismissesKeyboard(.immediately)
            }
            .navigationTitle("New Transaction")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    cancelButton
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    saveButton
                }
                
                ToolbarItem(placement: .keyboard) {
                    keyboardToolbar
                }
            }
            .accentColor(AppTheme.primaryGreen)
            .alert(item: Binding<AuthAlert?>(
                get: {
                    viewModel.validationError != nil ? AuthAlert(message: viewModel.validationError!) : nil
                },
                set: { _ in viewModel.validationError = nil }
            )) { alert in
                Alert(
                    title: Text("Cannot Save Transaction"),
                    message: Text(alert.message),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
        .overlay(
            Group {
                if viewModel.isProcessing {
                    biometricAuthOverlay
                }
            }
        )
    }
    
    // MARK: - UI Components
    
    private var transactionDetailsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Transaction Details")
                .font(AppTheme.headlineFont())
                .foregroundColor(AppTheme.textColor)
                .accessibilityAddTraits(.isHeader)
            
            customTextField(
                placeholder: "Title",
                text: $viewModel.title,
                icon: "text.cursor",
                field: .title
            )
            
            customTextField(
                placeholder: "Merchant",
                text: $viewModel.merchant,
                icon: "bag",
                field: .merchant
            )
            
            HStack {
                Image(systemName: "dollarsign.circle")
                    .foregroundColor(AppTheme.primaryGreen)
                    .frame(width: 24, height: 24)
                
                Text("$")
                    .foregroundColor(AppTheme.textColor.opacity(0.8))
                
                TextField("Amount", text: $viewModel.amount)
                    .keyboardType(.decimalPad)
                    .foregroundColor(AppTheme.textColor)
                    .focused($focusedField, equals: .amount)
                    .accessibilityLabel("Amount in dollars")
            }
            .padding()
            .background(AppTheme.cardBackground)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(focusedField == .amount ? AppTheme.primaryGreen : AppTheme.cardStroke, lineWidth: 1)
            )
        }
    }
    
    private var transactionTypeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Type")
                .font(AppTheme.headlineFont())
                .foregroundColor(AppTheme.textColor)
                .accessibilityAddTraits(.isHeader)
            
            HStack(spacing: 15) {
                // Expense button
                transactionTypeButton(
                    title: "Expense",
                    iconName: "arrow.up.circle.fill",
                    isSelected: viewModel.isExpense,
                    color: AppTheme.expenseColor
                ) {
                    withAnimation(.spring()) {
                        viewModel.isExpense = true
                    }
                }
                
                // Income button
                transactionTypeButton(
                    title: "Income",
                    iconName: "arrow.down.circle.fill",
                    isSelected: !viewModel.isExpense,
                    color: AppTheme.primaryGreen
                ) {
                    withAnimation(.spring()) {
                        viewModel.isExpense = false
                    }
                }
            }
        }
    }
    
    private var categoriesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Category")
                .font(AppTheme.headlineFont())
                .foregroundColor(AppTheme.textColor)
                .accessibilityAddTraits(.isHeader)
            
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 12) {
                ForEach(viewModel.categories, id: \.name) { category in
                    CategoryButton(
                        name: category.name,
                        icon: category.icon,
                     //   color: category.color,
                        isSelected: viewModel.selectedCategory == category.name,
                        action: {
                            withAnimation {
                                viewModel.selectedCategory = category.name
                            }
                        }
                    )
                }
            }
        }
    }
    
    private var datePickerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Date")
                .font(AppTheme.headlineFont())
                .foregroundColor(AppTheme.textColor)
                .accessibilityAddTraits(.isHeader)
            
            DatePicker(
                "",
                selection: $viewModel.date,
                displayedComponents: .date
            )
            .datePickerStyle(GraphicalDatePickerStyle())
            .accentColor(AppTheme.primaryGreen)
            .padding()
            .background(AppTheme.cardBackground)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(AppTheme.cardStroke, lineWidth: 1)
            )
            .accessibilityLabel("Transaction date: \(DateFormatter.localizedString(from: viewModel.date, dateStyle: .medium, timeStyle: .none))")
        }
    }
    
    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Notes (Optional)")
                .font(AppTheme.headlineFont())
                .foregroundColor(AppTheme.textColor)
                .accessibilityAddTraits(.isHeader)
            
            ZStack(alignment: .topLeading) {
                if viewModel.notes.isEmpty {
                    Text("Add notes about this transaction...")
                        .foregroundColor(AppTheme.textColor.opacity(0.4))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 12)
                }
                
                TextEditor(text: $viewModel.notes)
                    .focused($focusedField, equals: .notes)
                    .padding(4)
                    .frame(minHeight: 100)
                    .foregroundColor(AppTheme.textColor)
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)
                    .accessibilityLabel("Transaction notes")
            }
            .padding(8)
            .background(AppTheme.cardBackground)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(focusedField == .notes ? AppTheme.primaryGreen : AppTheme.cardStroke, lineWidth: 1)
            )
        }
    }
    
    private var cancelButton: some View {
        Button("Cancel") {
            isPresented = false
        }
        .foregroundColor(AppTheme.primaryGreen)
        .accessibilityLabel("Cancel transaction")
    }
    
    private var saveButton: some View {
        Button("Save") {
            startTransactionProcess()
        }
        .fontWeight(.bold)
        .foregroundColor(AppTheme.primaryGreen)
        .disabled(viewModel.title.isEmpty || viewModel.amount.isEmpty || viewModel.merchant.isEmpty)
        .opacity(viewModel.title.isEmpty || viewModel.amount.isEmpty || viewModel.merchant.isEmpty ? 0.5 : 1)
        .accessibilityLabel("Save transaction")
        .accessibilityHint("Double tap to save this transaction")
    }
    
    private var keyboardToolbar: some View {
        HStack {
            Button(action: {
                focusedField = nil
            }) {
                Text("Done")
                    .foregroundColor(AppTheme.primaryGreen)
            }
            
            Spacer()
            
            // Field navigation buttons
            if focusedField != nil {
                Button(action: {
                    navigateToPreviousField()
                }) {
                    Image(systemName: "chevron.up")
                        .foregroundColor(AppTheme.primaryGreen)
                }
                .disabled(previousField() == nil)
                .opacity(previousField() == nil ? 0.5 : 1)
                
                Button(action: {
                    navigateToNextField()
                }) {
                    Image(systemName: "chevron.down")
                        .foregroundColor(AppTheme.primaryGreen)
                }
                .disabled(nextField() == nil)
                .opacity(nextField() == nil ? 0.5 : 1)
            }
        }
        .padding(.horizontal)
    }
    
    private var biometricAuthOverlay: some View {
        ZStack {
            // Background blur
            Color.black.opacity(0.5)
                .edgesIgnoringSafeArea(.all)
            
            // Authentication prompt
            VStack(spacing: 20) {
                let authService = AuthenticationService.shared
                let biometricType = authService.getBiometricType()
                
                Image(systemName: biometricType == .faceID ? "faceid" : "touchid")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 60, height: 60)
                    .foregroundColor(AppTheme.primaryGreen)
                
                Text("Authenticate Transaction")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                let amountValue = Double(viewModel.amount) ?? 0
                Text("Please use \(biometricType.name) to authorize your \(viewModel.isExpense ? "payment" : "deposit") of $\(String(format: "%.2f", amountValue))")
                    .font(.headline)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.white.opacity(0.8))
                    .padding(.horizontal)
                
                HStack(spacing: 20) {
                    Button(action: {
                        // Cancel the transaction authentication
                        viewModel.isProcessing = false
                    }) {
                        Text("Cancel")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.gray.opacity(0.3))
                            .foregroundColor(.white)
                            .cornerRadius(15)
                    }
                    .accessibilityLabel("Cancel authentication")
                    
                    Button(action: {
                        authenticateTransaction()
                    }) {
                        Text("Authenticate")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(AppTheme.primaryGreen)
                            .foregroundColor(.white)
                            .cornerRadius(15)
                    }
                    .accessibilityLabel("Authenticate using \(biometricType.name)")
                }
                .padding(.top, 10)
            }
            .padding(30)
            .background(AppTheme.backgroundColor.opacity(0.9))
            .cornerRadius(20)
            .shadow(radius: 10)
            .padding(.horizontal, 40)
        }
        .onAppear {
            // If biometric auth is required, start the authentication process
            if AuthenticationService.shared.requireBiometricsForTransactions {
                authenticateTransaction()
            } else {
                // If not required, consider the transaction pre-authorized
                completeTransaction()
            }
        }
    }
    
    // MARK: - Helper Functions
    
    // Custom text field to reuse formatting
    private func customTextField(placeholder: String, text: Binding<String>, icon: String, field: Field) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(AppTheme.primaryGreen)
                .frame(width: 24, height: 24)
            
            TextField(placeholder, text: text)
                .foregroundColor(AppTheme.textColor)
                .padding(.vertical, 12)
                .focused($focusedField, equals: field)
                .submitLabel(nextField(from: field) == nil ? .done : .next)
                .onSubmit {
                    if let next = nextField(from: field) {
                        focusedField = next
                    } else {
                        focusedField = nil
                    }
                }
        }
        .padding(.horizontal)
        .background(AppTheme.cardBackground)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(focusedField == field ? AppTheme.primaryGreen : AppTheme.cardStroke, lineWidth: 1)
        )
        .accessibilityLabel("\(placeholder) field")
    }
    
    // Reusable transaction type button
    private func transactionTypeButton(
        title: String,
        iconName: String,
        isSelected: Bool,
        color: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack {
                Image(systemName: iconName)
                    .foregroundColor(isSelected ? AppTheme.backgroundColor : color)
                
                Text(title)
                    .fontWeight(isSelected ? .semibold : .regular)
                    .foregroundColor(isSelected ? AppTheme.backgroundColor : AppTheme.textColor)
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 15)
            .frame(maxWidth: .infinity)
            .background(
                Capsule()
                    .fill(isSelected ? color : color.opacity(0.1))
            )
        }
        .accessibilityAddTraits(isSelected ? [.isSelected, .isButton] : .isButton)
        .accessibilityLabel("\(title) transaction type")
    }
    
    // Start the transaction process with biometric authentication if needed
    private func startTransactionProcess() {
        viewModel.startTransactionProcess { transaction in
            if let transaction = transaction {
                onSave(transaction)
                isPresented = false
            }
        }
    }
    
    private func authenticateTransaction() {
        let authService = AuthenticationService.shared
        guard let amountValue = Double(viewModel.amount) else {
            viewModel.isProcessing = false
            return
        }
        
        authService.authenticateWithBiometrics(
            reason: "Authorize \(viewModel.isExpense ? "payment" : "deposit") of $\(String(format: "%.2f", amountValue))"
        ) { success, error in
            DispatchQueue.main.async {
                if success {
                    completeTransaction()
                } else {
                    viewModel.isProcessing = false
                    // Show error feedback if needed
                }
            }
        }
    }
    
    private func completeTransaction() {
        let transaction = viewModel.createTransaction()
        onSave(transaction)
        isPresented = false
    }
    
    // Field navigation helpers
    private func previousField() -> Field? {
        switch focusedField {
        case .title:
            return nil
        case .amount:
            return .title
        case .merchant:
            return .amount
        case .notes:
            return .merchant
        case .none:
            return nil
        }
    }
    
    private func nextField(from field: Field? = nil) -> Field? {
        let currentField = field ?? focusedField
        
        switch currentField {
        case .title:
            return .amount
        case .amount:
            return .merchant
        case .merchant:
            return .notes
        case .notes:
            return nil
        case .none:
            return .title
        }
    }
    
    private func navigateToPreviousField() {
        if let previous = previousField() {
            focusedField = previous
        }
    }
    
    private func navigateToNextField() {
        if let next = nextField() {
            focusedField = next
        } else {
            focusedField = nil
        }
    }
}

// MARK: - Supporting Types

// Helper struct for alert presentation
struct AuthAlert: Identifiable {
    var id: String { message }
    let message: String
}

// MARK: - Preview
struct TransactionView_Previews: PreviewProvider {
    static var previews: some View {
        TransactionView(
            isPresented: .constant(true),
            onSave: { _ in }
        )
        .preferredColorScheme(.dark)
        .environmentObject(AuthenticationService.shared)
    }
}
