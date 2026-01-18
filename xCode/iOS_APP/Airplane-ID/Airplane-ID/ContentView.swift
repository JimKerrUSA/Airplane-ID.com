//
//  ContentView.swift
//  Airplane-ID
//
//  Created by Jim Kerr on 1/15/26.
//

import SwiftUI
import SwiftData
import UIKit

// MARK: - Navigation Destinations
enum NavigationDestination: String, CaseIterable {
    case home = "Home"
    case maps = "Maps"
    case camera = "Camera"
    case hangar = "Hangar"
    case settings = "Settings"
    case journey = "Journey"
}

// MARK: - App Configuration
/// Global configuration flags
struct AppConfig {
    /// Developer tools are automatically enabled in DEBUG builds only.
    /// In Release builds (App Store), this is always false.
    static var developerToolsEnabled: Bool {
        #if DEBUG
        return true
        #else
        return false
        #endif
    }
}

// MARK: - Screen Scale for Responsive Design
/// Design baseline: iPhone 14 Pro (393 x 852 points in portrait)
/// Automatically detects orientation and uses appropriate baseline
struct ScreenScale {
    let width: CGFloat
    let height: CGFloat

    // Design baseline dimensions (iPhone 14 Pro portrait)
    static let baselinePortraitWidth: CGFloat = 393
    static let baselinePortraitHeight: CGFloat = 852

    // Detect if we're in landscape mode
    var isLandscape: Bool { width > height }

    // Use appropriate baseline dimensions based on orientation
    private var baselineWidth: CGFloat {
        isLandscape ? Self.baselinePortraitHeight : Self.baselinePortraitWidth
    }
    private var baselineHeight: CGFloat {
        isLandscape ? Self.baselinePortraitWidth : Self.baselinePortraitHeight
    }

    // Scale factors relative to baseline
    var widthScale: CGFloat { width / baselineWidth }
    var heightScale: CGFloat { height / baselineHeight }

    // Use the smaller scale to ensure content fits without clipping
    // Cap at 1.0 - only scale DOWN, never scale UP (which would cause clipping)
    var scale: CGFloat { min(1.0, min(widthScale, heightScale)) }

    // Helper to scale a dimension
    func scaled(_ value: CGFloat) -> CGFloat { value * scale }

    // Helper to scale font size (uses slightly less aggressive scaling for readability)
    func scaledFont(_ size: CGFloat) -> CGFloat {
        // Font scaling is less aggressive - use 70% of the scale difference
        let fontScale = 1.0 + (scale - 1.0) * 0.7
        return size * fontScale
    }

    // Default (1:1 scale for previews)
    static let `default` = ScreenScale(width: baselinePortraitWidth, height: baselinePortraitHeight)
}

// Environment key for screen scale
struct ScreenScaleKey: EnvironmentKey {
    static let defaultValue: ScreenScale = .default
}

extension EnvironmentValues {
    var screenScale: ScreenScale {
        get { self[ScreenScaleKey.self] }
        set { self[ScreenScaleKey.self] = newValue }
    }
}

// MARK: - Global App State
@Observable
class AppState {
    var status: String = "NEWBIE" // Updated by HomePage based on aircraft count
    var search: String = ""
    var captureMode: String = "camera" // Options: "camera" or "photo.stack"
    var totalAircraftCount: Int = 0 // Updated by HomePage from database
    var totalTypes: Int = 0 // Updated by HomePage from database
    var currentScreen: NavigationDestination // Track current navigation

    init() {
        // Read default page preference from UserDefaults
        let defaultPageKey = "appPref_defaultPage"
        let savedDefault = UserDefaults.standard.string(forKey: defaultPageKey) ?? "home"

        // Map preference string to NavigationDestination
        switch savedDefault {
        case "hangar": currentScreen = .hangar
        case "maps": currentScreen = .maps
        case "journey": currentScreen = .journey
        case "camera": currentScreen = .camera
        default: currentScreen = .home
        }
    }

    // Map navigation - set these before navigating to .maps to center on a specific location
    var mapTargetLatitude: Double?
    var mapTargetLongitude: Double?
    var mapTargetAircraftICAO: String? // ICAO code for showing correct aircraft icon

    /// Navigate to Maps page centered on a specific coordinate
    func navigateToMap(latitude: Double, longitude: Double, aircraftICAO: String? = nil) {
        mapTargetLatitude = latitude
        mapTargetLongitude = longitude
        mapTargetAircraftICAO = aircraftICAO
        currentScreen = .maps
    }

    /// Clear map target after navigation
    func clearMapTarget() {
        mapTargetLatitude = nil
        mapTargetLongitude = nil
        mapTargetAircraftICAO = nil
    }

    /// Display title for the current page shown in header
    /// Add new pages to this dictionary - defaults to enum rawValue uppercased as reminder
    var pageDisplayTitle: String {
        let titles: [NavigationDestination: String] = [
            .home: "HOME",
            .maps: "MAPS",
            .camera: "CAMERA",
            .hangar: "HANGAR",
            .settings: "SETTINGS",
            .journey: "STATUS"
        ]
        return titles[currentScreen] ?? currentScreen.rawValue.uppercased()
    }
}

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AppState.self) private var appState
    
    var body: some View {
        PortraitTemplate {
            Spacer()

            // Main page content will go here

            Spacer()
        }
    }
}

// MARK: - Top Menu Component
struct TopMenuView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        ZStack {
            AppColors.darkBlue

            // Header content - person icon left, page title right
            HStack(alignment: .bottom) {
                // Status indicator (left side)
                VStack(spacing: 2) {
                    Image(systemName: "person")
                        .font(.system(size: 32))
                        .foregroundStyle(.white)

                    Text(appState.status)
                        .font(.custom("Helvetica", size: 11))
                        .foregroundStyle(.white)
                }
                .onTapGesture {
                    Haptics.navigation()
                    appState.currentScreen = .journey
                }
                .padding(.leading, 16)

                Spacer()

                // Page title (right side) - bottom aligned with status text
                Text(appState.pageDisplayTitle)
                    .font(.custom("Helvetica", size: 11))
                    .foregroundStyle(.white)
                    .padding(.trailing, 16)
            }
            .padding(.top, 28)
        }
        .frame(height: 93)
        .frame(maxWidth: .infinity)
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundStyle(Color.gray)
                .ignoresSafeArea(),
            alignment: .bottom
        )
    }
}

// MARK: - Bottom Menu Component
struct BottomMenuView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        GeometryReader { geo in
            let menuWidth = max(min(geo.size.width * 0.95, 340), 160) // 95% of screen, min 160, max 340
            let cameraSize: CGFloat = 70
            let sideWidth = max((menuWidth - cameraSize) / 2, 40) // Prevent negative width
            let barOffset: CGFloat = -25 // Blue bar position (higher up)
            let iconsOffset: CGFloat = -15 // Icons/camera position

            ZStack(alignment: .bottom) {
                // Navigation bar rectangle - positioned behind camera button
                RoundedRectangle(cornerRadius: 40)
                    .fill(AppColors.darkBlue)
                    .frame(width: menuWidth, height: 50)
                    .overlay(
                        RoundedRectangle(cornerRadius: 40)
                            .stroke(Color.gray, lineWidth: 1)
                    )
                    .offset(y: barOffset)

                // Navigation icons in horizontal layout
                HStack(spacing: 0) {
                    // Left side icons
                    HStack {
                        Spacer()

                        // Home icon
                        VStack(spacing: 2) {
                            Image(systemName: "house")
                                .font(.system(size: 22, weight: .regular))
                                .foregroundStyle(AppColors.white)

                            Text("Home")
                                .font(.system(size: 9))
                                .foregroundStyle(AppColors.white)
                        }
                        .onTapGesture {
                            Haptics.navigation()
                            appState.currentScreen = .home
                        }

                        Spacer()

                        // Hangar icon
                        VStack(spacing: 2) {
                            Image(systemName: "airplane.departure")
                                .font(.system(size: 22, weight: .regular))
                                .foregroundStyle(AppColors.white)

                            Text("Hangar")
                                .font(.system(size: 9))
                                .foregroundStyle(AppColors.white)
                        }
                        .onTapGesture {
                            Haptics.navigation()
                            appState.currentScreen = .hangar
                        }

                        Spacer()
                    }
                    .frame(width: sideWidth)

                    // Center camera button
                    ZStack {
                        Circle()
                            .fill(AppColors.white)
                            .frame(width: cameraSize, height: cameraSize)
                            .overlay(
                                Circle()
                                    .stroke(AppColors.darkGray, lineWidth: 4)
                            )

                        // Capture mode icon
                        Image(systemName: appState.captureMode)
                            .font(.system(size: 24, weight: .regular))
                            .foregroundStyle(AppColors.mediumGray)
                    }
                    .frame(width: cameraSize)
                    .onTapGesture {
                        Haptics.navigation()
                        appState.currentScreen = .camera
                    }

                    // Right side icons
                    HStack {
                        Spacer()

                        // Maps icon
                        VStack(spacing: 2) {
                            Image(systemName: "map")
                                .font(.system(size: 22, weight: .regular))
                                .foregroundStyle(AppColors.white)

                            Text("Maps")
                                .font(.system(size: 9))
                                .foregroundStyle(AppColors.white)
                        }
                        .onTapGesture {
                            Haptics.navigation()
                            appState.currentScreen = .maps
                        }

                        Spacer()

                        // Settings icon
                        VStack(spacing: 2) {
                            Image(systemName: "gearshape")
                                .font(.system(size: 22, weight: .regular))
                                .foregroundStyle(AppColors.white)

                            Text("Settings")
                                .font(.system(size: 9))
                                .foregroundStyle(AppColors.white)
                        }
                        .onTapGesture {
                            Haptics.navigation()
                            appState.currentScreen = .settings
                        }

                        Spacer()
                    }
                    .frame(width: sideWidth)
                }
                .frame(width: menuWidth)
                .offset(y: iconsOffset) // Icons positioned lower than bar
            }
            .frame(maxWidth: .infinity)
            .frame(height: cameraSize + 10)
        }
        .frame(height: 80)
        .padding(.bottom, -5)
    }
}

// MARK: - Top Menu Component - Landscape Version
/// Landscape version of the top menu - compact without search bar
struct TopMenuViewLandscape: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        ZStack {
            AppColors.darkBlue
                .ignoresSafeArea(edges: .horizontal)

            // Header content - person icon left, page title right
            HStack(alignment: .bottom) {
                // Status indicator (left side)
                VStack(spacing: 2) {
                    Image(systemName: "person")
                        .font(.system(size: 28))
                        .foregroundStyle(.white)

                    Text(appState.status)
                        .font(.custom("Helvetica", size: 10))
                        .foregroundStyle(.white)
                }
                .onTapGesture {
                    Haptics.navigation()
                    appState.currentScreen = .journey
                }
                .padding(.leading, 16)

                Spacer()

                // Page title (right side) - bottom aligned with status text
                Text(appState.pageDisplayTitle)
                    .font(.custom("Helvetica", size: 10))
                    .foregroundStyle(.white)
                    .padding(.trailing, 86)
            }
        }
        .frame(height: 50)
        .frame(maxWidth: .infinity)
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundStyle(Color.gray)
                .ignoresSafeArea(),
            alignment: .bottom
        )
    }
}

// MARK: - Bottom Menu Component - Landscape Version
/// Landscape version of the bottom menu - vertical layout for side positioning
struct BottomMenuViewLandscape: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        ZStack(alignment: .center) {
            // Navigation bar rectangle - vertical orientation
            RoundedRectangle(cornerRadius: 50)
                .fill(AppColors.darkBlue)
                .frame(width: 65, height: 385)
                .overlay(
                    RoundedRectangle(cornerRadius: 50)
                        .stroke(Color.gray, lineWidth: 1)
                )

            // Navigation icons in vertical layout
            VStack(spacing: 0) {
                // Top section
                VStack {
                    Spacer()

                    // Home icon
                    VStack(spacing: 4) {
                        Image(systemName: "house")
                            .font(.system(size: 35, weight: .regular))
                            .foregroundStyle(AppColors.white)

                        Text("Home")
                            .font(.system(size: 12))
                            .foregroundStyle(AppColors.white)
                    }
                    .onTapGesture {
                        Haptics.navigation()
                        appState.currentScreen = .home
                    }

                    Spacer()

                    // Maps icon
                    VStack(spacing: 4) {
                        Image(systemName: "map")
                            .font(.system(size: 35, weight: .regular))
                            .foregroundStyle(AppColors.white)

                        Text("Maps")
                            .font(.system(size: 12))
                            .foregroundStyle(AppColors.white)
                    }
                    .onTapGesture {
                        Haptics.navigation()
                        appState.currentScreen = .maps
                    }

                    Spacer()
                }
                .frame(height: 142.5)

                // Center camera button
                ZStack {
                    Circle()
                        .fill(AppColors.white)
                        .frame(width: 100, height: 100)
                        .overlay(
                            Circle()
                                .stroke(AppColors.darkGray, lineWidth: 5)
                        )

                    // Capture mode icon
                    Image(systemName: appState.captureMode)
                        .font(.system(size: 35, weight: .regular))
                        .foregroundStyle(AppColors.mediumGray)
                }
                .frame(width: 100, height: 100)
                .onTapGesture {
                    Haptics.navigation()
                    appState.currentScreen = .camera
                }

                // Bottom section
                VStack {
                    Spacer()

                    // Hangar icon
                    VStack(spacing: 4) {
                        Image(systemName: "airplane.departure")
                            .font(.system(size: 35, weight: .regular))
                            .foregroundStyle(AppColors.white)

                        Text("Hangar")
                            .font(.system(size: 12))
                            .foregroundStyle(AppColors.white)
                    }
                    .onTapGesture {
                        Haptics.navigation()
                        appState.currentScreen = .hangar
                    }

                    Spacer()

                    // Settings icon
                    VStack(spacing: 4) {
                        Image(systemName: "gearshape")
                            .font(.system(size: 35, weight: .regular))
                            .foregroundStyle(AppColors.white)

                        Text("Settings")
                            .font(.system(size: 12))
                            .foregroundStyle(AppColors.white)
                    }
                    .onTapGesture {
                        Haptics.navigation()
                        appState.currentScreen = .settings
                    }

                    Spacer()
                }
                .frame(height: 142.5)
            }
            .frame(height: 385)
        }
        .frame(width: 100, height: 385)
    }
}

// MARK: - Portrait Template
/// Standard page template for PORTRAIT orientation with top menu, bottom menu, and consistent styling
/// Use this as the base for all portrait pages in the app
struct PortraitTemplate<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Top Menu Bar - Reusable component
                TopMenuView()

                // Main content area
                ZStack(alignment: .bottom) {
                    // Content area
                    VStack {
                        content
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                    // Bottom Navigation Bar - Reusable component
                    BottomMenuView()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .background(AppColors.primaryBlue)
            .ignoresSafeArea()
#if os(iOS)
            .navigationBarHidden(true)
#endif
        }
    }
}

// MARK: - Landscape Left Template
/// Template for LEFT LANDSCAPE orientation (footer on LEFT side)
/// Phone rotated with device top on RIGHT side
struct LandscapeLeftTemplate<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                ZStack {
                    // Background color
                    AppColors.primaryBlue
                        .ignoresSafeArea()

                    // Main layout with header
                    VStack(spacing: 0) {
                        // Top Menu Bar - Landscape version
                        TopMenuViewLandscape()

                        // Content area
                        VStack {
                            content
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }

                    // Left side navigation bar - adjusted positioning
                    BottomMenuViewLandscape()
                        .position(x: 50, y: (geometry.size.height + geometry.size.width) / 4 - 82)
                        .offset(x: 16)
                        .ignoresSafeArea()
                }
            }
#if os(iOS)
            .navigationBarHidden(true)
#endif
        }
    }
}

// MARK: - Landscape Right Template
/// Template for RIGHT LANDSCAPE orientation (footer on RIGHT side)
/// Phone rotated with device top on LEFT side
struct LandscapeRightTemplate<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                ZStack {
                    // Background color
                    AppColors.primaryBlue
                        .ignoresSafeArea()

                    // Main layout with header
                    VStack(spacing: 0) {
                        // Top Menu Bar - Landscape version
                        TopMenuViewLandscape()

                        // Content area
                        VStack {
                            content
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }

                    // Right side navigation bar - push to right edge
                    BottomMenuViewLandscape()
                        .position(x: geometry.size.width - 50, y: (geometry.size.height + geometry.size.width) / 4 - 82)
                        .offset(x: 104)
                        .ignoresSafeArea()
                }
            }
#if os(iOS)
            .navigationBarHidden(true)
#endif
        }
    }
}

// MARK: - Orientation-Aware Page Wrapper
/// Automatically switches between portrait, left horizontal, and right horizontal templates
/// based on device orientation. Use this wrapper for all pages to support all three orientations seamlessly.
struct OrientationAwarePage<PortraitContent: View, LeftContent: View, RightContent: View>: View {
    @State private var deviceOrientation: UIDeviceOrientation = UIDevice.current.orientation

    let portraitContent: PortraitContent
    let leftHorizontalContent: LeftContent
    let rightHorizontalContent: RightContent

    init(
        @ViewBuilder portrait: () -> PortraitContent,
        @ViewBuilder leftHorizontal: () -> LeftContent,
        @ViewBuilder rightHorizontal: () -> RightContent
    ) {
        self.portraitContent = portrait()
        self.leftHorizontalContent = leftHorizontal()
        self.rightHorizontalContent = rightHorizontal()
    }

    var body: some View {
        GeometryReader { geometry in
            if geometry.size.width < geometry.size.height {
                // Portrait orientation
                PortraitTemplate {
                    portraitContent
                }
            } else {
                // Landscape - use UIDevice orientation to determine left vs right
                // Note: UIDeviceOrientation naming is counterintuitive
                if deviceOrientation == .landscapeRight {
                    // .landscapeRight = device top on LEFT = camera LEFT = footer on RIGHT...
                    // BUT user reports opposite, so: footer on LEFT
                    LandscapeLeftTemplate {
                        leftHorizontalContent
                    }
                } else if deviceOrientation == .landscapeLeft {
                    // .landscapeLeft = device top on RIGHT = camera RIGHT = footer on LEFT...
                    // BUT user reports opposite, so: footer on RIGHT
                    LandscapeRightTemplate {
                        rightHorizontalContent
                    }
                } else {
                    // Fallback for other orientations - default to left
                    LandscapeLeftTemplate {
                        leftHorizontalContent
                    }
                }
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
    }
}

#Preview("Default") {
    ContentView()
        .modelContainer(for: CapturedAircraft.self, inMemory: true)
        .environment(AppState())
}

#Preview("Landscape Left", traits: .landscapeLeft) {
    LandscapeLeftTemplate {
        Spacer()
    }
    .environment(AppState())
}

#Preview("Landscape Right", traits: .landscapeRight) {
    LandscapeRightTemplate {
        Spacer()
    }
    .environment(AppState())
}
// MARK: - Color Extension for Hex Support
extension Color {
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
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - View Extension for Rounded Corners
extension View {
    func cornerRadius(_ radius: CGFloat, corners: RectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RectCorner: @preconcurrency OptionSet, Sendable {
    let rawValue: Int

    init(rawValue: Int) {
        self.rawValue = rawValue
    }

    static let topLeft = RectCorner(rawValue: 1 << 0)
    static let topRight = RectCorner(rawValue: 1 << 1)
    static let bottomLeft = RectCorner(rawValue: 1 << 2)
    static let bottomRight = RectCorner(rawValue: 1 << 3)
    static let allCorners: RectCorner = [.topLeft, .topRight, .bottomLeft, .bottomRight]
}

struct RoundedCorner: Shape, Sendable {
    var radius: CGFloat = .infinity
    var corners: RectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        var path = Path()

        let topLeft = CGPoint(x: rect.minX, y: rect.minY)
        let topRight = CGPoint(x: rect.maxX, y: rect.minY)
        let bottomLeft = CGPoint(x: rect.minX, y: rect.maxY)
        let bottomRight = CGPoint(x: rect.maxX, y: rect.maxY)

        // Start from top left
        if corners.contains(.topLeft) {
            path.move(to: CGPoint(x: rect.minX + radius, y: rect.minY))
        } else {
            path.move(to: topLeft)
        }

        // Top right corner
        if corners.contains(.topRight) {
            path.addLine(to: CGPoint(x: rect.maxX - radius, y: rect.minY))
            path.addArc(center: CGPoint(x: rect.maxX - radius, y: rect.minY + radius),
                       radius: radius,
                       startAngle: Angle(degrees: -90),
                       endAngle: Angle(degrees: 0),
                       clockwise: false)
        } else {
            path.addLine(to: topRight)
        }

        // Bottom right corner
        if corners.contains(.bottomRight) {
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - radius))
            path.addArc(center: CGPoint(x: rect.maxX - radius, y: rect.maxY - radius),
                       radius: radius,
                       startAngle: Angle(degrees: 0),
                       endAngle: Angle(degrees: 90),
                       clockwise: false)
        } else {
            path.addLine(to: bottomRight)
        }

        // Bottom left corner
        if corners.contains(.bottomLeft) {
            path.addLine(to: CGPoint(x: rect.minX + radius, y: rect.maxY))
            path.addArc(center: CGPoint(x: rect.minX + radius, y: rect.maxY - radius),
                       radius: radius,
                       startAngle: Angle(degrees: 90),
                       endAngle: Angle(degrees: 180),
                       clockwise: false)
        } else {
            path.addLine(to: bottomLeft)
        }

        // Back to top left corner
        if corners.contains(.topLeft) {
            path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + radius))
            path.addArc(center: CGPoint(x: rect.minX + radius, y: rect.minY + radius),
                       radius: radius,
                       startAngle: Angle(degrees: 180),
                       endAngle: Angle(degrees: 270),
                       clockwise: false)
        } else {
            path.addLine(to: topLeft)
        }

        path.closeSubpath()
        return path
    }
}
