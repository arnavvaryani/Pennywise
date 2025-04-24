//
//  AddTransactionModal.swift
//  Pennywise
//
//  Created by Arnav Varyani on 4/10/25.
//


import SwiftUI

struct AddTransactionModal: View {
    @Binding var isPresented: Bool
    @Binding var selectedTab: Int
    var onSave: ((Transaction) -> Void)?
    
    @State private var title: String = ""
    @State private var amount: String = ""
    @State private var isExpense: Bool = true
    @State private var selectedCategory: String = "Food"
    @State private var date: Date = Date()
    @State private var merchant: String = ""
    @State private var notes: String = ""
    
    // Animation states
    @State private var animateContent: Bool = false
    
    // Categories with appropriate icons
    let categories: [(String, String, Color)] = [
        ("Food", "fork.knife", AppTheme.primaryGreen),
        ("Shopping", "cart.fill", AppTheme.accentBlue),
        ("Transportation", "car.fill", AppTheme.incomeGreen),
        ("Entertainment", "play.fill", AppTheme.expenseColor),
        ("Housing", "house.fill", AppTheme.savingsYellow),
        ("Health", "heart.fill", AppTheme.investmentPurple),
        ("Education", "book.fill", AppTheme.alertOrange),
        ("Other", "ellipsis.circle.fill", Color.gray)
    ]
    
    var body: some View {
        ZStack {
            // Dim background
            Color.black.opacity(0.4)
                .edgesIgnoringSafeArea(.all)
                .onTapGesture {
                    dismissModal()
                }
            
            // Modal content
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: dismissModal) {
                        Text("Cancel")
                            .foregroundColor(AppTheme.primaryGreen)
                    }
                    
                    Spacer()
                    
                    Text("New Transaction")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Button(action: saveTransaction) {
                        Text("Save")
                            .fontWeight(.bold)
                            .foregroundColor(AppTheme.primaryGreen)
                    }
                    .disabled(title.isEmpty || amount.isEmpty || merchant.isEmpty)
                    .opacity(title.isEmpty || amount.isEmpty || merchant.isEmpty ? 0.5 : 1)
                }
                .padding()
                .background(AppTheme.backgroundSecondary)
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Transaction type selector
                        HStack(spacing: 15) {
                            transactionTypeButton(
                                title: "Expense",
                                iconName: "arrow.up.right",
                                isSelected: isExpense,
                                color: AppTheme.expenseColor
                            ) {
                                withAnimation(.spring()) {
                                    isExpense = true
                                }
                            }
                            
                            transactionTypeButton(
                                title: "Income",
                                iconName: "arrow.down.left",
                                isSelected: !isExpense,
                                color: AppTheme.incomeGreen
                            ) {
                                withAnimation(.spring()) {
                                    isExpense = false
                                }
                            }
                        }
                        .padding(.top)
                        
                        // Amount field with currency
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Amount")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.7))
                            
                            HStack(alignment: .center) {
                                Text("$")
                                    .font(.title2)
                                    .foregroundColor(.white)
                                
                                TextField("0.00", text: $amount)
                                    .font(.title)
                                    .keyboardType(.decimalPad)
                                    .foregroundColor(.white)
                            }
                            .padding()
                            .background(AppTheme.backgroundPrimary.opacity(0.5))
                            .cornerRadius(12)
                        }
                        
                        // Title and merchant fields
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Details")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.7))
                            
                            TextField("Title", text: $title)
                                .padding()
                                .background(AppTheme.backgroundPrimary.opacity(0.5))
                                .cornerRadius(12)
                                .foregroundColor(.white)
                            
                            TextField("Merchant", text: $merchant)
                                .padding()
                                .background(AppTheme.backgroundPrimary.opacity(0.5))
                                .cornerRadius(12)
                                .foregroundColor(.white)
                            
                            TextField("Notes (optional)", text: $notes)
                                .padding()
                                .background(AppTheme.backgroundPrimary.opacity(0.5))
                                .cornerRadius(12)
                                .foregroundColor(.white)
                        }
                        
                        // Category selector
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Category")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.7))
                            
                            LazyVGrid(columns: [
                                GridItem(.adaptive(minimum: 80, maximum: 100), spacing: 15)
                            ], spacing: 15) {
                                ForEach(categories, id: \.0) { category in
                                    categoryButton(
                                        title: category.0,
                                        icon: category.1,
                                        color: category.2,
                                        isSelected: selectedCategory == category.0
                                    ) {
                                        withAnimation {
                                            selectedCategory = category.0
                                        }
                                    }
                                }
                            }
                        }
                        
                        // Date picker
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Date")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.7))
                            
                            DatePicker(
                                "",
                                selection: $date,
                                displayedComponents: [.date]
                            )
                            .datePickerStyle(GraphicalDatePickerStyle())
                            .accentColor(AppTheme.primaryGreen)
                            .colorScheme(.dark)
                            .padding()
                            .background(AppTheme.backgroundPrimary.opacity(0.5))
                            .cornerRadius(12)
                        }
                        
                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal)
                }
            }
            .background(AppTheme.backgroundPrimary)
            .cornerRadius(20)
            .offset(y: animateContent ? 0 : UIScreen.main.bounds.height)
            .ignoresSafeArea(.keyboard)
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                animateContent = true
            }
        }
    }
    
    // MARK: - Helper Views
    
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
                    .font(.system(size: 16))
                    .foregroundColor(isSelected ? .white : color)
                
                Text(title)
                    .font(.subheadline)
                    .fontWeight(isSelected ? .semibold : .regular)
                    .foregroundColor(isSelected ? .white : color)
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 20)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? color : color.opacity(0.2))
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }
    
    private func categoryButton(
        title: String,
        icon: String,
        color: Color,
        isSelected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(isSelected ? color : color.opacity(0.2))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: icon)
                        .font(.system(size: 22))
                        .foregroundColor(isSelected ? .white : color)
                }
                
                Text(title)
                    .font(.caption)
                    .fontWeight(isSelected ? .semibold : .regular)
                    .foregroundColor(isSelected ? .white : .white.opacity(0.7))
                    .lineLimit(1)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(ScaleButtonStyle())
    }
    
    // MARK: - Functions
    
    private func dismissModal() {
        // Fixed: Ensure animation completes before updating binding
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
            animateContent = false
        }
        
        // Use a delay to ensure the animation completes before dismissing
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            isPresented = false
            selectedTab = 0 // Return to home tab
        }
    }
    
    private func saveTransaction() {
        guard let amountValue = Double(amount) else { return }
        
        // Create transaction
        let transaction = Transaction(
            id: Int.random(in: 100...10000),
            title: title,
            amount: isExpense ? -amountValue : amountValue,
            category: selectedCategory,
            date: date,
            merchant: merchant,
            icon: categories.first(where: { $0.0 == selectedCategory })?.1 ?? "circle.fill"
        )
        
        // Call save function
        onSave?(transaction)
        
        // Dismiss modal with proper animation sequence
        dismissModal()
    }
}
