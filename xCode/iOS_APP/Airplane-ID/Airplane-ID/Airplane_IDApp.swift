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
}

// MARK: - App Entry Point
@main
struct Airplane_IDApp: App {
    @State private var appState = AppState()

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            CapturedAircraft.self,
            User.self,
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
