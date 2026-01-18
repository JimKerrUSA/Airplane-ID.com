//
//  Airplane_IDApp.swift
//  Airplane-ID
//
//  Created by Jim Kerr on 1/15/26.
//

import SwiftUI
import SwiftData
import Photos

// MARK: - Main View (Navigation Router)
/// Switches between screens based on appState.currentScreen
struct MainView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    @State private var hasInitialized = false

    var body: some View {
        Group {
            switch appState.currentScreen {
            case .home:
                HomePage()
            case .maps:
                MapsPage()
            case .camera:
                CameraPage()
            case .hangar:
                HangarPage()
            case .settings:
                SettingsPage()
            case .journey:
                JourneyPage()
            }
        }
        .task {
            guard !hasInitialized else { return }
            hasInitialized = true
            await loadReferenceDataIfNeeded()
        }
    }

    /// Loads bundled reference data on first launch
    @MainActor
    private func loadReferenceDataIfNeeded() async {
        await loadAirlineCodesIfNeeded()
        await loadICAOCodesIfNeeded()
    }

    /// Load airline codes from bundled CSV if table is empty
    @MainActor
    private func loadAirlineCodesIfNeeded() async {
        let descriptor = FetchDescriptor<AirlineLookup>()
        let existingCount = (try? modelContext.fetchCount(descriptor)) ?? 0
        guard existingCount == 0 else { return }

        guard let csvURL = Bundle.main.url(forResource: "AirlineCodes", withExtension: "csv") else {
            print("AirlineCodes.csv not found in bundle")
            return
        }

        do {
            let csvContent = try String(contentsOf: csvURL, encoding: .utf8)
            let lines = csvContent.components(separatedBy: .newlines).filter { !$0.isEmpty }
            guard lines.count > 1 else { return }

            // Columns: airlineCode(0), iata(1), airlineName(2)
            for line in lines.dropFirst() {
                let columns = parseCSVLine(line)
                guard columns.count >= 3 else { continue }

                let airlineCode = columns[0].trimmingCharacters(in: .whitespaces)
                let iata = columns[1].trimmingCharacters(in: .whitespaces)
                let airlineName = columns[2].trimmingCharacters(in: .whitespaces)

                guard !airlineCode.isEmpty && !airlineName.isEmpty else { continue }

                let airline = AirlineLookup(
                    airlineCode: airlineCode,
                    iata: iata.isEmpty ? nil : iata,
                    airlineName: airlineName
                )
                modelContext.insert(airline)
            }

            try modelContext.save()
            print("Loaded \(lines.count - 1) airline codes from bundle")
        } catch {
            print("Error loading airline codes: \(error)")
        }
    }

    /// Load ICAO aircraft type codes from bundled CSV if table is empty
    @MainActor
    private func loadICAOCodesIfNeeded() async {
        let descriptor = FetchDescriptor<ICAOLookup>()
        let existingCount = (try? modelContext.fetchCount(descriptor)) ?? 0
        guard existingCount == 0 else { return }

        guard let csvURL = Bundle.main.url(forResource: "ICAOCodes", withExtension: "csv") else {
            print("ICAOCodes.csv not found in bundle")
            return
        }

        do {
            let csvContent = try String(contentsOf: csvURL, encoding: .utf8)
            let lines = csvContent.components(separatedBy: .newlines).filter { !$0.isEmpty }
            guard lines.count > 1 else { return }

            // Columns: icao(0), manufacturer(1), model(2), icaoClass(3), aircraftCategoryCode(4), aircraftType(5), engineCount(6), engineType(7)
            for line in lines.dropFirst() {
                let columns = parseCSVLine(line)
                guard columns.count >= 8 else { continue }

                let icao = columns[0].trimmingCharacters(in: .whitespaces)
                let manufacturer = columns[1].trimmingCharacters(in: .whitespaces)
                let model = columns[2].trimmingCharacters(in: .whitespaces)
                let icaoClass = columns[3].trimmingCharacters(in: .whitespaces)
                let aircraftCategoryCode = Int(columns[4].trimmingCharacters(in: .whitespaces)) ?? 1
                let aircraftType = columns[5].trimmingCharacters(in: .whitespaces)
                let engineCount = Int(columns[6].trimmingCharacters(in: .whitespaces)) ?? 0
                let engineType = Int(columns[7].trimmingCharacters(in: .whitespaces)) ?? 9

                guard !icao.isEmpty && !manufacturer.isEmpty else { continue }

                let aircraft = ICAOLookup(
                    icao: icao,
                    manufacturer: manufacturer,
                    model: model,
                    icaoClass: icaoClass,
                    aircraftCategoryCode: aircraftCategoryCode,
                    aircraftType: aircraftType,
                    engineCount: engineCount,
                    engineType: engineType
                )
                modelContext.insert(aircraft)
            }

            try modelContext.save()
            print("Loaded \(lines.count - 1) ICAO aircraft types from bundle")
        } catch {
            print("Error loading ICAO codes: \(error)")
        }
    }

    private func parseCSVLine(_ line: String) -> [String] {
        var result: [String] = []
        var current = ""
        var inQuotes = false
        for char in line {
            if char == "\"" { inQuotes.toggle() }
            else if char == "," && !inQuotes {
                result.append(current)
                current = ""
            } else { current.append(char) }
        }
        result.append(current)
        return result
    }
}

// MARK: - App Entry Point
@main
struct Airplane_IDApp: App {
    @State private var appState = AppState()
    @StateObject private var photoManager = PhotoLibraryManager.shared
    @Environment(\.scenePhase) private var scenePhase

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            CapturedAircraft.self,
            User.self,
            AirlineLookup.self,
            ICAOLookup.self,
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
            ZStack {
                MainView()
                    .environment(appState)

                // Permission gatekeeper - blocks app if photo access denied
                if photoManager.authorizationStatus == .denied ||
                   photoManager.authorizationStatus == .restricted {
                    PhotoPermissionView()
                        .transition(.opacity)
                }
            }
            .task {
                // Check and request photo permissions on every app launch
                _ = await photoManager.checkAndRequestAuthorization()
            }
            .onChange(of: scenePhase) { _, newPhase in
                // Re-check permissions when returning from Settings
                if newPhase == .active {
                    Task {
                        _ = await photoManager.checkAuthorization()
                    }
                }
            }
        }
        .modelContainer(sharedModelContainer)
    }
}
