
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
    @State private var selectedColor = AppTheme.primaryGreen
    
    let icons = [
        "house.fill", "cart.fill", "car.fill", "bolt.fill", "tv.fill",
        "heart.fill", "dollarsign.circle.fill", "tag.fill", "creditcard.fill",
        "gift.fill", "bag.fill", "airplane", "graduationcap.fill",
        "book.fill", "fork.knife", "cup.and.saucer.fill"
    ]
    
    let colors: [Color] = [
        AppTheme.primaryGreen,
        AppTheme.accentBlue,
        AppTheme.accentPurple,
        Color(hex: "#FF5757"),  // expense red
        Color(hex: "#FFD700"),  // savings yellow
        Color(hex: "#9370DB"),  // investment purple
        Color(hex: "#FF8C00")   // alert orange
    ]
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                AppTheme.backgroundGradient
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Category details section
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Category Details")
                                .font(.headline)
                                .foregroundColor(AppTheme.textColor)
                                .padding(.leading, 16)
                            
                            VStack(spacing: 16) {
                                // Category name field
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Category Name")
                                        .font(.subheadline)
                                        .foregroundColor(AppTheme.textColor.opacity(0.7))
                                    
                                    TextField("", text: $categoryName)
                                        .padding()
                                        .background(AppTheme.cardBackground)
                                        .cornerRadius(12)
                                        .foregroundColor(AppTheme.textColor)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(AppTheme.cardStroke, lineWidth: 1)
                                        )
                                }
                                
                                // Amount field
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Budget Amount")
                                        .font(.subheadline)
                                        .foregroundColor(AppTheme.textColor.opacity(0.7))
                                    
                                    HStack {
                                        Text("$")
                                            .foregroundColor(AppTheme.textColor)
                                            .padding(.leading, 16)
                                        
                                        TextField("", text: $amount)
                                            .keyboardType(.decimalPad)
                                            .foregroundColor(AppTheme.textColor)
                                            .padding(.vertical, 16)
                                    }
                                    .background(AppTheme.cardBackground)
                                    .cornerRadius(12)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(AppTheme.cardStroke, lineWidth: 1)
                                    )
                                }
                            }
                            .padding(16)
                            .background(AppTheme.cardBackground.opacity(0.5))
                            .cornerRadius(16)
                        }
                        
                        // Icon section
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Icon")
                                .font(.headline)
                                .foregroundColor(AppTheme.textColor)
                                .padding(.leading, 16)
                            
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 65))], spacing: 15) {
                                ForEach(icons, id: \.self) { icon in
                                    Button(action: {
                                        selectedIcon = icon
                                    }) {
                                        ZStack {
                                            Circle()
                                                .fill(selectedIcon == icon ? selectedColor.opacity(0.2) : AppTheme.cardBackground)
                                                .frame(width: 60, height: 60)
                                                .overlay(
                                                    Circle()
                                                        .stroke(selectedIcon == icon ? selectedColor : AppTheme.cardStroke, lineWidth: 1)
                                                )
                                            
                                            Image(systemName: icon)
                                                .font(.system(size: 24))
                                                .foregroundColor(selectedIcon == icon ? selectedColor : AppTheme.textColor.opacity(0.7))
                                        }
                                    }
                                    .buttonStyle(ScaleButtonStyle())
                                }
                            }
                            .padding(16)
                            .background(AppTheme.cardBackground.opacity(0.5))
                            .cornerRadius(16)
                        }
                        
                        // Color section
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Color")
                                .font(.headline)
                                .foregroundColor(AppTheme.textColor)
                                .padding(.leading, 16)
                            
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 60))], spacing: 15) {
                                ForEach(colors, id: \.self) { color in
                                    Button(action: {
                                        selectedColor = color
                                    }) {
                                        ZStack {
                                            Circle()
                                                .fill(color)
                                                .frame(width: 50, height: 50)
                                                .shadow(color: color.opacity(0.5), radius: 3, x: 0, y: 0)
                                            
                                            if selectedColor == color {
                                                Circle()
                                                    .stroke(Color.white, lineWidth: 2)
                                                    .frame(width: 60, height: 60)
                                            }
                                        }
                                    }
                                    .buttonStyle(ScaleButtonStyle())
                                }
                            }
                            .padding(16)
                            .background(AppTheme.cardBackground.opacity(0.5))
                            .cornerRadius(16)
                        }
                    }
                    .padding(16)
                }
            }
            .navigationTitle("Add Category")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(AppTheme.primaryGreen)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
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
                    .foregroundColor(AppTheme.primaryGreen)
                    .fontWeight(.semibold)
                    .opacity(categoryName.isEmpty || amount.isEmpty ? 0.5 : 1.0)
                    .disabled(categoryName.isEmpty || amount.isEmpty)
                }
            }
        }
    }
}

