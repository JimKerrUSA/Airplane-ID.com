//
//  Airplane_IDApp.swift
//  Airplane-ID
//
//  Created by Jim Kerr on 1/15/26.
//

import SwiftUI
import SwiftData

// MARK: - Main View (Navigation Router)
/// Switches between screens based on appState.currentScreen
struct MainView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        switch appState.currentScreen {
        case .home:
            HomePage()
        case .maps:
            // Placeholder - will be replaced with MapsPage()
            PlaceholderPage(title: "Maps", icon: "map")
        case .camera:
            // Placeholder - will be replaced with CameraPage()
            PlaceholderPage(title: "Camera", icon: "camera")
        case .hangar:
            // Placeholder - will be replaced with HangarPage()
            PlaceholderPage(title: "Hangar", icon: "airplane.departure")
        case .settings:
            // Placeholder - will be replaced with SettingsPage()
            PlaceholderPage(title: "Settings", icon: "gearshape")
        case .journey:
            JourneyPage()
        }
    }
}

// MARK: - Placeholder Page
/// Temporary placeholder for pages not yet built
struct PlaceholderPage: View {
    let title: String
    let icon: String

    var body: some View {
        OrientationAwarePage(
            portrait: {
                VStack(spacing: 20) {
                    Image(systemName: icon)
                        .font(.system(size: 80))
                        .foregroundStyle(.white.opacity(0.6))
                    Text(title)
                        .font(.system(size: 36, weight: .bold))
                        .foregroundStyle(.white)
                    Text("Coming Soon")
                        .font(.system(size: 18))
                        .foregroundStyle(.white.opacity(0.6))
                }
            },
            leftHorizontal: {
                VStack(spacing: 16) {
                    Image(systemName: icon)
                        .font(.system(size: 60))
                        .foregroundStyle(.white.opacity(0.6))
                    Text(title)
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(.white)
                    Text("Coming Soon")
                        .font(.system(size: 14))
                        .foregroundStyle(.white.opacity(0.6))
                }
                .padding(.leading, 120)
            },
            rightHorizontal: {
                VStack(spacing: 16) {
                    Image(systemName: icon)
                        .font(.system(size: 60))
                        .foregroundStyle(.white.opacity(0.6))
                    Text(title)
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(.white)
                    Text("Coming Soon")
                        .font(.system(size: 14))
                        .foregroundStyle(.white.opacity(0.6))
                }
                .padding(.trailing, 120)
            }
        )
    }
}

// MARK: - Journey Page
/// User's profile/journey page showing their level, badges, and leaderboard
struct JourneyPage: View {
    @Environment(AppState.self) private var appState

    // Dynamic title based on current status
    private var journeyTitle: String {
        switch appState.status {
        case "NEWBIE": return "Newbie's Journey"
        case "SPOTTER": return "Spotter's Journey"
        case "ENTHUSIAST": return "Enthusiast's Journey"
        case "EXPERT": return "Expert's Journey"
        case "ACE": return "Ace's Journey"
        case "LEGEND": return "Legend's Journey"
        default: return "Your Journey"
        }
    }

    // Level description
    private var levelDescription: String {
        switch appState.status {
        case "NEWBIE": return "You're just getting started! Capture 10 aircraft to become a Spotter."
        case "SPOTTER": return "You've got sharp eyes! Capture 100 aircraft to become an Enthusiast."
        case "ENTHUSIAST": return "You're hooked on aviation! Capture 250 aircraft to become an Expert."
        case "EXPERT": return "Your knowledge is impressive! Capture 500 aircraft to become an Ace."
        case "ACE": return "You're among the elite! Capture 1,100 aircraft to become a Legend."
        case "LEGEND": return "You've reached the pinnacle of aircraft spotting. You are a Legend!"
        default: return "Keep capturing aircraft to level up!"
        }
    }

    var body: some View {
        OrientationAwarePage(
            portrait: {
                VStack(spacing: 24) {
                    // Person icon
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 100))
                        .foregroundStyle(Color(hex: "F27C31"))

                    // Current status
                    Text(appState.status)
                        .font(.system(size: 42, weight: .bold))
                        .foregroundStyle(Color(hex: "FBBD1C"))

                    // Aircraft count
                    Text("\(appState.totalAircraftCount) Aircraft Captured")
                        .font(.system(size: 20))
                        .foregroundStyle(.white)

                    // Level description
                    Text(levelDescription)
                        .font(.system(size: 16))
                        .foregroundStyle(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)

                    Spacer().frame(height: 20)

                    // Badges section (placeholder)
                    VStack(spacing: 8) {
                        Text("Badges")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundStyle(.white)
                        Text("Coming Soon")
                            .font(.system(size: 14))
                            .foregroundStyle(.white.opacity(0.6))
                    }

                    // Leaderboard section (placeholder)
                    VStack(spacing: 8) {
                        Text("Leaderboard")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundStyle(.white)
                        Text("Coming Soon")
                            .font(.system(size: 14))
                            .foregroundStyle(.white.opacity(0.6))
                    }
                }
                .padding(.top, 20)
            },
            leftHorizontal: {
                HStack(spacing: 40) {
                    // Left side - profile info
                    VStack(spacing: 16) {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 80))
                            .foregroundStyle(Color(hex: "F27C31"))

                        Text(appState.status)
                            .font(.system(size: 32, weight: .bold))
                            .foregroundStyle(Color(hex: "FBBD1C"))

                        Text("\(appState.totalAircraftCount) Aircraft")
                            .font(.system(size: 16))
                            .foregroundStyle(.white)

                        Text(levelDescription)
                            .font(.system(size: 12))
                            .foregroundStyle(.white.opacity(0.8))
                            .multilineTextAlignment(.center)
                            .frame(width: 200)
                    }

                    // Right side - badges & leaderboard
                    VStack(spacing: 24) {
                        VStack(spacing: 4) {
                            Text("Badges")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundStyle(.white)
                            Text("Coming Soon")
                                .font(.system(size: 12))
                                .foregroundStyle(.white.opacity(0.6))
                        }

                        VStack(spacing: 4) {
                            Text("Leaderboard")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundStyle(.white)
                            Text("Coming Soon")
                                .font(.system(size: 12))
                                .foregroundStyle(.white.opacity(0.6))
                        }
                    }
                }
                .padding(.leading, 120)
            },
            rightHorizontal: {
                HStack(spacing: 40) {
                    // Left side - badges & leaderboard
                    VStack(spacing: 24) {
                        VStack(spacing: 4) {
                            Text("Badges")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundStyle(.white)
                            Text("Coming Soon")
                                .font(.system(size: 12))
                                .foregroundStyle(.white.opacity(0.6))
                        }

                        VStack(spacing: 4) {
                            Text("Leaderboard")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundStyle(.white)
                            Text("Coming Soon")
                                .font(.system(size: 12))
                                .foregroundStyle(.white.opacity(0.6))
                        }
                    }

                    // Right side - profile info
                    VStack(spacing: 16) {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 80))
                            .foregroundStyle(Color(hex: "F27C31"))

                        Text(appState.status)
                            .font(.system(size: 32, weight: .bold))
                            .foregroundStyle(Color(hex: "FBBD1C"))

                        Text("\(appState.totalAircraftCount) Aircraft")
                            .font(.system(size: 16))
                            .foregroundStyle(.white)

                        Text(levelDescription)
                            .font(.system(size: 12))
                            .foregroundStyle(.white.opacity(0.8))
                            .multilineTextAlignment(.center)
                            .frame(width: 200)
                    }
                }
                .padding(.trailing, 120)
            }
        )
    }
}

@main
struct Airplane_IDApp: App {
    @State private var appState = AppState()

    // MARK: - Development Settings
    private let loadTestData = true // Set to true to load test data on launch
    private let forceClearDatabase = true // Set to true to clear and reload all test data

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Item.self,
            CapturedAircraft.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            MainView()
                .environment(appState)
                .onAppear {
                    print("🚀 App onAppear triggered")
                    if forceClearDatabase {
                        print("🗑️ Clearing database...")
                        clearAllData()
                    }
                    if loadTestData {
                        print("📥 Loading test data...")
                        loadTestDataOnce()
                    }
                    print("✅ Startup complete")
                }
        }
        .modelContainer(sharedModelContainer)
    }

    // MARK: - Database Management

    /// Clears all data from the database
    private func clearAllData() {
        let context = sharedModelContainer.mainContext

        do {
            try context.delete(model: CapturedAircraft.self)
            try context.delete(model: Item.self)
            try context.save()
            print("🗑️ Database cleared successfully")
        } catch {
            print("❌ Error clearing database: \(error)")
        }
    }

    // MARK: - Test Data Loading

    /// Loads test data only once (checks if data already exists)
    private func loadTestDataOnce() {
        let context = sharedModelContainer.mainContext
        print("📊 Checking existing data...")

        // Check if we already have data
        let fetchDescriptor = FetchDescriptor<CapturedAircraft>()
        do {
            let existingCount = try context.fetchCount(fetchDescriptor)
            print("📊 Existing count: \(existingCount)")
            if existingCount > 0 {
                print("ℹ️ Test data already exists (\(existingCount) records), skipping import")
                return
            }
        } catch {
            print("❌ Error checking count: \(error)")
        }

        // Load test data
        print("📥 Calling importTestData...")
        importTestData()
    }

    /// Imports test data
    private func importTestData() {
        let context = sharedModelContainer.mainContext

        // Test data from CSV
        let testData: [(icao: String, manufacturer: String, model: String, engineType: String, numEngines: Int, registration: String, year: Int, month: Int, day: Int, utc: String, lat: Double, lon: Double, thumbs: Int, rating: Double)] = [
            ("A500", "Adam", "A-500", "Piston", 2, "N12345", 2024, 1, 27, "20:09:45", 43.99083, -88.57411, 0, 0),
            ("M346", "Aermacchi", "M-346 Master", "Jet", 2, "N4455", 2024, 2, 8, "20:09:45", 43.99056, -88.56877, 1, 4.5),
            ("M339", "Aermacchi", "MB-339", "Jet", 1, "N12VS", 2025, 3, 14, "20:09:45", 43.98986, -88.56456, 2, 5),
            ("AAT3", "Aero", "3 AT-3", "Piston", 1, "N3344", 2025, 5, 20, "20:09:45", 43.98964, -88.55993, 1, 5),
            ("B701", "Boeing", "707-100", "Jet", 4, "N1678", 2025, 6, 5, "20:09:45", 43.99007, -88.55594, 1, 3),
            ("C172", "Cessna", "Skyhawk", "Piston", 1, "N2757", 2025, 10, 31, "20:09:45", 43.99289, -88.57291, 1, 4),
            ("SR22", "Cirrus", "SR-22", "Piston", 1, "N252Q", 2025, 12, 24, "20:09:45", 43.98845, -88.55797, 2, 2),
            ("S22T", "Cirrus", "SR22 Turbo", "Piston", 1, "N7779", 2026, 1, 5, "20:09:45", 43.98959, -88.55556, 2, 1),
            ("DC3", "Douglas", "DC-3", "Piston", 2, "N1573", 2026, 1, 5, "20:09:45", 43.99073, -88.55169, 2, 0),
            ("ACAM", "Lockwood", "Air Cam", "Piston", 2, "N79QF", 2026, 1, 7, "20:09:45", 43.9879, -88.55548, 0, 5),
            ("HDJT", "Honda", "HondaJet", "Jet", 2, "N769F", 2026, 1, 15, "20:09:45", 43.98968, -88.55128, 0, 0)
        ]

        var importCount = 0

        for data in testData {
            // Create date from components
            var dateComponents = DateComponents()
            dateComponents.year = data.year
            dateComponents.month = data.month
            dateComponents.day = data.day
            dateComponents.timeZone = TimeZone(identifier: "UTC")

            // Parse time
            let timeParts = data.utc.split(separator: ":")
            if timeParts.count == 3 {
                dateComponents.hour = Int(timeParts[0])
                dateComponents.minute = Int(timeParts[1])
                dateComponents.second = Int(timeParts[2])
            }

            guard let captureDate = Calendar.current.date(from: dateComponents) else {
                print("❌ Failed to create date for \(data.icao)")
                continue
            }

            // Convert thumbs: 0 = nil, 1 = true, 2 = false
            let thumbsUp: Bool? = data.thumbs == 0 ? nil : (data.thumbs == 1 ? true : false)

            // Convert rating: 0 = nil, otherwise use value
            let rating: Int? = data.rating == 0 ? nil : Int(data.rating)

            let aircraft = CapturedAircraft(
                captureDate: captureDate,
                gpsLongitude: data.lon,
                gpsLatitude: data.lat,
                year: data.year,
                month: data.month,
                day: data.day,
                timeUTC: data.utc,
                icao: data.icao,
                manufacturer: data.manufacturer,
                model: data.model,
                engine: data.engineType,
                numberOfEngines: data.numEngines,
                registration: data.registration,
                rating: rating,
                thumbsUp: thumbsUp
            )

            context.insert(aircraft)
            importCount += 1
        }

        // Save context
        do {
            try context.save()
            print("✅ Successfully imported \(importCount) test aircraft records")
        } catch {
            print("❌ Error saving test data: \(error)")
        }
    }
}
