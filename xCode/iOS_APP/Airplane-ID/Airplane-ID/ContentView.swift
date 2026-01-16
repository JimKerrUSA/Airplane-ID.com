//
//  ContentView.swift
//  Airplane-ID
//
//  Created by Jim Kerr on 1/15/26.
//

import SwiftUI
import SwiftData

// MARK: - Global App State
@Observable
class AppState {
    var status: String = "EXPERT"
    var search: String = ""
    var captureMode: String = "camera" // Options: "camera" or "photo.stack"
    var totalAircraftCount: Int = 1234 // Placeholder value
    var totalTypes: Int = 142
    var levelProgress: Double = 0.78 // Progress as decimal (78%)
}

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AppState.self) private var appState
    
    var body: some View {
        PageTemplate {
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
                .padding(.trailing, 16)
                .padding(.top, 52)
            }
        }
        .frame(height: 140)
        .frame(maxWidth: .infinity)
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

// MARK: - Page Template
/// Standard page template with top menu, bottom menu, and consistent styling
/// Use this as the base for all pages in the app
struct PageTemplate<Content: View>: View {
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
            .background(Color(hex: "1D58A4"))
            .ignoresSafeArea()
#if os(iOS)
            .navigationBarHidden(true)
#endif
        }
    }
}

// MARK: - Page Template - Portrait Orientation
/// Standard page template for PORTRAIT orientation with top menu, bottom menu, and consistent styling
/// Use this as the base for all portrait pages in the app
struct HomePagePortrait<Content: View>: View {
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
            .background(Color(hex: "1D58A4"))
            .ignoresSafeArea()
#if os(iOS)
            .navigationBarHidden(true)
#endif
        }
    }
}

// MARK: - Page Template - Left Horizontal Orientation
/// Template for LEFT HORIZONTAL orientation
/// TODO: Build this template when ready for landscape left support
struct HomePageLeftHorizontal<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        // Placeholder for left horizontal layout
        Text("Left Horizontal - To Be Implemented")
            .foregroundStyle(.white)
    }
}

// MARK: - Page Template - Right Horizontal Orientation
/// Template for RIGHT HORIZONTAL orientation
/// TODO: Build this template when ready for landscape right support
struct HomePageRightHorizontal<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        // Placeholder for right horizontal layout
        Text("Right Horizontal - To Be Implemented")
            .foregroundStyle(.white)
    }
}

// MARK: - Orientation-Aware Page Wrapper
/// Automatically switches between portrait, left horizontal, and right horizontal templates
/// based on device orientation. Use this wrapper for all pages to support all three orientations seamlessly.
struct OrientationAwarePage<PortraitContent: View, LeftContent: View, RightContent: View>: View {
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(\.verticalSizeClass) var verticalSizeClass
    
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
                HomePagePortrait {
                    portraitContent
                }
            } else {
                // Landscape orientation - detect left vs right
                // For now, we'll use the same content for both until templates are built
                HomePageLeftHorizontal {
                    leftHorizontalContent
                }
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Item.self, inMemory: true)
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


