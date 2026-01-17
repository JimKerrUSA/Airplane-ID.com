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

    /// Loads bundled reference data (airline codes) on first launch
    private func loadReferenceDataIfNeeded() async {
        // Check if airline data already exists
        let descriptor = FetchDescriptor<AirlineLookup>()
        let existingCount = (try? modelContext.fetchCount(descriptor)) ?? 0

        guard existingCount == 0 else { return }  // Already populated

        // Load from bundled CSV
        guard let csvURL = Bundle.main.url(forResource: "AirlineCodes", withExtension: "csv") else {
            print("AirlineCodes.csv not found in bundle")
            return
        }

        do {
            let csvContent = try String(contentsOf: csvURL, encoding: .utf8)
            let lines = csvContent.components(separatedBy: .newlines).filter { !$0.isEmpty }
            guard lines.count > 1 else { return }

            // Parse CSV (skip header)
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

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            CapturedAircraft.self,
            User.self,
            AirlineLookup.self,
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
        }
        .modelContainer(sharedModelContainer)
    }
}
