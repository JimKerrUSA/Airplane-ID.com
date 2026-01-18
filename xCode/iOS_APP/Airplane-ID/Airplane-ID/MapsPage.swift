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

    /// Returns the appropriate map icon name based on ICAO code, aircraft type, and engine type
    /// Priority: 1) Exact ICAO match, 2) ICAO prefix match, 3) Generic type fallback
    /// Icons are in Assets.xcassets/MapIcons/
    /// - Returns: Asset name for the map icon
    var mapIconName: String {
        // Try ICAO-specific icon first (exact match, then prefix interpolation)
        if let icaoIcon = MapIconHelper.findICAOIcon(for: icao) {
            return icaoIcon
        }

        // Fall back to generic type-based icon
        return genericTypeIcon
    }

    /// Generic icon based on aircraft type and engine type (fallback when no ICAO match)
    private var genericTypeIcon: String {
        // Aircraft type codes:
        // "1" = Glider, "2" = Balloon, "3" = Blimp, "4" = FW Single, "5" = FW Multi
        // "6" = Rotorcraft, "7" = Weight Shift, "8" = Powered Parachute, "9" = Gyroplane
        // "H" = Hybrid Lift, "O" = Other

        switch aircraftType {
        case "2":  // Balloon
            return "MapIcons/icon-balloon"
        case "3":  // Blimp - use balloon as closest match
            return "MapIcons/icon-balloon"
        case "8":  // Powered Parachute - use balloon (vertical orientation)
            return "MapIcons/icon-balloon"
        case "4":  // Fixed Wing Single-Engine
            return "MapIcons/icon-single-prop"
        case "1":  // Glider - use single-prop silhouette
            return "MapIcons/icon-single-prop"
        case "7":  // Weight Shift Control - use single-prop
            return "MapIcons/icon-single-prop"
        case "5":  // Fixed Wing Multi-Engine - check engine type
            // Engine types: 1=Recip, 2=Turbo-prop, 3=Turbo-shaft, 4=Turbo-jet, 5=Turbo-fan
            if engineType == 4 || engineType == 5 {
                return "MapIcons/icon-jet"
            }
            return "MapIcons/icon-twin-prop"
        case "6":  // Rotorcraft
            return "MapIcons/icon-helicopter"
        case "9":  // Gyroplane - use helicopter
            return "MapIcons/icon-helicopter"
        case "H":  // Hybrid Lift (tiltrotor) - use jet
            return "MapIcons/icon-jet"
        default:   // "O" = Other or unknown - use single-prop as default
            return "MapIcons/icon-single-prop"
        }
    }
}

// MARK: - Map Icon Helper
/// Helper for finding ICAO-specific map icons with prefix interpolation
enum MapIconHelper {
    /// Set of available ICAO codes that have custom icons
    /// These correspond to icao-{CODE}.imageset in Assets.xcassets/MapIcons/
    static let availableICAOs: Set<String> = [
        "ACAM", "AS20", "AS50", "AT5T", "BALL",
        "BE23", "BE35", "BE55", "BE58", "BL17",
        "C140", "C150", "C172", "C180", "C182", "C185", "C206", "C207", "C208", "C210", "C310", "C421",
        "CH60", "COZY",
        "DA40", "DR40",
        "EC20", "ECHO",
        "GA7", "GSIS",
        "HDJT",
        "J3", "JAB4",
        "KODI",
        "M20P", "M20T", "M600",
        "NG5",
        "P28A", "P28R", "P46T",
        "PA11", "PA12", "PA18", "PA22", "PA24", "PA25", "PA27", "PA31", "PA32", "PA34", "PA44", "PA46",
        "PC12",
        "R22", "R44", "R66",
        "qsgt",
        "RV6", "RV10", "RV12",
        "SF50", "SIRA", "SR22",
        "T34P"
    ]

    /// Attempts to find an ICAO-specific icon for the given code
    /// Uses prefix interpolation: M20J → tries M20J, then M20, then M2, then M
    /// - Parameter icao: The aircraft's ICAO code
    /// - Returns: Asset path if found, nil otherwise
    static func findICAOIcon(for icao: String) -> String? {
        let code = icao.uppercased().trimmingCharacters(in: .whitespaces)
        guard !code.isEmpty else { return nil }

        // Try exact match first
        if availableICAOs.contains(code) {
            return "MapIcons/icao-\(code)"
        }

        // Try progressively shorter prefixes (minimum 2 characters)
        var prefix = code
        while prefix.count > 1 {
            prefix = String(prefix.dropLast())

            // Find any ICAO that starts with this prefix
            if let match = availableICAOs.first(where: { $0.hasPrefix(prefix) }) {
                // Prefer exact prefix match over partial
                if availableICAOs.contains(prefix) {
                    return "MapIcons/icao-\(prefix)"
                }
                // Use the first match found
                return "MapIcons/icao-\(match)"
            }
        }

        // No ICAO match found
        return nil
    }
}

// MARK: - Aircraft Cluster Model
/// Represents either a single aircraft or a cluster of multiple aircraft
struct AircraftCluster: Identifiable {
    let id = UUID()
    let aircraft: [CapturedAircraft]
    let coordinate: CLLocationCoordinate2D

    var isCluster: Bool { aircraft.count > 1 }
    var count: Int { aircraft.count }

    /// Single aircraft (for non-clustered display)
    var singleAircraft: CapturedAircraft? {
        aircraft.count == 1 ? aircraft.first : nil
    }

    /// Primary aircraft for icon display (uses first aircraft in cluster)
    var primaryAircraft: CapturedAircraft {
        aircraft.first!
    }
}

// MARK: - Clustering Helper
/// Clusters nearby aircraft based on map zoom level
enum AircraftClusterHelper {
    /// Minimum distance in degrees for aircraft to be clustered together
    /// Scales with zoom level (larger span = more clustering)
    static func clusterDistance(for mapSpan: Double) -> Double {
        // When zoomed out (span ~0.5), cluster within ~0.05 degrees (~3 miles)
        // When zoomed in (span ~0.05), cluster within ~0.005 degrees (~0.3 miles)
        return mapSpan * 0.1
    }

    /// Groups aircraft into clusters based on proximity
    static func cluster(_ aircraft: [CapturedAircraft], mapSpan: Double) -> [AircraftCluster] {
        guard !aircraft.isEmpty else { return [] }

        let threshold = clusterDistance(for: mapSpan)
        var remaining = aircraft
        var clusters: [AircraftCluster] = []

        while !remaining.isEmpty {
            let seed = remaining.removeFirst()
            var clusterMembers = [seed]
            var centerLat = seed.displayCoordinate.latitude
            var centerLon = seed.displayCoordinate.longitude

            // Find all aircraft within threshold of this seed
            var i = 0
            while i < remaining.count {
                let candidate = remaining[i]
                let candidateCoord = candidate.displayCoordinate

                // Simple distance check (works well for small areas)
                let latDiff = abs(candidateCoord.latitude - centerLat)
                let lonDiff = abs(candidateCoord.longitude - centerLon)

                if latDiff < threshold && lonDiff < threshold {
                    clusterMembers.append(candidate)
                    // Update center as average of all members
                    centerLat = clusterMembers.map { $0.displayCoordinate.latitude }.reduce(0, +) / Double(clusterMembers.count)
                    centerLon = clusterMembers.map { $0.displayCoordinate.longitude }.reduce(0, +) / Double(clusterMembers.count)
                    remaining.remove(at: i)
                } else {
                    i += 1
                }
            }

            let cluster = AircraftCluster(
                aircraft: clusterMembers,
                coordinate: CLLocationCoordinate2D(latitude: centerLat, longitude: centerLon)
            )
            clusters.append(cluster)
        }

        return clusters
    }
}

// MARK: - Aircraft Map Annotation View
/// Custom annotation view with black-outlined icon and side-positioned label
/// Matches Apple Maps design patterns
struct AircraftMapAnnotation: View {
    let aircraft: CapturedAircraft
    let showLabel: Bool
    let onTap: () -> Void

    /// Short label for map display (registration or abbreviated model)
    private var shortLabel: String {
        if let reg = aircraft.registration, !reg.isEmpty {
            return reg
        }
        // Fallback to abbreviated model (first 8 chars)
        let model = aircraft.model
        if model.count > 8 {
            return String(model.prefix(8))
        }
        return model
    }

    var body: some View {
        HStack(alignment: .center, spacing: 4) {
            // Aircraft icon with black outline effect
            aircraftIcon

            // Label positioned to the side (only when zoomed in)
            if showLabel {
                Text(shortLabel)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.black)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 2)
                    .background(
                        RoundedRectangle(cornerRadius: 3)
                            .fill(.white.opacity(0.9))
                    )
                    .lineLimit(1)
            }
        }
        .onTapGesture(perform: onTap)
    }

    /// Aircraft icon with black outline/shadow for visibility
    private var aircraftIcon: some View {
        Image(aircraft.mapIconName)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: 34, height: 34)
            .foregroundStyle(AppColors.orange)
            // Black outline effect using multiple shadows
            .shadow(color: .black, radius: 0.5, x: 0, y: 0)
            .shadow(color: .black, radius: 0.5, x: 0.5, y: 0)
            .shadow(color: .black, radius: 0.5, x: -0.5, y: 0)
            .shadow(color: .black, radius: 0.5, x: 0, y: 0.5)
            .shadow(color: .black, radius: 0.5, x: 0, y: -0.5)
    }
}

// MARK: - Cluster Annotation View
/// Annotation view for clustered aircraft (shows count badge)
struct ClusterAnnotation: View {
    let cluster: AircraftCluster
    let onTap: () -> Void

    var body: some View {
        ZStack {
            // Background circle with aircraft icon
            Circle()
                .fill(AppColors.orange)
                .frame(width: 44, height: 44)
                .overlay(
                    Circle()
                        .stroke(Color.black, lineWidth: 2)
                )
                .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)

            // Aircraft silhouette (use first aircraft's icon)
            Image(cluster.primaryAircraft.mapIconName)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 26, height: 26)
                .foregroundStyle(.white)

            // Count badge
            Text("\(cluster.count)")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(.white)
                .padding(.horizontal, 5)
                .padding(.vertical, 2)
                .background(
                    Capsule()
                        .fill(AppColors.darkBlue)
                        .overlay(
                            Capsule()
                                .stroke(Color.white, lineWidth: 1)
                        )
                )
                .offset(x: 16, y: -16)
        }
        .onTapGesture(perform: onTap)
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
    @State private var mapSpan: Double = 0.05  // Track zoom level (smaller = more zoomed in)

    /// Whether to show labels based on current zoom level
    /// Labels hidden when zoomed out far enough that they would overlap
    private var shouldShowLabels: Bool {
        mapSpan < 0.15  // Show labels when zoomed in (span < ~10 miles)
    }

    // Search state
    @State private var searchState = MapsSearchState()
    @State private var locationResults: [MKMapItem] = []
    @State private var isSearching = false
    @State private var searchTask: Task<Void, Never>?

    // Aircraft detail view state
    @State private var selectedAircraft: CapturedAircraft?
    @State private var selectedCluster: AircraftCluster?  // For cluster tap handling

    // Query aircraft with valid locations
    @Query private var allAircraft: [CapturedAircraft]

    /// Aircraft that have valid GPS coordinates for map display
    private var aircraftWithLocation: [CapturedAircraft] {
        allAircraft.filter { $0.hasValidLocation }
    }

    /// Clustered aircraft based on current zoom level
    private var aircraftClusters: [AircraftCluster] {
        AircraftClusterHelper.cluster(aircraftWithLocation, mapSpan: mapSpan)
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
        .fullScreenCover(item: $selectedAircraft) { aircraft in
            AircraftDetailView(aircraft: aircraft)
        }
    }

    // MARK: - Map View

    private var mapView: some View {
        Map(position: $cameraPosition) {
            // User location (blue dot)
            UserAnnotation()

            // Aircraft annotations - clustered when zoomed out, individual when zoomed in
            ForEach(aircraftClusters) { cluster in
                Annotation(
                    "",  // Empty title - we handle label in the content view
                    coordinate: cluster.coordinate
                ) {
                    if cluster.isCluster {
                        // Multiple aircraft - show cluster annotation
                        ClusterAnnotation(
                            cluster: cluster,
                            onTap: { handleClusterTap(cluster) }
                        )
                    } else if let aircraft = cluster.singleAircraft {
                        // Single aircraft - show individual annotation
                        AircraftMapAnnotation(
                            aircraft: aircraft,
                            showLabel: shouldShowLabels,
                            onTap: { selectedAircraft = aircraft }
                        )
                    }
                }
            }
        }
        .onMapCameraChange { context in
            // Track zoom level to control label visibility and clustering
            mapSpan = context.region.span.latitudeDelta
        }
        .mapControls {
            MapCompass()
            MapScaleView()
        }
    }

    /// Handle tap on a cluster - zoom in to show individual aircraft
    private func handleClusterTap(_ cluster: AircraftCluster) {
        // Zoom in to show the cluster's aircraft individually
        // Calculate a span that will split up the cluster
        let newSpan = mapSpan / 3  // Zoom in by 3x
        withAnimation {
            cameraPosition = .region(MKCoordinateRegion(
                center: cluster.coordinate,
                span: MKCoordinateSpan(latitudeDelta: newSpan, longitudeDelta: newSpan)
            ))
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
