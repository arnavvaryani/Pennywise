//
//  FinanceRootView.swift
//  Pennywise
//
//  Created for Pennywise App
//


import SwiftUI

// Simple add transaction view
struct AddTransactionView: View {
    @Binding var isPresented: Bool
    var onSave: (Transaction) -> Void
    
    @State private var title = ""
    @State private var amount = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                // Apply the background color to the entire view
                AppTheme.backgroundPrimary
                    .edgesIgnoringSafeArea(.all)
                
                VStack {
                    TextField("Title", text: $title)
                        .padding()
                        .background(AppTheme.backgroundSecondary)
                        .cornerRadius(10)
                        .padding(.horizontal)
                        .foregroundColor(.white)
                    
                    TextField("Amount", text: $amount)
                        .keyboardType(.decimalPad)
                        .padding()
                        .background(AppTheme.backgroundSecondary)
                        .cornerRadius(10)
                        .padding(.horizontal)
                        .foregroundColor(.white)
                    
                    Button("Save") {
                        let newTransaction = Transaction(
                            id: Int.random(in: 1...1000),
                            title: title,
                            amount: Double(amount) ?? 0,
                            category: "Other",
                            date: Date(),
                            merchant: "Unknown",
                            icon: "dollarsign.circle"
                        )
                        onSave(newTransaction)
                        isPresented = false
                    }
                    .padding()
                    .background(AppTheme.primary)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .padding(.top, 20)
                    
                    Spacer()
                }
                .padding(.top)
            }
            .navigationTitle("Add Transaction")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                trailing: Button("Cancel") {
                    isPresented = false
                }
                .foregroundColor(AppTheme.primary)
            )
        }
        .preferredColorScheme(.dark) // Force dark mode for modal
    }
}

// Preview
struct FinanceRootView_Previews: PreviewProvider {
    static var previews: some View {
        FinanceRootView()
            .preferredColorScheme(.dark)
    }
}




