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

    // Query to fetch the most recent aircraft captures
    @Query(
        sort: \CapturedAircraft.captureDate,
        order: .reverse
    ) private var allAircraft: [CapturedAircraft]

    // Computed property to get the 6 most recent sightings (portrait)
    private var recentSightings: [CapturedAircraft] {
        Array(allAircraft.prefix(6))
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
        Set(allAircraft.map { $0.icao }).count
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

    // MARK: - Aircraft Display Formatting

    /// Line 1: [AIRLINE CODE] MANUFACTURER MODEL
    /// Example: "UAL BOEING 747" or "PIPER PA-46-310P" (if no airline)
    func aircraftLine1(_ aircraft: CapturedAircraft) -> String {
        var parts: [String] = []
        if let code = aircraft.airlineCode, !code.isEmpty {
            parts.append(code.uppercased())
        }
        parts.append(aircraft.manufacturer.uppercased())
        parts.append(aircraft.model)
        return parts.joined(separator: " ")
    }

    /// Line 2: [CLASSIFICATION] [Type]
    /// Classification in CAPS, Type in Title Case
    /// Returns nil if neither value is available
    func aircraftLine2(_ aircraft: CapturedAircraft) -> String? {
        var parts: [String] = []
        if let classification = AircraftLookup.classificationName(aircraft.aircraftClassification) {
            parts.append(classification)
        }
        if let type = AircraftLookup.typeName(aircraft.aircraftType) {
            parts.append(type)
        }
        return parts.isEmpty ? nil : parts.joined(separator: " ")
    }

    var body: some View {
        // Portrait-only layout (locked orientation)
        PortraitTemplate {
            GeometryReader { geo in
            let contentWidth = geo.size.width * 0.92
            let statBoxWidth = (contentWidth - 10) / 2 // Two boxes with 10pt gap

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 10) {
                    // Stat boxes row - side by side
                    HStack(spacing: 10) {
                        // Total Aircraft box
                        VStack(spacing: 0) {
                            // Header
                            ZStack {
                                AppColors.darkBlue
                                Text("Total Aircraft")
                                    .font(.custom("Helvetica-Bold", size: 14))
                                    .foregroundStyle(.white)
                            }
                            .frame(height: 28)
                            .clipShape(RoundedCorner(radius: 8, corners: [.topLeft, .topRight]))

                            // Body
                            ZStack {
                                AppColors.white
                                Text(formatNumber(appState.totalAircraftCount))
                                    .font(.system(size: 32, weight: .bold))
                                    .foregroundStyle(AppColors.gold)
                            }
                            .frame(height: 50)
                            .overlay(
                                RoundedCorner(radius: 8, corners: [.bottomLeft, .bottomRight])
                                    .stroke(AppColors.borderBlue, lineWidth: 1)
                            )
                            .clipShape(RoundedCorner(radius: 8, corners: [.bottomLeft, .bottomRight]))
                        }
                        .frame(width: statBoxWidth)

                        // Total Types box
                        VStack(spacing: 0) {
                            // Header
                            ZStack {
                                AppColors.darkBlue
                                Text("Total Types")
                                    .font(.custom("Helvetica-Bold", size: 14))
                                    .foregroundStyle(.white)
                            }
                            .frame(height: 28)
                            .clipShape(RoundedCorner(radius: 8, corners: [.topLeft, .topRight]))

                            // Body
                            ZStack {
                                AppColors.white
                                Text(formatNumber(appState.totalTypes))
                                    .font(.system(size: 32, weight: .bold))
                                    .foregroundStyle(AppColors.gold)
                            }
                            .frame(height: 50)
                            .overlay(
                                RoundedCorner(radius: 8, corners: [.bottomLeft, .bottomRight])
                                    .stroke(AppColors.borderBlue, lineWidth: 1)
                            )
                            .clipShape(RoundedCorner(radius: 8, corners: [.bottomLeft, .bottomRight]))
                        }
                        .frame(width: statBoxWidth)
                    }

                    // Progress box
                    VStack(spacing: 0) {
                        // Header
                        ZStack {
                            AppColors.darkBlue
                            Text(isLegend ? "You Are a LEGEND!" : "Progress to \(nextLevel)")
                                .font(.custom("Helvetica-Bold", size: 14))
                                .foregroundStyle(.white)
                        }
                        .frame(width: contentWidth, height: 28)
                        .clipShape(RoundedCorner(radius: 8, corners: [.topLeft, .topRight]))

                        // Body with progress bar
                        ZStack {
                            AppColors.white
                            let progressBarWidth = contentWidth * 0.9
                            ZStack(alignment: .leading) {
                                Rectangle()
                                    .fill(AppColors.lightGray)
                                    .frame(width: progressBarWidth, height: 18)
                                Rectangle()
                                    .fill(Color(hex: isLegend ? "28A745" : "2B81C5"))
                                    .frame(width: progressBarWidth * levelProgress, height: 18)
                            }
                            .overlay(
                                Rectangle()
                                    .stroke(AppColors.black, lineWidth: 1)
                                    .frame(width: progressBarWidth, height: 18)
                            )
                        }
                        .frame(width: contentWidth, height: 40)
                        .overlay(
                            RoundedCorner(radius: 8, corners: [.bottomLeft, .bottomRight])
                                .stroke(AppColors.borderBlue, lineWidth: 1)
                        )
                        .clipShape(RoundedCorner(radius: 8, corners: [.bottomLeft, .bottomRight]))
                    }

                    // Recent Sightings box
                    VStack(spacing: 0) {
                        // Header
                        ZStack {
                            AppColors.darkBlue
                            Text("Recent Sightings")
                                .font(.custom("Helvetica-Bold", size: 15))
                                .foregroundStyle(.white)
                        }
                        .frame(width: contentWidth, height: 28)
                        .clipShape(RoundedCorner(radius: 8, corners: [.topLeft, .topRight]))

                        // Body
                        ZStack {
                            AppColors.white

                            if recentSightings.isEmpty {
                                VStack(spacing: 4) {
                                    Image(systemName: "airplane.departure")
                                        .font(.system(size: 28))
                                        .foregroundStyle(AppColors.orange.opacity(0.5))
                                    Text("No sightings yet")
                                        .font(.custom("Helvetica", size: 14))
                                        .foregroundStyle(AppColors.darkBlue.opacity(0.6))
                                }
                            } else {
                                VStack(alignment: .leading, spacing: 8) {
                                    ForEach(recentSightings) { aircraft in
                                        VStack(alignment: .leading, spacing: 1) {
                                            // Line 1: [IATA] MANUFACTURER MODEL
                                            Text(aircraftLine1(aircraft))
                                                .font(.custom("Helvetica-Bold", size: 15))
                                                .foregroundStyle(AppColors.darkBlue)
                                            // Line 2: [CLASSIFICATION] [Type] (if available)
                                            if let line2 = aircraftLine2(aircraft) {
                                                Text(line2)
                                                    .font(.custom("Helvetica", size: 13))
                                                    .foregroundStyle(AppColors.darkBlue.opacity(0.7))
                                            }
                                        }
                                    }
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                        .frame(width: contentWidth)
                        .frame(minHeight: 240)
                        .overlay(
                            RoundedCorner(radius: 8, corners: [.bottomLeft, .bottomRight])
                                .stroke(AppColors.borderBlue, lineWidth: 1)
                        )
                        .clipShape(RoundedCorner(radius: 8, corners: [.bottomLeft, .bottomRight]))
                    }

                    Spacer(minLength: 100) // Space for footer
                }
                .padding(.top, 10)
                .frame(maxWidth: .infinity)
            }
            }
        }
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
                AppColors.darkBlue
                VStack(alignment: .trailing, spacing: 0) {
                    shadowedText(label1)
                    shadowedText(label2)
                    shadowedText(label3)
                }
            }
            .frame(width: 100, height: 103)
            .clipShape(RoundedCorner(radius: 10, corners: [.topLeft, .bottomLeft]))

            ZStack {
                AppColors.white
                HStack {
                    Text(value)
                        .font(.system(size: 36, weight: .regular))
                        .foregroundStyle(AppColors.gold)
                        .shadow(color: .black, radius: 0, x: -1, y: -1)
                        .shadow(color: .black, radius: 0, x: 1, y: -1)
                        .shadow(color: .black, radius: 0, x: -1, y: 1)
                        .shadow(color: .black, radius: 0, x: 1, y: 1)
                    Image(systemName: "airplane")
                        .font(.system(size: 24))
                        .foregroundStyle(AppColors.orange)
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
                AppColors.darkBlue
                Text("Latest Sightings")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(.white)
            }
            .frame(height: 35)
            .clipShape(RoundedCorner(radius: 10, corners: [.topLeft, .topRight]))

            ZStack {
                AppColors.white
                if latestSightings.isEmpty {
                    VStack(spacing: 4) {
                        Image(systemName: "airplane.departure")
                            .font(.system(size: 30))
                            .foregroundStyle(AppColors.orange.opacity(0.5))
                        Text("No sightings yet")
                            .font(.system(size: 14))
                            .foregroundStyle(AppColors.darkBlue.opacity(0.6))
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
                    .stroke(AppColors.borderBlue, lineWidth: 1)
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
                .foregroundStyle(AppColors.orange)
            VStack(alignment: .leading, spacing: 1) {
                // Line 1: [IATA] MANUFACTURER MODEL
                Text(aircraftLine1(aircraft))
                    .font(.system(size: 19, weight: .bold))
                    .foregroundStyle(AppColors.darkBlue)
                    .lineLimit(1)
                // Line 2: [CLASSIFICATION] [Type] (if available)
                if let line2 = aircraftLine2(aircraft) {
                    Text(line2)
                        .font(.system(size: 15, weight: .regular))
                        .foregroundStyle(AppColors.darkBlue.opacity(0.7))
                }
            }
        }
    }

    // MARK: - Aircraft Display Formatting

    /// Line 1: [AIRLINE CODE] MANUFACTURER MODEL
    private func aircraftLine1(_ aircraft: CapturedAircraft) -> String {
        var parts: [String] = []
        if let code = aircraft.airlineCode, !code.isEmpty {
            parts.append(code.uppercased())
        }
        parts.append(aircraft.manufacturer.uppercased())
        parts.append(aircraft.model)
        return parts.joined(separator: " ")
    }

    /// Line 2: [CLASSIFICATION] [Type] - Classification in CAPS, Type in Title Case
    private func aircraftLine2(_ aircraft: CapturedAircraft) -> String? {
        var parts: [String] = []
        if let classification = AircraftLookup.classificationName(aircraft.aircraftClassification) {
            parts.append(classification)
        }
        if let type = AircraftLookup.typeName(aircraft.aircraftType) {
            parts.append(type)
        }
        return parts.isEmpty ? nil : parts.joined(separator: " ")
    }

    // MARK: - Progress Bar
    private var progressBar: some View {
        HStack(spacing: 0) {
            ZStack {
                AppColors.darkBlue
                Text(isLegend ? "You Are a LEGEND!" : "Progress to \(nextLevel)")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.white)
            }
            .frame(width: 240, height: 40)
            .clipShape(RoundedCorner(radius: 10, corners: [.topLeft, .bottomLeft]))

            ZStack {
                AppColors.white
                ZStack(alignment: .leading) {
                    Rectangle().fill(AppColors.lightGray).frame(height: 22)
                    Rectangle().fill(Color(hex: isLegend ? "28A745" : "2B81C5")).frame(width: 310 * levelProgress, height: 22)
                }
                .frame(width: 310, height: 22)
                .overlay(Rectangle().stroke(AppColors.black, lineWidth: 1))
            }
            .frame(width: 346, height: 40)
            .clipShape(RoundedCorner(radius: 10, corners: [.topRight, .bottomRight]))
        }
        .padding(.top, 5)
    }
}

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

// Sample data for previews
private let previewSampleAircraft: [CapturedAircraft] = {
    let aircraft1 = CapturedAircraft(captureTime: Date(), captureDate: Date(), year: 2026, month: 1, day: 15, gpsLongitude: -88.5, gpsLatitude: 43.9, iPhotoReference: "preview-1", icao: "HDJT", manufacturer: "Honda", model: "HondaJet", registration: "N769F")
    let aircraft2 = CapturedAircraft(captureTime: Date(), captureDate: Date(), year: 2026, month: 1, day: 7, gpsLongitude: -88.5, gpsLatitude: 43.9, iPhotoReference: "preview-2", icao: "ACAM", manufacturer: "Lockwood", model: "Air Cam", registration: "N79QF")
    let aircraft3 = CapturedAircraft(captureTime: Date(), captureDate: Date(), year: 2026, month: 1, day: 5, gpsLongitude: -88.5, gpsLatitude: 43.9, iPhotoReference: "preview-3", icao: "DC3", manufacturer: "Douglas", model: "DC-3", registration: "N1573")
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
    HomePage()
        .modelContainer(for: CapturedAircraft.self, inMemory: true)
        .environment(previewAppState())
}

#Preview("Landscape Left", traits: .landscapeLeft) {
    LandscapeLeftTemplate {
        HomePageLandscapeContentLeft(latestSightings: previewSampleAircraft, nextLevel: "ENTHUSIAST", levelProgress: 0.01)
    }
    .modelContainer(for: CapturedAircraft.self, inMemory: true)
    .environment(previewAppState())
}

#Preview("Landscape Right", traits: .landscapeRight) {
    LandscapeRightTemplate {
        HomePageLandscapeContentRight(latestSightings: previewSampleAircraft, nextLevel: "ENTHUSIAST", levelProgress: 0.01)
    }
    .modelContainer(for: CapturedAircraft.self, inMemory: true)
    .environment(previewAppState())
}
