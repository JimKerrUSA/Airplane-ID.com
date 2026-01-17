//
//  Theme.swift
//  Airplane-ID
//
//  Created by Jim Kerr on 1/16/26.
//
//  Centralized theme constants for consistent styling across the app.
//  Use these constants instead of hardcoded hex values.
//

import SwiftUI

// MARK: - App Colors
/// All color constants used throughout the app
enum AppColors {
    // MARK: Primary Brand Colors
    static let darkBlue = Color(hex: "082A49")      // Headers, labels, text
    static let primaryBlue = Color(hex: "1D58A4")   // Main blue backgrounds
    static let gold = Color(hex: "FBBD1C")          // Numbers, accents, highlights
    static let orange = Color(hex: "F27C31")        // Icons, airplane indicators

    // MARK: Background Colors
    static let settingsBackground = Color(hex: "121516")  // Dark settings background
    static let settingsRow = Color(hex: "1D1E21")         // Settings row background
    static let white = Color(hex: "FFFFFF")
    static let black = Color(hex: "000000")

    // MARK: UI Element Colors
    static let linkBlue = Color(hex: "639BEC")      // Links, buttons, toggles
    static let borderBlue = Color(hex: "124A93")    // Box borders
    static let darkGray = Color(hex: "313131")      // Dark borders
    static let mediumGray = Color(hex: "3A3A3C")    // Camera icon
    static let lightGray = Color(hex: "B9C6D1")     // Progress bar background

    // MARK: Status Colors
    static let success = Color(hex: "4CAF50")       // Success messages (green)
    static let error = Color(hex: "F44336")         // Error messages (red)
    static let warning = Color(hex: "FF5722")       // Warning/danger (orange)
    static let info = Color(hex: "03A9F4")          // Info messages (light blue)

    // MARK: Progress Bar Colors
    static let progressFill = Color(hex: "2B81C5")  // Normal progress bar
    static let progressLegend = Color(hex: "28A745") // Legend level (green)
}

// MARK: - App Fonts
/// Typography constants (for future use)
enum AppFonts {
    static let headerSize: CGFloat = 32
    static let titleSize: CGFloat = 26
    static let bodySize: CGFloat = 19
    static let captionSize: CGFloat = 14

    // Custom font names
    static let boldFont = "Helvetica-Bold"
}

// MARK: - App Spacing
/// Layout spacing constants (for future use)
enum AppSpacing {
    static let small: CGFloat = 5
    static let medium: CGFloat = 10
    static let large: CGFloat = 15
    static let xlarge: CGFloat = 20

    static let cornerRadius: CGFloat = 10
    static let cornerRadiusLarge: CGFloat = 15
}
