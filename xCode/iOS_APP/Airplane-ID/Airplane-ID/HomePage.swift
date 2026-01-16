//
//  HomePage.swift
//  Airplane-ID
//
//  Created by Jim Kerr on 1/15/26.
//

import SwiftUI
import SwiftData

struct HomePage: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AppState.self) private var appState

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
        case "LEGEND": return "LEGEND" // Already at max
        default: return "SPOTTER"
        }
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

    // Load test data if needed
    private func loadTestDataIfNeeded() {
        print("🏠 HomePage: Checking for test data...")

        // Check if we already have data
        if allAircraft.count > 0 {
            print("ℹ️ Data already exists (\(allAircraft.count) records)")
            return
        }

        print("📥 Loading test data...")

        // Test data from CSV
        let testData: [(icao: String, manufacturer: String, model: String, registration: String, year: Int, month: Int, day: Int, lat: Double, lon: Double)] = [
            ("A500", "Adam", "A-500", "N12345", 2024, 1, 27, 43.99083, -88.57411),
            ("M346", "Aermacchi", "M-346 Master", "N4455", 2024, 2, 8, 43.99056, -88.56877),
            ("M339", "Aermacchi", "MB-339", "N12VS", 2025, 3, 14, 43.98986, -88.56456),
            ("AAT3", "Aero", "3 AT-3", "N3344", 2025, 5, 20, 43.98964, -88.55993),
            ("B701", "Boeing", "707-100", "N1678", 2025, 6, 5, 43.99007, -88.55594),
            ("C172", "Cessna", "Skyhawk", "N2757", 2025, 10, 31, 43.99289, -88.57291),
            ("SR22", "Cirrus", "SR-22", "N252Q", 2025, 12, 24, 43.98845, -88.55797),
            ("S22T", "Cirrus", "SR22 Turbo", "N7779", 2026, 1, 5, 43.98959, -88.55556),
            ("DC3", "Douglas", "DC-3", "N1573", 2026, 1, 5, 43.99073, -88.55169),
            ("ACAM", "Lockwood", "Air Cam", "N79QF", 2026, 1, 7, 43.9879, -88.55548),
            ("HDJT", "Honda", "HondaJet", "N769F", 2026, 1, 15, 43.98968, -88.55128)
        ]

        for data in testData {
            var dateComponents = DateComponents()
            dateComponents.year = data.year
            dateComponents.month = data.month
            dateComponents.day = data.day
            dateComponents.hour = 20
            dateComponents.minute = 9
            dateComponents.second = 45
            dateComponents.timeZone = TimeZone(identifier: "UTC")

            guard let captureDate = Calendar.current.date(from: dateComponents) else { continue }

            let aircraft = CapturedAircraft(
                captureDate: captureDate,
                gpsLongitude: data.lon,
                gpsLatitude: data.lat,
                year: data.year,
                month: data.month,
                day: data.day,
                icao: data.icao,
                manufacturer: data.manufacturer,
                model: data.model,
                registration: data.registration
            )

            modelContext.insert(aircraft)
        }

        do {
            try modelContext.save()
            print("✅ Loaded 11 test aircraft")
        } catch {
            print("❌ Error saving: \(error)")
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
                    
                    // Progress to ACE box
                    VStack(spacing: 0) {
                        // Top section - Dark blue header with rounded top corners
                        ZStack {
                            Color(hex: "082A49")
                            
                            Text("Progress to ACE")
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
                                    
                                    // Progress (completed portion)
                                    Rectangle()
                                        .fill(Color(hex: "2B81C5"))
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
            },
            leftHorizontal: {
                // Left horizontal version content (footer on LEFT side)
                HomePageLandscapeLeftContent(latestSightings: latestSightings, nextLevel: nextLevel, levelProgress: levelProgress)
            },
            rightHorizontal: {
                // Right horizontal version content (footer on RIGHT side)
                HomePageLandscapeRightContent(latestSightings: latestSightings, nextLevel: nextLevel, levelProgress: levelProgress)
            }
        )
        .onAppear {
            loadTestDataIfNeeded()
            // Update AppState from database
            appState.status = currentStatus
            appState.totalAircraftCount = aircraftCount
        }
        .onChange(of: allAircraft.count) { _, _ in
            // Update AppState when aircraft count changes
            appState.status = currentStatus
            appState.totalAircraftCount = aircraftCount
        }
    }
}

// MARK: - Landscape Content Views for Previews

struct HomePageLandscapeLeftContent: View {
    @Environment(AppState.self) private var appState
    let latestSightings: [CapturedAircraft]
    let nextLevel: String
    let levelProgress: Double

    func formatNumber(_ number: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = ","
        return formatter.string(from: NSNumber(value: number)) ?? "\(number)"
    }

    var body: some View {
        // Content group - all boxes together, offset from footer on left
        HStack {
            VStack(spacing: 8) {
                // Main content area - two columns
                HStack(alignment: .top, spacing: 10) {
                    // Left column - Stat boxes stacked
                    VStack(spacing: 0) {
                        // Total Aircraft Found box
                        HStack(spacing: 0) {
                            ZStack {
                                Color(hex: "082A49")
                                VStack(alignment: .trailing, spacing: 0) {
                                    Text("Total").font(.system(size: 22, weight: .bold)).foregroundStyle(.white)
                                        .shadow(color: .black, radius: 0, x: -1, y: -1).shadow(color: .black, radius: 0, x: 1, y: -1)
                                        .shadow(color: .black, radius: 0, x: -1, y: 1).shadow(color: .black, radius: 0, x: 1, y: 1)
                                    Text("Aircraft").font(.system(size: 22, weight: .bold)).foregroundStyle(.white)
                                        .shadow(color: .black, radius: 0, x: -1, y: -1).shadow(color: .black, radius: 0, x: 1, y: -1)
                                        .shadow(color: .black, radius: 0, x: -1, y: 1).shadow(color: .black, radius: 0, x: 1, y: 1)
                                    Text("Found").font(.system(size: 22, weight: .bold)).foregroundStyle(.white)
                                        .shadow(color: .black, radius: 0, x: -1, y: -1).shadow(color: .black, radius: 0, x: 1, y: -1)
                                        .shadow(color: .black, radius: 0, x: -1, y: 1).shadow(color: .black, radius: 0, x: 1, y: 1)
                                }
                            }
                            .frame(width: 100, height: 103)
                            .clipShape(RoundedCorner(radius: 10, corners: [.topLeft, .bottomLeft]))
                            ZStack {
                                Color(hex: "FFFFFF")
                                HStack {
                                    Text(formatNumber(appState.totalAircraftCount)).font(.system(size: 36, weight: .regular)).foregroundStyle(Color(hex: "FBBD1C"))
                                        .shadow(color: .black, radius: 0, x: -1, y: -1).shadow(color: .black, radius: 0, x: 1, y: -1)
                                        .shadow(color: .black, radius: 0, x: -1, y: 1).shadow(color: .black, radius: 0, x: 1, y: 1)
                                    Image(systemName: "airplane").font(.system(size: 24)).foregroundStyle(Color(hex: "F27C31"))
                                }
                            }
                            .frame(width: 170, height: 103)
                            .clipShape(RoundedCorner(radius: 10, corners: [.topRight, .bottomRight]))
                        }

                        Spacer()

                        // Total Aircraft Types box
                        HStack(spacing: 0) {
                            ZStack {
                                Color(hex: "082A49")
                                VStack(alignment: .trailing, spacing: 0) {
                                    Text("Total").font(.system(size: 22, weight: .bold)).foregroundStyle(.white)
                                        .shadow(color: .black, radius: 0, x: -1, y: -1).shadow(color: .black, radius: 0, x: 1, y: -1)
                                        .shadow(color: .black, radius: 0, x: -1, y: 1).shadow(color: .black, radius: 0, x: 1, y: 1)
                                    Text("Aircraft").font(.system(size: 22, weight: .bold)).foregroundStyle(.white)
                                        .shadow(color: .black, radius: 0, x: -1, y: -1).shadow(color: .black, radius: 0, x: 1, y: -1)
                                        .shadow(color: .black, radius: 0, x: -1, y: 1).shadow(color: .black, radius: 0, x: 1, y: 1)
                                    Text("Types").font(.system(size: 22, weight: .bold)).foregroundStyle(.white)
                                        .shadow(color: .black, radius: 0, x: -1, y: -1).shadow(color: .black, radius: 0, x: 1, y: -1)
                                        .shadow(color: .black, radius: 0, x: -1, y: 1).shadow(color: .black, radius: 0, x: 1, y: 1)
                                }
                            }
                            .frame(width: 100, height: 103)
                            .clipShape(RoundedCorner(radius: 10, corners: [.topLeft, .bottomLeft]))
                            ZStack {
                                Color(hex: "FFFFFF")
                                HStack {
                                    Text(formatNumber(appState.totalTypes)).font(.system(size: 36, weight: .regular)).foregroundStyle(Color(hex: "FBBD1C"))
                                        .shadow(color: .black, radius: 0, x: -1, y: -1).shadow(color: .black, radius: 0, x: 1, y: -1)
                                        .shadow(color: .black, radius: 0, x: -1, y: 1).shadow(color: .black, radius: 0, x: 1, y: 1)
                                    Image(systemName: "airplane").font(.system(size: 24)).foregroundStyle(Color(hex: "F27C31"))
                                }
                            }
                            .frame(width: 170, height: 103)
                            .clipShape(RoundedCorner(radius: 10, corners: [.topRight, .bottomRight]))
                        }
                    }
                    .frame(width: 270, height: 220)
                    .padding(.trailing, 3)

                    // Right column - Latest Sightings (same height as stat boxes combined)
                    VStack(spacing: 0) {
                        ZStack {
                            Color(hex: "082A49")
                            Text("Latest Sightings").font(.system(size: 20, weight: .bold)).foregroundStyle(.white)
                        }
                        .frame(height: 35)
                        .clipShape(RoundedCorner(radius: 10, corners: [.topLeft, .topRight]))
                        ZStack {
                            Color(hex: "FFFFFF")
                            if latestSightings.isEmpty {
                                VStack(spacing: 4) {
                                    Image(systemName: "airplane.departure").font(.system(size: 30)).foregroundStyle(Color(hex: "F27C31").opacity(0.5))
                                    Text("No sightings yet").font(.system(size: 14)).foregroundStyle(Color(hex: "082A49").opacity(0.6))
                                }
                            } else {
                                VStack(alignment: .leading, spacing: 9) {
                                    ForEach(latestSightings) { aircraft in
                                        HStack(alignment: .center, spacing: 6) {
                                            Image(systemName: "airplane").font(.system(size: 22)).foregroundStyle(Color(hex: "F27C31"))
                                            VStack(alignment: .leading, spacing: 1) {
                                                Text((aircraft.manufacturer ?? "Unknown").uppercased())
                                                    .font(.system(size: 19, weight: .regular)).foregroundStyle(Color(hex: "082A49"))
                                                if let registration = aircraft.registration, !registration.isEmpty {
                                                    Text("\(registration.uppercased()) \(aircraft.model ?? "")")
                                                        .font(.system(size: 15, weight: .regular)).foregroundStyle(Color(hex: "082A49")).lineLimit(1)
                                                } else {
                                                    Text(aircraft.model ?? "")
                                                        .font(.system(size: 15, weight: .regular)).foregroundStyle(Color(hex: "082A49")).lineLimit(1)
                                                }
                                            }
                                        }
                                    }
                                }
                                .padding(.leading, 23).padding(.trailing, 8).padding(.vertical, 6).frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                        .frame(height: 185)
                        .overlay(RoundedCorner(radius: 10, corners: [.bottomLeft, .bottomRight]).stroke(Color(hex: "124A93"), lineWidth: 1))
                        .clipShape(RoundedCorner(radius: 10, corners: [.bottomLeft, .bottomRight]))
                    }
                    .frame(width: 270, height: 220)
                    .padding(.leading, 3)
                }

                // Progress bar - centered under boxes above
                HStack(spacing: 0) {
                    ZStack {
                        Color(hex: "082A49")
                        Text("Progress to \(nextLevel)").font(.system(size: 18, weight: .bold)).foregroundStyle(.white)
                    }
                    .frame(width: 240, height: 40)
                    .clipShape(RoundedCorner(radius: 10, corners: [.topLeft, .bottomLeft]))
                    ZStack {
                        Color(hex: "FFFFFF")
                        ZStack(alignment: .leading) {
                            Rectangle().fill(Color(hex: "B9C6D1")).frame(height: 22)
                            Rectangle().fill(Color(hex: "2B81C5")).frame(width: 310 * levelProgress, height: 22)
                        }
                        .frame(width: 310, height: 22)
                        .overlay(Rectangle().stroke(Color(hex: "000000"), lineWidth: 1))
                    }
                    .frame(width: 346, height: 40)
                    .clipShape(RoundedCorner(radius: 10, corners: [.topRight, .bottomRight]))
                }
                .padding(.top, 5)
            }
            .padding(.top, 8)
            .padding(.leading, 120) // Space for footer on left

            Spacer()
        }
    }
}

struct HomePageLandscapeRightContent: View {
    @Environment(AppState.self) private var appState
    let latestSightings: [CapturedAircraft]
    let nextLevel: String
    let levelProgress: Double

    func formatNumber(_ number: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = ","
        return formatter.string(from: NSNumber(value: number)) ?? "\(number)"
    }

    var body: some View {
        // Content group - all boxes together, offset from footer on right
        HStack {
            Spacer()

            VStack(spacing: 8) {
                // Main content area - two columns
                HStack(alignment: .top, spacing: 10) {
                    // Left column - Stat boxes stacked
                    VStack(spacing: 0) {
                        // Total Aircraft Found box
                        HStack(spacing: 0) {
                            ZStack {
                                Color(hex: "082A49")
                                VStack(alignment: .trailing, spacing: 0) {
                                    Text("Total").font(.system(size: 22, weight: .bold)).foregroundStyle(.white)
                                        .shadow(color: .black, radius: 0, x: -1, y: -1).shadow(color: .black, radius: 0, x: 1, y: -1)
                                        .shadow(color: .black, radius: 0, x: -1, y: 1).shadow(color: .black, radius: 0, x: 1, y: 1)
                                    Text("Aircraft").font(.system(size: 22, weight: .bold)).foregroundStyle(.white)
                                        .shadow(color: .black, radius: 0, x: -1, y: -1).shadow(color: .black, radius: 0, x: 1, y: -1)
                                        .shadow(color: .black, radius: 0, x: -1, y: 1).shadow(color: .black, radius: 0, x: 1, y: 1)
                                    Text("Found").font(.system(size: 22, weight: .bold)).foregroundStyle(.white)
                                        .shadow(color: .black, radius: 0, x: -1, y: -1).shadow(color: .black, radius: 0, x: 1, y: -1)
                                        .shadow(color: .black, radius: 0, x: -1, y: 1).shadow(color: .black, radius: 0, x: 1, y: 1)
                                }
                            }
                            .frame(width: 100, height: 103)
                            .clipShape(RoundedCorner(radius: 10, corners: [.topLeft, .bottomLeft]))
                            ZStack {
                                Color(hex: "FFFFFF")
                                HStack {
                                    Text(formatNumber(appState.totalAircraftCount)).font(.system(size: 36, weight: .regular)).foregroundStyle(Color(hex: "FBBD1C"))
                                        .shadow(color: .black, radius: 0, x: -1, y: -1).shadow(color: .black, radius: 0, x: 1, y: -1)
                                        .shadow(color: .black, radius: 0, x: -1, y: 1).shadow(color: .black, radius: 0, x: 1, y: 1)
                                    Image(systemName: "airplane").font(.system(size: 24)).foregroundStyle(Color(hex: "F27C31"))
                                }
                            }
                            .frame(width: 170, height: 103)
                            .clipShape(RoundedCorner(radius: 10, corners: [.topRight, .bottomRight]))
                        }

                        Spacer()

                        // Total Aircraft Types box
                        HStack(spacing: 0) {
                            ZStack {
                                Color(hex: "082A49")
                                VStack(alignment: .trailing, spacing: 0) {
                                    Text("Total").font(.system(size: 22, weight: .bold)).foregroundStyle(.white)
                                        .shadow(color: .black, radius: 0, x: -1, y: -1).shadow(color: .black, radius: 0, x: 1, y: -1)
                                        .shadow(color: .black, radius: 0, x: -1, y: 1).shadow(color: .black, radius: 0, x: 1, y: 1)
                                    Text("Aircraft").font(.system(size: 22, weight: .bold)).foregroundStyle(.white)
                                        .shadow(color: .black, radius: 0, x: -1, y: -1).shadow(color: .black, radius: 0, x: 1, y: -1)
                                        .shadow(color: .black, radius: 0, x: -1, y: 1).shadow(color: .black, radius: 0, x: 1, y: 1)
                                    Text("Types").font(.system(size: 22, weight: .bold)).foregroundStyle(.white)
                                        .shadow(color: .black, radius: 0, x: -1, y: -1).shadow(color: .black, radius: 0, x: 1, y: -1)
                                        .shadow(color: .black, radius: 0, x: -1, y: 1).shadow(color: .black, radius: 0, x: 1, y: 1)
                                }
                            }
                            .frame(width: 100, height: 103)
                            .clipShape(RoundedCorner(radius: 10, corners: [.topLeft, .bottomLeft]))
                            ZStack {
                                Color(hex: "FFFFFF")
                                HStack {
                                    Text(formatNumber(appState.totalTypes)).font(.system(size: 36, weight: .regular)).foregroundStyle(Color(hex: "FBBD1C"))
                                        .shadow(color: .black, radius: 0, x: -1, y: -1).shadow(color: .black, radius: 0, x: 1, y: -1)
                                        .shadow(color: .black, radius: 0, x: -1, y: 1).shadow(color: .black, radius: 0, x: 1, y: 1)
                                    Image(systemName: "airplane").font(.system(size: 24)).foregroundStyle(Color(hex: "F27C31"))
                                }
                            }
                            .frame(width: 170, height: 103)
                            .clipShape(RoundedCorner(radius: 10, corners: [.topRight, .bottomRight]))
                        }
                    }
                    .frame(width: 270, height: 220)
                    .padding(.trailing, 3)

                    // Right column - Latest Sightings (same height as stat boxes combined)
                    VStack(spacing: 0) {
                        ZStack {
                            Color(hex: "082A49")
                            Text("Latest Sightings").font(.system(size: 20, weight: .bold)).foregroundStyle(.white)
                        }
                        .frame(height: 35)
                        .clipShape(RoundedCorner(radius: 10, corners: [.topLeft, .topRight]))
                        ZStack {
                            Color(hex: "FFFFFF")
                            if latestSightings.isEmpty {
                                VStack(spacing: 4) {
                                    Image(systemName: "airplane.departure").font(.system(size: 30)).foregroundStyle(Color(hex: "F27C31").opacity(0.5))
                                    Text("No sightings yet").font(.system(size: 14)).foregroundStyle(Color(hex: "082A49").opacity(0.6))
                                }
                            } else {
                                VStack(alignment: .leading, spacing: 9) {
                                    ForEach(latestSightings) { aircraft in
                                        HStack(alignment: .center, spacing: 6) {
                                            Image(systemName: "airplane").font(.system(size: 22)).foregroundStyle(Color(hex: "F27C31"))
                                            VStack(alignment: .leading, spacing: 1) {
                                                Text((aircraft.manufacturer ?? "Unknown").uppercased())
                                                    .font(.system(size: 19, weight: .regular)).foregroundStyle(Color(hex: "082A49"))
                                                if let registration = aircraft.registration, !registration.isEmpty {
                                                    Text("\(registration.uppercased()) \(aircraft.model ?? "")")
                                                        .font(.system(size: 15, weight: .regular)).foregroundStyle(Color(hex: "082A49")).lineLimit(1)
                                                } else {
                                                    Text(aircraft.model ?? "")
                                                        .font(.system(size: 15, weight: .regular)).foregroundStyle(Color(hex: "082A49")).lineLimit(1)
                                                }
                                            }
                                        }
                                    }
                                }
                                .padding(.leading, 23).padding(.trailing, 8).padding(.vertical, 6).frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                        .frame(height: 185)
                        .overlay(RoundedCorner(radius: 10, corners: [.bottomLeft, .bottomRight]).stroke(Color(hex: "124A93"), lineWidth: 1))
                        .clipShape(RoundedCorner(radius: 10, corners: [.bottomLeft, .bottomRight]))
                    }
                    .frame(width: 270, height: 220)
                    .padding(.leading, 3)
                }

                // Progress bar - centered under boxes above
                HStack(spacing: 0) {
                    ZStack {
                        Color(hex: "082A49")
                        Text("Progress to \(nextLevel)").font(.system(size: 18, weight: .bold)).foregroundStyle(.white)
                    }
                    .frame(width: 240, height: 40)
                    .clipShape(RoundedCorner(radius: 10, corners: [.topLeft, .bottomLeft]))
                    ZStack {
                        Color(hex: "FFFFFF")
                        ZStack(alignment: .leading) {
                            Rectangle().fill(Color(hex: "B9C6D1")).frame(height: 22)
                            Rectangle().fill(Color(hex: "2B81C5")).frame(width: 310 * levelProgress, height: 22)
                        }
                        .frame(width: 310, height: 22)
                        .overlay(Rectangle().stroke(Color(hex: "000000"), lineWidth: 1))
                    }
                    .frame(width: 346, height: 40)
                    .clipShape(RoundedCorner(radius: 10, corners: [.topRight, .bottomRight]))
                }
                .padding(.top, 5)
            }
            .padding(.top, 8)
            .padding(.trailing, 120) // Space for footer on right
        }
    }
}

#Preview("Default") {
    HomePage()
        .modelContainer(for: CapturedAircraft.self, inMemory: true)
        .environment(AppState())
}

// Sample data for landscape previews
private let previewSampleAircraft: [CapturedAircraft] = {
    let aircraft1 = CapturedAircraft(captureDate: Date(), gpsLongitude: -88.5, gpsLatitude: 43.9, year: 2026, month: 1, day: 15, icao: "HDJT", manufacturer: "Honda", model: "HondaJet", registration: "N769F")
    let aircraft2 = CapturedAircraft(captureDate: Date(), gpsLongitude: -88.5, gpsLatitude: 43.9, year: 2026, month: 1, day: 7, icao: "ACAM", manufacturer: "Lockwood", model: "Air Cam", registration: "N79QF")
    let aircraft3 = CapturedAircraft(captureDate: Date(), gpsLongitude: -88.5, gpsLatitude: 43.9, year: 2026, month: 1, day: 5, icao: "DC3", manufacturer: "Douglas", model: "DC-3", registration: "N1573")
    return [aircraft1, aircraft2, aircraft3]
}()

#Preview("Landscape Left", traits: .landscapeLeft) {
    LandscapeLeftTemplate {
        HomePageLandscapeLeftContent(latestSightings: previewSampleAircraft, nextLevel: "LEGEND", levelProgress: 0.78)
    }
    .modelContainer(for: CapturedAircraft.self, inMemory: true)
    .environment(AppState())
}

#Preview("Landscape Right", traits: .landscapeRight) {
    LandscapeRightTemplate {
        HomePageLandscapeRightContent(latestSightings: previewSampleAircraft, nextLevel: "LEGEND", levelProgress: 0.78)
    }
    .modelContainer(for: CapturedAircraft.self, inMemory: true)
    .environment(AppState())
}
