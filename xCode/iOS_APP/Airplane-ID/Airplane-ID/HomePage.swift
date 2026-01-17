//
//  HomePage.swift
//  Airplane-ID
//
//  Created by Jim Kerr on 1/15/26.
//

import SwiftUI
import SwiftData

struct HomePage: View {
    @Environment(AppState.self) private var appState
    @Environment(\.screenScale) private var screenScale

    // Query to fetch the most recent aircraft captures
    @Query(
        sort: \CapturedAircraft.captureDate,
        order: .reverse
    ) private var allAircraft: [CapturedAircraft]

    // Computed property to get the 3 most recent sightings (portrait)
    private var recentSightings: [CapturedAircraft] {
        Array(allAircraft.prefix(3))
    }

    // Computed property to get the 3 most recent sightings (landscape)
    private var latestSightings: [CapturedAircraft] {
        Array(allAircraft.prefix(3))
    }

    // MARK: - Level Progression Logic
    // Thresholds: 0=NEWBIE, 10=SPOTTER, 100=ENTHUSIAST, 250=EXPERT, 500=ACE, 1100=LEGEND

    // Current aircraft count from database
    private var aircraftCount: Int {
        allAircraft.count
    }

    // Count of unique aircraft types (unique ICAO codes)
    private var uniqueTypesCount: Int {
        Set(allAircraft.compactMap { $0.icao }).count
    }

    // Current status based on aircraft count
    private var currentStatus: String {
        switch aircraftCount {
        case 0..<10: return "NEWBIE"
        case 10..<100: return "SPOTTER"
        case 100..<250: return "ENTHUSIAST"
        case 250..<500: return "EXPERT"
        case 500..<1100: return "ACE"
        default: return "LEGEND"
        }
    }

    // Next level to achieve
    private var nextLevel: String {
        switch currentStatus {
        case "NEWBIE": return "SPOTTER"
        case "SPOTTER": return "ENTHUSIAST"
        case "ENTHUSIAST": return "EXPERT"
        case "EXPERT": return "ACE"
        case "ACE": return "LEGEND"
        case "LEGEND": return "" // Already at max - empty triggers special display
        default: return "SPOTTER"
        }
    }

    // Check if user has reached max level (LEGEND)
    private var isLegend: Bool {
        currentStatus == "LEGEND"
    }

    // Progress percentage toward next level (0.0 to 1.0)
    private var levelProgress: Double {
        switch aircraftCount {
        case 0..<10:
            return Double(aircraftCount) / 10.0  // 0-9 toward 10
        case 10..<100:
            return Double(aircraftCount - 10) / 90.0  // 10-99 toward 100
        case 100..<250:
            return Double(aircraftCount - 100) / 150.0  // 100-249 toward 250
        case 250..<500:
            return Double(aircraftCount - 250) / 250.0  // 250-499 toward 500
        case 500..<1100:
            return Double(aircraftCount - 500) / 600.0  // 500-1099 toward 1100
        default:
            return 1.0  // LEGEND - max level achieved
        }
    }

    // Helper function to format numbers with commas
    func formatNumber(_ number: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = ","
        return formatter.string(from: NSNumber(value: number)) ?? "\(number)"
    }
    
    var body: some View {
        OrientationAwarePage(
            portrait: {
                // Portrait version content
                VStack(spacing: 0) {
                    // Top data boxes row
                    HStack(spacing: 0) {
                        // Left box - Dark blue with rounded top-left and bottom-left corners
                        ZStack {
                            Color(hex: "082A49")
                            
                            VStack(alignment: .trailing, spacing: 0) {
                                Text("Total")
                                    .font(.system(size: 26, weight: .bold, design: .default))
                                    .foregroundStyle(.white)
                                    .shadow(color: .black, radius: 0, x: -1, y: -1)
                                    .shadow(color: .black, radius: 0, x: 1, y: -1)
                                    .shadow(color: .black, radius: 0, x: -1, y: 1)
                                    .shadow(color: .black, radius: 0, x: 1, y: 1)
                                
                                Text("Aircraft")
                                    .font(.system(size: 26, weight: .bold, design: .default))
                                    .foregroundStyle(.white)
                                    .shadow(color: .black, radius: 0, x: -1, y: -1)
                                    .shadow(color: .black, radius: 0, x: 1, y: -1)
                                    .shadow(color: .black, radius: 0, x: -1, y: 1)
                                    .shadow(color: .black, radius: 0, x: 1, y: 1)
                                
                                Text("Found")
                                    .font(.system(size: 26, weight: .bold, design: .default))
                                    .foregroundStyle(.white)
                                    .shadow(color: .black, radius: 0, x: -1, y: -1)
                                    .shadow(color: .black, radius: 0, x: 1, y: -1)
                                    .shadow(color: .black, radius: 0, x: -1, y: 1)
                                    .shadow(color: .black, radius: 0, x: 1, y: 1)
                            }
                        }
                        .frame(width: 125, height: 106)
                        .clipShape(RoundedCorner(radius: 10, corners: [.topLeft, .bottomLeft]))
                        
                        // Right box - White with rounded top-right and bottom-right corners
                        ZStack {
                            Color(hex: "FFFFFF")
                            
                            Text(formatNumber(appState.totalAircraftCount))
                                .font(.system(size: 40, weight: .regular, design: .default))
                                .foregroundStyle(Color(hex: "FBBD1C"))
                                .shadow(color: .black, radius: 0, x: -1, y: -1)
                                .shadow(color: .black, radius: 0, x: 1, y: -1)
                                .shadow(color: .black, radius: 0, x: -1, y: 1)
                                .shadow(color: .black, radius: 0, x: 1, y: 1)
                        }
                        .frame(width: 222, height: 106)
                        .clipShape(RoundedCorner(radius: 10, corners: [.topRight, .bottomRight]))
                    }
                    .padding(.top, 13) // 13px below top menu
                    
                    // Second data box row
                    HStack(spacing: 0) {
                        // Left box - Dark blue with rounded top-left and bottom-left corners
                        ZStack {
                            Color(hex: "082A49")
                            
                            VStack(alignment: .trailing, spacing: 0) {
                                Text("Total")
                                    .font(.system(size: 26, weight: .bold, design: .default))
                                    .foregroundStyle(.white)
                                    .shadow(color: .black, radius: 0, x: -1, y: -1)
                                    .shadow(color: .black, radius: 0, x: 1, y: -1)
                                    .shadow(color: .black, radius: 0, x: -1, y: 1)
                                    .shadow(color: .black, radius: 0, x: 1, y: 1)
                                
                                Text("Aircraft")
                                    .font(.system(size: 26, weight: .bold, design: .default))
                                    .foregroundStyle(.white)
                                    .shadow(color: .black, radius: 0, x: -1, y: -1)
                                    .shadow(color: .black, radius: 0, x: 1, y: -1)
                                    .shadow(color: .black, radius: 0, x: -1, y: 1)
                                    .shadow(color: .black, radius: 0, x: 1, y: 1)
                                
                                Text("Types")
                                    .font(.system(size: 26, weight: .bold, design: .default))
                                    .foregroundStyle(.white)
                                    .shadow(color: .black, radius: 0, x: -1, y: -1)
                                    .shadow(color: .black, radius: 0, x: 1, y: -1)
                                    .shadow(color: .black, radius: 0, x: -1, y: 1)
                                    .shadow(color: .black, radius: 0, x: 1, y: 1)
                            }
                        }
                        .frame(width: 125, height: 106)
                        .clipShape(RoundedCorner(radius: 10, corners: [.topLeft, .bottomLeft]))
                        
                        // Right box - White with rounded top-right and bottom-right corners
                        ZStack {
                            Color(hex: "FFFFFF")
                            
                            Text(formatNumber(appState.totalTypes))
                                .font(.system(size: 40, weight: .regular, design: .default))
                                .foregroundStyle(Color(hex: "FBBD1C"))
                                .shadow(color: .black, radius: 0, x: -1, y: -1)
                                .shadow(color: .black, radius: 0, x: 1, y: -1)
                                .shadow(color: .black, radius: 0, x: -1, y: 1)
                                .shadow(color: .black, radius: 0, x: 1, y: 1)
                        }
                        .frame(width: 222, height: 106)
                        .clipShape(RoundedCorner(radius: 10, corners: [.topRight, .bottomRight]))
                    }
                    .padding(.top, 13) // 13px below first box
                    
                    // Progress box
                    VStack(spacing: 0) {
                        // Top section - Dark blue header with rounded top corners
                        ZStack {
                            Color(hex: "082A49")

                            Text(isLegend ? "You Are a LEGEND!" : "Progress to \(nextLevel)")
                                .font(.system(size: 26, weight: .bold, design: .default))
                                .foregroundStyle(.white)
                        }
                        .frame(width: 347, height: 39)
                        .clipShape(RoundedCorner(radius: 10, corners: [.topLeft, .topRight]))

                        // Bottom section - White with blue border and rounded bottom corners
                        ZStack {
                            Color(hex: "FFFFFF")

                            // Progress bar
                            GeometryReader { geometry in
                                ZStack(alignment: .leading) {
                                    // Background (incomplete portion)
                                    Rectangle()
                                        .fill(Color(hex: "B9C6D1"))
                                        .frame(width: 313, height: 25)

                                    // Progress (completed portion) - Green for LEGEND, blue otherwise
                                    Rectangle()
                                        .fill(Color(hex: isLegend ? "28A745" : "2B81C5"))
                                        .frame(width: 313 * levelProgress, height: 25)
                                }
                                .overlay(
                                    Rectangle()
                                        .stroke(Color(hex: "000000"), lineWidth: 1)
                                        .frame(width: 313, height: 25)
                                )
                                .frame(width: 313, height: 25)
                                .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
                            }
                        }
                        .frame(width: 347, height: 56)
                        .overlay(
                            RoundedCorner(radius: 10, corners: [.bottomLeft, .bottomRight])
                                .stroke(Color(hex: "124A93"), lineWidth: 1)
                        )
                        .clipShape(RoundedCorner(radius: 10, corners: [.bottomLeft, .bottomRight]))
                    }
                    .padding(.top, 13) // 13px below second box
                    
                    // Bottom box - Recent Sightings
                    VStack(spacing: 0) {
                        // Top section - Dark blue header with rounded top corners
                        ZStack {
                            Color(hex: "082A49")

                            Text("Recent Sightings")
                                .font(.system(size: 26, weight: .bold, design: .default))
                                .foregroundStyle(.white)
                        }
                        .frame(width: 347, height: 39)
                        .clipShape(RoundedCorner(radius: 10, corners: [.topLeft, .topRight]))

                        // Bottom section - White with blue border and rounded bottom corners
                        ZStack {
                            Color(hex: "FFFFFF")

                            // Recent sightings list
                            if recentSightings.isEmpty {
                                // Empty state
                                VStack(spacing: 8) {
                                    Image(systemName: "airplane.departure")
                                        .font(.system(size: 40))
                                        .foregroundStyle(Color(hex: "F27C31").opacity(0.5))
                                    Text("No sightings yet")
                                        .font(.system(size: 18, weight: .regular))
                                        .foregroundStyle(Color(hex: "082A49").opacity(0.6))
                                }
                            } else {
                                VStack(alignment: .leading, spacing: 12) {
                                    ForEach(recentSightings) { aircraft in
                                        HStack(alignment: .center, spacing: 10) {
                                            // Airplane icon - centered vertically with text
                                            Image(systemName: "airplane")
                                                .font(.system(size: 28))
                                                .foregroundStyle(Color(hex: "F27C31"))

                                            // Manufacturer and Registration/Model stacked
                                            VStack(alignment: .leading, spacing: 2) {
                                                // Line 1: Manufacturer in ALL CAPS, SF Pro Regular 23pt
                                                Text((aircraft.manufacturer ?? "Unknown").uppercased())
                                                    .font(.system(size: 23, weight: .regular))
                                                    .foregroundStyle(Color(hex: "082A49"))

                                                // Line 2: Registration (CAPS) + Model (Title Case), SF Pro Regular 19pt
                                                if let registration = aircraft.registration, !registration.isEmpty {
                                                    Text("\(registration.uppercased()) \(aircraft.model ?? "")")
                                                        .font(.system(size: 19, weight: .regular))
                                                        .foregroundStyle(Color(hex: "082A49"))
                                                } else {
                                                    Text(aircraft.model ?? "")
                                                        .font(.system(size: 19, weight: .regular))
                                                        .foregroundStyle(Color(hex: "082A49"))
                                                }
                                            }
                                            .padding(.leading, 3) // Move text 3px right
                                        }
                                    }
                                }
                                .padding(.leading, 20)
                                .padding(.trailing, 20)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                        .frame(width: 347, height: 211)
                        .overlay(
                            RoundedCorner(radius: 10, corners: [.bottomLeft, .bottomRight])
                                .stroke(Color(hex: "124A93"), lineWidth: 1)
                        )
                        .clipShape(RoundedCorner(radius: 10, corners: [.bottomLeft, .bottomRight]))
                    }
                    .padding(.top, 13) // 13px below progress box
                    
                    Spacer()
                }
                // Note: scaleEffect removed - using fixed dimensions that fit iPhone 14 Pro (393x852)
                // If content doesn't fit, we need to adjust individual dimensions, not scale
            },
            leftHorizontal: {
                // Left horizontal version content (footer on LEFT side)
                HomePageLandscapeLeftContent(latestSightings: latestSightings, nextLevel: nextLevel, levelProgress: levelProgress, isLegend: isLegend)
            },
            rightHorizontal: {
                // Right horizontal version content (footer on RIGHT side)
                HomePageLandscapeRightContent(latestSightings: latestSightings, nextLevel: nextLevel, levelProgress: levelProgress, isLegend: isLegend)
            }
        )
        .onAppear {
            // Update AppState from database
            appState.status = currentStatus
            appState.totalAircraftCount = aircraftCount
            appState.totalTypes = uniqueTypesCount
        }
        .onChange(of: allAircraft.count) { _, _ in
            // Update AppState when aircraft count changes
            appState.status = currentStatus
            appState.totalAircraftCount = aircraftCount
            appState.totalTypes = uniqueTypesCount
        }
    }
}

// MARK: - Landscape Content View (Consolidated)
/// Single parameterized view for both landscape orientations
/// footerOnLeft: true = footer on left side, false = footer on right side

struct HomePageLandscapeContent: View {
    @Environment(AppState.self) private var appState
    @Environment(\.screenScale) private var screenScale
    let latestSightings: [CapturedAircraft]
    let nextLevel: String
    let levelProgress: Double
    let footerOnLeft: Bool
    var isLegend: Bool = false

    func formatNumber(_ number: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = ","
        return formatter.string(from: NSNumber(value: number)) ?? "\(number)"
    }

    var body: some View {
        HStack {
            if !footerOnLeft { Spacer() }

            VStack(spacing: 8) {
                // Main content area - two columns
                HStack(alignment: .top, spacing: 10) {
                    // Left column - Stat boxes stacked
                    statBoxesColumn

                    // Right column - Latest Sightings
                    latestSightingsColumn
                }

                // Progress bar
                progressBar
            }
            .padding(.top, 8)
            .padding(footerOnLeft ? .leading : .trailing, 120)

            if footerOnLeft { Spacer() }
        }
        // Note: scaleEffect removed - fixed dimensions should work for most devices
    }

    // MARK: - Stat Boxes Column
    private var statBoxesColumn: some View {
        VStack(spacing: 0) {
            // Total Aircraft Found box
            statBox(
                label1: "Total", label2: "Aircraft", label3: "Found",
                value: formatNumber(appState.totalAircraftCount)
            )

            Spacer()

            // Total Aircraft Types box
            statBox(
                label1: "Total", label2: "Aircraft", label3: "Types",
                value: formatNumber(appState.totalTypes)
            )
        }
        .frame(width: 270, height: 220)
        .padding(.trailing, 3)
    }

    // MARK: - Stat Box Component
    private func statBox(label1: String, label2: String, label3: String, value: String) -> some View {
        HStack(spacing: 0) {
            ZStack {
                Color(hex: "082A49")
                VStack(alignment: .trailing, spacing: 0) {
                    shadowedText(label1)
                    shadowedText(label2)
                    shadowedText(label3)
                }
            }
            .frame(width: 100, height: 103)
            .clipShape(RoundedCorner(radius: 10, corners: [.topLeft, .bottomLeft]))

            ZStack {
                Color(hex: "FFFFFF")
                HStack {
                    Text(value)
                        .font(.system(size: 36, weight: .regular))
                        .foregroundStyle(Color(hex: "FBBD1C"))
                        .shadow(color: .black, radius: 0, x: -1, y: -1)
                        .shadow(color: .black, radius: 0, x: 1, y: -1)
                        .shadow(color: .black, radius: 0, x: -1, y: 1)
                        .shadow(color: .black, radius: 0, x: 1, y: 1)
                    Image(systemName: "airplane")
                        .font(.system(size: 24))
                        .foregroundStyle(Color(hex: "F27C31"))
                }
            }
            .frame(width: 170, height: 103)
            .clipShape(RoundedCorner(radius: 10, corners: [.topRight, .bottomRight]))
        }
    }

    // MARK: - Shadowed Text Helper
    private func shadowedText(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 22, weight: .bold))
            .foregroundStyle(.white)
            .shadow(color: .black, radius: 0, x: -1, y: -1)
            .shadow(color: .black, radius: 0, x: 1, y: -1)
            .shadow(color: .black, radius: 0, x: -1, y: 1)
            .shadow(color: .black, radius: 0, x: 1, y: 1)
    }

    // MARK: - Latest Sightings Column
    private var latestSightingsColumn: some View {
        VStack(spacing: 0) {
            ZStack {
                Color(hex: "082A49")
                Text("Latest Sightings")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(.white)
            }
            .frame(height: 35)
            .clipShape(RoundedCorner(radius: 10, corners: [.topLeft, .topRight]))

            ZStack {
                Color(hex: "FFFFFF")
                if latestSightings.isEmpty {
                    VStack(spacing: 4) {
                        Image(systemName: "airplane.departure")
                            .font(.system(size: 30))
                            .foregroundStyle(Color(hex: "F27C31").opacity(0.5))
                        Text("No sightings yet")
                            .font(.system(size: 14))
                            .foregroundStyle(Color(hex: "082A49").opacity(0.6))
                    }
                } else {
                    VStack(alignment: .leading, spacing: 9) {
                        ForEach(latestSightings) { aircraft in
                            sightingRow(aircraft: aircraft)
                        }
                    }
                    .padding(.leading, 23)
                    .padding(.trailing, 8)
                    .padding(.vertical, 6)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .frame(height: 185)
            .overlay(
                RoundedCorner(radius: 10, corners: [.bottomLeft, .bottomRight])
                    .stroke(Color(hex: "124A93"), lineWidth: 1)
            )
            .clipShape(RoundedCorner(radius: 10, corners: [.bottomLeft, .bottomRight]))
        }
        .frame(width: 270, height: 220)
        .padding(.leading, 3)
    }

    // MARK: - Sighting Row Component
    private func sightingRow(aircraft: CapturedAircraft) -> some View {
        HStack(alignment: .center, spacing: 6) {
            Image(systemName: "airplane")
                .font(.system(size: 22))
                .foregroundStyle(Color(hex: "F27C31"))
            VStack(alignment: .leading, spacing: 1) {
                Text((aircraft.manufacturer ?? "Unknown").uppercased())
                    .font(.system(size: 19, weight: .regular))
                    .foregroundStyle(Color(hex: "082A49"))
                if let registration = aircraft.registration, !registration.isEmpty {
                    Text("\(registration.uppercased()) \(aircraft.model ?? "")")
                        .font(.system(size: 15, weight: .regular))
                        .foregroundStyle(Color(hex: "082A49"))
                        .lineLimit(1)
                } else {
                    Text(aircraft.model ?? "")
                        .font(.system(size: 15, weight: .regular))
                        .foregroundStyle(Color(hex: "082A49"))
                        .lineLimit(1)
                }
            }
        }
    }

    // MARK: - Progress Bar
    private var progressBar: some View {
        HStack(spacing: 0) {
            ZStack {
                Color(hex: "082A49")
                Text(isLegend ? "You Are a LEGEND!" : "Progress to \(nextLevel)")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.white)
            }
            .frame(width: 240, height: 40)
            .clipShape(RoundedCorner(radius: 10, corners: [.topLeft, .bottomLeft]))

            ZStack {
                Color(hex: "FFFFFF")
                ZStack(alignment: .leading) {
                    Rectangle().fill(Color(hex: "B9C6D1")).frame(height: 22)
                    Rectangle().fill(Color(hex: isLegend ? "28A745" : "2B81C5")).frame(width: 310 * levelProgress, height: 22)
                }
                .frame(width: 310, height: 22)
                .overlay(Rectangle().stroke(Color(hex: "000000"), lineWidth: 1))
            }
            .frame(width: 346, height: 40)
            .clipShape(RoundedCorner(radius: 10, corners: [.topRight, .bottomRight]))
        }
        .padding(.top, 5)
    }
}

// MARK: - Type Aliases for Backward Compatibility
/// These allow existing code to continue working without changes
typealias HomePageLandscapeLeftContent = HomePageLandscapeContentLeft
typealias HomePageLandscapeRightContent = HomePageLandscapeContentRight

struct HomePageLandscapeContentLeft: View {
    @Environment(AppState.self) private var appState
    let latestSightings: [CapturedAircraft]
    let nextLevel: String
    let levelProgress: Double
    var isLegend: Bool = false

    var body: some View {
        HomePageLandscapeContent(
            latestSightings: latestSightings,
            nextLevel: nextLevel,
            levelProgress: levelProgress,
            footerOnLeft: true,
            isLegend: isLegend
        )
    }
}

struct HomePageLandscapeContentRight: View {
    @Environment(AppState.self) private var appState
    let latestSightings: [CapturedAircraft]
    let nextLevel: String
    let levelProgress: Double
    var isLegend: Bool = false

    var body: some View {
        HomePageLandscapeContent(
            latestSightings: latestSightings,
            nextLevel: nextLevel,
            levelProgress: levelProgress,
            footerOnLeft: false,
            isLegend: isLegend
        )
    }
}

// MARK: - Portrait Content View (for Previews)
struct HomePagePortraitContent: View {
    @Environment(AppState.self) private var appState
    let recentSightings: [CapturedAircraft]
    let nextLevel: String
    let levelProgress: Double
    var isLegend: Bool = false

    func formatNumber(_ number: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = ","
        return formatter.string(from: NSNumber(value: number)) ?? "\(number)"
    }

    var body: some View {
        VStack(spacing: 0) {
            // Top data boxes row - Total Aircraft Found
            HStack(spacing: 0) {
                ZStack {
                    Color(hex: "082A49")
                    VStack(alignment: .trailing, spacing: 0) {
                        Text("Total").font(.system(size: 26, weight: .bold)).foregroundStyle(.white)
                            .shadow(color: .black, radius: 0, x: -1, y: -1).shadow(color: .black, radius: 0, x: 1, y: -1)
                            .shadow(color: .black, radius: 0, x: -1, y: 1).shadow(color: .black, radius: 0, x: 1, y: 1)
                        Text("Aircraft").font(.system(size: 26, weight: .bold)).foregroundStyle(.white)
                            .shadow(color: .black, radius: 0, x: -1, y: -1).shadow(color: .black, radius: 0, x: 1, y: -1)
                            .shadow(color: .black, radius: 0, x: -1, y: 1).shadow(color: .black, radius: 0, x: 1, y: 1)
                        Text("Found").font(.system(size: 26, weight: .bold)).foregroundStyle(.white)
                            .shadow(color: .black, radius: 0, x: -1, y: -1).shadow(color: .black, radius: 0, x: 1, y: -1)
                            .shadow(color: .black, radius: 0, x: -1, y: 1).shadow(color: .black, radius: 0, x: 1, y: 1)
                    }
                }
                .frame(width: 125, height: 106)
                .clipShape(RoundedCorner(radius: 10, corners: [.topLeft, .bottomLeft]))

                ZStack {
                    Color(hex: "FFFFFF")
                    Text(formatNumber(appState.totalAircraftCount))
                        .font(.system(size: 40, weight: .regular))
                        .foregroundStyle(Color(hex: "FBBD1C"))
                        .shadow(color: .black, radius: 0, x: -1, y: -1).shadow(color: .black, radius: 0, x: 1, y: -1)
                        .shadow(color: .black, radius: 0, x: -1, y: 1).shadow(color: .black, radius: 0, x: 1, y: 1)
                }
                .frame(width: 222, height: 106)
                .clipShape(RoundedCorner(radius: 10, corners: [.topRight, .bottomRight]))
            }
            .padding(.top, 13)

            // Second data box row - Total Aircraft Types
            HStack(spacing: 0) {
                ZStack {
                    Color(hex: "082A49")
                    VStack(alignment: .trailing, spacing: 0) {
                        Text("Total").font(.system(size: 26, weight: .bold)).foregroundStyle(.white)
                            .shadow(color: .black, radius: 0, x: -1, y: -1).shadow(color: .black, radius: 0, x: 1, y: -1)
                            .shadow(color: .black, radius: 0, x: -1, y: 1).shadow(color: .black, radius: 0, x: 1, y: 1)
                        Text("Aircraft").font(.system(size: 26, weight: .bold)).foregroundStyle(.white)
                            .shadow(color: .black, radius: 0, x: -1, y: -1).shadow(color: .black, radius: 0, x: 1, y: -1)
                            .shadow(color: .black, radius: 0, x: -1, y: 1).shadow(color: .black, radius: 0, x: 1, y: 1)
                        Text("Types").font(.system(size: 26, weight: .bold)).foregroundStyle(.white)
                            .shadow(color: .black, radius: 0, x: -1, y: -1).shadow(color: .black, radius: 0, x: 1, y: -1)
                            .shadow(color: .black, radius: 0, x: -1, y: 1).shadow(color: .black, radius: 0, x: 1, y: 1)
                    }
                }
                .frame(width: 125, height: 106)
                .clipShape(RoundedCorner(radius: 10, corners: [.topLeft, .bottomLeft]))

                ZStack {
                    Color(hex: "FFFFFF")
                    Text(formatNumber(appState.totalTypes))
                        .font(.system(size: 40, weight: .regular))
                        .foregroundStyle(Color(hex: "FBBD1C"))
                        .shadow(color: .black, radius: 0, x: -1, y: -1).shadow(color: .black, radius: 0, x: 1, y: -1)
                        .shadow(color: .black, radius: 0, x: -1, y: 1).shadow(color: .black, radius: 0, x: 1, y: 1)
                }
                .frame(width: 222, height: 106)
                .clipShape(RoundedCorner(radius: 10, corners: [.topRight, .bottomRight]))
            }
            .padding(.top, 13)

            // Progress box
            VStack(spacing: 0) {
                ZStack {
                    Color(hex: "082A49")
                    Text(isLegend ? "You Are a LEGEND!" : "Progress to \(nextLevel)")
                        .font(.system(size: 26, weight: .bold))
                        .foregroundStyle(.white)
                }
                .frame(width: 347, height: 39)
                .clipShape(RoundedCorner(radius: 10, corners: [.topLeft, .topRight]))

                ZStack {
                    Color(hex: "FFFFFF")
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            Rectangle().fill(Color(hex: "B9C6D1")).frame(width: 313, height: 25)
                            Rectangle().fill(Color(hex: isLegend ? "28A745" : "2B81C5")).frame(width: 313 * levelProgress, height: 25)
                        }
                        .overlay(Rectangle().stroke(Color(hex: "000000"), lineWidth: 1).frame(width: 313, height: 25))
                        .frame(width: 313, height: 25)
                        .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
                    }
                }
                .frame(width: 347, height: 56)
                .overlay(RoundedCorner(radius: 10, corners: [.bottomLeft, .bottomRight]).stroke(Color(hex: "124A93"), lineWidth: 1))
                .clipShape(RoundedCorner(radius: 10, corners: [.bottomLeft, .bottomRight]))
            }
            .padding(.top, 13)

            // Recent Sightings box
            VStack(spacing: 0) {
                ZStack {
                    Color(hex: "082A49")
                    Text("Recent Sightings")
                        .font(.system(size: 26, weight: .bold))
                        .foregroundStyle(.white)
                }
                .frame(width: 347, height: 39)
                .clipShape(RoundedCorner(radius: 10, corners: [.topLeft, .topRight]))

                ZStack {
                    Color(hex: "FFFFFF")
                    if recentSightings.isEmpty {
                        VStack(spacing: 8) {
                            Image(systemName: "airplane.departure")
                                .font(.system(size: 40))
                                .foregroundStyle(Color(hex: "F27C31").opacity(0.5))
                            Text("No sightings yet")
                                .font(.system(size: 18, weight: .regular))
                                .foregroundStyle(Color(hex: "082A49").opacity(0.6))
                        }
                    } else {
                        VStack(alignment: .leading, spacing: 12) {
                            ForEach(recentSightings) { aircraft in
                                HStack(alignment: .center, spacing: 10) {
                                    Image(systemName: "airplane")
                                        .font(.system(size: 28))
                                        .foregroundStyle(Color(hex: "F27C31"))
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text((aircraft.manufacturer ?? "Unknown").uppercased())
                                            .font(.system(size: 23, weight: .regular))
                                            .foregroundStyle(Color(hex: "082A49"))
                                        if let registration = aircraft.registration, !registration.isEmpty {
                                            Text("\(registration.uppercased()) \(aircraft.model ?? "")")
                                                .font(.system(size: 19, weight: .regular))
                                                .foregroundStyle(Color(hex: "082A49"))
                                        } else {
                                            Text(aircraft.model ?? "")
                                                .font(.system(size: 19, weight: .regular))
                                                .foregroundStyle(Color(hex: "082A49"))
                                        }
                                    }
                                    .padding(.leading, 3)
                                }
                            }
                        }
                        .padding(.leading, 20)
                        .padding(.trailing, 20)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .frame(width: 347, height: 211)
                .overlay(RoundedCorner(radius: 10, corners: [.bottomLeft, .bottomRight]).stroke(Color(hex: "124A93"), lineWidth: 1))
                .clipShape(RoundedCorner(radius: 10, corners: [.bottomLeft, .bottomRight]))
            }
            .padding(.top, 13)

            Spacer()
        }
    }
}

// Sample data for previews
private let previewSampleAircraft: [CapturedAircraft] = {
    let aircraft1 = CapturedAircraft(captureDate: Date(), gpsLongitude: -88.5, gpsLatitude: 43.9, year: 2026, month: 1, day: 15, icao: "HDJT", manufacturer: "Honda", model: "HondaJet", registration: "N769F")
    let aircraft2 = CapturedAircraft(captureDate: Date(), gpsLongitude: -88.5, gpsLatitude: 43.9, year: 2026, month: 1, day: 7, icao: "ACAM", manufacturer: "Lockwood", model: "Air Cam", registration: "N79QF")
    let aircraft3 = CapturedAircraft(captureDate: Date(), gpsLongitude: -88.5, gpsLatitude: 43.9, year: 2026, month: 1, day: 5, icao: "DC3", manufacturer: "Douglas", model: "DC-3", registration: "N1573")
    return [aircraft1, aircraft2, aircraft3]
}()

// Preview AppState with realistic values
private func previewAppState() -> AppState {
    let state = AppState()
    state.status = "SPOTTER"
    state.totalAircraftCount = 11
    state.totalTypes = 11
    return state
}

#Preview("Portrait") {
    PortraitTemplate {
        HomePagePortraitContent(recentSightings: previewSampleAircraft, nextLevel: "ENTHUSIAST", levelProgress: 0.01)
    }
    .modelContainer(for: CapturedAircraft.self, inMemory: true)
    .environment(previewAppState())
}

#Preview("Landscape Left", traits: .landscapeLeft) {
    LandscapeLeftTemplate {
        HomePageLandscapeLeftContent(latestSightings: previewSampleAircraft, nextLevel: "ENTHUSIAST", levelProgress: 0.01)
    }
    .modelContainer(for: CapturedAircraft.self, inMemory: true)
    .environment(previewAppState())
}

#Preview("Landscape Right", traits: .landscapeRight) {
    LandscapeRightTemplate {
        HomePageLandscapeRightContent(latestSightings: previewSampleAircraft, nextLevel: "ENTHUSIAST", levelProgress: 0.01)
    }
    .modelContainer(for: CapturedAircraft.self, inMemory: true)
    .environment(previewAppState())
}
