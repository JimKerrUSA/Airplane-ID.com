//
//  SettingsPage.swift
//  Airplane-ID
//
//  Created by Jim Kerr on 1/15/26.
//

import SwiftUI

// MARK: - Settings Page
/// Settings page with dark background (#121516)
/// Custom orientation handling to ensure dark background covers entire screen including footer area
struct SettingsPage: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        GeometryReader { geometry in
            let isLandscape = geometry.size.width > geometry.size.height
            let safeArea = geometry.safeAreaInsets
            let isLandscapeRight = safeArea.leading > safeArea.trailing

            if isLandscape {
                if isLandscapeRight {
                    // Landscape Right - footer on right
                    SettingsLandscapeRightView(geometry: geometry)
                } else {
                    // Landscape Left - footer on left
                    SettingsLandscapeLeftView(geometry: geometry)
                }
            } else {
                // Portrait
                SettingsPortraitView()
            }
        }
    }
}

// MARK: - Settings Portrait View
struct SettingsPortraitView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                TopMenuView()

                ZStack(alignment: .bottom) {
                    // Dark background for entire content area
                    Color(hex: "121516")
                        .ignoresSafeArea()

                    SettingsContent()

                    BottomMenuView()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .background(Color(hex: "121516"))
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

    var body: some View {
        NavigationStack {
            ZStack {
                // Dark background for entire screen
                Color(hex: "121516")
                    .ignoresSafeArea()

                // Main layout with header
                VStack(spacing: 0) {
                    TopMenuViewLandscape()

                    // Content area - ScrollView needs to fill remaining space
                    ScrollView {
                        SettingsScrollContent()
                            .padding(.leading, 120)
                    }
                }

                // Left side navigation bar
                BottomMenuViewLandscape()
                    .position(x: 50, y: (geometry.size.height + geometry.size.width) / 4 - 82)
                    .offset(x: 20)
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

    var body: some View {
        NavigationStack {
            ZStack {
                // Dark background for entire screen
                Color(hex: "121516")
                    .ignoresSafeArea()

                // Main layout with header
                VStack(spacing: 0) {
                    TopMenuViewLandscape()

                    // Content area - ScrollView needs to fill remaining space
                    ScrollView {
                        SettingsScrollContent()
                            .padding(.trailing, 120)
                    }
                }

                // Right side navigation bar
                BottomMenuViewLandscape()
                    .position(x: geometry.size.width - 50, y: (geometry.size.height + geometry.size.width) / 4 - 82)
                    .offset(x: 100)
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
    var body: some View {
        ScrollView {
            SettingsScrollContent()
        }
    }
}

// MARK: - Settings Scroll Content (Inner content without ScrollView)
/// The actual settings content - used inside ScrollView
/// Separated so landscape views can manage their own ScrollView
struct SettingsScrollContent: View {
    var body: some View {
        VStack {
            Spacer().frame(height: 20)

            // Settings title
            Text("Settings")
                .font(.system(size: 32, weight: .bold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)

            Spacer().frame(height: 30)

            // Settings menu items
            VStack(spacing: 15) {
                SettingsRow(icon: "person.circle", title: "Account", subtitle: "Manage your account")
                SettingsRow(icon: "bell", title: "Notifications", subtitle: "Configure alerts")
                SettingsRow(icon: "icloud", title: "Sync", subtitle: "Cloud backup settings")
                SettingsRow(icon: "questionmark.circle", title: "Help", subtitle: "FAQ and support")
                SettingsRow(icon: "info.circle", title: "About", subtitle: "Version and credits")
            }
            .padding(.horizontal, 20)

            Spacer().frame(height: 120) // Space for footer
        }
    }
}

// MARK: - Settings Row Component
/// Reusable row for settings menu items
struct SettingsRow: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        HStack(spacing: 16) {
            // Icon
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundStyle(Color(hex: "F27C31"))
                .frame(width: 40)

            // Text
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.white)
                Text(subtitle)
                    .font(.system(size: 14))
                    .foregroundStyle(.white.opacity(0.6))
            }

            Spacer()

            // Chevron
            Image(systemName: "chevron.right")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.white.opacity(0.4))
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 16)
        .background(Color(hex: "1D1E21"))
        .cornerRadius(12)
    }
}

// MARK: - Previews
#Preview("Portrait") {
    SettingsPortraitView()
        .environment(AppState())
}

#Preview("Landscape Left", traits: .landscapeLeft) {
    GeometryReader { geometry in
        SettingsLandscapeLeftView(geometry: geometry)
    }
    .environment(AppState())
}

#Preview("Landscape Right", traits: .landscapeRight) {
    GeometryReader { geometry in
        SettingsLandscapeRightView(geometry: geometry)
    }
    .environment(AppState())
}
