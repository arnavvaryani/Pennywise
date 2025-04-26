//
//  FinanceOnboardingPage.swift
//  Pennywise
//
//  Created by Arnav Varyani on 4/8/25.
//

import SwiftUI

struct FinanceOnboardingPage {
    let title: String
    let description: String
    let imageName: String
}

struct FinanceOnboardingView: View {
    @StateObject private var viewModel = FinanceOnboardingViewModel()
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    
    private let pages = [
        FinanceOnboardingPage(
            title: "Welcome to Pennywise",
            description: "Take control of your finances with our smart tracking and analytics tools that help you understand your spending habits and financial health.",
            imageName: "dollarsign.circle"
        ),
        FinanceOnboardingPage(
            title: "Track Your Spending",
            description: "Easily log your daily expenses and income to keep a real-time overview of your financial situation.",
            imageName: "list.bullet.clipboard"
        ),
        FinanceOnboardingPage(
            title: "Financial Goals",
            description: "Set and track financial goals like saving for a vacation, paying off debt, or building an emergency fund.",
            imageName: "target"
        ),
        FinanceOnboardingPage(
            title: "Secure & Private",
            description: "Your financial data is encrypted and never shared. We take security seriously so you can focus on your finances.",
            imageName: "lock.shield"
        )
    ]
    
    var body: some View {
        ZStack {
            // Background gradient from AppTheme
            AppTheme.backgroundGradient
                .edgesIgnoringSafeArea(.all)
            
            TabView(selection: $viewModel.currentPage) {
                ForEach(0..<pages.count, id: \.self) { index in
                    pageView(for: pages[index])
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.easeInOut, value: viewModel.currentPage)
            
            VStack {
                Spacer()
                
                HStack {
                    // Skip button (hidden on last page)
                    if viewModel.currentPage < pages.count - 1 {
                        Button("Skip") {
                            viewModel.completeOnboarding()
                            hasCompletedOnboarding = true
                        }
                        .padding()
                        .foregroundColor(AppTheme.textColor.opacity(0.7))
                    }
                    
                    Spacer()
                    
                    // Page indicator
                    PageIndicator(
                        numberOfPages: pages.count,
                        currentPage: viewModel.currentPage
                    )
                    
                    Spacer()
                    
                    // Next/Get Started button
                    Button(viewModel.isLastPage ? "Get Started" : "Next") {
                        if viewModel.isLastPage {
                            viewModel.completeOnboarding()
                            hasCompletedOnboarding = true
                        } else {
                            viewModel.goToNextPage()
                        }
                    }
                    .padding()
                    .foregroundColor(AppTheme.primaryGreen)
                    .fontWeight(.semibold)
                }
                .padding(.bottom, 30)
            }
        }
        .edgesIgnoringSafeArea(.all)
        .onAppear {
            viewModel.totalPages = pages.count
        }
    }
    
    private func pageView(for page: FinanceOnboardingPage) -> some View {
        VStack(spacing: 30) {
            Spacer()
            
            Text(page.title)
                .font(.largeTitle)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
                .foregroundColor(AppTheme.textColor)
            
            // Icon with themed colors and glow effect
            ZStack {
                Circle()
                    .fill(AppTheme.primaryGreen.opacity(0.15))
                    .frame(width: 160, height: 160)
                    .blur(radius: 20)
                
                Image(systemName: page.imageName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 80)
                    .foregroundColor(AppTheme.primaryGreen)
                    .shadow(color: AppTheme.primaryGreen.opacity(0.5), radius: 10, x: 0, y: 0)
            }
            .padding(.vertical, 20)
            
            Text(page.description)
                .font(.body)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
                .foregroundColor(AppTheme.textColor.opacity(0.7))
            
            Spacer()
            Spacer()
        }
        .padding()
        .animation(.easeOut, value: viewModel.currentPage)
    }
}

class FinanceOnboardingViewModel: ObservableObject {
    @Published var currentPage = 0
    @Published var totalPages = 0
    
    var isLastPage: Bool {
        return currentPage == totalPages - 1
    }
    
    func goToNextPage() {
        if currentPage < totalPages - 1 {
            currentPage += 1
        }
    }
    
    func completeOnboarding() {
        // Additional completion logic if needed
    }
}

struct PageIndicator: View {
    let numberOfPages: Int
    let currentPage: Int
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<numberOfPages, id: \.self) { page in
                Circle()
                    .fill(currentPage == page ? AppTheme.primaryGreen : AppTheme.textColor.opacity(0.3))
                    .frame(width: 8, height: 8)
                    .scaleEffect(currentPage == page ? 1.2 : 1.0)
                    .animation(.spring(), value: currentPage)
            }
        }
    }
}

struct FinanceOnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        FinanceOnboardingView()
            .preferredColorScheme(.dark)
    }
}
