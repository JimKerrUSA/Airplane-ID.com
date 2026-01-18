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
            case .upload:
                UploadPage()
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
        await loadCountryCodesIfNeeded()
    }

    /// Load airline codes from bundled CSV if table is empty
    @MainActor
    private func loadAirlineCodesIfNeeded() async {
        let descriptor = FetchDescriptor<AirlineLookup>()
        let existingCount = (try? modelContext.fetchCount(descriptor)) ?? 0
        guard existingCount == 0 else { return }

        guard let csvURL = Bundle.main.url(forResource: "AirlineCodes", withExtension: "csv") else {
            #if DEBUG
            print("AirlineCodes.csv not found in bundle")
            #endif
            return
        }

        do {
            let csvContent = try String(contentsOf: csvURL, encoding: .utf8)
            let lines = csvContent.components(separatedBy: .newlines).filter { !$0.isEmpty }
            guard lines.count > 1 else { return }

            // Columns: airlineCode(0), iata(1), airlineName(2)
            for line in lines.dropFirst() {
                let columns = CSVParser.parseLine(line)
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
            #if DEBUG
            print("Loaded \(lines.count - 1) airline codes from bundle")
            #endif
        } catch {
            #if DEBUG
            print("Error loading airline codes: \(error)")
            #endif
        }
    }

    /// Load ICAO aircraft type codes from bundled CSV if table is empty
    @MainActor
    private func loadICAOCodesIfNeeded() async {
        let descriptor = FetchDescriptor<ICAOLookup>()
        let existingCount = (try? modelContext.fetchCount(descriptor)) ?? 0
        guard existingCount == 0 else { return }

        guard let csvURL = Bundle.main.url(forResource: "ICAOCodes", withExtension: "csv") else {
            #if DEBUG
            print("ICAOCodes.csv not found in bundle")
            #endif
            return
        }

        do {
            let csvContent = try String(contentsOf: csvURL, encoding: .utf8)
            let lines = csvContent.components(separatedBy: .newlines).filter { !$0.isEmpty }
            guard lines.count > 1 else { return }

            // Columns: icao(0), manufacturer(1), model(2), icaoClass(3), aircraftCategoryCode(4), aircraftType(5), engineCount(6), engineType(7)
            for line in lines.dropFirst() {
                let columns = CSVParser.parseLine(line)
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
            #if DEBUG
            print("Loaded \(lines.count - 1) ICAO aircraft types from bundle")
            #endif
        } catch {
            #if DEBUG
            print("Error loading ICAO codes: \(error)")
            #endif
        }
    }

    /// Load country codes from bundled CSV if table is empty
    @MainActor
    private func loadCountryCodesIfNeeded() async {
        let descriptor = FetchDescriptor<CountryLookup>()
        let existingCount = (try? modelContext.fetchCount(descriptor)) ?? 0
        guard existingCount == 0 else { return }

        guard let csvURL = Bundle.main.url(forResource: "CountryCodes", withExtension: "csv") else {
            #if DEBUG
            print("CountryCodes.csv not found in bundle")
            #endif
            return
        }

        do {
            let csvContent = try String(contentsOf: csvURL, encoding: .utf8)
            let lines = csvContent.components(separatedBy: .newlines).filter { !$0.isEmpty }
            guard lines.count > 1 else { return }

            // Columns: code(0), name(1)
            for line in lines.dropFirst() {
                let columns = CSVParser.parseLine(line)
                guard columns.count >= 2 else { continue }

                let code = columns[0].trimmingCharacters(in: .whitespaces).uppercased()
                let name = columns[1].trimmingCharacters(in: .whitespaces)

                guard code.count == 2 && !name.isEmpty else { continue }

                let country = CountryLookup(code: code, name: name)
                modelContext.insert(country)
            }

            try modelContext.save()
            #if DEBUG
            print("Loaded \(lines.count - 1) country codes from bundle")
            #endif
        } catch {
            #if DEBUG
            print("Error loading country codes: \(error)")
            #endif
        }
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
            CountryLookup.self,
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

                // Capture mode change toast overlay
                if appState.showCaptureModeToast {
                    VStack {
                        Spacer()

                        HStack(spacing: 12) {
                            Image(systemName: appState.captureModeIcon)
                                .font(.system(size: 20, weight: .medium))
                                .foregroundStyle(.white)

                            Text(appState.captureToastMessage)
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(.white)
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 14)
                        .background(
                            Capsule()
                                .fill(AppColors.darkBlue.opacity(0.95))
                                .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
                        )
                        .padding(.bottom, 120) // Above the footer
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .animation(.spring(duration: 0.3), value: appState.showCaptureModeToast)
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
