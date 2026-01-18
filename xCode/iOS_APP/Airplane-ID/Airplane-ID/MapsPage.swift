//
//  MapsPage.swift
//  Airplane-ID
//
//  Created by Jim Kerr on 1/16/26.
//
//  Full-screen Apple Maps integration with aircraft location display,
//  location search, and aircraft search capabilities.
//

import SwiftUI
import MapKit
import SwiftData

// MARK: - CapturedAircraft Map Extensions
extension CapturedAircraft {
    /// Whether this aircraft has valid GPS coordinates for display on map
    var hasValidLocation: Bool {
        // Check current location first (priority)
        if let lat = gpsLatitudeNow, let lon = gpsLongitudeNow, lat != 0 && lon != 0 {
            return true
        }
        // Fall back to capture location
        return gpsLatitude != 0 && gpsLongitude != 0
    }

    /// The coordinate to display on map (current location has priority over capture location)
    var displayCoordinate: CLLocationCoordinate2D {
        // Priority: current location > capture location
        if let lat = gpsLatitudeNow, let lon = gpsLongitudeNow, lat != 0 && lon != 0 {
            return CLLocationCoordinate2D(latitude: lat, longitude: lon)
        }
        return CLLocationCoordinate2D(latitude: gpsLatitude, longitude: gpsLongitude)
    }

    /// Display label for map annotation: "Model Manufacturer (Registration)"
    var mapDisplayLabel: String {
        if let reg = registration, !reg.isEmpty {
            return "\(model) \(manufacturer) (\(reg))"
        }
        return "\(model) \(manufacturer)"
    }
}

// MARK: - Recent Search Model
/// A search item stored in recent searches history
struct RecentSearch: Codable, Identifiable, Equatable {
    let id: UUID
    let text: String
    let type: String  // "location" or "aircraft"
    let timestamp: Date

    init(text: String, type: String) {
        self.id = UUID()
        self.text = text
        self.type = type
        self.timestamp = Date()
    }
}

// MARK: - Maps Search State
/// Observable state for map search functionality with UserDefaults persistence
@Observable
final class MapsSearchState {
    enum SearchMode: String, CaseIterable {
        case location = "Locations"
        case aircraft = "Aircraft"
    }

    // MARK: - Properties
    var searchMode: SearchMode = .location
    var searchText: String = ""
    var recentSearches: [RecentSearch] = []

    private let maxRecentSearches = 6
    private let recentSearchesKey = "mapsSearch_recentSearches"

    // MARK: - Initialization
    init() {
        load()
    }

    // MARK: - Public Methods

    /// Add a search to recent history
    func addRecentSearch(_ text: String, type: SearchMode) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        // Remove existing entry with same text and type (if any)
        recentSearches.removeAll { $0.text == trimmed && $0.type == type.rawValue }

        // Add new entry at the beginning
        let search = RecentSearch(text: trimmed, type: type.rawValue)
        recentSearches.insert(search, at: 0)

        // Limit to max items
        if recentSearches.count > maxRecentSearches {
            recentSearches = Array(recentSearches.prefix(maxRecentSearches))
        }

        save()
    }

    /// Clear all recent searches
    func clearRecentSearches() {
        recentSearches.removeAll()
        save()
    }

    /// Remove a specific recent search
    func removeRecentSearch(_ search: RecentSearch) {
        recentSearches.removeAll { $0.id == search.id }
        save()
    }

    // MARK: - Persistence

    private func save() {
        do {
            let data = try JSONEncoder().encode(recentSearches)
            UserDefaults.standard.set(data, forKey: recentSearchesKey)
        } catch {
            #if DEBUG
            print("MapsSearchState: Failed to save recent searches - \(error)")
            #endif
        }
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: recentSearchesKey) else { return }
        do {
            recentSearches = try JSONDecoder().decode([RecentSearch].self, from: data)
        } catch {
            #if DEBUG
            print("MapsSearchState: Failed to load recent searches - \(error)")
            #endif
        }
    }
}

// MARK: - Maps Page
/// Map view showing aircraft sighting locations with search capabilities
struct MapsPage: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext
    private let locationManager = LocationManager.shared

    // Map state
    @State private var cameraPosition: MapCameraPosition = .userLocation(fallback: .automatic)
    @State private var showingSearchSheet = false

    // Search state
    @State private var searchState = MapsSearchState()
    @State private var locationResults: [MKMapItem] = []
    @State private var isSearching = false
    @State private var searchTask: Task<Void, Never>?

    // Query aircraft with valid locations
    @Query private var allAircraft: [CapturedAircraft]

    /// Aircraft that have valid GPS coordinates for map display
    private var aircraftWithLocation: [CapturedAircraft] {
        allAircraft.filter { $0.hasValidLocation }
    }

    /// Filtered aircraft matching search text
    private var filteredAircraft: [CapturedAircraft] {
        let searchText = searchState.searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !searchText.isEmpty else { return [] }

        let keywords = searchText.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
        guard !keywords.isEmpty else { return [] }

        return aircraftWithLocation.filter { aircraft in
            let searchable = "\(aircraft.icao) \(aircraft.manufacturer) \(aircraft.model) \(aircraft.registration ?? "")"
                .lowercased()
            return keywords.allSatisfy { searchable.contains($0) }
        }
        .prefix(20)
        .map { $0 }
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Full-screen map
                mapView
                    .ignoresSafeArea()

                // UI Overlays
                VStack(spacing: 0) {
                    // Header
                    mapsHeader

                    // Spacer pushes footer to bottom
                    Spacer()

                    // Control buttons positioned above footer
                    HStack {
                        Spacer()
                        VStack(spacing: 12) {
                            // Return to location button
                            Button(action: centerOnUserLocation) {
                                Image(systemName: "location.fill")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundStyle(AppColors.primaryBlue)
                                    .frame(width: 44, height: 44)
                                    .background(Color.white)
                                    .clipShape(Circle())
                                    .shadow(radius: 3)
                            }

                            // Search button
                            Button(action: { showingSearchSheet = true }) {
                                Image(systemName: "magnifyingglass")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundStyle(.white)
                                    .frame(width: 44, height: 44)
                                    .background(AppColors.mediumGray)
                                    .clipShape(Circle())
                                    .shadow(radius: 3)
                            }
                        }
                        .padding(.trailing, 16)
                        .padding(.bottom, 16)
                    }

                    // Footer
                    BottomMenuView()
                }
            }
        }
        .onAppear {
            locationManager.checkAndRequestAuthorization()
        }
        .sheet(isPresented: $showingSearchSheet) {
            MapsSearchSheet(
                searchState: searchState,
                locationResults: locationResults,
                isSearching: isSearching,
                filteredAircraft: filteredAircraft,
                onLocationSelected: handleLocationSelected,
                onAircraftSelected: handleAircraftSelected,
                onRecentSearchSelected: handleRecentSearchSelected,
                onSearchTextChanged: performLocationSearch
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
    }

    // MARK: - Map View

    private var mapView: some View {
        Map(position: $cameraPosition) {
            // User location (blue dot)
            UserAnnotation()

            // Aircraft markers
            ForEach(aircraftWithLocation) { aircraft in
                Annotation(
                    aircraft.mapDisplayLabel,
                    coordinate: aircraft.displayCoordinate
                ) {
                    Image(systemName: "airplane")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(AppColors.orange)
                        .rotationEffect(.degrees(-45))
                }
            }
        }
        .mapControls {
            MapCompass()
            MapScaleView()
        }
    }

    // MARK: - Header

    private var mapsHeader: some View {
        HStack {
            // Left side - user status indicator
            HStack(spacing: 8) {
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(.white)

                Circle()
                    .fill(Color.green)
                    .frame(width: 10, height: 10)
            }
            .padding(.leading, 16)

            Spacer()

            // Page title
            Text("MAPS")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(.white)

            Spacer()

            // Right side spacer for balance
            HStack(spacing: 8) {
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(.clear)

                Circle()
                    .fill(Color.clear)
                    .frame(width: 10, height: 10)
            }
            .padding(.trailing, 16)
        }
        .frame(height: 56)
        .background(AppColors.darkBlue)
    }

    // MARK: - Actions

    private func centerOnUserLocation() {
        withAnimation {
            cameraPosition = .userLocation(fallback: .automatic)
        }
    }

    private func centerOnCoordinate(_ coordinate: CLLocationCoordinate2D) {
        withAnimation {
            cameraPosition = .region(MKCoordinateRegion(
                center: coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            ))
        }
    }

    private func handleLocationSelected(_ mapItem: MKMapItem) {
        let displayName = mapItem.name ?? searchState.searchText
        searchState.addRecentSearch(displayName, type: .location)
        centerOnCoordinate(mapItem.location.coordinate)
        showingSearchSheet = false
    }

    private func handleAircraftSelected(_ aircraft: CapturedAircraft) {
        searchState.addRecentSearch(aircraft.mapDisplayLabel, type: .aircraft)
        centerOnCoordinate(aircraft.displayCoordinate)
        showingSearchSheet = false
    }

    private func handleRecentSearchSelected(_ search: RecentSearch) {
        if search.type == MapsSearchState.SearchMode.aircraft.rawValue {
            // Search for the aircraft
            searchState.searchMode = .aircraft
            searchState.searchText = search.text
        } else {
            // Re-run location search
            searchState.searchMode = .location
            searchState.searchText = search.text
            performLocationSearch(search.text)
        }
    }

    private func performLocationSearch(_ query: String) {
        searchTask?.cancel()

        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            locationResults = []
            isSearching = false
            return
        }

        isSearching = true

        searchTask = Task {
            // Debounce: wait 300ms before searching
            try? await Task.sleep(nanoseconds: 300_000_000)

            guard !Task.isCancelled else { return }

            let request = MKLocalSearch.Request()
            request.naturalLanguageQuery = trimmed
            request.resultTypes = [.address, .pointOfInterest]

            let search = MKLocalSearch(request: request)
            do {
                let response = try await search.start()
                await MainActor.run {
                    locationResults = Array(response.mapItems.prefix(20))
                    isSearching = false
                }
            } catch {
                await MainActor.run {
                    locationResults = []
                    isSearching = false
                }
                #if DEBUG
                print("MapsPage: Location search error - \(error.localizedDescription)")
                #endif
            }
        }
    }
}

// MARK: - Maps Search Sheet
/// Bottom sheet for searching locations and aircraft
struct MapsSearchSheet: View {
    @Bindable var searchState: MapsSearchState
    let locationResults: [MKMapItem]
    let isSearching: Bool
    let filteredAircraft: [CapturedAircraft]
    let onLocationSelected: (MKMapItem) -> Void
    let onAircraftSelected: (CapturedAircraft) -> Void
    let onRecentSearchSelected: (RecentSearch) -> Void
    let onSearchTextChanged: (String) -> Void

    @Environment(\.dismiss) private var dismiss
    @FocusState private var isSearchFocused: Bool

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search mode picker
                Picker("Search Mode", selection: $searchState.searchMode) {
                    ForEach(MapsSearchState.SearchMode.allCases, id: \.self) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 16)
                .padding(.top, 8)

                // Search field
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)

                    TextField(searchPlaceholder, text: $searchState.searchText)
                        .textFieldStyle(.plain)
                        .focused($isSearchFocused)
                        .autocorrectionDisabled()
                        .onChange(of: searchState.searchText) { _, newValue in
                            if searchState.searchMode == .location {
                                onSearchTextChanged(newValue)
                            }
                        }

                    if !searchState.searchText.isEmpty {
                        Button(action: { searchState.searchText = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.secondary)
                        }
                    }

                    if isSearching {
                        ProgressView()
                            .scaleEffect(0.8)
                    }
                }
                .padding(12)
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)

                // Results list
                List {
                    if searchState.searchText.isEmpty {
                        // Show recent searches
                        if !searchState.recentSearches.isEmpty {
                            Section {
                                ForEach(searchState.recentSearches) { search in
                                    Button(action: { onRecentSearchSelected(search) }) {
                                        HStack {
                                            Image(systemName: "clock")
                                                .foregroundStyle(.secondary)
                                                .frame(width: 24)

                                            Text(search.text)
                                                .foregroundStyle(.primary)

                                            Spacer()

                                            Image(systemName: search.type == "aircraft" ? "airplane" : "mappin")
                                                .foregroundStyle(.secondary)
                                                .font(.caption)
                                        }
                                    }
                                }
                                .onDelete { indexSet in
                                    for index in indexSet {
                                        searchState.removeRecentSearch(searchState.recentSearches[index])
                                    }
                                }
                            } header: {
                                Text("Recent Searches")
                            }
                        }
                    } else {
                        // Show search results
                        if searchState.searchMode == .location {
                            locationResultsSection
                        } else {
                            aircraftResultsSection
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
            .navigationTitle("Search")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .onAppear {
            isSearchFocused = true
        }
    }

    private var searchPlaceholder: String {
        switch searchState.searchMode {
        case .location:
            return "City, airport, country..."
        case .aircraft:
            return "ICAO, manufacturer, model, registration..."
        }
    }

    @ViewBuilder
    private var locationResultsSection: some View {
        if locationResults.isEmpty && !isSearching {
            Section {
                Text("No locations found")
                    .foregroundStyle(.secondary)
            }
        } else {
            Section {
                ForEach(Array(locationResults.enumerated()), id: \.offset) { index, mapItem in
                    Button(action: { onLocationSelected(mapItem) }) {
                        HStack {
                            Image(systemName: "mappin.circle.fill")
                                .foregroundStyle(AppColors.primaryBlue)
                                .frame(width: 24)

                            Text(mapItem.name ?? "Unknown")
                                .foregroundStyle(.primary)

                            Spacer()
                        }
                    }
                }
            } header: {
                Text("Locations")
            }
        }
    }

    @ViewBuilder
    private var aircraftResultsSection: some View {
        if filteredAircraft.isEmpty {
            Section {
                Text("No aircraft found with GPS coordinates")
                    .foregroundStyle(.secondary)
            }
        } else {
            Section {
                ForEach(filteredAircraft) { aircraft in
                    Button(action: { onAircraftSelected(aircraft) }) {
                        HStack {
                            Image(systemName: "airplane")
                                .foregroundStyle(AppColors.orange)
                                .rotationEffect(.degrees(-45))
                                .frame(width: 24)

                            VStack(alignment: .leading, spacing: 2) {
                                // Line 1: Model + Manufacturer (always shown)
                                Text("\(aircraft.model) \(aircraft.manufacturer)")
                                    .font(.headline)
                                    .foregroundStyle(.primary)

                                // Line 2: Registration + Owner (if either exists)
                                // Line 3 fallback: Aircraft Type + Engine Type
                                if let secondLine = aircraftSearchSecondLine(aircraft) {
                                    Text(secondLine)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }

                            Spacer()
                        }
                    }
                }
            } header: {
                Text("Aircraft (\(filteredAircraft.count))")
            }
        }
    }

    /// Determines the second line for aircraft search results
    /// Priority: Registration + Owner, fallback to Aircraft Type + Engine Type
    private func aircraftSearchSecondLine(_ aircraft: CapturedAircraft) -> String? {
        // Try Line 2: Registration + Owner
        let registration = aircraft.registration
        let owner = aircraft.registeredOwner

        if registration != nil || owner != nil {
            // Build line with available data
            var parts: [String] = []
            if let reg = registration, !reg.isEmpty {
                parts.append(reg)
            }
            if let own = owner, !own.isEmpty {
                parts.append(own)
            }
            if !parts.isEmpty {
                return parts.joined(separator: " ")
            }
        }

        // Fallback to Line 3: Aircraft Type + Engine Type
        let typeName = AircraftLookup.typeName(aircraft.aircraftType)
        let engineName = AircraftLookup.engineTypeName(aircraft.engineType)

        var fallbackParts: [String] = []
        if let type = typeName {
            fallbackParts.append(type)
        }
        if let engine = engineName {
            fallbackParts.append(engine)
        }

        if !fallbackParts.isEmpty {
            return fallbackParts.joined(separator: " ")
        }

        return nil
    }
}

// MARK: - Previews
#Preview("Portrait") {
    MapsPage()
        .environment(AppState())
        .modelContainer(for: CapturedAircraft.self, inMemory: true)
}
