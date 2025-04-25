
//  AddBudgetCategoryView.swift
//  Pennywise
//
//  Created by Arnav Varyani on 4/8/25.


import SwiftUI

struct AddBudgetCategoryView: View {
    let onAdd: (BudgetCategory) -> Void
    
    @Environment(\.presentationMode) var presentationMode
    @State private var categoryName = ""
    @State private var amount = ""
    @State private var selectedIcon = "tag.fill"
    @State private var selectedColor = Color.primary
    
    let icons = [
        "house.fill", "cart.fill", "car.fill", "bolt.fill", "tv.fill", 
        "heart.fill", "dollarsign.circle.fill", "tag.fill", "creditcard.fill",
        "gift.fill", "bag.fill", "airplane", "graduationcap.fill", "cross.fill",
        "book.fill", "fork.knife", "cup.and.saucer.fill"
    ]
    
    let colors: [Color] = [
        AppTheme.primary,
        AppTheme.secondary,
        AppTheme.incomeGreen,
        AppTheme.expenseRed,
        AppTheme.savingsYellow,
        AppTheme.investmentPurple,
        AppTheme.alertOrange
    ]
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Category Details")) {
                    TextField("Category Name", text: $categoryName)
                    
                    HStack {
                        Text("$")
                        TextField("Amount", text: $amount)
                            .keyboardType(.decimalPad)
                    }
                }
                
                Section(header: Text("Icon")) {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 50))], spacing: 15) {
                        ForEach(icons, id: \.self) { icon in
                            ZStack {
                                Circle()
                                    .fill(selectedIcon == icon ? selectedColor.opacity(0.2) : Color.clear)
                                    .frame(width: 50, height: 50)
                                
                                Image(systemName: icon)
                                    .font(.system(size: 24))
                                    .foregroundColor(selectedIcon == icon ? selectedColor : Color.primary)
                            }
                            .onTapGesture {
                                selectedIcon = icon
                            }
                        }
                    }
                }
                
                Section(header: Text("Color")) {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 50))], spacing: 15) {
                        ForEach(colors, id: \.self) { color in
                            Circle()
                                .fill(color)
                                .frame(width: 30, height: 30)
                                .overlay(
                                    Circle()
                                        .stroke(selectedColor == color ? Color.white : Color.clear, lineWidth: 2)
                                )
                                .onTapGesture {
                                    selectedColor = color
                                }
                        }
                    }
                }
            }
            .navigationTitle("Add Category")
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("Save") {
                    if let amountValue = Double(amount), !categoryName.isEmpty {
                        let newCategory = BudgetCategory(
                            name: categoryName,
                            amount: amountValue,
                            icon: selectedIcon,
                            color: selectedColor
                        )
                        onAdd(newCategory)
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                .disabled(categoryName.isEmpty || amount.isEmpty)
            )
        }
    }
}
