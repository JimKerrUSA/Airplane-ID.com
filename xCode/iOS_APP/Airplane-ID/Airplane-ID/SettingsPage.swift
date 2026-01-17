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
    @State private var showingSystemSettings = false
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
                Button(action: { showingAccountSettings = true }) {
                    SettingsRowContent(icon: "person.circle", title: "Account Settings", subtitle: "Manage your account")
                }

                // App Preferences
                Button(action: { showingAppPreferences = true }) {
                    SettingsRowContent(icon: "square.3.layers.3d", title: "App Preferences", subtitle: "Configure application behavior")
                }

                // System
                Button(action: { showingSystemSettings = true }) {
                    SettingsRowContent(icon: "switch.2", title: "System", subtitle: "Modify system settings")
                }

                // About
                Button(action: { showingAbout = true }) {
                    SettingsRowContent(icon: "info.circle", title: "About", subtitle: "Version and credits")
                }

                // Developer Tools (only if enabled)
                if AppConfig.developerToolsEnabled {
                    Button(action: { showingDeveloperTools = true }) {
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
        .sheet(isPresented: $showingSystemSettings) {
            SystemSettingsView()
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
                                ProfileDetailRow(label: "Member Since", value: formatDate(user.memberDate))
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

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
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
struct AppPreferencesView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.settingsBackground.ignoresSafeArea()

                VStack(spacing: 20) {
                    Image(systemName: "square.3.layers.3d")
                        .font(.system(size: 60))
                        .foregroundStyle(AppColors.linkBlue)

                    Text("App Preferences")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(.white)

                    Text("Coming Soon")
                        .font(.system(size: 16))
                        .foregroundStyle(.white.opacity(0.6))
                }
            }
            .navigationTitle("App Preferences")
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
        }
    }
}

// MARK: - System Settings View (Placeholder)
struct SystemSettingsView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.settingsBackground.ignoresSafeArea()

                VStack(spacing: 20) {
                    Image(systemName: "switch.2")
                        .font(.system(size: 60))
                        .foregroundStyle(AppColors.linkBlue)

                    Text("System Settings")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(.white)

                    Text("Coming Soon")
                        .font(.system(size: 16))
                        .foregroundStyle(.white.opacity(0.6))
                }
            }
            .navigationTitle("System")
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
        }
    }
}

// MARK: - About View (Placeholder)
struct AboutView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.settingsBackground.ignoresSafeArea()

                VStack(spacing: 20) {
                    Image(systemName: "airplane")
                        .font(.system(size: 60))
                        .foregroundStyle(AppColors.orange)

                    Text("Airplane-ID")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(.white)

                    Text("Version 1.0.0")
                        .font(.system(size: 16))
                        .foregroundStyle(.white.opacity(0.6))

                    Text("© 2026 LJ Aero")
                        .font(.system(size: 14))
                        .foregroundStyle(.white.opacity(0.4))
                        .padding(.top, 20)
                }
            }
            .navigationTitle("About")
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

        // Parse CSV on background thread, then insert on main thread
        DispatchQueue.global(qos: .userInitiated).async {
            guard let csvURL = Bundle.main.url(forResource: "AirplaneID-TestData", withExtension: "csv") else {
                DispatchQueue.main.async { self.statusMessage = "✗ CSV file not found" }
                return
            }

            do {
                let csvContent = try String(contentsOf: csvURL, encoding: .utf8)
                let lines = csvContent.components(separatedBy: .newlines).filter { !$0.isEmpty }
                guard lines.count > 1 else {
                    DispatchQueue.main.async { self.statusMessage = "✗ CSV file is empty" }
                    return
                }

                let dataLines = Array(lines.dropFirst().prefix(count))
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
                dateFormatter.timeZone = TimeZone(identifier: "UTC")

                // Parse CSV into raw data tuples on background thread
                // (captureDate, longitude, latitude, year, month, day, icao, manufacturer, model, engineType, engineCount, registration, rating, thumbsUp)
                var parsedData: [(Date, Double, Double, Int?, Int?, Int?, String?, String?, String?, String?, Int?, String?, Bool?, Bool?)] = []

                for line in dataLines {
                    let columns = self.parseCSVLine(line)
                    guard columns.count >= 13 else { continue }

                    let captureDate = dateFormatter.date(from: "\(columns[8]) \(columns[9])") ?? Date()
                    parsedData.append((
                        captureDate,
                        Double(columns[7]) ?? 0.0,  // longitude
                        Double(columns[6]) ?? 0.0,  // latitude
                        Int(columns[10]),           // year
                        Int(columns[11]),           // month
                        Int(columns[12]),           // day
                        columns[0],                 // icao
                        columns[1],                 // manufacturer
                        columns[2],                 // model
                        columns[4],                 // engineType
                        Int(columns[5]) ?? 1,       // engineCount
                        columns[3],                 // registration
                        [nil, true, false].randomElement()!,  // rating
                        [nil, true, false].randomElement()!  // thumbsUp
                    ))
                }

                // Insert into SwiftData on main thread (thread-safe)
                DispatchQueue.main.async {
                    do {
                        for data in parsedData {
                            let aircraft = CapturedAircraft(
                                // Required - from device
                                captureTime: data.0,
                                captureDate: data.0,
                                year: data.3 ?? 0,
                                month: data.4 ?? 0,
                                day: data.5 ?? 0,
                                gpsLongitude: data.1,
                                gpsLatitude: data.2,
                                iPhotoReference: "test-import-\(UUID().uuidString)",  // Placeholder for test data
                                // Required - from AI
                                icao: data.6 ?? "",
                                manufacturer: data.7 ?? "",
                                model: data.8 ?? "",
                                // Optional
                                registration: data.11,
                                engineType: data.9,
                                engineCount: data.10,
                                rating: data.12,
                                thumbsUp: data.13
                            )
                            self.modelContext.insert(aircraft)
                        }
                        try self.modelContext.save()
                        self.statusMessage = "✓ Imported \(parsedData.count) aircraft"
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3) { self.statusMessage = nil }
                    } catch {
                        self.statusMessage = "✗ Error saving: \(error.localizedDescription)"
                    }
                }
            } catch {
                DispatchQueue.main.async { self.statusMessage = "✗ Error: \(error.localizedDescription)" }
            }
        }
    }

    private func parseCSVLine(_ line: String) -> [String] {
        var result: [String] = []
        var current = ""
        var inQuotes = false
        for char in line {
            if char == "\"" { inQuotes.toggle() }
            else if char == "," && !inQuotes {
                result.append(current.trimmingCharacters(in: .whitespaces))
                current = ""
            } else { current.append(char) }
        }
        result.append(current.trimmingCharacters(in: .whitespaces))
        return result
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

            let columns = parseCSVLine(lines[1])
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
