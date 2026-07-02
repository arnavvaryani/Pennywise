//
//  FinanceOnboardingView.swift
//  Pennywise
//

import SwiftUI

struct FinanceOnboardingView: View {
    @State private var viewModel = FinanceOnboardingViewModel()
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
            AppTheme.enhancedBackgroundGradient
            
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
                
                PWGlassCard(cornerRadius: 22) {
                    HStack(spacing: 12) {
                        if viewModel.currentPage < pages.count - 1 {
                            Button("Skip") {
                                viewModel.completeOnboarding()
                                hasCompletedOnboarding = true
                            }
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(AppTheme.textColor.opacity(0.75))
                        } else {
                            Text(" ")
                                .font(.subheadline)
                                .frame(width: 40)
                                .hidden()
                        }
                        
                        Spacer()
                        
                        PageIndicator(numberOfPages: pages.count, currentPage: viewModel.currentPage)
                        
                        Spacer()
                        
                        Button {
                            if viewModel.isLastPage {
                                viewModel.completeOnboarding()
                                hasCompletedOnboarding = true
                            } else {
                                viewModel.goToNextPage()
                            }
                        } label: {
                            PWPill(
                                title: viewModel.isLastPage ? "Get Started" : "Next",
                                systemImage: viewModel.isLastPage ? "checkmark" : "chevron.right",
                                tint: AppTheme.primaryGreen,
                                isSelected: true
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 18)
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
            
            PWGlassCard {
                Text(page.description)
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundColor(AppTheme.textColor.opacity(0.75))
            }
            .padding(.horizontal, 16)
            
            Spacer()
            Spacer()
        }
        .padding()
        .animation(.easeOut, value: viewModel.currentPage)
    }
}

