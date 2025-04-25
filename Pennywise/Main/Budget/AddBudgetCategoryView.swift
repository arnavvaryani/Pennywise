
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
    @State private var showCustomCategory = false
    @State private var selectedPredefinedCategory: PredefinedCategory?
    
    // Get predefined categories from the system
    let predefinedCategories = BudgetCategorySystem.shared.predefinedCategories
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                AppTheme.backgroundGradient
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Predefined categories section
                        if !showCustomCategory {
                            predefinedCategoriesSection
                        }
                        
                        // Custom category details section
                        if showCustomCategory || selectedPredefinedCategory != nil {
                            categoryDetailsSection
                        }
                    }
                    .padding(16)
                }
            }
            .navigationTitle(showCustomCategory ? "Custom Category" : "Add Category")
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
                        saveCategory()
                    }
                    .foregroundColor(AppTheme.primaryGreen)
                    .fontWeight(.semibold)
                    .disabled(!isSaveEnabled)
                    .opacity(isSaveEnabled ? 1.0 : 0.5)
                }
            }
        }
    }
    
    // Check if Save button should be enabled
    private var isSaveEnabled: Bool {
        if showCustomCategory {
            return !categoryName.isEmpty && !amount.isEmpty
        } else {
            return selectedPredefinedCategory != nil && !amount.isEmpty
        }
    }
    
    // MARK: - UI Components
    
    // Predefined categories grid section
    private var predefinedCategoriesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Choose a Category")
                .font(.headline)
                .foregroundColor(AppTheme.textColor)
                .padding(.leading, 16)
            
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 100, maximum: 120))], spacing: 16) {
                // Predefined categories
                ForEach(predefinedCategories) { category in
                    predefinedCategoryButton(category)
                }
                
                // Custom category option
                Button(action: {
                    showCustomCategory = true
                }) {
                    VStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(Color.gray.opacity(0.2))
                                .frame(width: 60, height: 60)
                            
                            Image(systemName: "plus")
                                .font(.system(size: 24))
                                .foregroundColor(AppTheme.textColor.opacity(0.7))
                        }
                        
                        Text("Custom")
                            .font(.subheadline)
                            .foregroundColor(AppTheme.textColor)
                            .lineLimit(1)
                    }
                    .padding(.vertical, 12)
                    .frame(maxWidth: .infinity)
                    .background(AppTheme.cardBackground.opacity(0.5))
                    .cornerRadius(12)
                }
            }
            .padding()
            .background(AppTheme.cardBackground.opacity(0.5))
            .cornerRadius(16)
        }
    }
    
    // Single predefined category button
    private func predefinedCategoryButton(_ category: PredefinedCategory) -> some View {
        Button(action: {
            selectedPredefinedCategory = category
            
            // Pre-populate values from the predefined category
            categoryName = category.name
            selectedIcon = category.icon
            selectedColor = category.color
            
            // Automatically generate suggested budget amount
            // In a real app, this would be more sophisticated
            // For now, we'll just use a percentage of assumed income
            let assumedIncome = 5000.0
            let suggestedAmount: Double
            
            if category.name == "Housing" {
                suggestedAmount = assumedIncome * 0.3
            } else if category.name == "Groceries" {
                suggestedAmount = assumedIncome * 0.1
            } else if category.isEssential {
                suggestedAmount = assumedIncome * 0.05
            } else {
                suggestedAmount = assumedIncome * 0.03
            }
            
            amount = String(format: "%.0f", suggestedAmount)
        }) {
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(category.color.opacity(0.2))
                        .frame(width: 60, height: 60)
                        .overlay(
                            Circle()
                                .stroke(
                                    selectedPredefinedCategory?.name == category.name ?
                                    category.color : Color.clear,
                                    lineWidth: 2
                                )
                        )
                    
                    Image(systemName: category.icon)
                        .font(.system(size: 24))
                        .foregroundColor(category.color)
                }
                
                Text(category.name)
                    .font(.subheadline)
                    .foregroundColor(AppTheme.textColor)
                    .lineLimit(1)
            }
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity)
            .background(
                selectedPredefinedCategory?.name == category.name ?
                category.color.opacity(0.15) :
                AppTheme.cardBackground.opacity(0.5)
            )
            .cornerRadius(12)
        }
    }
    
    // Category details form section
    private var categoryDetailsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(showCustomCategory ? "Custom Category Details" : "Budget Details")
                .font(.headline)
                .foregroundColor(AppTheme.textColor)
                .padding(.leading, 16)
            
            VStack(spacing: 16) {
                // Only show name field for custom category
                if showCustomCategory {
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
                }
                
                // Budget amount field
                VStack(alignment: .leading, spacing: 8) {
                    Text("Monthly Budget Amount")
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
                
                // Only show icon and color pickers for custom category
                if showCustomCategory {
                    // Icon picker
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Icon")
                            .font(.subheadline)
                            .foregroundColor(AppTheme.textColor.opacity(0.7))
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(commonIcons, id: \.self) { icon in
                                    Button(action: {
                                        selectedIcon = icon
                                    }) {
                                        ZStack {
                                            Circle()
                                                .fill(selectedIcon == icon ? selectedColor.opacity(0.2) : AppTheme.cardBackground)
                                                .frame(width: 50, height: 50)
                                            
                                            Image(systemName: icon)
                                                .font(.system(size: 20))
                                                .foregroundColor(selectedIcon == icon ? selectedColor : AppTheme.textColor.opacity(0.7))
                                        }
                                    }
                                }
                            }
                            .padding(.vertical, 8)
                        }
                    }
                    
                    // Color picker
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Color")
                            .font(.subheadline)
                            .foregroundColor(AppTheme.textColor.opacity(0.7))
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(themeColors, id: \.self) { color in
                                    Button(action: {
                                        selectedColor = color
                                    }) {
                                        ZStack {
                                            Circle()
                                                .fill(color)
                                                .frame(width: 40, height: 40)
                                            
                                            if color == selectedColor {
                                                Circle()
                                                    .stroke(Color.white, lineWidth: 2)
                                                    .frame(width: 46, height: 46)
                                            }
                                        }
                                    }
                                }
                            }
                            .padding(.vertical, 8)
                        }
                    }
                }
            }
            .padding(16)
            .background(AppTheme.cardBackground.opacity(0.5))
            .cornerRadius(16)
        }
    }
    
    // MARK: - Helper Methods
    
    // Save the new category
    private func saveCategory() {
        if let amountValue = Double(amount) {
            let newCategory: BudgetCategory
            
            if showCustomCategory {
                // Custom category
                newCategory = BudgetCategory(
                    name: categoryName,
                    amount: amountValue,
                    icon: selectedIcon,
                    color: selectedColor
                )
            } else if let predefined = selectedPredefinedCategory {
                // Predefined category
                newCategory = BudgetCategory(
                    name: predefined.name,
                    amount: amountValue,
                    icon: predefined.icon,
                    color: predefined.color
                )
            } else {
                // Should never happen due to disabled Save button
                return
            }
            
            onAdd(newCategory)
            presentationMode.wrappedValue.dismiss()
        }
    }
    
    // Common icons for categories
    private var commonIcons: [String] {
        [
            "house.fill", "cart.fill", "car.fill", "fork.knife",
            "heart.fill", "bolt.fill", "tv.fill", "gamecontroller.fill",
            "airplane", "gift.fill", "dollarsign.circle.fill", "creditcard.fill",
            "book.fill", "graduationcap.fill", "bag.fill", "tag.fill"
        ]
    }
    
    // Theme colors for categories
    private var themeColors: [Color] {
        [
            AppTheme.primaryGreen, AppTheme.accentBlue, AppTheme.accentPurple,
            Color(hex: "#FF5757"), Color(hex: "#FFD700"), Color(hex: "#50C878"),
            Color(hex: "#FF8C00"), Color(hex: "#9370DB"), Color(hex: "#DA70D6"),
            Color(hex: "#20B2AA"), Color(hex: "#32CD32"), Color(hex: "#FA8072")
        ]
    }
}
