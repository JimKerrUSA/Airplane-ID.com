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

    /// Returns the appropriate map icon name based on ICAO code, manufacturer, and aircraft type
    /// Priority: 1) Exact ICAO match with manufacturer verification, 2) Generic type fallback
    /// Special handling: Airliners use SF Symbol (returned as "sf.airplane")
    /// Icons are in Assets.xcassets/MapIcons/
    /// - Returns: Asset name for the map icon, or "sf.airplane" for SF Symbol
    var mapIconName: String {
        // Check if this is an airliner - use SF Symbol for large commercial jets
        if isAirliner {
            return "sf.airplane"  // Special prefix indicates SF Symbol
        }

        // Try ICAO-specific icon with manufacturer verification
        if let icaoIcon = MapIconHelper.findICAOIcon(for: icao, manufacturer: manufacturer) {
            return icaoIcon
        }

        // Fall back to generic type-based icon
        return genericTypeIcon
    }

    /// Whether this aircraft is a large airliner that should use the generic jet SF Symbol
    /// Criteria: Major airliner manufacturer OR multi-engine jet with 15+ seats
    private var isAirliner: Bool {
        // Check if manufacturer is a major airliner producer
        if MapIconHelper.isAirlinerManufacturer(manufacturer) {
            return true
        }

        // Check if it's a multi-engine jet with 15+ seats (regional/commercial jet)
        if aircraftType == "5" {  // Fixed Wing Multi-Engine
            if engineType == 4 || engineType == 5 {  // Turbo-jet or Turbo-fan
                if let seats = seatCount, seats >= 15 {
                    return true
                }
            }
        }

        return false
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
                // Small business jet (already filtered out airliners above)
                return "MapIcons/icon-jet"
            }
            return "MapIcons/icon-twin-prop"
        case "6":  // Rotorcraft
            // Check if it's a quadcopter/drone (4+ motors)
            if let engines = engineCount, engines >= 4 {
                return "MapIcons/icao-F4"  // Quadcopter drone icon
            }
            return "MapIcons/icon-helicopter"
        case "9":  // Gyroplane - use helicopter
            return "MapIcons/icon-helicopter"
        case "H":  // Hybrid Lift (tiltrotor) - use SF Symbol
            return "sf.airplane"
        default:   // "O" = Other or unknown - use single-prop as default
            return "MapIcons/icon-single-prop"
        }
    }
}

// MARK: - Map Icon Helper
/// Helper for finding ICAO-specific map icons with manufacturer verification
enum MapIconHelper {

    // =========================================================================
    // MANUAL ICAO OVERRIDES - Edit this dictionary to fix icon mismatches
    // =========================================================================
    // Format: "AIRCRAFT_ICAO": "ICON_ICAO"
    // - AIRCRAFT_ICAO = The ICAO code of the plane being displayed
    // - ICON_ICAO = The ICAO code of the icon to use (must exist in icaoToManufacturer)
    //
    // Add a row when you discover an aircraft showing the wrong icon.
    // These overrides are checked FIRST, before any other matching logic.
    // =========================================================================
    static let icaoOverrides: [String: String] = [
        // Air Tractor variants → use AT-502 icon
        "AT3T": "AT5T",   // AT-301 Turbo
        "AT30": "AT5T",   // AT-300
        "AT40": "AT5T",   // AT-400
        "AT50": "AT5T",   // AT-500
        "AT60": "AT5T",   // AT-600
        "AT80": "AT5T",   // AT-800

        // Add more overrides below as needed:
        // "WRONG_ICAO": "CORRECT_ICON_ICAO",
    ]

    /// ICAO codes mapped to their manufacturers (normalized to uppercase for matching)
    /// Only includes general aviation aircraft - NOT airliners
    static let icaoToManufacturer: [String: String] = [
        // Aeronca
        "ACAM": "AERONCA",
        // American Champion / Bellanca
        "BL17": "BELLANCA",
        // Beechcraft
        "BE23": "BEECH", "BE35": "BEECH", "BE55": "BEECH", "BE58": "BEECH",
        // Cessna
        "C140": "CESSNA", "C150": "CESSNA", "C172": "CESSNA", "C180": "CESSNA",
        "C182": "CESSNA", "C185": "CESSNA", "C206": "CESSNA", "C207": "CESSNA",
        "C208": "CESSNA", "C210": "CESSNA", "C310": "CESSNA", "C421": "CESSNA",
        // Cirrus
        "SR22": "CIRRUS", "SF50": "CIRRUS",
        // Cozy/Long-EZ (Experimental)
        "COZY": "COZY",
        // Diamond
        "DA40": "DIAMOND",
        // Eurocopter/Airbus Helicopters
        "AS20": "EUROCOPTER", "AS50": "EUROCOPTER", "EC20": "EUROCOPTER",
        // Grumman/American General
        "GA7": "GRUMMAN",
        // Honda
        "HDJT": "HONDA",
        // Jabiru
        "JAB4": "JABIRU",
        // Kodiak (Quest/Daher)
        "KODI": "KODIAK",
        // Mooney
        "M20P": "MOONEY", "M20T": "MOONEY",
        // Piper
        "J3": "PIPER", "PA11": "PIPER", "PA12": "PIPER", "PA18": "PIPER",
        "PA22": "PIPER", "PA24": "PIPER", "PA25": "PIPER", "PA27": "PIPER",
        "PA31": "PIPER", "PA32": "PIPER", "PA34": "PIPER", "PA44": "PIPER",
        "PA46": "PIPER", "P28A": "PIPER", "P28R": "PIPER", "P46T": "PIPER",
        // Piper M600 (turboprop)
        "M600": "PIPER",
        // Pilatus
        "PC12": "PILATUS",
        // Robin
        "DR40": "ROBIN",
        // Robinson
        "R22": "ROBINSON", "R44": "ROBINSON", "R66": "ROBINSON",
        // Sikorsky
        "CH60": "SIKORSKY",
        // Sling (The Airplane Factory)
        "SIRA": "SLING",
        // Socata/Daher
        "AT5T": "SOCATA",
        // Van's Aircraft (RV series)
        "RV6": "VANS", "RV10": "VANS", "RV12": "VANS",
        // Balloon
        "BALL": "BALLOON",
        // Others
        "ECHO": "ECHO", "GSIS": "GSIS", "NG5": "NG5", "qsgt": "QSGT", "T34P": "BEECH",
        // Drones/UAV
        "F4": "DJI"  // DJI Phantom quadcopter
    ]

    /// Major airliner manufacturers - these should use the generic jet SF Symbol
    static let airlinerManufacturers: Set<String> = [
        "BOEING", "AIRBUS", "EMBRAER", "BOMBARDIER", "MCDONNELL DOUGLAS",
        "MCDONNELL-DOUGLAS", "LOCKHEED", "ATR", "FOKKER", "SAAB", "BAE",
        "BRITISH AEROSPACE", "TUPOLEV", "ILYUSHIN", "ANTONOV", "COMAC",
        "SUKHOI", "MITSUBISHI"
    ]

    /// Set of available ICAO codes that have custom icons
    static var availableICAOs: Set<String> {
        Set(icaoToManufacturer.keys)
    }

    /// Normalizes manufacturer name for comparison
    static func normalizeManufacturer(_ manufacturer: String) -> String {
        let normalized = manufacturer.uppercased()
            .replacingOccurrences(of: "AIRCRAFT", with: "")
            .replacingOccurrences(of: "INDUSTRIES", with: "")
            .replacingOccurrences(of: "CORP", with: "")
            .replacingOccurrences(of: "INC", with: "")
            .replacingOccurrences(of: "LLC", with: "")
            .replacingOccurrences(of: ".", with: "")
            .replacingOccurrences(of: ",", with: "")
            .trimmingCharacters(in: .whitespaces)

        // Handle common variations
        if normalized.contains("CESSNA") { return "CESSNA" }
        if normalized.contains("PIPER") { return "PIPER" }
        if normalized.contains("BEECH") || normalized.contains("HAWKER") || normalized.contains("TEXTRON") { return "BEECH" }
        if normalized.contains("CIRRUS") { return "CIRRUS" }
        if normalized.contains("MOONEY") { return "MOONEY" }
        if normalized.contains("DIAMOND") { return "DIAMOND" }
        if normalized.contains("ROBINSON") { return "ROBINSON" }
        if normalized.contains("EUROCOPTER") || normalized.contains("AIRBUS HELICOPTERS") { return "EUROCOPTER" }
        if normalized.contains("PILATUS") { return "PILATUS" }
        if normalized.contains("VANS") || normalized.contains("VAN'S") { return "VANS" }
        if normalized.contains("GRUMMAN") { return "GRUMMAN" }
        if normalized.contains("SIKORSKY") { return "SIKORSKY" }
        if normalized.contains("SOCATA") || normalized.contains("DAHER") { return "SOCATA" }
        if normalized.contains("QUEST") || normalized.contains("KODIAK") { return "KODIAK" }
        if normalized.contains("JABIRU") { return "JABIRU" }
        if normalized.contains("HONDA") { return "HONDA" }
        if normalized.contains("DJI") { return "DJI" }

        return normalized
    }

    /// Checks if manufacturer is a major airliner producer
    static func isAirlinerManufacturer(_ manufacturer: String) -> Bool {
        let normalized = manufacturer.uppercased()
        return airlinerManufacturers.contains { normalized.contains($0) }
    }

    /// Attempts to find an ICAO-specific icon that matches both code and manufacturer
    /// Checks manual overrides first, then exact match, then prefix matching
    /// - Parameters:
    ///   - icao: The aircraft's ICAO code
    ///   - manufacturer: The aircraft's manufacturer (for verification)
    /// - Returns: Asset path if found and manufacturer matches, nil otherwise
    static func findICAOIcon(for icao: String, manufacturer: String) -> String? {
        let code = icao.uppercased().trimmingCharacters(in: .whitespaces)
        guard !code.isEmpty else { return nil }

        // 1. Check manual overrides FIRST (bypasses manufacturer check)
        if let overrideIcon = icaoOverrides[code] {
            // Verify the override icon exists
            if icaoToManufacturer[overrideIcon] != nil {
                return "MapIcons/icao-\(overrideIcon)"
            }
        }

        // 2. Special handling for Van's RV aircraft
        // RV homebuilts often list builder's name as manufacturer, not "Van's Aircraft"
        // If ICAO starts with "RV", try to match to our RV icons directly
        if code.hasPrefix("RV") {
            // Try exact match first
            if icaoToManufacturer[code] != nil {
                return "MapIcons/icao-\(code)"
            }
            // Try to find any RV icon that matches the prefix (RV6, RV10, RV12)
            let rvIcons = ["RV6", "RV10", "RV12"]
            for rvIcon in rvIcons {
                if code.hasPrefix(rvIcon.dropLast()) || code == rvIcon {
                    return "MapIcons/icao-\(rvIcon)"
                }
            }
            // Fall back to RV6 as generic RV silhouette
            return "MapIcons/icao-RV6"
        }

        let normalizedMfg = normalizeManufacturer(manufacturer)

        // 3. Try exact match - verify manufacturer matches
        if let iconMfg = icaoToManufacturer[code] {
            if iconMfg == normalizedMfg {
                return "MapIcons/icao-\(code)"
            }
            // Manufacturer doesn't match - don't use this icon
            return nil
        }

        // 4. Try prefix matching with manufacturer verification
        var prefix = code
        while prefix.count >= 2 {
            prefix = String(prefix.dropLast())

            // Find ICAO codes that start with this prefix
            let matches = icaoToManufacturer.filter { $0.key.hasPrefix(prefix) }

            // Check if any match has the same manufacturer
            for (matchCode, matchMfg) in matches {
                if matchMfg == normalizedMfg {
                    return "MapIcons/icao-\(matchCode)"
                }
            }
        }

        // No matching ICAO icon found
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

    var body: some View {
        HStack(alignment: .center, spacing: 3) {
            // Aircraft icon with black outline effect
            aircraftIcon

            // ICAO label positioned to the side (only when zoomed in)
            // White text with black outline - no background box
            if showLabel {
                Text(aircraft.icao)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(.white)
                    // Black outline effect using multiple shadows
                    .shadow(color: .black, radius: 0.5, x: 0, y: 0)
                    .shadow(color: .black, radius: 0.5, x: 1, y: 0)
                    .shadow(color: .black, radius: 0.5, x: -1, y: 0)
                    .shadow(color: .black, radius: 0.5, x: 0, y: 1)
                    .shadow(color: .black, radius: 0.5, x: 0, y: -1)
                    .lineLimit(1)
            }
        }
        .onTapGesture(perform: onTap)
    }

    /// Aircraft icon with black outline/shadow for visibility
    /// Handles both SF Symbols (prefixed with "sf.") and asset images
    @ViewBuilder
    private var aircraftIcon: some View {
        let iconName = aircraft.mapIconName

        if iconName.hasPrefix("sf.") {
            // SF Symbol (for airliners)
            let symbolName = String(iconName.dropFirst(3))  // Remove "sf." prefix
            Image(systemName: symbolName)
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(AppColors.orange)
                .rotationEffect(.degrees(-45))
                // Black outline effect using multiple shadows
                .shadow(color: .black, radius: 0.5, x: 0, y: 0)
                .shadow(color: .black, radius: 0.5, x: 0.5, y: 0)
                .shadow(color: .black, radius: 0.5, x: -0.5, y: 0)
                .shadow(color: .black, radius: 0.5, x: 0, y: 0.5)
                .shadow(color: .black, radius: 0.5, x: 0, y: -0.5)
        } else {
            // Custom asset image
            Image(iconName)
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
            clusterIcon

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

    /// Cluster icon - handles both SF Symbols and asset images
    @ViewBuilder
    private var clusterIcon: some View {
        let iconName = cluster.primaryAircraft.mapIconName

        if iconName.hasPrefix("sf.") {
            // SF Symbol (for airliners)
            let symbolName = String(iconName.dropFirst(3))
            Image(systemName: symbolName)
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(.white)
                .rotationEffect(.degrees(-45))
        } else {
            // Custom asset image
            Image(iconName)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 26, height: 26)
                .foregroundStyle(.white)
        }
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
    @State private var mapCenter: CLLocationCoordinate2D?  // Track visible region center

    // Performance constants
    private let maxVisibleAircraft = 150  // Limit aircraft rendered for performance
    private let viewportBuffer: Double = 1.5  // Extend visible region by 50% for smoother panning

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

    /// All aircraft that have valid GPS coordinates
    private var allAircraftWithLocation: [CapturedAircraft] {
        allAircraft.filter { $0.hasValidLocation }
    }

    /// Aircraft visible in current viewport (filtered for performance)
    /// Only includes aircraft within the visible region + buffer, limited to maxVisibleAircraft
    private var visibleAircraft: [CapturedAircraft] {
        guard let center = mapCenter else {
            // No center yet - return limited set
            return Array(allAircraftWithLocation.prefix(maxVisibleAircraft))
        }

        // Calculate viewport bounds with buffer
        let latBuffer = mapSpan * viewportBuffer
        let lonBuffer = mapSpan * viewportBuffer

        let minLat = center.latitude - latBuffer
        let maxLat = center.latitude + latBuffer
        let minLon = center.longitude - lonBuffer
        let maxLon = center.longitude + lonBuffer

        // Filter to viewport and limit count
        let inViewport = allAircraftWithLocation.filter { aircraft in
            let coord = aircraft.displayCoordinate
            return coord.latitude >= minLat && coord.latitude <= maxLat &&
                   coord.longitude >= minLon && coord.longitude <= maxLon
        }

        // Limit total rendered for performance
        return Array(inViewport.prefix(maxVisibleAircraft))
    }

    /// Clustered aircraft based on current zoom level (uses viewport-filtered aircraft)
    private var aircraftClusters: [AircraftCluster] {
        AircraftClusterHelper.cluster(visibleAircraft, mapSpan: mapSpan)
    }

    /// Filtered aircraft matching search text (searches ALL aircraft, not just visible)
    private var filteredAircraft: [CapturedAircraft] {
        let searchText = searchState.searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !searchText.isEmpty else { return [] }

        let keywords = searchText.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
        guard !keywords.isEmpty else { return [] }

        return allAircraftWithLocation.filter { aircraft in
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
        .onMapCameraChange(frequency: .onEnd) { context in
            // Track zoom level and center for viewport-based filtering
            // Uses .onEnd to only recalculate when user stops panning (better performance)
            mapSpan = context.region.span.latitudeDelta
            mapCenter = context.region.center
        }
        .mapStyle(.standard(pointsOfInterest: .excludingAll))  // Cleaner map without POI clutter
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
