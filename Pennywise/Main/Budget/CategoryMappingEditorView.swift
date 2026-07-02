//
//  CategoryMappingEditorView.swift
//  Pennywise
//
//  Created by Arnav Varyani on 4/25/25.
//

import SwiftUI

struct CategoryMappingEditorView: View {
    let budgetCategory: String
    
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    @State private var selectedCategories: [String] = []
    
    private let mappingSystem = CategoryMappingSystem.shared
    
    var potentialCategories: [String] {
        mappingSystem.getAllPotentialPlaidCategories()
    }
    
    var filteredCategories: [String] {
        if searchText.isEmpty {
            return potentialCategories
        } else {
            return potentialCategories.filter { $0.lowercased().contains(searchText.lowercased()) }
        }
    }
    
    var body: some View {
        ZStack {
            AppTheme.enhancedBackgroundGradient
            
            VStack(spacing: 20) {
                // Header explanation
                VStack(spacing: 12) {
                    Image(systemName: "arrow.triangle.swap")
                        .font(.system(size: 40))
                        .foregroundColor(AppTheme.accentBlue)
                        .padding(.top, 20)
                    
                    Text("Map Plaid Categories")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(AppTheme.textColor)
                    
                    Text("Select Plaid transaction categories to map to your \"\(budgetCategory)\" budget category")
                        .font(.subheadline)
                        .multilineTextAlignment(.center)
                        .foregroundColor(AppTheme.textColor.opacity(0.7))
                        .padding(.horizontal, 20)
                }
                
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(AppTheme.textColor.opacity(0.7))
                        .padding(.leading, 12)
                    
                    TextField("Search categories", text: $searchText)
                        .foregroundColor(AppTheme.textColor)
                        .padding(.vertical, 10)
                    
                    if !searchText.isEmpty {
                        Button(action: {
                            searchText = ""
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(AppTheme.textColor.opacity(0.7))
                        }
                        .padding(.trailing, 12)
                    }
                }
                .pwGlassSurface(cornerRadius: 14)
                .padding(.horizontal, 20)
                
                // Currently selected categories
                if !selectedCategories.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Selected Categories")
                            .font(.headline)
                            .foregroundColor(AppTheme.textColor)
                            .padding(.leading, 20)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(selectedCategories, id: \.self) { category in
                                    HStack(spacing: 5) {
                                        Text(category)
                                            .font(.caption)
                                            .foregroundColor(AppTheme.textColor)
                                            .lineLimit(1)
                                        
                                        Button(action: {
                                            removeSelectedCategory(category)
                                        }) {
                                            Image(systemName: "xmark.circle.fill")
                                                .foregroundColor(AppTheme.textColor.opacity(0.6))
                                                .font(.system(size: 14))
                                        }
                                    }
                                    .padding(.vertical, 6)
                                    .padding(.horizontal, 10)
                                    .background(AppTheme.primaryGreen.opacity(0.2))
                                    .cornerRadius(15)
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                    }
                }
                
                // Categories list
                List {
                    ForEach(filteredCategories, id: \.self) { category in
                        HStack {
                            Text(category)
                                .foregroundColor(AppTheme.textColor)
                            
                            Spacer()
                            
                            if selectedCategories.contains(category) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(AppTheme.primaryGreen)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            toggleCategory(category)
                        }
                        .listRowBackground(AppTheme.cardBackground)
                    }
                }
                .listStyle(PlainListStyle())
                .scrollContentBackground(.hidden)
                .background(Color.clear)
                .environment(\.defaultMinListRowHeight, 44)
                
                // Info text
                Text("Mapping Plaid categories to your budget categories ensures that transactions are correctly categorized in your budget reports.")
                    .font(.caption)
                    .foregroundColor(AppTheme.textColor.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
            }
        }
        .navigationTitle("Map Categories")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Save") {
                    saveChanges()
                }
                .foregroundColor(AppTheme.primaryGreen)
                .fontWeight(.semibold)
            }
        }
        .onAppear {
            // Initialize selected categories from the mapping system
            selectedCategories = mappingSystem.getMappings(for: budgetCategory)
        }
    }
    
    // MARK: - Actions
    
    private func toggleCategory(_ category: String) {
        if selectedCategories.contains(category) {
            removeSelectedCategory(category)
        } else {
            selectedCategories.append(category)
        }
    }
    
    private func removeSelectedCategory(_ category: String) {
        selectedCategories.removeAll { $0 == category }
    }
    
    private func saveChanges() {
        // Update the mappings in the system
        mappingSystem.updateMappings(for: budgetCategory, plaidCategories: selectedCategories)
        
        // Ensure ingestion/calculations use the same mapping immediately (device-local overrides).
        CategoryMappingService.updateOverrides(forBudgetCategory: budgetCategory, plaidCategories: selectedCategories)
        
        // Dismiss
        dismiss()
    }
}
