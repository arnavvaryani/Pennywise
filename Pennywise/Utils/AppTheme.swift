//
//  AppTheme.swift
//  Pennywise
//
//  Created for Pennywise App
//

import SwiftUI

struct AppTheme {
    // MARK: - Colors
    
    // Primary colors - with better contrast for accessibility
    static let primary = Color(hex: "#0047AB")          // Cobalt Blue
    static let secondary = Color(hex: "#4682B4")        // Steel Blue
    static let primaryGreen = Color(hex: "#7FE660")     // Bright Green
    static let accentBlue = Color(hex: "#56D6DA")       // Teal Blue
    static let accentPurple = Color(hex: "#6074DD")     // Purple
    static let textColor = Color.adaptiveText           // Adaptive text color
    
    // Background colors - adaptive for light/dark mode
    static let backgroundColor = Color.adaptiveBackground
    static let backgroundPrimary = Color.adaptivePrimary
    static let backgroundSecondary = Color.adaptiveSecondary
    
    // Financial colors with improved accessibility contrast
    static let incomeGreen = Color(hex: "#50C878")     // Emerald Green
    static let expenseRed = Color(hex: "#FF5757")      // Light Red
    static let expenseColor = Color(hex: "#FF5757")    // Same as expenseRed (alias for consistency)
    static let savingsYellow = Color(hex: "#FFD700")   // Gold
    static let investmentPurple = Color(hex: "#9370DB") // Medium Purple
    static let alertOrange = Color(hex: "#FF8C00")     // Dark Orange
    
    // Additional UI elements
    static let cardStroke = Color.adaptiveStroke
    static let cardBackground = Color.adaptiveCardBackground
    
    // MARK: - Gradients
    
    // Background gradient used throughout the app - adapts to color scheme
    static var backgroundGradient: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [
                backgroundPrimary,
                backgroundSecondary,
                backgroundPrimary
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    // Enhanced gradient with highlights
    static var enhancedBackgroundGradient: some View {
        ZStack {
            // Base blue gradient that matches the reference image
            LinearGradient(
                gradient: Gradient(colors: [
                    backgroundPrimary.opacity(0.8),
                    backgroundPrimary,
                    backgroundSecondary,
                    backgroundPrimary.opacity(0.9),
                    backgroundPrimary.opacity(0.85)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .edgesIgnoringSafeArea(.all)
            
            // Subtle teal highlight in top-right area
            RadialGradient(
                gradient: Gradient(colors: [
                    accentBlue.opacity(0.3),  // Teal
                    Color.clear
                ]),
                center: UnitPoint(x: 0.8, y: 0.2),  // Top right area
                startRadius: 5,
                endRadius: 300
            )
            
            // Very subtle green highlight top-left
            RadialGradient(
                gradient: Gradient(colors: [
                    primaryGreen.opacity(0.15),  // Green
                    Color.clear
                ]),
                center: UnitPoint(x: 0.2, y: 0.3),  // Top left area
                startRadius: 10,
                endRadius: 250
            )
            
            // Purple accent in bottom-middle
            RadialGradient(
                gradient: Gradient(colors: [
                    accentPurple.opacity(0.25),  // Purple
                    Color.clear
                ]),
                center: UnitPoint(x: 0.5, y: 0.8), // Bottom middle
                startRadius: 5,
                endRadius: 200
            )
        }
    }
    
    // Gradient for primary actions
    static func primaryGradient() -> LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [primary, secondary]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    static func incomeGradient() -> LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [incomeGreen, incomeGreen.opacity(0.7)]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    static func expenseGradient() -> LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [expenseRed, expenseRed.opacity(0.7)]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    // MARK: - Typography with Dynamic Type Support
    
    // Font styles with dynamic type support
    static func titleFont() -> Font {
        Font.system(.title2, design: .rounded).weight(.semibold)
    }
    
    static func headlineFont() -> Font {
        Font.system(.headline, design: .rounded).weight(.semibold)
    }
    
    static func bodyFont() -> Font {
        Font.system(.body, design: .rounded).weight(.regular)
    }
    
    static func captionFont() -> Font {
        Font.system(.caption, design: .rounded).weight(.medium)
    }
    
    // MARK: - Responsive Modifiers
    
    // Apply horizontal padding based on screen size
    static func responsiveHorizontalPadding() -> CGFloat {
        let screenWidth = UIScreen.main.bounds.width
        if screenWidth > 400 {
            return 24
        } else {
            return 16
        }
    }
    
    // Dynamic card padding based on screen size
    static func cardPadding() -> EdgeInsets {
        let screenWidth = UIScreen.main.bounds.width
        if screenWidth > 400 {
            return EdgeInsets(top: 16, leading: 20, bottom: 16, trailing: 20)
        } else {
            return EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16)
        }
    }
    
    // MARK: - Shadow Styles
    
    // Function to apply consistent shadows
    static func applyShadow(to view: some View, intensity: ShadowIntensity = .medium) -> some View {
        let radius: CGFloat
        let y: CGFloat
        let opacity: Double
        
        switch intensity {
        case .light:
            radius = 4
            y = 2
            opacity = 0.1
        case .medium:
            radius = 8
            y = 4
            opacity = 0.15
        case .strong:
            radius = 12
            y = 6
            opacity = 0.2
        }
        
        return view.shadow(
            color: Color.black.opacity(opacity),
            radius: radius,
            x: 0,
            y: y
        )
    }
    
    enum ShadowIntensity {
        case light, medium, strong
    }
}

// MARK: - Color Extensions

extension Color {
    // Initialize color from hex string
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
    
    // Convenient adaptive colors that respond to light/dark mode
    static var adaptiveText: Color {
        Color(UIColor { traitCollection in
            return traitCollection.userInterfaceStyle == .dark ?
                   UIColor(white: 1.0, alpha: 1.0) :
                   UIColor(white: 0.1, alpha: 1.0)
        })
    }
    
    static var adaptiveBackground: Color {
        Color(UIColor { traitCollection in
            return traitCollection.userInterfaceStyle == .dark ?
                   UIColor(hex: "#0F2549") :
                   UIColor(hex: "#F8F9FA")
        })
    }
    
    static var adaptivePrimary: Color {
        Color(UIColor { traitCollection in
            return traitCollection.userInterfaceStyle == .dark ?
                   UIColor(hex: "#121212") :
                   UIColor(hex: "#FFFFFF")
        })
    }
    
    static var adaptiveSecondary: Color {
        Color(UIColor { traitCollection in
            return traitCollection.userInterfaceStyle == .dark ?
                   UIColor(hex: "#1E1E1E") :
                   UIColor(hex: "#F0F0F0")
        })
    }
    
    static var adaptiveStroke: Color {
        Color(UIColor { traitCollection in
            return traitCollection.userInterfaceStyle == .dark ?
                   UIColor(red: 0.34, green: 0.84, blue: 0.85, alpha: 0.2) :
                   UIColor(red: 0.34, green: 0.84, blue: 0.85, alpha: 0.3)
        })
    }
    
    static var adaptiveCardBackground: Color {
        Color(UIColor { traitCollection in
            return traitCollection.userInterfaceStyle == .dark ?
                   UIColor(red: 0.37, green: 0.45, blue: 0.87, alpha: 0.15) :
                   UIColor(white: 1.0, alpha: 0.95)
        })
    }
    
    // Convert SwiftUI Color to UIColor
    func toUIColor() -> UIColor {
        let components = self.components()
        return UIColor(red: components.r, green: components.g, blue: components.b, alpha: components.a)
    }
    
    // Get RGBA components
    private func components() -> (r: CGFloat, g: CGFloat, b: CGFloat, a: CGFloat) {
        let scanner = Scanner(string: self.description.trimmingCharacters(in: CharacterSet.alphanumerics.inverted))
        var hexNumber: UInt64 = 0
        var r: CGFloat = 0.0, g: CGFloat = 0.0, b: CGFloat = 0.0, a: CGFloat = 0.0
        
        // For SwiftUI.Color's default description format or UIColor
        if scanner.scanHexInt64(&hexNumber) {
            r = CGFloat((hexNumber & 0xff000000) >> 24) / 255
            g = CGFloat((hexNumber & 0x00ff0000) >> 16) / 255
            b = CGFloat((hexNumber & 0x0000ff00) >> 8) / 255
            a = CGFloat(hexNumber & 0x000000ff) / 255
            return (r, g, b, a)
        }
        
        // If it's a standard color that doesn't use hex
        // These are approximate values for common colors
        let standardColors: [String: (CGFloat, CGFloat, CGFloat, CGFloat)] = [
            "red": (1, 0, 0, 1),
            "green": (0, 1, 0, 1),
            "blue": (0, 0, 1, 1),
            "black": (0, 0, 0, 1),
            "white": (1, 1, 1, 1),
            "gray": (0.5, 0.5, 0.5, 1),
            "yellow": (1, 1, 0, 1),
            "orange": (1, 0.5, 0, 1),
            "purple": (0.5, 0, 0.5, 1)
        ]
        
        for (colorName, components) in standardColors {
            if self.description.lowercased().contains(colorName) {
                return components
            }
        }
        
        // Default to black if color can't be determined
        return (0, 0, 0, 1)
    }
    
    // Hex string representation of the color
    var hexString: String {
        let components = self.components()
        let r = Int(components.r * 255)
        let g = Int(components.g * 255)
        let b = Int(components.b * 255)
        let a = Int(components.a * 255)
        
        if a < 255 {
            return String(format: "#%02X%02X%02X%02X", a, r, g, b)
        } else {
            return String(format: "#%02X%02X%02X", r, g, b)
        }
    }
}

// MARK: - UIColor Extension for convenience
extension UIColor {
    convenience init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            red: CGFloat(r) / 255,
            green: CGFloat(g) / 255,
            blue: CGFloat(b) / 255,
            alpha: CGFloat(a) / 255
        )
    }
}

// MARK: - View Extensions for Common Modifiers
extension View {
    // Apply consistent card styling
    func cardStyle(padding: EdgeInsets? = nil) -> some View {
        self.padding(padding ?? AppTheme.cardPadding())
            .background(AppTheme.cardBackground)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(AppTheme.cardStroke, lineWidth: 1)
            )
    }
    
    // Apply consistent primary button styling
    func primaryButtonStyle() -> some View {
        self.padding(.vertical, 12)
            .padding(.horizontal, 24)
            .background(AppTheme.primaryGreen)
            .foregroundColor(.white)
            .cornerRadius(12)
            .shadow(
                color: AppTheme.primaryGreen.opacity(0.3),
                radius: 5,
                x: 0,
                y: 3
            )
    }
    
    // Apply responsive horizontal padding
    func responsivePadding() -> some View {
        self.padding(.horizontal, AppTheme.responsiveHorizontalPadding())
    }
}

