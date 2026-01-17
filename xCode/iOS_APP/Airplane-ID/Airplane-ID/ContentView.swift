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
/// Global configuration flags - set developerToolsEnabled to false before App Store release
struct AppConfig {
    /// Set to false before publishing to App Store
    static let developerToolsEnabled = true
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
    var scale: CGFloat { min(widthScale, heightScale) }

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
    var currentScreen: NavigationDestination = .home // Track current navigation
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
            Color(hex: "082A49")
            
            // Search bar (centered to screen) - positioned to align bottom with EXPERT text
            VStack {
                Spacer()
                
                HStack(spacing: 0) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 30, weight: .bold))
                        .foregroundStyle(Color(hex: "000000").opacity(0.5))
                        .padding(.leading, 12)
                    
                    TextField("", text: Binding(
                        get: { appState.search },
                        set: { appState.search = $0 }
                    ))
                    .padding(.leading, 10)
                    
                    Spacer()
                }
                .frame(width: 240, height: 50)
                .background(Color(hex: "FFFFFF"))
                .cornerRadius(10)
                .padding(.bottom, 16) // Match bottom padding with status indicator
            }
            .frame(maxWidth: .infinity)
            
            // Status indicator (top right) - independently positioned
            HStack(alignment: .top) {
                Spacer()

                VStack(spacing: 4) {
                    Image(systemName: "person")
                        .font(.system(size: 45))
                        .foregroundStyle(.white)

                    Text(appState.status)
                        .font(.custom("Helvetica", size: 12))
                        .foregroundStyle(.white)
                }
                .onTapGesture {
                    appState.currentScreen = .journey
                }
                .padding(.trailing, 16)
                .padding(.top, 52)
            }
        }
        .frame(height: 140)
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
        ZStack(alignment: .bottom) {
            // Navigation bar rectangle - positioned behind camera button (rendered first = back layer)
            RoundedRectangle(cornerRadius: 50)
                .fill(Color(hex: "082A49"))
                .frame(width: 385, height: 65)
                .overlay(
                    RoundedRectangle(cornerRadius: 50)
                        .stroke(Color.gray, lineWidth: 1)
                )
                .offset(y: -35) // Center on the circle
            
            // Navigation icons in horizontal layout
            HStack(spacing: 0) {
                // Left side icons
                HStack {
                    Spacer()
                    
                    // Home icon
                    VStack(spacing: 4) {
                        Image(systemName: "house")
                            .font(.system(size: 35, weight: .regular))
                            .foregroundStyle(Color(hex: "FFFFFF"))

                        Text("Home")
                            .font(.system(size: 12))
                            .foregroundStyle(Color(hex: "FFFFFF"))
                    }
                    .onTapGesture {
                        appState.currentScreen = .home
                    }

                    Spacer()

                    // Hangar icon
                    VStack(spacing: 4) {
                        Image(systemName: "airplane.departure")
                            .font(.system(size: 35, weight: .regular))
                            .foregroundStyle(Color(hex: "FFFFFF"))

                        Text("Hangar")
                            .font(.system(size: 12))
                            .foregroundStyle(Color(hex: "FFFFFF"))
                    }
                    .onTapGesture {
                        appState.currentScreen = .hangar
                    }

                    Spacer()
                }
                .frame(width: 142.5) // Half of 385 minus half of camera button (192.5 - 50)

                // Center camera button
                ZStack {
                    Circle()
                        .fill(Color(hex: "FFFFFF"))
                        .frame(width: 100, height: 100)
                        .overlay(
                            Circle()
                                .stroke(Color(hex: "313131"), lineWidth: 5)
                        )

                    // Capture mode icon
                    Image(systemName: appState.captureMode)
                        .font(.system(size: 35, weight: .regular))
                        .foregroundStyle(Color(hex: "3A3A3C"))
                }
                .frame(width: 100)
                .onTapGesture {
                    appState.currentScreen = .camera
                }

                // Right side icons
                HStack {
                    Spacer()

                    // Maps icon
                    VStack(spacing: 4) {
                        Image(systemName: "map")
                            .font(.system(size: 35, weight: .regular))
                            .foregroundStyle(Color(hex: "FFFFFF"))

                        Text("Maps")
                            .font(.system(size: 12))
                            .foregroundStyle(Color(hex: "FFFFFF"))
                    }
                    .onTapGesture {
                        appState.currentScreen = .maps
                    }

                    Spacer()

                    // Settings icon
                    VStack(spacing: 4) {
                        Image(systemName: "gearshape")
                            .font(.system(size: 35, weight: .regular))
                            .foregroundStyle(Color(hex: "FFFFFF"))

                        Text("Settings")
                            .font(.system(size: 12))
                            .foregroundStyle(Color(hex: "FFFFFF"))
                    }
                    .onTapGesture {
                        appState.currentScreen = .settings
                    }

                    Spacer()
                }
                .frame(width: 142.5) // Half of 385 minus half of camera button (192.5 - 50)
            }
            .frame(width: 385)
            .offset(y: -17.5) // Align with the navigation bar
        }
        .frame(height: 100) // Total height is camera button height
        .padding(.bottom, -5) // -5px padding to lower the footer
    }
}

// MARK: - Top Menu Component - Landscape Version
/// Landscape version of the top menu - reduced height (83px vs 140px portrait)
struct TopMenuViewLandscape: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        ZStack {
            Color(hex: "082A49")
                .ignoresSafeArea(edges: .horizontal)

            // Search bar (centered to screen)
            VStack {
                Spacer()

                HStack(spacing: 0) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 30, weight: .bold))
                        .foregroundStyle(Color(hex: "000000").opacity(0.5))
                        .padding(.leading, 12)

                    TextField("", text: Binding(
                        get: { appState.search },
                        set: { appState.search = $0 }
                    ))
                    .padding(.leading, 10)

                    Spacer()
                }
                .frame(width: 240, height: 50)
                .background(Color(hex: "FFFFFF"))
                .cornerRadius(10)
                .padding(.bottom, 8)
            }
            .frame(maxWidth: .infinity)

            // Status indicator (top right)
            HStack(alignment: .top) {
                Spacer()

                VStack(spacing: 4) {
                    Image(systemName: "person")
                        .font(.system(size: 45))
                        .foregroundStyle(.white)

                    Text(appState.status)
                        .font(.custom("Helvetica", size: 12))
                        .foregroundStyle(.white)
                }
                .onTapGesture {
                    appState.currentScreen = .journey
                }
                .padding(.trailing, 86)
                .padding(.top, 8)
            }
        }
        .frame(height: 83)
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
                .fill(Color(hex: "082A49"))
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
                            .foregroundStyle(Color(hex: "FFFFFF"))

                        Text("Home")
                            .font(.system(size: 12))
                            .foregroundStyle(Color(hex: "FFFFFF"))
                    }
                    .onTapGesture {
                        appState.currentScreen = .home
                    }

                    Spacer()

                    // Maps icon
                    VStack(spacing: 4) {
                        Image(systemName: "map")
                            .font(.system(size: 35, weight: .regular))
                            .foregroundStyle(Color(hex: "FFFFFF"))

                        Text("Maps")
                            .font(.system(size: 12))
                            .foregroundStyle(Color(hex: "FFFFFF"))
                    }
                    .onTapGesture {
                        appState.currentScreen = .maps
                    }

                    Spacer()
                }
                .frame(height: 142.5)

                // Center camera button
                ZStack {
                    Circle()
                        .fill(Color(hex: "FFFFFF"))
                        .frame(width: 100, height: 100)
                        .overlay(
                            Circle()
                                .stroke(Color(hex: "313131"), lineWidth: 5)
                        )

                    // Capture mode icon
                    Image(systemName: appState.captureMode)
                        .font(.system(size: 35, weight: .regular))
                        .foregroundStyle(Color(hex: "3A3A3C"))
                }
                .frame(width: 100, height: 100)
                .onTapGesture {
                    appState.currentScreen = .camera
                }

                // Bottom section
                VStack {
                    Spacer()

                    // Hangar icon
                    VStack(spacing: 4) {
                        Image(systemName: "airplane.departure")
                            .font(.system(size: 35, weight: .regular))
                            .foregroundStyle(Color(hex: "FFFFFF"))

                        Text("Hangar")
                            .font(.system(size: 12))
                            .foregroundStyle(Color(hex: "FFFFFF"))
                    }
                    .onTapGesture {
                        appState.currentScreen = .hangar
                    }

                    Spacer()

                    // Settings icon
                    VStack(spacing: 4) {
                        Image(systemName: "gearshape")
                            .font(.system(size: 35, weight: .regular))
                            .foregroundStyle(Color(hex: "FFFFFF"))

                        Text("Settings")
                            .font(.system(size: 12))
                            .foregroundStyle(Color(hex: "FFFFFF"))
                    }
                    .onTapGesture {
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
/// Injects ScreenScale environment for responsive layouts
struct PortraitTemplate<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        GeometryReader { geometry in
            let screenScale = ScreenScale(width: geometry.size.width, height: geometry.size.height)

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
                .background(Color(hex: "1D58A4"))
                .ignoresSafeArea()
#if os(iOS)
                .navigationBarHidden(true)
#endif
            }
            .environment(\.screenScale, screenScale)
        }
    }
}

// MARK: - Landscape Left Template
/// Template for LEFT LANDSCAPE orientation (footer on LEFT side)
/// Phone rotated with device top on RIGHT side
/// Injects ScreenScale environment for responsive layouts (uses landscape baseline)
struct LandscapeLeftTemplate<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                // For landscape, swap baseline dimensions
                let screenScale = ScreenScale(width: geometry.size.width, height: geometry.size.height)

                ZStack {
                    // Background color
                    Color(hex: "1D58A4")
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
                .environment(\.screenScale, screenScale)
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
/// Injects ScreenScale environment for responsive layouts (uses landscape baseline)
struct LandscapeRightTemplate<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                // For landscape, swap baseline dimensions
                let screenScale = ScreenScale(width: geometry.size.width, height: geometry.size.height)

                ZStack {
                    // Background color
                    Color(hex: "1D58A4")
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
                .environment(\.screenScale, screenScale)
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

struct RectCorner: OptionSet, Sendable {
    let rawValue: Int

    nonisolated init(rawValue: Int) {
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
