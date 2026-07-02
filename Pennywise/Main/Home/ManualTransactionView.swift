//
//  ManualTransactionView.swift
//  Pennywise
//
//  Manual transaction entry view
//

import SwiftUI

struct ManualTransactionView: View {
    var viewModel: HomeViewModel
    @Environment(\.dismiss) var dismiss
    
    @State private var name = ""
    @State private var amount = ""
    @State private var date = Date()
    @State private var category = "General"
    @State private var merchantName = ""
    @State private var isIncome = false
    
    let categories = ["General", "Food", "Shopping", "Transportation", "Entertainment", "Utilities", "Health", "Income"]
    
    var body: some View {
        ZStack {
            AppTheme.enhancedBackgroundGradient
            
            Form {
                Section(header: Text("Transaction Details")) {
                    TextField("Name", text: $name)
                    
                    TextField("Merchant", text: $merchantName)
                    
                    HStack {
                        Text("$")
                        TextField("Amount", text: $amount)
                            .keyboardType(.decimalPad)
                    }
                    
                    Toggle("Income", isOn: $isIncome)
                    
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                    
                    Picker("Category", selection: $category) {
                        ForEach(categories, id: \.self) { cat in
                            Text(cat).tag(cat)
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
        }
        .navigationTitle("Add Transaction")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") {
                    dismiss()
                }
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Save") {
                    saveTransaction()
                }
                .disabled(name.isEmpty || amount.isEmpty)
            }
        }
    }
    
    private func saveTransaction() {
        guard let amountValue = Double(amount) else { return }
        let finalAmount = isIncome ? -abs(amountValue) : abs(amountValue)
        
        Task {
            await viewModel.addTransaction(
                name: name,
                amount: finalAmount,
                date: date,
                category: category,
                merchantName: merchantName.isEmpty ? name : merchantName
            )
            
            await MainActor.run {
                dismiss()
            }
        }
    }
}

