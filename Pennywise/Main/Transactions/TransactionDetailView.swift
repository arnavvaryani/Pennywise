//
////
////  TransactionDetailView.swift
////  Pennywise
////
////  Created by Arnav Varyani on 4/15/25.
////
//
//import SwiftUI
//
//
//
//extension String {
//    func prefixString(_ len: Int) -> String {
//        String(self.prefix(min(len, count)))
//    }
//    func suffixString(_ len: Int) -> String {
//        String(self.suffix(min(len, count)))
//    }
//}
//
//// MARK: - Category Editor View
//
//struct CategoryEditorView: View {
//    @Environment(\.presentationMode) var presentationMode
//    let initialCategory: String
//    let onSave: (String) -> Void
//    @State private var selectedCategory: String
//
//    let categories = [
//        "Food", "Shopping", "Transportation", "Entertainment",
//        "Health", "Utilities", "Housing", "Education",
//        "Travel", "Income", "Subscriptions", "Personal Care",
//        "Gifts", "Business", "Other"
//    ]
//
//    init(initialCategory: String, onSave: @escaping (String) -> Void) {
//        self.initialCategory = initialCategory
//        self.onSave = onSave
//        self._selectedCategory = State(initialValue: initialCategory)
//    }
//
//    var body: some View {
//        NavigationView {
//            ZStack {
//                AppTheme.backgroundGradient.ignoresSafeArea()
//                ScrollView {
//                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 140))], spacing: 16) {
//                        ForEach(categories, id: \.self) { cat in
//                            Button {
//                                selectedCategory = cat
//                            } label: {
//                                VStack(spacing: 10) {
//                                    ZStack {
//                                        Circle()
//                                            .fill(categoryColor(for: cat)
//                                                    .opacity(selectedCategory == cat ? 0.5 : 0.2))
//                                            .frame(width: 50, height: 50)
//                                        Image(systemName: getCategoryIcon(for: cat))
//                                            .font(.system(size: 20))
//                                            .foregroundColor(selectedCategory == cat
//                                                             ? AppTheme.backgroundColor
//                                                             : categoryColor(for: cat))
//                                    }
//                                    Text(cat)
//                                        .font(.subheadline)
//                                        .fontWeight(selectedCategory == cat ? .semibold : .regular)
//                                        .foregroundColor(AppTheme.textColor)
//                                }
//                                .padding()
//                                .background(RoundedRectangle(cornerRadius: 16)
//                                                .fill(selectedCategory == cat
//                                                      ? categoryColor(for: cat).opacity(0.2)
//                                                      : AppTheme.cardBackground))
//                                .overlay(RoundedRectangle(cornerRadius: 16)
//                                            .stroke(selectedCategory == cat
//                                                    ? categoryColor(for: cat)
//                                                    : AppTheme.cardStroke,
//                                                    lineWidth: 1))
//                            }
//                            .buttonStyle(ScaleButtonStyle())
//                        }
//                    }
//                    .padding()
//                }
//            }
//            .navigationTitle("Change Category")
//            .navigationBarTitleDisplayMode(.inline)
//            .toolbar {
//                ToolbarItem(placement: .navigationBarLeading) {
//                    Button("Cancel") { presentationMode.wrappedValue.dismiss() }
//                        .foregroundColor(AppTheme.primaryGreen)
//                }
//                ToolbarItem(placement: .navigationBarTrailing) {
//                    Button("Save") {
//                        onSave(selectedCategory)
//                        presentationMode.wrappedValue.dismiss()
//                    }
//                    .fontWeight(.semibold)
//                    .foregroundColor(AppTheme.primaryGreen)
//                }
//            }
//        }
//    }
//
//    private func getCategoryIcon(for cat: String) -> String {
//        let lc = cat.lowercased()
//        switch true {
//        case lc.contains("food"), lc.contains("restaurant"): return "fork.knife"
//        case lc.contains("shop"), lc.contains("store"):     return "cart"
//        case lc.contains("transport"), lc.contains("travel"):return "car.fill"
//        case lc.contains("entertain"), lc.contains("recreation"):return "play.tv"
//        case lc.contains("health"), lc.contains("medical"): return "heart.fill"
//        case lc.contains("utility"), lc.contains("bill"):   return "bolt.fill"
//        case lc.contains("home"), lc.contains("house"), lc.contains("rent"): return "house.fill"
//        case lc.contains("education"), lc.contains("school"): return "book.fill"
//        case lc.contains("income"), lc.contains("deposit"): return "arrow.down.circle.fill"
//        case lc.contains("subscription"):                   return "repeat"
//        case lc.contains("gift"):                           return "gift.fill"
//        case lc.contains("personal"):                       return "person.fill"
//        case lc.contains("business"):                       return "briefcase.fill"
//        default:                                            return "dollarsign.circle"
//        }
//    }
//
//    private func categoryColor(for cat: String) -> Color {
//        let lc = cat.lowercased()
//        switch true {
//        case lc.contains("food"), lc.contains("restaurant"): return AppTheme.primaryGreen
//        case lc.contains("shop"), lc.contains("store"):     return AppTheme.accentBlue
//        case lc.contains("transport"), lc.contains("travel"):return AppTheme.accentPurple
//        case lc.contains("entertain"), lc.contains("leisure"):return Color(hex: "#FFD700").opacity(0.8)
//        case lc.contains("health"), lc.contains("medical"): return Color(hex: "#FF5757")
//        case lc.contains("utility"), lc.contains("bill"):   return Color(hex: "#9370DB")
//        case lc.contains("house"), lc.contains("home"), lc.contains("rent"): return Color(hex: "#CD853F")
//        case lc.contains("education"), lc.contains("school"): return Color(hex: "#4682B4")
//        case lc.contains("income"), lc.contains("deposit"): return AppTheme.primaryGreen
//        case lc.contains("subscription"):                   return Color(hex: "#BA55D3")
//        case lc.contains("personal"):                       return Color(hex: "#FF7F50")
//        case lc.contains("gift"):                           return Color(hex: "#FF69B4")
//        case lc.contains("business"):                       return Color(hex: "#2E8B57")
//        default:                                            return AppTheme.accentBlue
//        }
//    }
//}
//
