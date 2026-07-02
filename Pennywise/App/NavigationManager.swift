import SwiftUI
import Combine

@MainActor
class NavigationManager: ObservableObject {
    @Published var homePath = NavigationPath()
    @Published var budgetPath = NavigationPath()
    @Published var insightsPath = NavigationPath()
    @Published var settingsPath = NavigationPath()
    
    @Published var selectedTab: Int = 0
    
    func navigate(to route: AppRoute) {
        switch selectedTab {
        case 0: homePath.append(route)
        case 1: budgetPath.append(route)
        case 2: insightsPath.append(route)
        case 3: settingsPath.append(route)
        default: break
        }
    }
    
    func popToRoot() {
        switch selectedTab {
        case 0: homePath = NavigationPath()
        case 1: budgetPath = NavigationPath()
        case 2: insightsPath = NavigationPath()
        case 3: settingsPath = NavigationPath()
        default: break
        }
    }
}
