//
//  FinanceOnboardingViewModel.swift
//  Pennywise
//

import Observation

@Observable
class FinanceOnboardingViewModel {
    var currentPage = 0
    var totalPages = 0
    
    var isLastPage: Bool {
        currentPage == totalPages - 1
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

