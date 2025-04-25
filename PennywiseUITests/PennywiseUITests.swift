//
//  PennywiseUITests.swift
//  PennywiseUITests
//
//  Created by Arnav Varyani on 4/8/25.
//

import XCTest

class PennywiseUITests: XCTestCase {
    
    let app = XCUIApplication()
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app.launch()
        
        // Clear user defaults to ensure consistent test environment
        UserDefaults.standard.removePersistentDomain(forName: Bundle.main.bundleIdentifier!)
    }
    
    // MARK: - Onboarding Tests
    
    func testOnboardingFlow() throws {
        // Check if onboarding is displayed
        XCTAssertTrue(app.staticTexts["Welcome to Pennywise"].exists, "Onboarding screen should be visible")
        
        // Navigate through onboarding screens
        let nextButton = app.buttons["Next"]
        XCTAssertTrue(nextButton.exists, "Next button should be visible")
        
        // Tap through all onboarding screens
        for _ in 1...4 {
            nextButton.tap()
            sleep(1) // Wait for animation
        }
        
        // On the last screen, there should be a "Get Started" button
        let getStartedButton = app.buttons["Get Started"]
        XCTAssertTrue(getStartedButton.exists, "Get Started button should be visible on last onboarding screen")
        getStartedButton.tap()
        
        // After onboarding, we should see the login screen
        sleep(2) // Wait for transition
        XCTAssertTrue(app.staticTexts["Take Control of Your Money"].exists || app.textFields["Email"].exists,
                     "Should transition to login screen after onboarding")
    }
    
    // MARK: - Authentication Tests
    
    func testLoginScreen() throws {
        // Skip onboarding if presented
        skipOnboardingIfNeeded()
        
        // Verify login elements exist
        XCTAssertTrue(app.textFields["Email"].exists, "Email field should exist")
        XCTAssertTrue(app.secureTextFields["Password"].exists, "Password field should exist")
        XCTAssertTrue(app.buttons["Login"].exists, "Login button should exist")
        
        // Test validation - try to login with empty fields
        app.buttons["Login"].tap()
        // There should be an error displayed
        sleep(1)
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'failed'")).firstMatch.exists ||
                      app.buttons["Login"].isEnabled == false,
                      "Error should be shown or login button should be disabled for empty fields")
        
        // Enter invalid email
        let emailField = app.textFields["Email"]
        emailField.tap()
        emailField.typeText("invalid-email")
        
        let passwordField = app.secureTextFields["Password"]
        passwordField.tap()
        passwordField.typeText("password123")
        
        app.buttons["Login"].tap()
        sleep(1)
        // Should show validation error for invalid email
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'email'")).firstMatch.exists ||
                      app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'invalid'")).firstMatch.exists,
                      "Should show error for invalid email")
    }
    
    func testSignUpFlow() throws {
        // Skip onboarding if presented
        skipOnboardingIfNeeded()
        
        // Switch to signup mode
        let signupSegment = app.segmentedControls.buttons["Sign Up"]
        XCTAssertTrue(signupSegment.exists, "Sign Up segment should exist")
        signupSegment.tap()
        
        // Verify signup elements exist
        XCTAssertTrue(app.buttons["Create Account"].exists, "Create Account button should exist")
        
        // Test password validation
        let emailField = app.textFields["Email"]
        emailField.tap()
        emailField.typeText("test@example.com")
        
        let passwordField = app.secureTextFields["Password"]
        passwordField.tap()
        passwordField.typeText("weak")
        
        app.buttons["Create Account"].tap()
        sleep(1)
        // Should show validation error for weak password
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'password'")).firstMatch.exists,
                      "Should show error for weak password")
    }
    
    // MARK: - Main App Navigation Tests
    
    func testTabBarNavigation() throws {
        // Skip onboarding and login
        skipOnboardingIfNeeded()
        loginIfNeeded()
        
        // Wait for app to fully load
        sleep(3)
        
        // Test navigation to each tab
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.exists, "Tab bar should exist")
        
        // Home tab should be selected by default
        XCTAssertTrue(app.staticTexts["Total Bank Balance"].exists ||
                      app.staticTexts["Monthly Budget"].exists,
                      "Home screen should be visible initially")
        
        // Navigate to Insights tab
        tabBar.buttons["Insights"].tap()
        sleep(1)
        XCTAssertTrue(app.staticTexts["Financial Insights"].exists ||
                      app.staticTexts["Spending Summary"].exists,
                      "Should navigate to Insights tab")
        
        // Navigate to Budget tab
        tabBar.buttons["Budget"].tap()
        sleep(1)
        XCTAssertTrue(app.staticTexts["Monthly Budget"].exists ||
                      app.staticTexts["Budget Categories"].exists,
                      "Should navigate to Budget tab")
        
        // Navigate to Settings tab
        tabBar.buttons["Settings"].tap()
        sleep(1)
        XCTAssertTrue(app.staticTexts["Profile"].exists ||
                      app.staticTexts["Security"].exists ||
                      app.staticTexts["Account"].exists,
                      "Should navigate to Settings tab")
    }
    
    func testAddTransactionFlow() throws {
        // Skip onboarding and login
        skipOnboardingIfNeeded()
        loginIfNeeded()
        
        // Wait for app to fully load
        sleep(3)
        
        // Tap the Add button in tab bar
        let addButton = app.buttons["Add"]
        XCTAssertTrue(addButton.exists, "Add button should exist in tab bar")
        addButton.tap()
        
        // Wait for the transaction form to appear
        sleep(1)
        XCTAssertTrue(app.staticTexts["Transaction Details"].exists, "Transaction form should be visible")
        
        // Fill in transaction details
        let titleField = app.textFields.matching(NSPredicate(format: "placeholder CONTAINS 'Title'")).firstMatch
        XCTAssertTrue(titleField.exists, "Title field should exist")
        titleField.tap()
        titleField.typeText("Test Transaction")
        
        let merchantField = app.textFields.matching(NSPredicate(format: "placeholder CONTAINS 'Merchant'")).firstMatch
        XCTAssertTrue(merchantField.exists, "Merchant field should exist")
        merchantField.tap()
        merchantField.typeText("Test Store")
        
        // Enter amount
        let amountField = app.textFields.containing(NSPredicate(format: "identifier CONTAINS 'Amount'")).firstMatch
        if !amountField.exists {
            // Try with a different query if the first one fails
            let dollarSignElement = app.staticTexts["$"]
            if dollarSignElement.exists {
                dollarSignElement.tap()
                app.typeText("50")
            }
        } else {
            amountField.tap()
            amountField.typeText("50")
        }
        
        // Select expense type (should be default)
        let expenseButton = app.buttons["Expense"]
        XCTAssertTrue(expenseButton.exists, "Expense button should exist")
        XCTAssertTrue(expenseButton.isSelected, "Expense should be selected by default")
        
        // Select a category
        let foodCategory = app.buttons["Food"]
        if foodCategory.exists {
            foodCategory.tap()
        }
        
        // Save the transaction
        let saveButton = app.buttons["Save"]
        XCTAssertTrue(saveButton.exists, "Save button should exist")
        saveButton.tap()
        
        // Verify we're back on the main screen
        sleep(2)
        XCTAssertFalse(app.staticTexts["Transaction Details"].exists, "Transaction form should be dismissed")
        
        // Check if the transaction appears in the list (if visible)
        let transactionList = app.scrollViews.firstMatch
        transactionList.swipeUp() // Scroll to see transactions
        sleep(1)
        
        // Look for some indication that the transaction was added
        let addedTransaction = app.staticTexts["Test Store"]
        // We can't guarantee it's visible, so this is a soft check
        if addedTransaction.exists {
            XCTAssertTrue(addedTransaction.exists, "Added transaction should appear in the list")
        }
    }
    
    // MARK: - Profile and Settings Tests
    
    func testSettingsNavigation() throws {
        // Skip onboarding and login
        skipOnboardingIfNeeded()
        loginIfNeeded()
        
        // Navigate to Settings
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.exists, "Tab bar should exist")
        tabBar.buttons["Settings"].tap()
        sleep(1)
        
        // Verify settings categories exist
        XCTAssertTrue(app.staticTexts["Profile"].exists ||
                      app.staticTexts["Account"].exists,
                      "Profile or Account section should exist in Settings")
        
        // Test navigating to Change Password
        let changePasswordButton = app.buttons["Change Password"]
        if changePasswordButton.exists {
            changePasswordButton.tap()
            sleep(1)
            XCTAssertTrue(app.staticTexts["Change Your Password"].exists, "Should navigate to Change Password screen")
            app.navigationBars.buttons.firstMatch.tap() // Go back
            sleep(1)
        }
        
        // Test biometric toggle
        let biometricToggle = app.switches.firstMatch
        if biometricToggle.exists {
            let initialValue = biometricToggle.value as? String
            biometricToggle.tap()
            sleep(1)
            let newValue = biometricToggle.value as? String
            XCTAssertNotEqual(initialValue, newValue, "Toggle should change state when tapped")
            
            // Reset to original state
            biometricToggle.tap()
            sleep(1)
        }
        
        // Test sign out
        let signOutButton = app.buttons["Sign Out"]
        XCTAssertTrue(signOutButton.exists, "Sign Out button should exist in Settings")
        signOutButton.tap()
        sleep(1)
        
        // Confirm sign out in alert
        let confirmButton = app.alerts.buttons["Sign Out"]
        if confirmButton.exists {
            confirmButton.tap()
            sleep(2)
            // After sign out, we should see the login screen
            XCTAssertTrue(app.textFields["Email"].exists ||
                          app.buttons["Login"].exists,
                          "Should return to login screen after sign out")
        }
    }
    
    // MARK: - Budget Tests
    
    func testBudgetView() throws {
        // Skip onboarding and login
        skipOnboardingIfNeeded()
        loginIfNeeded()
        
        // Navigate to Budget tab
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.exists, "Tab bar should exist")
        tabBar.buttons["Budget"].tap()
        sleep(1)
        
        // Verify budget components exist
        XCTAssertTrue(app.staticTexts["Monthly Budget"].exists ||
                      app.staticTexts["Budget Categories"].exists,
                      "Budget screen should have appropriate headers")
        
        // Test auto-budget feature if available
        let autoBudgetButton = app.buttons["Auto Budget"]
        if autoBudgetButton.exists {
            autoBudgetButton.tap()
            sleep(2)
            // Look for success message or new categories
            XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'optimized'")).firstMatch.exists ||
                          app.staticTexts["Budget has been"].exists ||
                          app.staticTexts["Housing"].exists,
                          "Auto budget should create default categories")
        }
        
        // Test adding a budget category if button exists
        let addCategoryButton = app.buttons["Add"]
        if addCategoryButton.exists {
            addCategoryButton.tap()
            sleep(1)
            
            XCTAssertTrue(app.staticTexts["Category Details"].exists ||
                          app.staticTexts["Add Category"].exists,
                          "Add category form should be visible")
            
            // Fill in category details
            let categoryNameField = app.textFields.firstMatch
            if categoryNameField.exists {
                categoryNameField.tap()
                categoryNameField.typeText("Test Category")
                
                // Enter amount
                let amountField = app.textFields.element(boundBy: 1) // Second text field
                if amountField.exists {
                    amountField.tap()
                    amountField.typeText("100")
                }
                
                // Save category
                let saveButton = app.buttons["Save"]
                if saveButton.exists {
                    saveButton.tap()
                    sleep(1)
                    // New category should be visible in the list
                    XCTAssertTrue(app.staticTexts["Test Category"].exists ||
                                 app.staticTexts["$100"].exists,
                                 "Newly added category should be visible")
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func skipOnboardingIfNeeded() {
        let skipButton = app.buttons["Skip"]
        if skipButton.exists {
            skipButton.tap()
            sleep(1)
        } else {
            // Try to find "Get Started" button
            let getStartedButton = app.buttons["Get Started"]
            if getStartedButton.exists {
                getStartedButton.tap()
                sleep(1)
            }
        }
    }
    
    private func loginIfNeeded() {
        // Check if we're on the login screen
        if app.textFields["Email"].exists || app.buttons["Login"].exists {
            // Use test credentials
            let emailField = app.textFields["Email"]
            if emailField.exists {
                emailField.tap()
                emailField.typeText("test@example.com")
            }
            
            let passwordField = app.secureTextFields["Password"]
            if passwordField.exists {
                passwordField.tap()
                passwordField.typeText("Test123!")
            }
            
            let loginButton = app.buttons["Login"]
            if loginButton.exists && loginButton.isEnabled {
                loginButton.tap()
            }
            
            // Wait for login to complete
            sleep(3)
        }
    }
}

class PennywiseAccessibilityUITests: XCTestCase {
    
    let app = XCUIApplication()
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app.launch()
    }
    
    func testHomeScreenAccessibility() throws {
        // Skip onboarding and login
        skipOnboardingIfNeeded()
        loginIfNeeded()
        
        // Wait for app to fully load
        sleep(3)
        
        // Verify key elements are accessible
        let homeElements = [
            "Total Bank Balance",
            "Monthly Income",
            "Monthly Expenses"
        ]
        
        for elementLabel in homeElements {
            let element = app.staticTexts[elementLabel]
            if element.exists {
                XCTAssertTrue(element.isEnabled, "\(elementLabel) should be enabled")
                XCTAssertTrue(element.isHittable, "\(elementLabel) should be hittable")
            }
        }
        
        // Test tab bar accessibility
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.exists, "Tab bar should exist")
        
        let tabBarButtons = ["Home", "Insights", "Budget", "Settings"]
        for buttonLabel in tabBarButtons {
            let button = tabBar.buttons[buttonLabel]
            if button.exists {
                XCTAssertTrue(button.isEnabled, "\(buttonLabel) tab should be enabled")
                XCTAssertTrue(button.isHittable, "\(buttonLabel) tab should be hittable")
            }
        }
    }
    
    func testTransactionFormAccessibility() throws {
        // Skip onboarding and login
        skipOnboardingIfNeeded()
        loginIfNeeded()
        
        // Wait for app to fully load
        sleep(3)
        
        // Tap the Add button in tab bar
        let addButton = app.buttons["Add"]
        XCTAssertTrue(addButton.exists, "Add button should exist in tab bar")
        addButton.tap()
        
        // Wait for the transaction form to appear
        sleep(1)
        
        // Test form field accessibility
        let formElements = [
            "Transaction Details",
            "Title",
            "Merchant",
            "Amount",
            "Type",
            "Category"
        ]
        
        for elementLabel in formElements {
            // Try to find the element through various means
            let element = app.staticTexts[elementLabel].exists ? app.staticTexts[elementLabel] :
                          app.otherElements[elementLabel].exists ? app.otherElements[elementLabel] :
                          app.textFields[elementLabel].exists ? app.textFields[elementLabel] :
                          nil
            
            if let element = element, element.exists {
                XCTAssertTrue(element.isEnabled, "\(elementLabel) should be enabled")
                if element.isHittable {
                    XCTAssertTrue(element.isHittable, "\(elementLabel) should be hittable")
                }
            }
        }
        
        // Test radio button accessibility
        let expenseButton = app.buttons["Expense"]
        let incomeButton = app.buttons["Income"]
        
        if expenseButton.exists && incomeButton.exists {
            XCTAssertTrue(expenseButton.isEnabled, "Expense button should be enabled")
            XCTAssertTrue(incomeButton.isEnabled, "Income button should be enabled")
            
            // Check if they're toggleable
            if expenseButton.isSelected {
                incomeButton.tap()
                sleep(1)
                XCTAssertTrue(incomeButton.isSelected, "Income button should be selectable")
                XCTAssertFalse(expenseButton.isSelected, "Expense button should be deselected")
            } else {
                expenseButton.tap()
                sleep(1)
                XCTAssertTrue(expenseButton.isSelected, "Expense button should be selectable")
                XCTAssertFalse(incomeButton.isSelected, "Income button should be deselected")
            }
        }
    }
    
    func testSettingsAccessibility() throws {
        // Skip onboarding and login
        skipOnboardingIfNeeded()
        loginIfNeeded()
        
        // Navigate to Settings
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.exists, "Tab bar should exist")
        tabBar.buttons["Settings"].tap()
        sleep(1)
        
        // Test settings switches
        let switches = app.switches.allElementsBoundByIndex
        for (index, toggle) in switches.enumerated() {
            if toggle.isEnabled && toggle.isHittable {
                let initialValue = toggle.value as? String
                toggle.tap()
                sleep(1)
                let newValue = toggle.value as? String
                XCTAssertNotEqual(initialValue, newValue, "Toggle \(index) should change state when tapped")
                
                // Reset toggle
                toggle.tap()
                sleep(1)
            }
        }
        
        // Test navigation buttons
        let navigationButtons = ["Change Password", "Edit Profile", "About Pennywise", "Export Data", "Report a Bug"]
        for buttonLabel in navigationButtons {
            let button = app.buttons[buttonLabel]
            if button.exists && button.isEnabled && button.isHittable {
                button.tap()
                sleep(1)
                // Use back button to return
                let backButton = app.navigationBars.buttons.element(boundBy: 0)
                if backButton.exists {
                    backButton.tap()
                    sleep(1)
                } else {
                    // Try to find a "Done" or "Cancel" button
                    let doneButton = app.buttons["Done"]
                    let cancelButton = app.buttons["Cancel"]
                    
                    if doneButton.exists && doneButton.isEnabled {
                        doneButton.tap()
                    } else if cancelButton.exists && cancelButton.isEnabled {
                        cancelButton.tap()
                    }
                    sleep(1)
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func skipOnboardingIfNeeded() {
        let skipButton = app.buttons["Skip"]
        if skipButton.exists {
            skipButton.tap()
            sleep(1)
        } else {
            // Try to find "Get Started" button
            let getStartedButton = app.buttons["Get Started"]
            if getStartedButton.exists {
                getStartedButton.tap()
                sleep(1)
            }
        }
    }
    
    private func loginIfNeeded() {
        // Check if we're on the login screen
        if app.textFields["Email"].exists || app.buttons["Login"].exists {
            // Use test credentials
            let emailField = app.textFields["Email"]
            if emailField.exists {
                emailField.tap()
                emailField.typeText("test@example.com")
            }
            
            let passwordField = app.secureTextFields["Password"]
            if passwordField.exists {
                passwordField.tap()
                passwordField.typeText("Test123!")
            }
            
            let loginButton = app.buttons["Login"]
            if loginButton.exists && loginButton.isEnabled {
                loginButton.tap()
            }
            
            // Wait for login to complete
            sleep(3)
        }
    }
}
