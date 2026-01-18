//
//  SettingsPage.swift
//  Airplane-ID
//
//  Created by Jim Kerr on 1/15/26.
//

import SwiftUI
import SwiftData
import UIKit

// MARK: - Settings Page
/// Settings page with dark background (#121516)
/// Custom orientation handling to ensure dark background covers entire screen including footer area
/// Uses UIDevice.current.orientation for reliable landscape left/right detection
struct SettingsPage: View {
    @Environment(AppState.self) private var appState
    @State private var deviceOrientation: UIDeviceOrientation = UIDevice.current.orientation
    @State private var showingAccountSettings = false

    var body: some View {
        GeometryReader { geometry in
            let isLandscape = geometry.size.width > geometry.size.height

            if isLandscape {
                // Note: UIDeviceOrientation naming is counterintuitive
                // .landscapeRight means the device is rotated so camera is on the right (user's "Landscape Left")
                // .landscapeLeft means the device is rotated so camera is on the left (user's "Landscape Right")
                if deviceOrientation == .landscapeRight {
                    // Camera on right - footer on left
                    SettingsLandscapeLeftView(geometry: geometry, showingAccountSettings: $showingAccountSettings)
                } else if deviceOrientation == .landscapeLeft {
                    // Camera on left - footer on right
                    SettingsLandscapeRightView(geometry: geometry, showingAccountSettings: $showingAccountSettings)
                } else {
                    // Default to left view
                    SettingsLandscapeLeftView(geometry: geometry, showingAccountSettings: $showingAccountSettings)
                }
            } else {
                // Portrait
                SettingsPortraitView(showingAccountSettings: $showingAccountSettings)
            }
        }
        .onAppear {
            UIDevice.current.beginGeneratingDeviceOrientationNotifications()
            deviceOrientation = UIDevice.current.orientation
        }
        .onDisappear {
            UIDevice.current.endGeneratingDeviceOrientationNotifications()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)) { _ in
            deviceOrientation = UIDevice.current.orientation
        }
        .fullScreenCover(isPresented: $showingAccountSettings) {
            AccountSettingsView()
        }
    }
}

// MARK: - Settings Portrait View
struct SettingsPortraitView: View {
    @Binding var showingAccountSettings: Bool

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                TopMenuView()

                ZStack(alignment: .bottom) {
                    // Dark background for entire content area
                    AppColors.settingsBackground
                        .ignoresSafeArea()

                    SettingsContent(showingAccountSettings: $showingAccountSettings)

                    BottomMenuView()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .background(AppColors.settingsBackground)
            .ignoresSafeArea()
#if os(iOS)
            .navigationBarHidden(true)
#endif
        }
    }
}

// MARK: - Settings Landscape Left View
struct SettingsLandscapeLeftView: View {
    let geometry: GeometryProxy
    @Binding var showingAccountSettings: Bool

    var body: some View {
        NavigationStack {
            ZStack {
                // Dark background for entire screen
                AppColors.settingsBackground
                    .ignoresSafeArea()

                // Main layout with header
                VStack(spacing: 0) {
                    TopMenuViewLandscape()

                    // Content area - ScrollView needs to fill remaining space
                    ScrollView {
                        SettingsScrollContent(showingAccountSettings: $showingAccountSettings)
                            .padding(.leading, 120)
                    }
                }

                // Left side navigation bar
                BottomMenuViewLandscape()
                    .position(x: 50, y: (geometry.size.height + geometry.size.width) / 4 - 82)
                    .offset(x: 16)
                    .ignoresSafeArea()
            }
#if os(iOS)
            .navigationBarHidden(true)
#endif
        }
    }
}

// MARK: - Settings Landscape Right View
struct SettingsLandscapeRightView: View {
    let geometry: GeometryProxy
    @Binding var showingAccountSettings: Bool

    var body: some View {
        NavigationStack {
            ZStack {
                // Dark background for entire screen
                AppColors.settingsBackground
                    .ignoresSafeArea()

                // Main layout with header
                VStack(spacing: 0) {
                    TopMenuViewLandscape()

                    // Content area - ScrollView needs to fill remaining space
                    ScrollView {
                        SettingsScrollContent(showingAccountSettings: $showingAccountSettings)
                            .padding(.trailing, 120)
                    }
                }

                // Right side navigation bar
                BottomMenuViewLandscape()
                    .position(x: geometry.size.width - 50, y: (geometry.size.height + geometry.size.width) / 4 - 82)
                    .offset(x: 104)
                    .ignoresSafeArea()
            }
#if os(iOS)
            .navigationBarHidden(true)
#endif
        }
    }
}

// MARK: - Settings Content (Portrait - includes ScrollView)
/// The settings content for portrait - includes ScrollView wrapper
struct SettingsContent: View {
    @Binding var showingAccountSettings: Bool

    var body: some View {
        ScrollView {
            SettingsScrollContent(showingAccountSettings: $showingAccountSettings)
        }
    }
}

// MARK: - Settings Scroll Content (Inner content without ScrollView)
/// The actual settings content - used inside ScrollView
/// Shows menu categories that open sub-pages as sheets
struct SettingsScrollContent: View {
    // Account Settings binding from parent (fullScreenCover handled at SettingsPage level)
    @Binding var showingAccountSettings: Bool

    // Sheet presentation states for other settings
    @State private var showingAppPreferences = false
    @State private var showingAbout = false
    @State private var showingDeveloperTools = false

    var body: some View {
        VStack {
            Spacer().frame(height: 20)

            // Settings title
            Text("Settings")
                .font(.system(size: 32, weight: .bold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)

            Spacer().frame(height: 10)

            // Settings menu items
            VStack(spacing: 15) {
                // Account Settings
                Button(action: {
                    Haptics.light()
                    showingAccountSettings = true
                }) {
                    SettingsRowContent(icon: "person.circle", title: "Account Settings", subtitle: "Manage your account")
                }

                // App Preferences
                Button(action: {
                    Haptics.light()
                    showingAppPreferences = true
                }) {
                    SettingsRowContent(icon: "slider.horizontal.3", title: "App Preferences", subtitle: "Display, behavior, and data management")
                }

                // About
                Button(action: {
                    Haptics.light()
                    showingAbout = true
                }) {
                    SettingsRowContent(icon: "info.circle", title: "About", subtitle: "Version and credits")
                }

                // Developer Tools (only if enabled)
                if AppConfig.developerToolsEnabled {
                    Button(action: {
                        Haptics.light()
                        showingDeveloperTools = true
                    }) {
                        SettingsRowContent(icon: "wrench.and.screwdriver", title: "Developer Tools", subtitle: "Testing and debug options")
                    }
                }
            }
            .padding(.horizontal, 20)

            Spacer().frame(height: 120) // Space for footer
        }
        // Sheet presentations (Account Settings handled at SettingsPage level)
        .sheet(isPresented: $showingAppPreferences) {
            AppPreferencesView()
        }
        .sheet(isPresented: $showingAbout) {
            AboutView()
        }
        .sheet(isPresented: $showingDeveloperTools) {
            DeveloperToolsView()
        }
    }
}

// MARK: - Account Settings View
/// Sub-page showing user profile and account management with edit functionality
struct AccountSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var users: [User]

    // Edit mode state
    @State private var isEditing = false

    // Editable field values (loaded from user, saved on Save)
    @State private var editDisplayName = ""
    @State private var editName = ""
    @State private var editEmail = ""
    @State private var editPhone = ""
    @State private var editHomeAirport = ""

    private var currentUser: User? { users.first }

    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.settingsBackground.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // User profile section
                        if let user = currentUser {
                            VStack(spacing: 15) {
                                // Profile header
                                Image(systemName: "person.circle.fill")
                                    .font(.system(size: 80))
                                    .foregroundStyle(AppColors.linkBlue)

                                Text(isEditing ? editDisplayName : user.displayName)
                                    .font(.system(size: 28, weight: .bold))
                                    .foregroundStyle(.white)

                                Text(user.memberLevel.uppercased())
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(AppColors.gold)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 4)
                                    .background(AppColors.settingsRow)
                                    .cornerRadius(12)
                            }
                            .padding(.top, 20)

                            // Profile details - editable or read-only based on isEditing
                            VStack(spacing: 12) {
                                if isEditing {
                                    EditableProfileRow(label: "Display Name", value: $editDisplayName)
                                    EditableProfileRow(label: "Name", value: $editName)
                                    EditableProfileRow(label: "Email", value: $editEmail)
                                    EditableProfileRow(label: "Phone", value: $editPhone)
                                    EditableProfileRow(label: "Home Airport", value: $editHomeAirport)
                                } else {
                                    ProfileDetailRow(label: "Display Name", value: user.displayName)
                                    ProfileDetailRow(label: "Name", value: user.name)
                                    ProfileDetailRow(label: "Email", value: user.email)
                                    ProfileDetailRow(label: "Phone", value: user.phone ?? "Not set")
                                    ProfileDetailRow(label: "Home Airport", value: user.homeAirport ?? "Not set")
                                }
                                ProfileDetailRow(label: "Member Since", value: DateFormatting.formatDate(user.memberDate))
                            }
                            .padding(.horizontal, 20)
                            .padding(.top, 20)

                            // Security settings with toggle switches
                            VStack(spacing: 15) {
                                Text("Security")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundStyle(.white)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.horizontal, 20)
                                    .padding(.top, 20)

                                VStack(spacing: 12) {
                                    SecurityToggleRow(
                                        label: "Password Required",
                                        isOn: Binding(
                                            get: { user.passwordRequired },
                                            set: { newValue in
                                                user.passwordRequired = newValue
                                                try? modelContext.save()
                                            }
                                        )
                                    )
                                    SecurityToggleRow(
                                        label: "Face ID Enabled",
                                        isOn: Binding(
                                            get: { user.faceIDEnabled },
                                            set: { newValue in
                                                user.faceIDEnabled = newValue
                                                try? modelContext.save()
                                            }
                                        )
                                    )
                                }
                                .padding(.horizontal, 20)

                                // Change password button (placeholder)
                                Button(action: { /* TODO: Implement password change */ }) {
                                    HStack {
                                        Image(systemName: "key")
                                            .font(.system(size: 20))
                                        Text("Change Password")
                                            .font(.system(size: 16, weight: .semibold))
                                    }
                                    .foregroundStyle(AppColors.linkBlue)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background(AppColors.settingsRow)
                                    .cornerRadius(12)
                                }
                                .padding(.horizontal, 20)
                            }

                            // Privacy settings with toggle switches
                            VStack(spacing: 15) {
                                Text("Privacy")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundStyle(.white)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.horizontal, 20)
                                    .padding(.top, 20)

                                VStack(spacing: 12) {
                                    SecurityToggleRow(
                                        label: "Show Online Status",
                                        isOn: Binding(
                                            get: { user.showOnlineStatus },
                                            set: { newValue in
                                                user.showOnlineStatus = newValue
                                                try? modelContext.save()
                                            }
                                        )
                                    )
                                    SecurityToggleRow(
                                        label: "Show Location",
                                        isOn: Binding(
                                            get: { user.showLocation },
                                            set: { newValue in
                                                user.showLocation = newValue
                                                try? modelContext.save()
                                            }
                                        )
                                    )
                                    SecurityToggleRow(
                                        label: "Receive Latest News",
                                        isOn: Binding(
                                            get: { user.receiveNews },
                                            set: { newValue in
                                                user.receiveNews = newValue
                                                try? modelContext.save()
                                            }
                                        )
                                    )
                                    SecurityToggleRow(
                                        label: "Receive Activity Summary",
                                        isOn: Binding(
                                            get: { user.receiveActivitySummary },
                                            set: { newValue in
                                                user.receiveActivitySummary = newValue
                                                try? modelContext.save()
                                            }
                                        )
                                    )
                                }
                                .padding(.horizontal, 20)
                            }
                        } else {
                            // No user found
                            VStack(spacing: 15) {
                                Image(systemName: "person.crop.circle.badge.questionmark")
                                    .font(.system(size: 60))
                                    .foregroundStyle(AppColors.linkBlue)

                                Text("No User Profile")
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundStyle(.white)

                                Text("Import a user profile from Developer Tools to see your account details.")
                                    .font(.system(size: 16))
                                    .foregroundStyle(.white.opacity(0.6))
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 40)
                            }
                            .padding(.top, 60)
                        }

                        Spacer().frame(height: 40)
                    }
                }
                .scrollDismissesKeyboard(.never)
            }
            .navigationTitle("Account Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if !isEditing {
                        Button(action: { dismiss() }) {
                            HStack(spacing: 4) {
                                Image(systemName: "chevron.left")
                                Text("Back")
                            }
                            .foregroundStyle(AppColors.linkBlue)
                        }
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    if currentUser != nil {
                        if isEditing {
                            HStack(spacing: 16) {
                                Button("Cancel") {
                                    cancelEditing()
                                }
                                .foregroundStyle(.white.opacity(0.6))

                                Button("Save") {
                                    saveChanges()
                                }
                                .foregroundStyle(AppColors.linkBlue)
                                .fontWeight(.semibold)
                            }
                        } else {
                            Button("Edit") {
                                startEditing()
                            }
                            .foregroundStyle(AppColors.linkBlue)
                        }
                    }
                }
            }
            .onAppear {
                loadUserData()
            }
        }
    }

    private func loadUserData() {
        guard let user = currentUser else { return }
        editDisplayName = user.displayName
        editName = user.name
        editEmail = user.email
        editPhone = user.phone ?? ""
        editHomeAirport = user.homeAirport ?? ""
    }

    private func startEditing() {
        loadUserData()
        isEditing = true
    }

    private func cancelEditing() {
        loadUserData()
        isEditing = false
    }

    private func saveChanges() {
        guard let user = currentUser else { return }
        user.displayName = editDisplayName
        user.name = editName
        user.email = editEmail
        user.phone = editPhone.isEmpty ? nil : editPhone
        user.homeAirport = editHomeAirport.isEmpty ? nil : editHomeAirport
        try? modelContext.save()
        isEditing = false
    }
}

// MARK: - Profile Detail Row
struct ProfileDetailRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 16))
                .foregroundStyle(.white.opacity(0.6))
            Spacer()
            Text(value)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(.white)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(AppColors.settingsRow)
        .cornerRadius(10)
    }
}

// MARK: - Editable Profile Row
struct EditableProfileRow: View {
    let label: String
    @Binding var value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 16))
                .foregroundStyle(.white.opacity(0.6))
                .frame(width: 110, alignment: .leading)
            TextField("", text: $value)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(.white)
                .textFieldStyle(.plain)
                .multilineTextAlignment(.trailing)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(AppColors.settingsRow)
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(AppColors.linkBlue.opacity(0.5), lineWidth: 1)
        )
    }
}

// MARK: - Security Toggle Row
struct SecurityToggleRow: View {
    let label: String
    @Binding var isOn: Bool

    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 16))
                .foregroundStyle(.white.opacity(0.6))
            Spacer()
            Toggle("", isOn: $isOn)
                .tint(AppColors.linkBlue)
                .labelsHidden()
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 16)
        .background(AppColors.settingsRow)
        .cornerRadius(10)
    }
}

// MARK: - App Preferences View (Placeholder)
// MARK: - App Preferences Manager
/// Stores user preferences using UserDefaults via @AppStorage
/// Access via AppPreferences.shared or use @AppStorage directly in views
class AppPreferences {
    static let shared = AppPreferences()

    // Keys for UserDefaults
    static let timeFormatKey = "appPref_timeFormat"
    static let dateFormatKey = "appPref_dateFormat"
    static let timeZoneKey = "appPref_timeZone"
    static let defaultPageKey = "appPref_defaultPage"

    private init() {}
}

// MARK: - Preference Enums

enum TimeFormatPreference: String, CaseIterable {
    case system = "system"
    case twelveHour = "12hour"
    case twentyFourHour = "24hour"

    var displayName: String {
        switch self {
        case .system: return "System Default"
        case .twelveHour: return "12 Hour (AM/PM)"
        case .twentyFourHour: return "24 Hour"
        }
    }

    var example: String {
        switch self {
        case .system: return "Uses device setting"
        case .twelveHour: return "2:30 PM"
        case .twentyFourHour: return "14:30"
        }
    }
}

enum DateFormatPreference: String, CaseIterable {
    case system = "system"
    case dayMonthYear = "DMY"
    case monthDayYear = "MDY"
    case yearMonthDay = "YMD"

    var displayName: String {
        switch self {
        case .system: return "System Default"
        case .dayMonthYear: return "Day-Month-Year"
        case .monthDayYear: return "Month-Day-Year"
        case .yearMonthDay: return "Year-Month-Day"
        }
    }

    var example: String {
        switch self {
        case .system: return "Uses device setting"
        case .dayMonthYear: return "18-01-2026"
        case .monthDayYear: return "01-18-2026"
        case .yearMonthDay: return "2026-01-18"
        }
    }
}

enum TimeZonePreference: String, CaseIterable {
    case device = "device"
    case utc = "utc"

    var displayName: String {
        switch self {
        case .device: return "Device Time Zone"
        case .utc: return "UTC Time"
        }
    }

    var example: String {
        switch self {
        case .device: return "Uses local time"
        case .utc: return "Coordinated Universal Time"
        }
    }
}

enum DefaultPagePreference: String, CaseIterable {
    case home = "home"
    case hangar = "hangar"
    case maps = "maps"
    case journey = "journey"
    case camera = "camera"

    var displayName: String {
        switch self {
        case .home: return "Home"
        case .hangar: return "Hangar"
        case .maps: return "Maps"
        case .journey: return "Journey"
        case .camera: return "Camera"
        }
    }

    var icon: String {
        switch self {
        case .home: return "house.fill"
        case .hangar: return "airplane"
        case .maps: return "map.fill"
        case .journey: return "trophy.fill"
        case .camera: return "camera.fill"
        }
    }
}

enum CapturePreference: String, CaseIterable {
    case camera = "camera"
    case upload = "upload"

    var displayName: String {
        switch self {
        case .camera: return "Camera"
        case .upload: return "Photo Upload"
        }
    }

    var description: String {
        switch self {
        case .camera: return "Take new photos"
        case .upload: return "Select from library"
        }
    }

    var icon: String {
        switch self {
        case .camera: return "camera"
        case .upload: return "photo.badge.plus"
        }
    }
}

struct AppPreferencesView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(AppState.self) private var appState

    // Preferences stored in UserDefaults
    @AppStorage(AppPreferences.timeFormatKey) private var timeFormat: String = TimeFormatPreference.system.rawValue
    @AppStorage(AppPreferences.dateFormatKey) private var dateFormat: String = DateFormatPreference.system.rawValue
    @AppStorage(AppPreferences.timeZoneKey) private var timeZone: String = TimeZonePreference.device.rawValue
    @AppStorage(AppPreferences.defaultPageKey) private var defaultPage: String = DefaultPagePreference.home.rawValue
    @AppStorage(AppConfig.captureModeKey) private var captureMode: String = CapturePreference.camera.rawValue

    // Data management confirmation dialogs
    @State private var showingDeleteConfirmation = false
    @State private var showingResetConfirmation = false
    @State private var statusMessage: String? = nil

    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.settingsBackground.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {
                        // Time & Date Section
                        preferencesSection(title: "Time & Date") {
                            // Time Format
                            PreferencePickerRow(
                                label: "Time Format",
                                selection: $timeFormat,
                                options: TimeFormatPreference.allCases.map { ($0.rawValue, $0.displayName, $0.example) }
                            )

                            // Date Format
                            PreferencePickerRow(
                                label: "Date Format",
                                selection: $dateFormat,
                                options: DateFormatPreference.allCases.map { ($0.rawValue, $0.displayName, $0.example) }
                            )

                            // Time Zone
                            PreferencePickerRow(
                                label: "Time Zone",
                                selection: $timeZone,
                                options: TimeZonePreference.allCases.map { ($0.rawValue, $0.displayName, $0.example) }
                            )
                        }

                        // App Behavior Section
                        preferencesSection(title: "App Behavior") {
                            // Default Page
                            PreferencePickerRow(
                                label: "Default Open Page",
                                selection: $defaultPage,
                                options: DefaultPagePreference.allCases.map { ($0.rawValue, $0.displayName, "") }
                            )

                            // Capture Mode
                            CaptureModePickerRow(
                                selection: $captureMode,
                                appState: appState
                            )
                        }

                        // Reset Preferences Section
                        VStack(alignment: .leading, spacing: 8) {
                            Text("PREFERENCES")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(.white.opacity(0.5))
                                .padding(.leading, 4)

                            Button(action: {
                                Haptics.light()
                                resetPreferencesOnly()
                            }) {
                                HStack(spacing: 14) {
                                    Image(systemName: "slider.horizontal.3")
                                        .font(.system(size: 18))
                                        .foregroundStyle(AppColors.linkBlue)
                                        .frame(width: 24)

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Reset Preferences")
                                            .font(.system(size: 15, weight: .medium))
                                            .foregroundStyle(.white)
                                        Text("Restore default settings (keeps your data)")
                                            .font(.system(size: 12))
                                            .foregroundStyle(.white.opacity(0.5))
                                    }

                                    Spacer()

                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundStyle(.white.opacity(0.3))
                                }
                                .padding(.vertical, 14)
                                .padding(.horizontal, 16)
                                .background(AppColors.settingsRow)
                                .cornerRadius(10)
                            }
                        }

                        // Spacer between preferences and danger zone
                        Spacer().frame(height: 24)

                        // Danger Zone Section
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 6) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .font(.system(size: 12))
                                    .foregroundStyle(AppColors.error)
                                Text("DANGER ZONE")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundStyle(AppColors.error)
                            }
                            .padding(.leading, 4)

                            // Status message
                            if let message = statusMessage {
                                Text(message)
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundStyle(message.starts(with: "✓") ? AppColors.success : AppColors.error)
                                    .frame(maxWidth: .infinity, alignment: .center)
                                    .padding(.vertical, 8)
                            }

                            VStack(spacing: 12) {
                                // Delete All Aircraft
                                Button(action: {
                                    Haptics.warning()
                                    showingDeleteConfirmation = true
                                }) {
                                    HStack(spacing: 14) {
                                        Image(systemName: "trash")
                                            .font(.system(size: 18))
                                            .foregroundStyle(AppColors.warning)
                                            .frame(width: 24)

                                        VStack(alignment: .leading, spacing: 2) {
                                            Text("Delete All Aircraft")
                                                .font(.system(size: 15, weight: .medium))
                                                .foregroundStyle(.white)
                                            Text("Remove all captured aircraft records")
                                                .font(.system(size: 12))
                                                .foregroundStyle(.white.opacity(0.5))
                                        }

                                        Spacer()

                                        Image(systemName: "chevron.right")
                                            .font(.system(size: 12, weight: .semibold))
                                            .foregroundStyle(.white.opacity(0.3))
                                    }
                                    .padding(.vertical, 14)
                                    .padding(.horizontal, 16)
                                    .background(AppColors.settingsRow)
                                    .cornerRadius(10)
                                }

                                // Reset App
                                Button(action: {
                                    Haptics.warning()
                                    showingResetConfirmation = true
                                }) {
                                    HStack(spacing: 14) {
                                        Image(systemName: "arrow.counterclockwise")
                                            .font(.system(size: 18))
                                            .foregroundStyle(AppColors.error)
                                            .frame(width: 24)

                                        VStack(alignment: .leading, spacing: 2) {
                                            Text("Reset App")
                                                .font(.system(size: 15, weight: .medium))
                                                .foregroundStyle(.white)
                                            Text("Clear all data and restore defaults")
                                                .font(.system(size: 12))
                                                .foregroundStyle(.white.opacity(0.5))
                                        }

                                        Spacer()

                                        Image(systemName: "chevron.right")
                                            .font(.system(size: 12, weight: .semibold))
                                            .foregroundStyle(.white.opacity(0.3))
                                    }
                                    .padding(.vertical, 14)
                                    .padding(.horizontal, 16)
                                    .background(AppColors.settingsRow)
                                    .cornerRadius(10)
                                }
                            }

                            Text("These actions cannot be undone.")
                                .font(.system(size: 12))
                                .foregroundStyle(.white.opacity(0.4))
                                .padding(.leading, 4)
                                .padding(.top, 4)
                        }

                        Spacer().frame(height: 40)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                }
            }
            .navigationTitle("App Preferences")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        Haptics.light()
                        dismiss()
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                            Text("Back")
                        }
                        .foregroundStyle(AppColors.linkBlue)
                    }
                }
            }
            .confirmationDialog("Delete All Aircraft?", isPresented: $showingDeleteConfirmation, titleVisibility: .visible) {
                Button("Delete All Aircraft", role: .destructive) { deleteAllAircraft() }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("This will permanently delete all captured aircraft records. This action cannot be undone.")
            }
            .confirmationDialog("Reset App?", isPresented: $showingResetConfirmation, titleVisibility: .visible) {
                Button("Reset Everything", role: .destructive) { resetApp() }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("This will delete ALL data including aircraft records and user profiles, and restore default settings. This action cannot be undone.")
            }
        }
    }

    // MARK: - Section Builder
    @ViewBuilder
    private func preferencesSection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title.uppercased())
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.white.opacity(0.5))
                .padding(.leading, 4)

            VStack(spacing: 1) {
                content()
            }
            .background(AppColors.settingsRow)
            .cornerRadius(10)
        }
    }

    // MARK: - Data Management Functions

    private func resetPreferencesOnly() {
        // Reset preferences to defaults without deleting any data
        timeFormat = TimeFormatPreference.system.rawValue
        dateFormat = DateFormatPreference.system.rawValue
        timeZone = TimeZonePreference.device.rawValue
        defaultPage = DefaultPagePreference.home.rawValue
        captureMode = CapturePreference.camera.rawValue
        appState.setCaptureMode(CapturePreference.camera.rawValue)

        Haptics.success()
        statusMessage = "✓ Preferences restored to defaults"
        clearStatusAfterDelay()
    }

    private func deleteAllAircraft() {
        do {
            try modelContext.delete(model: CapturedAircraft.self)
            try modelContext.save()
            Haptics.success()
            statusMessage = "✓ All aircraft deleted"
            clearStatusAfterDelay()
        } catch {
            Haptics.error()
            statusMessage = "✗ Error: \(error.localizedDescription)"
        }
    }

    private func resetApp() {
        do {
            // Delete all data
            try modelContext.delete(model: CapturedAircraft.self)
            try modelContext.delete(model: User.self)
            try modelContext.save()

            // Reset preferences to defaults
            timeFormat = TimeFormatPreference.system.rawValue
            dateFormat = DateFormatPreference.system.rawValue
            timeZone = TimeZonePreference.device.rawValue
            defaultPage = DefaultPagePreference.home.rawValue
            captureMode = CapturePreference.camera.rawValue
            appState.setCaptureMode(CapturePreference.camera.rawValue)

            Haptics.success()
            statusMessage = "✓ App reset complete"
            clearStatusAfterDelay()
        } catch {
            Haptics.error()
            statusMessage = "✗ Error: \(error.localizedDescription)"
        }
    }

    private func clearStatusAfterDelay() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            statusMessage = nil
        }
    }
}

// MARK: - Preference Picker Row
/// Generic picker row for preferences with label, current value, and dropdown options
struct PreferencePickerRow: View {
    let label: String
    @Binding var selection: String
    let options: [(value: String, name: String, example: String)]

    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 15))
                .foregroundStyle(.white)
            Spacer()
            Menu {
                ForEach(options, id: \.value) { option in
                    Button(action: {
                        Haptics.selection()
                        selection = option.value
                    }) {
                        HStack {
                            Text(option.name)
                            if !option.example.isEmpty {
                                Text("(\(option.example))")
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            } label: {
                HStack(spacing: 4) {
                    Text(selectedDisplayName)
                        .font(.system(size: 15))
                        .foregroundStyle(AppColors.linkBlue)
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.system(size: 10))
                        .foregroundStyle(AppColors.linkBlue.opacity(0.7))
                }
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
    }

    private var selectedDisplayName: String {
        options.first(where: { $0.value == selection })?.name ?? "Unknown"
    }
}

// MARK: - Capture Mode Picker Row
/// Special picker for capture mode that syncs with AppState
struct CaptureModePickerRow: View {
    @Binding var selection: String
    var appState: AppState

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Default Capture Mode")
                    .font(.system(size: 15))
                    .foregroundStyle(.white)
                Text("Long-press center button to toggle")
                    .font(.system(size: 11))
                    .foregroundStyle(.white.opacity(0.5))
            }
            Spacer()
            Menu {
                ForEach(CapturePreference.allCases, id: \.rawValue) { option in
                    Button(action: {
                        Haptics.selection()
                        selection = option.rawValue
                        // Sync with AppState
                        appState.setCaptureMode(option.rawValue)
                    }) {
                        HStack {
                            Image(systemName: option.icon)
                            Text(option.displayName)
                            Text("- \(option.description)")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: selectedIcon)
                        .font(.system(size: 14))
                        .foregroundStyle(AppColors.linkBlue)
                    Text(selectedDisplayName)
                        .font(.system(size: 15))
                        .foregroundStyle(AppColors.linkBlue)
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.system(size: 10))
                        .foregroundStyle(AppColors.linkBlue.opacity(0.7))
                }
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
    }

    private var selectedDisplayName: String {
        CapturePreference(rawValue: selection)?.displayName ?? "Camera"
    }

    private var selectedIcon: String {
        CapturePreference(rawValue: selection)?.icon ?? "camera"
    }
}

// MARK: - About View
/// Professional about page with app description, legal links, and company info
struct AboutView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL

    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.settingsBackground.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // App Logo and Name
                        VStack(spacing: 12) {
                            Image("AirplaneID-icon")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 100, height: 100)
                                .clipShape(RoundedRectangle(cornerRadius: 22))
                                .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)

                            Text(AppConfig.appName)
                                .font(.system(size: 32, weight: .bold))
                                .foregroundStyle(.white)

                            Text("Version \(AppConfig.appVersion)")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(.white.opacity(0.5))
                        }
                        .padding(.top, 20)

                        // App Description
                        VStack(spacing: 16) {
                            Text("Your Personal Aircraft Identification Companion")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundStyle(AppColors.gold)
                                .multilineTextAlignment(.center)

                            VStack(alignment: .leading, spacing: 12) {
                                Text("Airplane-ID transforms aircraft sightings into a fun adventure of learning and discovery. Use your camera to instantly identify aircraft, build your personal collection of sightings, and become a master PlaneSpotter.")
                                    .font(.system(size: 15))
                                    .foregroundStyle(.white.opacity(0.8))
                                    .lineSpacing(4)

                                Text("Our advanced Hangar catalog lets you organize, filter, and explore your collection by manufacturer, type, airline, and more—tracking everything from vintage props to modern jets.")
                                    .font(.system(size: 15))
                                    .foregroundStyle(.white.opacity(0.8))
                                    .lineSpacing(4)

                                Text("Not only can you spot planes and log them, you can track them for years to come using our interactive map. Where is that plane now? We let you know. Tap any aircraft to find its current location or explore the world to see where your sightings have taken you.")
                                    .font(.system(size: 15))
                                    .foregroundStyle(.white.opacity(0.8))
                                    .lineSpacing(4)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 8)

                            Text("Join thousands of aviation enthusiasts documenting the skies.")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(.white.opacity(0.6))
                                .italic()
                                .multilineTextAlignment(.center)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 20)
                        .background(AppColors.settingsRow)
                        .cornerRadius(12)
                        .padding(.horizontal, 16)

                        // Legal Section
                        VStack(alignment: .leading, spacing: 8) {
                            Text("LEGAL")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(.white.opacity(0.5))
                                .padding(.leading, 4)

                            VStack(spacing: 1) {
                                AboutLinkRow(title: "Privacy Policy", icon: "hand.raised.fill") {
                                    if let url = URL(string: AppConfig.privacyPolicyURL) {
                                        openURL(url)
                                    }
                                }

                                AboutLinkRow(title: "Terms of Service", icon: "doc.text.fill") {
                                    if let url = URL(string: AppConfig.termsOfServiceURL) {
                                        openURL(url)
                                    }
                                }

                                AboutLinkRow(title: "End User License Agreement", icon: "signature") {
                                    if let url = URL(string: AppConfig.eulaURL) {
                                        openURL(url)
                                    }
                                }
                            }
                            .background(AppColors.settingsRow)
                            .cornerRadius(10)
                        }
                        .padding(.horizontal, 16)

                        // Support Section
                        VStack(alignment: .leading, spacing: 8) {
                            Text("SUPPORT")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(.white.opacity(0.5))
                                .padding(.leading, 4)

                            VStack(spacing: 1) {
                                AboutLinkRow(title: "Help Center", icon: "questionmark.circle.fill") {
                                    if let url = URL(string: AppConfig.supportURL) {
                                        openURL(url)
                                    }
                                }

                                AboutLinkRow(title: "Contact Support", icon: "envelope.fill") {
                                    if let url = URL(string: "mailto:\(AppConfig.supportEmail)") {
                                        openURL(url)
                                    }
                                }

                                AboutLinkRow(title: "Visit Our Website", icon: "globe") {
                                    if let url = URL(string: AppConfig.websiteURL) {
                                        openURL(url)
                                    }
                                }
                            }
                            .background(AppColors.settingsRow)
                            .cornerRadius(10)
                        }
                        .padding(.horizontal, 16)

                        // Company Info Footer
                        VStack(spacing: 8) {
                            Divider()
                                .background(.white.opacity(0.2))
                                .padding(.horizontal, 40)

                            Image(systemName: "building.2.fill")
                                .font(.system(size: 20))
                                .foregroundStyle(.white.opacity(0.3))
                                .padding(.top, 8)

                            Text(AppConfig.companyName)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(.white.opacity(0.6))

                            Text("© \(AppConfig.copyrightYear) \(AppConfig.companyName)")
                                .font(.system(size: 12))
                                .foregroundStyle(.white.opacity(0.4))

                            Text("All Rights Reserved")
                                .font(.system(size: 11))
                                .foregroundStyle(.white.opacity(0.3))

                            Text("Made with ❤️ for aviation enthusiasts")
                                .font(.system(size: 11))
                                .foregroundStyle(.white.opacity(0.3))
                                .padding(.top, 4)
                        }
                        .padding(.vertical, 20)

                        Spacer().frame(height: 20)
                    }
                }
            }
            .navigationTitle("About")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        Haptics.light()
                        dismiss()
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                            Text("Back")
                        }
                        .foregroundStyle(AppColors.linkBlue)
                    }
                }
            }
        }
    }
}

// MARK: - About Link Row
/// Tappable row for legal/support links in About page
struct AboutLinkRow: View {
    let title: String
    let icon: String
    let action: () -> Void

    var body: some View {
        Button(action: {
            Haptics.light()
            action()
        }) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundStyle(AppColors.linkBlue)
                    .frame(width: 24)

                Text(title)
                    .font(.system(size: 15))
                    .foregroundStyle(.white)

                Spacer()

                Image(systemName: "arrow.up.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.4))
            }
            .padding(.vertical, 14)
            .padding(.horizontal, 16)
        }
    }
}

// MARK: - Developer Tools View
/// Sub-page with all testing and debug options
struct DeveloperToolsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var showingDeleteConfirmation = false
    @State private var showingResetConfirmation = false
    @State private var statusMessage: String? = nil

    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.settingsBackground.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // Status message at top
                        if let message = statusMessage {
                            Text(message)
                                .font(.system(size: 16, weight: .medium))
                                .foregroundStyle(message.starts(with: "✓") ? AppColors.success : AppColors.error)
                                .padding(.top, 10)
                        }

                        // User Data Section
                        VStack(alignment: .leading, spacing: 15) {
                            Text("User Data")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 20)

                            Button(action: { importUserFromCSV() }) {
                                HStack(spacing: 16) {
                                    Image(systemName: "person.badge.plus")
                                        .font(.system(size: 22))
                                        .foregroundStyle(AppColors.info)
                                        .frame(width: 36)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Import User Profile")
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundStyle(.white)
                                        Text("Load from CSV")
                                            .font(.system(size: 13))
                                            .foregroundStyle(.white.opacity(0.6))
                                    }
                                    Spacer()
                                }
                                .padding(.vertical, 14)
                                .padding(.horizontal, 14)
                                .background(AppColors.settingsRow)
                                .cornerRadius(10)
                            }
                            .padding(.horizontal, 20)
                        }

                        // Import Aircraft Section
                        VStack(alignment: .leading, spacing: 15) {
                            Text("Import Aircraft")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 20)

                            VStack(spacing: 12) {
                                Button(action: { importFromCSV(count: 25) }) {
                                    DevToolButtonContent(title: "Import 25 Aircraft", subtitle: "Quick test", iconColor: "4CAF50")
                                }
                                Button(action: { importFromCSV(count: 100) }) {
                                    DevToolButtonContent(title: "Import 100 Aircraft", subtitle: "ENTHUSIAST level", iconColor: "8BC34A")
                                }
                                Button(action: { importFromCSV(count: 500) }) {
                                    DevToolButtonContent(title: "Import 500 Aircraft", subtitle: "ACE level", iconColor: "2196F3")
                                }
                                Button(action: { importFromCSV(count: 1100) }) {
                                    DevToolButtonContent(title: "Import 1,100 Aircraft", subtitle: "LEGEND level", iconColor: "9C27B0")
                                }
                                Button(action: { importFromCSV(count: 2000) }) {
                                    DevToolButtonContent(title: "Import All 2,000 Aircraft", subtitle: "Full map coverage", iconColor: "FF9800")
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                        .padding(.top, 10)


                        // Danger Zone Section
                        VStack(alignment: .leading, spacing: 15) {
                            Text("Danger Zone")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundStyle(AppColors.error)
                                .padding(.horizontal, 20)

                            VStack(spacing: 12) {
                                Button(action: { showingDeleteConfirmation = true }) {
                                    HStack(spacing: 16) {
                                        Image(systemName: "trash")
                                            .font(.system(size: 22))
                                            .foregroundStyle(AppColors.error)
                                            .frame(width: 36)
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text("Delete All Aircraft")
                                                .font(.system(size: 16, weight: .semibold))
                                                .foregroundStyle(.white)
                                            Text("Remove aircraft records only")
                                                .font(.system(size: 13))
                                                .foregroundStyle(.white.opacity(0.6))
                                        }
                                        Spacer()
                                    }
                                    .padding(.vertical, 14)
                                    .padding(.horizontal, 14)
                                    .background(AppColors.settingsRow)
                                    .cornerRadius(10)
                                }

                                Button(action: { showingResetConfirmation = true }) {
                                    HStack(spacing: 16) {
                                        Image(systemName: "arrow.counterclockwise")
                                            .font(.system(size: 22))
                                            .foregroundStyle(AppColors.warning)
                                            .frame(width: 36)
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text("Reset App")
                                                .font(.system(size: 16, weight: .semibold))
                                                .foregroundStyle(.white)
                                            Text("Clear ALL data")
                                                .font(.system(size: 13))
                                                .foregroundStyle(.white.opacity(0.6))
                                        }
                                        Spacer()
                                    }
                                    .padding(.vertical, 14)
                                    .padding(.horizontal, 14)
                                    .background(AppColors.settingsRow)
                                    .cornerRadius(10)
                                }
                            }
                            .padding(.horizontal, 20)
                        }

                        Spacer().frame(height: 40)
                    }
                }
            }
            .navigationTitle("Developer Tools")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                            Text("Back")
                        }
                        .foregroundStyle(AppColors.linkBlue)
                    }
                }
            }
            .confirmationDialog("Delete All Aircraft?", isPresented: $showingDeleteConfirmation, titleVisibility: .visible) {
                Button("Delete All Aircraft", role: .destructive) { deleteAllAircraft() }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("This will permanently delete all captured aircraft records.")
            }
            .confirmationDialog("Reset App?", isPresented: $showingResetConfirmation, titleVisibility: .visible) {
                Button("Reset Everything", role: .destructive) { resetApp() }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("This will delete ALL data including aircraft and user profiles.")
            }
        }
    }

    // MARK: - Data Functions

    private func importFromCSV(count: Int) {
        statusMessage = "Importing \(count) aircraft..."

        // Use Swift concurrency for thread-safe CSV import
        Task {
            // Parse CSV in background
            let result = await parseCSVInBackground(count: count)

            // Insert into SwiftData on main actor
            await MainActor.run {
                switch result {
                case .success(let parsedData):
                    insertParsedAircraft(parsedData)
                case .failure(let error):
                    statusMessage = "✗ \(error.localizedDescription)"
                }
            }
        }
    }

    /// Parse CSV file in background - returns parsed data or error
    private func parseCSVInBackground(count: Int) async -> Result<[ParsedAircraftData], CSVImportError> {
        await Task.detached(priority: .userInitiated) {
            guard let csvURL = Bundle.main.url(forResource: "AirplaneID-TestData", withExtension: "csv") else {
                return .failure(.fileNotFound)
            }

            do {
                let csvContent = try String(contentsOf: csvURL, encoding: .utf8)
                let lines = csvContent.components(separatedBy: .newlines).filter { !$0.isEmpty }
                guard lines.count > 1 else {
                    return .failure(.emptyFile)
                }

                let dataLines = Array(lines.dropFirst().prefix(count))
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
                dateFormatter.timeZone = TimeZone(identifier: "UTC")

                var parsedData: [ParsedAircraftData] = []

                for line in dataLines {
                    let columns = CSVParser.parseLine(line)
                    guard columns.count >= 15 else { continue }

                    let captureDate = dateFormatter.date(from: "\(columns[10]) \(columns[11])") ?? Date()
                    parsedData.append(ParsedAircraftData(
                        captureDate: captureDate,
                        longitude: Double(columns[9]) ?? 0.0,
                        latitude: Double(columns[8]) ?? 0.0,
                        year: Int(columns[12]),
                        month: Int(columns[13]),
                        day: Int(columns[14]),
                        icao: columns[0],
                        manufacturer: columns[1],
                        model: columns[2],
                        engineType: columns[4].isEmpty ? nil : Int(columns[4]),
                        engineCount: Int(columns[5]) ?? 1,
                        registration: columns[3],
                        aircraftType: columns[6].isEmpty ? nil : columns[6],
                        aircraftClassification: columns[7].isEmpty ? nil : Int(columns[7]),
                        rating: [nil, 0.5, 1.0, 1.5, 2.0, 2.5, 3.0, 3.5, 4.0, 4.5, 5.0].randomElement() ?? nil,
                        thumbsUp: [nil, true, false].randomElement() ?? nil
                    ))
                }

                return .success(parsedData)
            } catch {
                return .failure(.parseError(error.localizedDescription))
            }
        }.value
    }

    /// Insert parsed aircraft data into SwiftData (must be called on MainActor)
    @MainActor
    private func insertParsedAircraft(_ parsedData: [ParsedAircraftData]) {
        do {
            for data in parsedData {
                let aircraft = CapturedAircraft(
                    captureTime: data.captureDate,
                    captureDate: data.captureDate,
                    year: data.year ?? 0,
                    month: data.month ?? 0,
                    day: data.day ?? 0,
                    gpsLongitude: data.longitude,
                    gpsLatitude: data.latitude,
                    iPhotoReference: "test-import-\(UUID().uuidString)",
                    icao: data.icao ?? "",
                    manufacturer: data.manufacturer ?? "",
                    model: data.model ?? "",
                    registration: data.registration,
                    aircraftClassification: data.aircraftClassification,
                    aircraftType: data.aircraftType,
                    engineType: data.engineType,
                    engineCount: data.engineCount,
                    rating: data.rating,
                    thumbsUp: data.thumbsUp
                )
                modelContext.insert(aircraft)
            }
            try modelContext.save()
            statusMessage = "✓ Imported \(parsedData.count) aircraft"
            Task {
                try? await Task.sleep(for: .seconds(3))
                await MainActor.run { statusMessage = nil }
            }
        } catch {
            statusMessage = "✗ Error saving: \(error.localizedDescription)"
        }
    }

    private func importUserFromCSV() {
        statusMessage = "Importing user profile..."

        guard let csvURL = Bundle.main.url(forResource: "AirplaneID-UserData", withExtension: "csv") else {
            statusMessage = "✗ User CSV not found"
            return
        }

        do {
            try modelContext.delete(model: User.self)

            let csvContent = try String(contentsOf: csvURL, encoding: .utf8)
            let lines = csvContent.components(separatedBy: .newlines).filter { !$0.isEmpty }
            guard lines.count > 1 else {
                statusMessage = "✗ User CSV is empty"
                return
            }

            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"

            let columns = CSVParser.parseLine(lines[1])
            guard columns.count >= 10 else {
                statusMessage = "✗ Invalid CSV format"
                return
            }

            let user = User(
                name: columns[0],
                email: columns[1],
                phone: columns[2].isEmpty ? nil : columns[2],
                passwordHash: columns[3].isEmpty ? nil : columns[3],
                passwordRequired: columns[4].lowercased() == "true",
                faceIDEnabled: columns[5].lowercased() == "true",
                displayName: columns[6],
                memberDate: dateFormatter.date(from: columns[7]) ?? Date(),
                homeAirport: columns[8].isEmpty ? nil : columns[8],
                memberLevel: columns[9]
            )

            modelContext.insert(user)
            try modelContext.save()

            statusMessage = "✓ User imported: \(columns[6])"
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) { statusMessage = nil }
        } catch {
            statusMessage = "✗ Error: \(error.localizedDescription)"
        }
    }

    private func deleteAllAircraft() {
        do {
            try modelContext.delete(model: CapturedAircraft.self)
            try modelContext.save()
            statusMessage = "✓ All aircraft deleted"
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) { statusMessage = nil }
        } catch {
            statusMessage = "✗ Error: \(error.localizedDescription)"
        }
    }

    private func resetApp() {
        do {
            try modelContext.delete(model: CapturedAircraft.self)
            try modelContext.delete(model: User.self)
            try modelContext.save()
            statusMessage = "✓ App reset complete"
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) { statusMessage = nil }
        } catch {
            statusMessage = "✗ Error: \(error.localizedDescription)"
        }
    }
}

// MARK: - Dev Tool Button Content
struct DevToolButtonContent: View {
    let title: String
    let subtitle: String
    let iconColor: String

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: "square.and.arrow.down")
                .font(.system(size: 22))
                .foregroundStyle(Color(hex: iconColor))
                .frame(width: 36)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                Text(subtitle)
                    .font(.system(size: 13))
                    .foregroundStyle(.white.opacity(0.6))
            }
            Spacer()
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 14)
        .background(AppColors.settingsRow)
        .cornerRadius(10)
    }
}

// MARK: - Settings Row Content (Button version of SettingsRow)
struct SettingsRowContent: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 22))
                .foregroundStyle(AppColors.linkBlue)
                .frame(width: 36)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                Text(subtitle)
                    .font(.system(size: 13))
                    .foregroundStyle(.white.opacity(0.6))
                    .lineLimit(1)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white.opacity(0.4))
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 14)
        .background(AppColors.settingsRow)
        .cornerRadius(10)
    }
}

// MARK: - Previews
#Preview("Portrait") {
    SettingsPortraitView(showingAccountSettings: .constant(false))
        .environment(AppState())
}

#Preview("Landscape Left", traits: .landscapeLeft) {
    GeometryReader { geometry in
        SettingsLandscapeLeftView(geometry: geometry, showingAccountSettings: .constant(false))
    }
    .environment(AppState())
}

#Preview("Landscape Right", traits: .landscapeRight) {
    GeometryReader { geometry in
        SettingsLandscapeRightView(geometry: geometry, showingAccountSettings: .constant(false))
    }
    .environment(AppState())
}
