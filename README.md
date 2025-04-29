# Pennywise - Finance Management App

Pennywise is a comprehensive personal finance management app built with SwiftUI, Firebase, and Plaid integration. It enables users to track expenses, manage budgets, gain financial insights, and securely connect to their bank accounts.

![Pennywise App](https://via.placeholder.com/800x400.png?text=Pennywise+Finance+App)

## Features

- **Secure Authentication**: Log in with email/password, Google Sign-In, and biometric authentication (Face ID/Touch ID)
- **Bank Account Integration**: Connect with bank accounts via Plaid API
- **Transaction Management**: View, categorize, and filter transactions automatically synced from connected accounts
- **Manual Transactions**: Add cash transactions manually when needed
- **Budget Planning**: Create and manage budget categories with customizable limits
- **Financial Insights**: Visualize spending patterns, track income vs. expenses, and discover saving opportunities
- **Data Visualization**: Interactive charts and graphs for better financial understanding
- **Offline Support**: Firestore persistence for offline access to financial data
- **Data Export**: Export financial data as CSV files
- **Profile Management**: Update profile information and security settings

## Architecture

Pennywise follows a modern SwiftUI architecture with MVVM (Model-View-ViewModel) design patterns:

- **Views**: Built with SwiftUI for responsive UI across iOS devices
- **ViewModels**: Handle business logic and data processing, using Combine for reactive updates
- **Models**: Core data structures representing financial entities
- **Services**: Firebase and Plaid integration services for data management

### Key Components

- **Authentication Service**: Manages user authentication state and methods
- **Plaid Manager**: Handles bank account integration and transaction syncing
- **Firestore Manager**: Manages cloud data storage and retrieval
- **Plaid-Firestore Sync**: Synchronizes Plaid data with Firestore for persistence

## Getting Started

### Prerequisites

- Xcode 14.0+
- iOS 16.0+
- Swift 5.7+
- Firebase account
- Plaid developer account

### Configuration

1. Clone the repository
   ```
   git clone https://github.com/yourusername/pennywise.git
   cd pennywise
   ```

2. Install CocoaPods dependencies
   ```
   pod install
   ```

3. Set up Firebase
   - Create a new Firebase project
   - Add an iOS app to your Firebase project
   - Download the `GoogleService-Info.plist` file and add it to your Xcode project
   - Enable Authentication, Firestore, and Storage services in Firebase console

4. Configure Plaid
   - Create a Plaid developer account
   - Set up your Plaid application
   - Update the `PlaidSandboxManager.swift` file with your Plaid credentials:
     ```swift
     private let clientID = "your_client_id"
     private let secret = "your_secret"
     ```

5. Build and run the project in Xcode

## Project Structure

```
Pennywise/
├── Authentication/
│   ├── AuthenticationService.swift
│   ├── AuthError.swift
│   ├── BiometricAuthenticationView.swift
│   └── FirebaseUIViewRepresentable.swift
├── Plaid Integration/
│   ├── PlaidManager.swift
│   ├── PlaidSandboxManager.swift
│   ├── PlaidTransaction.swift
│   └── PlaidFirestoreSync.swift
├── Firestore/
│   ├── FirestoreManager.swift
│   └── FirebaseAppDelegate.swift
├── Views/
│   ├── Onboarding/
│   │   └── FinanceOnboardingView.swift
│   ├── Home/
│   │   └── FinanceHomeView.swift
│   ├── Budget/
│   │   ├── BudgetPlannerView.swift
│   │   ├── AddBudgetCategoryView.swift
│   │   └── CategoryDetailView.swift
│   ├── Insights/
│   │   └── InsightsView.swift
│   ├── Settings/
│   │   ├── SettingsView.swift
│   │   ├── EditProfileView.swift
│   │   └── ChangePasswordView.swift
│   └── Common/
│       ├── TransactionView.swift
│       └── TransactionRow.swift
├── Models/
│   ├── Transaction.swift
│   ├── BudgetCategory.swift
│   └── MonthlyFinancialData.swift
├── Components/
│   ├── Charts/
│   │   ├── PieChartView.swift
│   │   └── SpendingHistoryChartView.swift
│   └── UI/
│       ├── TabBar.swift
│       └── AppTheme.swift
└── App/
    ├── AppCoordinator.swift
    ├── PennywiseApp.swift
    └── LaunchScreenView.swift
```

## Authentication Flow

Pennywise offers multiple authentication methods:

1. **Email/Password Authentication**: Traditional sign-up and login
2. **Google Sign-In**: OAuth authentication via Firebase
3. **Biometric Authentication**: Face ID/Touch ID for quick access

The authentication flow is managed by the `AuthenticationService` class, which maintains the authentication state and provides methods for signing in, signing out, and managing user profiles.

## Plaid Integration

The app integrates with Plaid to securely connect to users' bank accounts:

1. **Link Token Creation**: The app requests a link token from Plaid
2. **Account Linking**: Users authenticate with their bank through the Plaid Link interface
3. **Public Token Exchange**: The public token is exchanged for an access token
4. **Data Retrieval**: Account and transaction data is fetched from Plaid
5. **Synchronization**: Data is stored in Firestore for offline access

## Data Synchronization

Pennywise uses a sophisticated synchronization system:

1. **Plaid-Firestore Sync**: When Plaid data is fetched, it's automatically synced to Firestore
2. **Offline Support**: Firestore persistence allows the app to work offline
3. **Background Syncing**: Data is periodically synced in the background
4. **Manual Sync**: Users can manually trigger a sync when needed

## Styling and Theming

The app uses a consistent theme defined in `AppTheme.swift`:

- **Color Palette**: Primary colors, accent colors, and semantic colors (income, expense)
- **Typography**: Font styles and sizes for different UI elements
- **Layout**: Common spacing and padding values
- **Components**: Reusable UI components with consistent styling

## Export Functionality

Users can export their financial data in CSV format:

1. **Transactions**: Export all transaction history
2. **Budget Categories**: Export budget allocations and spending
3. **Accounts Summary**: Export account balances and details
4. **Complete Export**: Export all financial data as a package

## Security Considerations

The app implements several security features:

- **Keychain Storage**: Sensitive information like access tokens is stored in the iOS Keychain
- **Biometric Authentication**: Optional biometric verification for app access
- **Secure Network Communication**: All API communication uses HTTPS
- **Firebase Security Rules**: Proper Firestore security rules to protect user data

## Contributing

We welcome contributions to Pennywise! Please see our [CONTRIBUTING.md](CONTRIBUTING.md) for details on our code of conduct and the process for submitting pull requests.

## License

This project is licensed under the MIT License - see the [LICENSE.md](LICENSE.md) file for details.

## Acknowledgements

- [Firebase](https://firebase.google.com/) - Authentication and data storage
- [Plaid](https://plaid.com/) - Financial data integration
- [SwiftUI](https://developer.apple.com/xcode/swiftui/) - User interface framework
- [Combine](https://developer.apple.com/documentation/combine) - Reactive programming framework
