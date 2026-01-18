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
import UIKit

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

// MARK: - Date Formatting
/// Shared date formatting utilities to avoid duplicate DateFormatter creation
enum DateFormatting {
    /// Format date as medium style (e.g., "Jan 17, 2026")
    static func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }

    /// Format date and time (e.g., "Jan 17, 2026 at 3:45 PM")
    static func formatDateTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    /// Format coordinates as string (e.g., "37.7749, -122.4194")
    static func formatCoordinates(_ lat: Double, _ lon: Double) -> String {
        String(format: "%.4f, %.4f", lat, lon)
    }
}

// MARK: - Aircraft Lookup Tables
/// FAA aircraft classification and type code lookups
enum AircraftLookup {
    // MARK: Aircraft Classification (AC-CAT in FAA data)
    // Stored as Int (1-9), displayed in ALL CAPS
    static let classifications: [Int: String] = [
        1: "STANDARD",
        2: "LIMITED",
        3: "RESTRICTED",
        4: "EXPERIMENTAL",
        5: "PROVISIONAL",
        6: "MULTIPLE",
        7: "PRIMARY",
        8: "SPECIAL FLIGHT PERMIT",
        9: "LIGHT SPORT"
    ]

    /// Returns classification display name (ALL CAPS) or nil if not found
    static func classificationName(_ code: Int?) -> String? {
        guard let code = code else { return nil }
        return classifications[code]
    }

    // MARK: Aircraft Type (TYPE-ACFT in FAA data)
    // Stored as String (1-9, H, O), displayed in Title Case
    static let types: [String: String] = [
        "1": "Glider",
        "2": "Balloon",
        "3": "Blimp/Dirigible",
        "4": "Fixed Wing Single-Engine",
        "5": "Fixed Wing Multi-Engine",
        "6": "Rotorcraft",
        "7": "Weight Shift Control",
        "8": "Powered Parachute",
        "9": "Gyroplane",
        "H": "Hybrid Lift",
        "O": "Unclassified"
    ]

    /// Returns type display name (Title Case) or nil if not found
    static func typeName(_ code: String?) -> String? {
        guard let code = code else { return nil }
        return types[code]
    }

    // MARK: Aircraft Category Code (FAA aircraft category)
    // Stored as Int (1-3), displayed in Title Case
    static let categories: [Int: String] = [
        1: "Land",
        2: "Sea",
        3: "Amphibian"
    ]

    /// Returns category display name (Title Case) or nil if not found
    static func categoryName(_ code: Int?) -> String? {
        guard let code = code else { return nil }
        return categories[code]
    }

    // MARK: Engine Type (TYPE-ENG in FAA data)
    // Stored as Int (0-10), displayed in Title Case
    static let engineTypes: [Int: String] = [
        0: "None",
        1: "Reciprocating",
        2: "Turbo-prop",
        3: "Turbo-shaft",
        4: "Turbo-jet",
        5: "Turbo-fan",
        6: "Ramjet",
        7: "2 Cycle",
        8: "4 Cycle",
        9: "Unknown",
        10: "Electric",
        11: "Rotary"
    ]

    /// Returns engine type display name (Title Case) or nil if not found
    static func engineTypeName(_ code: Int?) -> String? {
        guard let code = code else { return nil }
        return engineTypes[code]
    }
}

// MARK: - Haptic Feedback Manager
/// Centralized haptic feedback for tactile user experience
/// Usage: Haptics.play(.navigation) or Haptics.navigation()
enum Haptics {

    // MARK: - Feedback Types

    /// Pre-defined haptic feedback types for consistent UX
    enum FeedbackType {
        /// Major navigation buttons (Home, Maps, Camera, Hangar, Settings, Journey)
        /// Feel: Firm, satisfying tap
        case navigation

        /// Opening sheets, modals, detail views
        /// Feel: Light, subtle acknowledgment
        case light

        /// Toggles, switches, picker changes
        /// Feel: Crisp selection click
        case selection

        /// Successfully completed action (capture, save, sync)
        /// Feel: Positive double-tap pattern
        case success

        /// Warning or attention needed
        /// Feel: Attention-getting buzz
        case warning

        /// Error or failed action
        /// Feel: Sharp negative feedback
        case error

        /// Camera shutter / capture moment
        /// Feel: Satisfying medium impact
        case capture

        /// Soft feedback for less important interactions
        /// Feel: Very subtle
        case soft
    }

    // MARK: - Feedback Generators (lazy initialized)

    private static let lightImpact = UIImpactFeedbackGenerator(style: .light)
    private static let mediumImpact = UIImpactFeedbackGenerator(style: .medium)
    private static let heavyImpact = UIImpactFeedbackGenerator(style: .heavy)
    private static let softImpact = UIImpactFeedbackGenerator(style: .soft)
    private static let rigidImpact = UIImpactFeedbackGenerator(style: .rigid)
    private static let selectionFeedback = UISelectionFeedbackGenerator()
    private static let notificationFeedback = UINotificationFeedbackGenerator()

    // MARK: - Main Play Function

    /// Play haptic feedback for the given type
    static func play(_ type: FeedbackType) {
        switch type {
        case .navigation:
            mediumImpact.impactOccurred()
        case .light:
            lightImpact.impactOccurred()
        case .selection:
            selectionFeedback.selectionChanged()
        case .success:
            notificationFeedback.notificationOccurred(.success)
        case .warning:
            notificationFeedback.notificationOccurred(.warning)
        case .error:
            notificationFeedback.notificationOccurred(.error)
        case .capture:
            mediumImpact.impactOccurred()
        case .soft:
            softImpact.impactOccurred()
        }
    }

    // MARK: - Convenience Functions

    /// Major navigation buttons (Home, Maps, Camera, Hangar, Settings, Journey)
    static func navigation() { play(.navigation) }

    /// Opening sheets, modals, detail views
    static func light() { play(.light) }

    /// Toggles, switches, picker changes
    static func selection() { play(.selection) }

    /// Successfully completed action
    static func success() { play(.success) }

    /// Warning or attention needed
    static func warning() { play(.warning) }

    /// Error or failed action
    static func error() { play(.error) }

    /// Camera shutter / capture moment
    static func capture() { play(.capture) }

    /// Soft feedback for subtle interactions
    static func soft() { play(.soft) }

    // MARK: - Prepare Generators (optional optimization)

    /// Call this to pre-warm haptic generators for immediate response
    /// Useful before time-critical interactions like camera capture
    static func prepare(_ type: FeedbackType) {
        switch type {
        case .navigation, .capture:
            mediumImpact.prepare()
        case .light:
            lightImpact.prepare()
        case .selection:
            selectionFeedback.prepare()
        case .success, .warning, .error:
            notificationFeedback.prepare()
        case .soft:
            softImpact.prepare()
        }
    }
}
