//
//  HangarPage.swift
//  Airplane-ID
//
//  Created by Jim Kerr on 1/16/26.
//

import SwiftUI
import SwiftData

// MARK: - Hangar Filter State
/// Observable filter state with persistence to UserDefaults
@Observable
class HangarFilterState {
    // Filter values
    var searchText: String = ""
    var selectedYear: Int?
    var selectedMonth: Int?
    var selectedManufacturer: String?
    var selectedIATA: String?
    var selectedICAO: String?
    var selectedClassification: Int?
    var selectedType: String?
    var selectedCountry: String?
    var selectedState: String?
    var selectedCity: String?

    // Check if any filters are active
    var hasActiveFilters: Bool {
        !searchText.isEmpty ||
        selectedYear != nil ||
        selectedMonth != nil ||
        selectedManufacturer != nil ||
        selectedIATA != nil ||
        selectedICAO != nil ||
        selectedClassification != nil ||
        selectedType != nil ||
        selectedCountry != nil ||
        selectedState != nil ||
        selectedCity != nil
    }

    // Clear all filters
    func clearAll() {
        searchText = ""
        selectedYear = nil
        selectedMonth = nil
        selectedManufacturer = nil
        selectedIATA = nil
        selectedICAO = nil
        selectedClassification = nil
        selectedType = nil
        selectedCountry = nil
        selectedState = nil
        selectedCity = nil
        save()
    }

    // Persistence keys
    private let defaults = UserDefaults.standard
    private let keyPrefix = "hangarFilter_"

    init() {
        load()
    }

    func save() {
        defaults.set(searchText, forKey: keyPrefix + "searchText")
        defaults.set(selectedYear, forKey: keyPrefix + "year")
        defaults.set(selectedMonth, forKey: keyPrefix + "month")
        defaults.set(selectedManufacturer, forKey: keyPrefix + "manufacturer")
        defaults.set(selectedIATA, forKey: keyPrefix + "iata")
        defaults.set(selectedICAO, forKey: keyPrefix + "icao")
        defaults.set(selectedClassification, forKey: keyPrefix + "classification")
        defaults.set(selectedType, forKey: keyPrefix + "type")
        defaults.set(selectedCountry, forKey: keyPrefix + "country")
        defaults.set(selectedState, forKey: keyPrefix + "state")
        defaults.set(selectedCity, forKey: keyPrefix + "city")
    }

    private func load() {
        searchText = defaults.string(forKey: keyPrefix + "searchText") ?? ""
        selectedYear = defaults.object(forKey: keyPrefix + "year") as? Int
        selectedMonth = defaults.object(forKey: keyPrefix + "month") as? Int
        selectedManufacturer = defaults.string(forKey: keyPrefix + "manufacturer")
        selectedIATA = defaults.string(forKey: keyPrefix + "iata")
        selectedICAO = defaults.string(forKey: keyPrefix + "icao")
        selectedClassification = defaults.object(forKey: keyPrefix + "classification") as? Int
        selectedType = defaults.string(forKey: keyPrefix + "type")
        selectedCountry = defaults.string(forKey: keyPrefix + "country")
        selectedState = defaults.string(forKey: keyPrefix + "state")
        selectedCity = defaults.string(forKey: keyPrefix + "city")
    }
}

// MARK: - Hangar Page
/// User's collection of captured aircraft
struct HangarPage: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext

    // Query all aircraft sorted by capture time (newest first)
    @Query(sort: \CapturedAircraft.captureTime, order: .reverse)
    private var allAircraft: [CapturedAircraft]

    @State private var filterState = HangarFilterState()
    @State private var showingFilterSheet = false
    @State private var selectedAircraft: CapturedAircraft?

    // Filtered aircraft based on current filters
    private var filteredAircraft: [CapturedAircraft] {
        allAircraft.filter { aircraft in
            // Text search - search across multiple fields
            if !filterState.searchText.isEmpty {
                let search = filterState.searchText.lowercased()
                let matchesSearch =
                    aircraft.manufacturer.lowercased().contains(search) ||
                    aircraft.model.lowercased().contains(search) ||
                    aircraft.icao.lowercased().contains(search) ||
                    (aircraft.registration?.lowercased().contains(search) ?? false) ||
                    (aircraft.iata?.lowercased().contains(search) ?? false) ||
                    (aircraft.registeredCity?.lowercased().contains(search) ?? false) ||
                    (aircraft.registeredState?.lowercased().contains(search) ?? false) ||
                    (aircraft.country?.lowercased().contains(search) ?? false)
                if !matchesSearch { return false }
            }

            // Year filter
            if let year = filterState.selectedYear, aircraft.year != year {
                return false
            }

            // Month filter
            if let month = filterState.selectedMonth, aircraft.month != month {
                return false
            }

            // Manufacturer filter
            if let mfr = filterState.selectedManufacturer, aircraft.manufacturer != mfr {
                return false
            }

            // IATA filter
            if let iata = filterState.selectedIATA, aircraft.iata != iata {
                return false
            }

            // ICAO filter
            if let icao = filterState.selectedICAO, aircraft.icao != icao {
                return false
            }

            // Classification filter
            if let classification = filterState.selectedClassification,
               aircraft.aircraftClassification != classification {
                return false
            }

            // Type filter
            if let type = filterState.selectedType, aircraft.aircraftType != type {
                return false
            }

            // Country filter
            if let country = filterState.selectedCountry, aircraft.country != country {
                return false
            }

            // State filter
            if let state = filterState.selectedState, aircraft.registeredState != state {
                return false
            }

            // City filter
            if let city = filterState.selectedCity, aircraft.registeredCity != city {
                return false
            }

            return true
        }
    }

    // Group aircraft by year and month for section headers
    private var groupedAircraft: [(key: String, aircraft: [CapturedAircraft])] {
        let grouped = Dictionary(grouping: filteredAircraft) { aircraft in
            "\(aircraft.year)-\(String(format: "%02d", aircraft.month))"
        }
        return grouped.sorted { $0.key > $1.key }
            .map { (key: formatSectionHeader($0.key), aircraft: $0.value) }
    }

    // Format "2026-01" to "2026 JANUARY"
    private func formatSectionHeader(_ key: String) -> String {
        let parts = key.split(separator: "-")
        guard parts.count == 2,
              let year = Int(parts[0]),
              let month = Int(parts[1]) else {
            return key
        }
        let monthNames = ["", "JANUARY", "FEBRUARY", "MARCH", "APRIL", "MAY", "JUNE",
                          "JULY", "AUGUST", "SEPTEMBER", "OCTOBER", "NOVEMBER", "DECEMBER"]
        return "\(year) \(monthNames[month])"
    }

    var body: some View {
        PortraitTemplate {
            GeometryReader { geo in
                let contentWidth = geo.size.width * 0.92

                VStack(spacing: 0) {
                    // Filter bar
                    HStack {
                        // Filter button
                        Button(action: { showingFilterSheet = true }) {
                            Text("FILTER")
                                .font(.custom("Helvetica-Bold", size: 14))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(AppColors.darkBlue)
                                .cornerRadius(6)
                        }

                        Spacer()

                        // Result count - centered
                        Text("\(filteredAircraft.count) aircraft")
                            .font(.custom("Helvetica-Bold", size: 14))
                            .foregroundStyle(.white)

                        Spacer()

                        // Clear filters button (only visible when filters active)
                        if filterState.hasActiveFilters {
                            Button(action: { filterState.clearAll() }) {
                                Text("CLEAR")
                                    .font(.custom("Helvetica-Bold", size: 14))
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(AppColors.orange)
                                    .cornerRadius(6)
                            }
                        } else {
                            // Invisible placeholder to balance layout when CLEAR is hidden
                            Color.clear
                                .frame(width: 58, height: 28)
                        }
                    }
                    .padding(.horizontal, (geo.size.width - contentWidth) / 2)
                    .padding(.vertical, 10)

                    // Main list area
                    ZStack {
                        AppColors.white
                            .cornerRadius(12)

                        if filteredAircraft.isEmpty {
                            // Empty state
                            VStack(spacing: 12) {
                                Image(systemName: "airplane")
                                    .font(.system(size: 48))
                                    .foregroundStyle(AppColors.darkBlue.opacity(0.3))
                                Text(filterState.hasActiveFilters ? "No aircraft match your filters" : "No aircraft captured yet")
                                    .font(.custom("Helvetica", size: 16))
                                    .foregroundStyle(AppColors.darkBlue.opacity(0.6))
                                if filterState.hasActiveFilters {
                                    Button("Clear Filters") {
                                        filterState.clearAll()
                                    }
                                    .font(.custom("Helvetica-Bold", size: 14))
                                    .foregroundStyle(AppColors.linkBlue)
                                }
                            }
                        } else {
                            // Scrollable list with sticky headers
                            ScrollView {
                                LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
                                    ForEach(groupedAircraft, id: \.key) { group in
                                        Section {
                                            ForEach(group.aircraft) { aircraft in
                                                HangarListItem(aircraft: aircraft)
                                                    .padding(.horizontal, 12)
                                                    .padding(.vertical, 6)
                                                    .contentShape(Rectangle())
                                                    .onTapGesture {
                                                        selectedAircraft = aircraft
                                                    }
                                            }
                                        } header: {
                                            HangarSectionHeader(title: group.key)
                                        }
                                    }
                                }
                                .padding(.bottom, 100) // Space for footer
                            }
                        }
                    }
                    .frame(width: contentWidth)
                    .frame(maxHeight: .infinity)
                }
                .padding(.top, 5)
            }
        }
        .sheet(isPresented: $showingFilterSheet) {
            HangarFilterSheet(filterState: filterState, allAircraft: allAircraft)
        }
        .fullScreenCover(item: $selectedAircraft) { aircraft in
            AircraftDetailView(aircraft: aircraft)
        }
    }
}

// MARK: - Section Header
struct HangarSectionHeader: View {
    let title: String

    var body: some View {
        HStack {
            Text(title)
                .font(.custom("Helvetica-Bold", size: 15))
                .foregroundStyle(.white)
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(AppColors.darkBlue)
    }
}

// MARK: - List Item
struct HangarListItem: View {
    let aircraft: CapturedAircraft

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            // Line 1: [IATA] MANUFACTURER MODEL
            Text(line1)
                .font(.custom("Helvetica-Bold", size: 17))
                .foregroundStyle(AppColors.darkBlue)
                .lineLimit(1)

            // Line 2: [CLASSIFICATION] [Type]
            if let line2Text = line2 {
                Text(line2Text)
                    .font(.custom("Helvetica", size: 14))
                    .foregroundStyle(AppColors.darkBlue.opacity(0.7))
                    .lineLimit(1)
            }

            // Line 3: Registration, City, State, Country
            if let line3Text = line3 {
                Text(line3Text)
                    .font(.custom("Helvetica", size: 12))
                    .foregroundStyle(AppColors.darkBlue.opacity(0.5))
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 4)
    }

    // Line 1: [IATA] MANUFACTURER MODEL
    private var line1: String {
        var parts: [String] = []
        if let iata = aircraft.iata, !iata.isEmpty {
            parts.append(iata.uppercased())
        }
        parts.append(aircraft.manufacturer.uppercased())
        parts.append(aircraft.model)
        return parts.joined(separator: " ")
    }

    // Line 2: [CLASSIFICATION] [Type]
    private var line2: String? {
        var parts: [String] = []
        if let classification = AircraftLookup.classificationName(aircraft.aircraftClassification) {
            parts.append(classification)
        }
        if let type = AircraftLookup.typeName(aircraft.aircraftType) {
            parts.append(type)
        }
        return parts.isEmpty ? nil : parts.joined(separator: " ")
    }

    // Line 3: Registration, City, State, Country
    private var line3: String? {
        var parts: [String] = []
        if let reg = aircraft.registration, !reg.isEmpty {
            parts.append(reg.uppercased())
        }
        if let city = aircraft.registeredCity, !city.isEmpty {
            parts.append(city)
        }
        if let state = aircraft.registeredState, !state.isEmpty {
            parts.append(state)
        }
        if let country = aircraft.country, !country.isEmpty {
            parts.append(country)
        }
        return parts.isEmpty ? nil : parts.joined(separator: " ")
    }
}

// MARK: - Filter Sheet
struct HangarFilterSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var filterState: HangarFilterState
    let allAircraft: [CapturedAircraft]

    // MARK: - Bi-directional Filter Logic
    // Each dropdown shows options from aircraft matching ALL OTHER active filters (excluding itself)

    /// Filter aircraft by all criteria EXCEPT the specified one
    private func aircraftExcluding(_ exclude: String) -> [CapturedAircraft] {
        allAircraft.filter { aircraft in
            // Year filter (skip if excluding year)
            if exclude != "year", let year = filterState.selectedYear, aircraft.year != year {
                return false
            }
            // Month filter (skip if excluding month)
            if exclude != "month", let month = filterState.selectedMonth, aircraft.month != month {
                return false
            }
            // Manufacturer filter (skip if excluding manufacturer)
            if exclude != "manufacturer", let mfr = filterState.selectedManufacturer, aircraft.manufacturer != mfr {
                return false
            }
            // IATA filter (skip if excluding iata)
            if exclude != "iata", let iata = filterState.selectedIATA, aircraft.iata != iata {
                return false
            }
            // ICAO filter (skip if excluding icao)
            if exclude != "icao", let icao = filterState.selectedICAO, aircraft.icao != icao {
                return false
            }
            // Classification filter (skip if excluding classification)
            if exclude != "classification", let classification = filterState.selectedClassification,
               aircraft.aircraftClassification != classification {
                return false
            }
            // Type filter (skip if excluding type)
            if exclude != "type", let type = filterState.selectedType, aircraft.aircraftType != type {
                return false
            }
            // Country filter (skip if excluding country)
            if exclude != "country", let country = filterState.selectedCountry, aircraft.country != country {
                return false
            }
            // State filter (skip if excluding state)
            if exclude != "state", let state = filterState.selectedState, aircraft.registeredState != state {
                return false
            }
            // City filter (skip if excluding city)
            if exclude != "city", let city = filterState.selectedCity, aircraft.registeredCity != city {
                return false
            }
            return true
        }
    }

    // Available options for each dropdown - filtered by all OTHER active filters
    private var availableYears: [Int] {
        Array(Set(aircraftExcluding("year").map { $0.year })).sorted(by: >)
    }

    private var availableMonths: [Int] {
        Array(Set(aircraftExcluding("month").map { $0.month })).sorted()
    }

    private var availableManufacturers: [String] {
        Array(Set(aircraftExcluding("manufacturer").map { $0.manufacturer })).sorted()
    }

    private var availableIATAs: [String] {
        Array(Set(aircraftExcluding("iata").compactMap { $0.iata }.filter { !$0.isEmpty })).sorted()
    }

    private var availableICAOs: [String] {
        Array(Set(aircraftExcluding("icao").map { $0.icao })).sorted()
    }

    private var availableClassifications: [Int] {
        Array(Set(aircraftExcluding("classification").compactMap { $0.aircraftClassification })).sorted()
    }

    private var availableTypes: [String] {
        Array(Set(aircraftExcluding("type").compactMap { $0.aircraftType })).sorted()
    }

    private var availableCountries: [String] {
        Array(Set(aircraftExcluding("country").compactMap { $0.country }.filter { !$0.isEmpty })).sorted()
    }

    private var availableStates: [String] {
        Array(Set(aircraftExcluding("state").compactMap { $0.registeredState }.filter { !$0.isEmpty })).sorted()
    }

    private var availableCities: [String] {
        Array(Set(aircraftExcluding("city").compactMap { $0.registeredCity }.filter { !$0.isEmpty })).sorted()
    }

    private let monthNames = ["", "January", "February", "March", "April", "May", "June",
                              "July", "August", "September", "October", "November", "December"]

    var body: some View {
        NavigationStack {
            Form {
                // Search Section
                Section("Search") {
                    TextField("Search aircraft...", text: $filterState.searchText)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    if !filterState.searchText.isEmpty {
                        Text("Searches: manufacturer, model, ICAO, registration, IATA, city, state, country")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                // Date Filters
                Section("Date") {
                    Picker("Year", selection: $filterState.selectedYear) {
                        Text("Any Year").tag(nil as Int?)
                        ForEach(availableYears, id: \.self) { year in
                            Text(String(year)).tag(year as Int?)
                        }
                    }

                    Picker("Month", selection: $filterState.selectedMonth) {
                        Text("Any Month").tag(nil as Int?)
                        ForEach(availableMonths, id: \.self) { month in
                            Text(monthNames[month]).tag(month as Int?)
                        }
                    }
                }

                // Aircraft Filters
                Section("Aircraft") {
                    Picker("Manufacturer", selection: $filterState.selectedManufacturer) {
                        Text("Any Manufacturer").tag(nil as String?)
                        ForEach(availableManufacturers, id: \.self) { mfr in
                            Text(mfr).tag(mfr as String?)
                        }
                    }

                    Picker("ICAO Type", selection: $filterState.selectedICAO) {
                        Text("Any ICAO").tag(nil as String?)
                        ForEach(availableICAOs, id: \.self) { icao in
                            Text(icao).tag(icao as String?)
                        }
                    }

                    // Always show IATA picker (even if empty, for when data is added)
                    Picker("IATA Airline", selection: $filterState.selectedIATA) {
                        Text("Any Airline").tag(nil as String?)
                        ForEach(availableIATAs, id: \.self) { iata in
                            Text(iata).tag(iata as String?)
                        }
                    }
                }

                // Classification Filters
                Section("Classification") {
                    Picker("Category", selection: $filterState.selectedClassification) {
                        Text("Any Category").tag(nil as Int?)
                        ForEach(availableClassifications, id: \.self) { code in
                            Text(AircraftLookup.classificationName(code) ?? "Unknown")
                                .tag(code as Int?)
                        }
                    }

                    Picker("Type", selection: $filterState.selectedType) {
                        Text("Any Type").tag(nil as String?)
                        ForEach(availableTypes, id: \.self) { code in
                            Text(AircraftLookup.typeName(code) ?? code)
                                .tag(code as String?)
                        }
                    }
                }

                // Location Filters
                Section("Location") {
                    Picker("Country", selection: $filterState.selectedCountry) {
                        Text("Any Country").tag(nil as String?)
                        ForEach(availableCountries, id: \.self) { country in
                            Text(country).tag(country as String?)
                        }
                    }

                    Picker("State", selection: $filterState.selectedState) {
                        Text("Any State").tag(nil as String?)
                        ForEach(availableStates, id: \.self) { state in
                            Text(state).tag(state as String?)
                        }
                    }

                    Picker("City", selection: $filterState.selectedCity) {
                        Text("Any City").tag(nil as String?)
                        ForEach(availableCities, id: \.self) { city in
                            Text(city).tag(city as String?)
                        }
                    }
                }

                // Clear All
                if filterState.hasActiveFilters {
                    Section {
                        Button(role: .destructive) {
                            filterState.clearAll()
                        } label: {
                            HStack {
                                Spacer()
                                Text("Clear All Filters")
                                Spacer()
                            }
                        }
                    }
                }
            }
            .navigationTitle(filterState.hasActiveFilters ? "" : "Filter Aircraft")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                // CLEAR button on left - only visible when filters are active
                ToolbarItem(placement: .topBarLeading) {
                    if filterState.hasActiveFilters {
                        Button {
                            filterState.clearAll()
                        } label: {
                            Text("Clear")
                                .foregroundStyle(AppColors.orange)
                        }
                    }
                }

                // Done/Search button on right
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        filterState.save()
                        dismiss()
                    } label: {
                        Text(filterState.hasActiveFilters ? "Search" : "Done")
                            .fontWeight(.semibold)
                    }
                    .tint(filterState.hasActiveFilters ? Color(hex: "28A745") : nil)
                    .buttonStyle(.borderedProminent)
                }
            }
        }
    }
}

// MARK: - Aircraft Detail View
/// Full-screen detail view for a captured aircraft
/// Follows the AccountSettingsView pattern for editable modals
struct AircraftDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    let aircraft: CapturedAircraft

    // Edit mode state
    @State private var isEditing = false
    @State private var showingRatingSelector = false

    // Edit values (populated when entering edit mode)
    @State private var editManufacturer = ""
    @State private var editModel = ""
    @State private var editRegistration = ""
    @State private var editICAO = ""
    @State private var editIATA = ""

    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.settingsBackground.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 0) {
                        // Photo placeholder with rating overlay
                        ZStack(alignment: .bottomLeading) {
                            // Photo background
                            Rectangle()
                                .fill(AppColors.darkBlue.opacity(0.3))

                            // Photo placeholder content
                            VStack(spacing: 12) {
                                Image(systemName: "photo")
                                    .font(.system(size: 60))
                                    .foregroundStyle(.white.opacity(0.5))
                                Text("Aircraft Photo")
                                    .font(.custom("Helvetica", size: 14))
                                    .foregroundStyle(.white.opacity(0.5))
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)

                            // Star rating overlay at bottom-left
                            starRatingOverlay
                                .padding(.leading, 2)
                                .padding(.bottom, 2)
                        }
                        .frame(height: 220)

                        // Aircraft identification section
                        VStack(alignment: .leading, spacing: 2) {
                            // Line 1: Manufacturer
                            Text(aircraft.manufacturer.uppercased())
                                .font(.custom("Helvetica-Bold", size: 22))
                                .foregroundStyle(.white)

                            // Line 2: Model
                            Text(aircraft.model)
                                .font(.system(size: 20, weight: .medium))
                                .foregroundStyle(.white)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 20)
                        .padding(.top, 20)

                        // Type (e.g., "Fixed Wing Single-Engine")
                        if let typeName = AircraftLookup.typeName(aircraft.aircraftType) {
                            Text(typeName)
                                .font(.custom("Helvetica", size: 16))
                                .foregroundStyle(.white.opacity(0.7))
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 20)
                                .padding(.top, 8)
                        }

                        // Aircraft Identification Section (editable - AI may get wrong)
                        // Always visible since manufacturer/model/icao are required
                        detailSection(title: "Aircraft Identification") {
                            EditableDetailRow(label: "Manufacturer", value: $editManufacturer, isEditing: isEditing)
                            EditableDetailRow(label: "Model", value: $editModel, isEditing: isEditing)
                            EditableDetailRow(label: "ICAO", value: $editICAO, isEditing: isEditing, placeholder: "e.g. B738")
                            // Registration only shown if has data or editing
                            if !editRegistration.isEmpty || isEditing {
                                EditableDetailRow(label: "Registration", value: $editRegistration, isEditing: isEditing, placeholder: "e.g. N12345")
                            }
                            // Country (from FAA data)
                            if let country = aircraft.country, !country.isEmpty {
                                DetailRow(label: "Country", value: country)
                            } else if isEditing {
                                DetailRow(label: "Country", value: "—")
                            }
                        }

                        // Operator Section (IATA editable, owner info from FAA)
                        if hasOperatorData || isEditing {
                            detailSection(title: "Operator") {
                                if !editIATA.isEmpty || isEditing {
                                    EditableDetailRow(label: "IATA", value: $editIATA, isEditing: isEditing, placeholder: "e.g. UA")
                                }
                                if let owner = aircraft.registeredOwner, !owner.isEmpty {
                                    DetailRow(label: "Owner", value: owner)
                                } else if isEditing {
                                    DetailRow(label: "Owner", value: "—")
                                }
                                if let ownerType = aircraft.ownerType, !ownerType.isEmpty {
                                    DetailRow(label: "Owner Type", value: ownerType)
                                } else if isEditing {
                                    DetailRow(label: "Owner Type", value: "—")
                                }
                                if let addr1 = aircraft.registeredAddress1, !addr1.isEmpty {
                                    DetailRow(label: "Address", value: addr1)
                                } else if isEditing {
                                    DetailRow(label: "Address", value: "—")
                                }
                                if let addr2 = aircraft.registeredAddress2, !addr2.isEmpty {
                                    DetailRow(label: "Address 2", value: addr2)
                                }
                                if let city = aircraft.registeredCity, !city.isEmpty {
                                    DetailRow(label: "City", value: city)
                                } else if isEditing {
                                    DetailRow(label: "City", value: "—")
                                }
                                if let state = aircraft.registeredState, !state.isEmpty {
                                    DetailRow(label: "State", value: state)
                                } else if isEditing {
                                    DetailRow(label: "State", value: "—")
                                }
                                if let zip = aircraft.registeredZip, !zip.isEmpty {
                                    DetailRow(label: "Zip", value: zip)
                                } else if isEditing {
                                    DetailRow(label: "Zip", value: "—")
                                }
                            }
                        }

                        // Aircraft Specifications Section (read-only from FAA data)
                        if hasSpecificationsData || isEditing {
                            detailSection(title: "Aircraft Specifications") {
                                if aircraft.aircraftClassification != nil || isEditing {
                                    DetailRow(label: "Classification", value: AircraftLookup.classificationName(aircraft.aircraftClassification) ?? "—")
                                }
                                if aircraft.aircraftType != nil || isEditing {
                                    DetailRow(label: "Type", value: AircraftLookup.typeName(aircraft.aircraftType) ?? "—")
                                }
                                if let serial = aircraft.serialNumber, !serial.isEmpty {
                                    DetailRow(label: "Serial Number", value: serial)
                                } else if isEditing {
                                    DetailRow(label: "Serial Number", value: "—")
                                }
                                if aircraft.yearMfg != nil || isEditing {
                                    DetailRow(label: "Year Manufactured", value: aircraft.yearMfg != nil ? String(aircraft.yearMfg!) : "—")
                                }
                                if let engineType = aircraft.engineType, !engineType.isEmpty {
                                    DetailRow(label: "Engine Type", value: engineType)
                                } else if isEditing {
                                    DetailRow(label: "Engine Type", value: "—")
                                }
                                if aircraft.engineCount != nil || isEditing {
                                    DetailRow(label: "Engine Count", value: aircraft.engineCount != nil ? String(aircraft.engineCount!) : "—")
                                }
                                if aircraft.seatCount != nil || isEditing {
                                    DetailRow(label: "Seat Count", value: aircraft.seatCount != nil ? String(aircraft.seatCount!) : "—")
                                }
                                if let weightClass = aircraft.weightClass, !weightClass.isEmpty {
                                    DetailRow(label: "Weight Class", value: weightClass)
                                } else if isEditing {
                                    DetailRow(label: "Weight Class", value: "—")
                                }
                            }
                        }

                        // Certification Section (read-only from FAA data)
                        if hasCertificationData || isEditing {
                            detailSection(title: "Certification") {
                                if aircraft.airworthinessDate != nil || isEditing {
                                    DetailRow(label: "Airworthiness Date", value: aircraft.airworthinessDate != nil ? formatDate(aircraft.airworthinessDate!) : "—")
                                }
                                if aircraft.certificateIssueDate != nil || isEditing {
                                    DetailRow(label: "Certificate Issued", value: aircraft.certificateIssueDate != nil ? formatDate(aircraft.certificateIssueDate!) : "—")
                                }
                                if aircraft.certificateExpireDate != nil || isEditing {
                                    DetailRow(label: "Certificate Expires", value: aircraft.certificateExpireDate != nil ? formatDate(aircraft.certificateExpireDate!) : "—")
                                }
                            }
                        }

                        // Sighting Details Section (read-only from device) - always visible
                        detailSection(title: "Sighting Details") {
                            DetailRow(label: "Date", value: formatDateTime(aircraft.captureTime))
                            DetailRow(label: "Location", value: formatCoordinates(aircraft.gpsLatitude, aircraft.gpsLongitude))
                        }

                        Spacer().frame(height: 40)
                    }
                }
                .scrollDismissesKeyboard(.never)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if !isEditing {
                        Button(action: { dismiss() }) {
                            HStack(spacing: 4) {
                                Image(systemName: "chevron.left")
                                Text("Back")
                            }
                            .foregroundStyle(AppColors.linkBlue)
                        }
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    if isEditing {
                        HStack(spacing: 16) {
                            Button("Cancel") {
                                cancelEditing()
                            }
                            .foregroundStyle(.white.opacity(0.6))

                            Button("Save") {
                                saveChanges()
                            }
                            .foregroundStyle(AppColors.linkBlue)
                            .fontWeight(.semibold)
                        }
                    } else {
                        Button("Edit") {
                            startEditing()
                        }
                        .foregroundStyle(AppColors.linkBlue)
                    }
                }
            }
            .sheet(isPresented: $showingRatingSelector) {
                RatingSelectorSheet(
                    currentRating: aircraft.rating,
                    onSelect: { newRating in
                        aircraft.rating = newRating
                        try? modelContext.save()
                    }
                )
                .presentationDetents([.height(280)])
            }
            .onAppear {
                populateEditValues()
            }
        }
    }

    // MARK: - Populate Edit Values
    private func populateEditValues() {
        editManufacturer = aircraft.manufacturer
        editModel = aircraft.model
        editICAO = aircraft.icao
        editIATA = aircraft.iata ?? ""
        editRegistration = aircraft.registration ?? ""
    }

    // MARK: - Star Rating Overlay

    @ViewBuilder
    private var starRatingOverlay: some View {
        if let rating = aircraft.rating, rating > 0 {
            // Rated: Show stars (tappable only in edit mode)
            Button(action: {
                if isEditing {
                    showingRatingSelector = true
                }
            }) {
                StarRatingDisplay(rating: rating)
            }
            .disabled(!isEditing)
        } else {
            // Unrated: Show "Rate" text (always tappable)
            Button(action: {
                showingRatingSelector = true
            }) {
                Text("Rate")
                    .font(.custom("Helvetica", size: 14))
                    .foregroundStyle(.white.opacity(0.8))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 6)
                    .background(Color.black.opacity(0.4))
                    .cornerRadius(12)
            }
        }
    }

    // MARK: - Helper Views

    @ViewBuilder
    private func detailSection(title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(spacing: 12) {
            Text(title)
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                .padding(.top, 20)

            VStack(spacing: 8) {
                content()
            }
            .padding(.horizontal, 20)
        }
    }

    // MARK: - Section Visibility

    private var hasOperatorData: Bool {
        (aircraft.iata != nil && !aircraft.iata!.isEmpty) ||
        (aircraft.registeredOwner != nil && !aircraft.registeredOwner!.isEmpty) ||
        (aircraft.ownerType != nil && !aircraft.ownerType!.isEmpty) ||
        (aircraft.registeredAddress1 != nil && !aircraft.registeredAddress1!.isEmpty) ||
        (aircraft.registeredCity != nil && !aircraft.registeredCity!.isEmpty) ||
        (aircraft.registeredState != nil && !aircraft.registeredState!.isEmpty) ||
        (aircraft.registeredZip != nil && !aircraft.registeredZip!.isEmpty)
    }

    private var hasSpecificationsData: Bool {
        aircraft.aircraftClassification != nil ||
        aircraft.aircraftType != nil ||
        (aircraft.serialNumber != nil && !aircraft.serialNumber!.isEmpty) ||
        aircraft.yearMfg != nil ||
        (aircraft.engineType != nil && !aircraft.engineType!.isEmpty) ||
        aircraft.engineCount != nil ||
        aircraft.seatCount != nil ||
        (aircraft.weightClass != nil && !aircraft.weightClass!.isEmpty)
    }

    private var hasCertificationData: Bool {
        aircraft.airworthinessDate != nil ||
        aircraft.certificateIssueDate != nil ||
        aircraft.certificateExpireDate != nil
    }

    // MARK: - Formatting Helpers

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }

    private func formatDateTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    private func formatCoordinates(_ lat: Double, _ lon: Double) -> String {
        String(format: "%.4f, %.4f", lat, lon)
    }

    // MARK: - Edit Mode Functions

    private func startEditing() {
        populateEditValues()
        isEditing = true
    }

    private func cancelEditing() {
        populateEditValues()  // Revert to original values
        isEditing = false
    }

    private func saveChanges() {
        aircraft.manufacturer = editManufacturer
        aircraft.model = editModel
        aircraft.registration = editRegistration.isEmpty ? nil : editRegistration
        aircraft.icao = editICAO
        aircraft.iata = editIATA.isEmpty ? nil : editIATA
        try? modelContext.save()
        isEditing = false
    }
}

// MARK: - Detail Row Component
struct DetailRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 15))
                .foregroundStyle(.white.opacity(0.6))
            Spacer()
            Text(value)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(.white)
                .multilineTextAlignment(.trailing)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 16)
        .background(AppColors.settingsRow)
        .cornerRadius(10)
    }
}

// MARK: - Editable Detail Row Component
struct EditableDetailRow: View {
    let label: String
    @Binding var value: String
    let isEditing: Bool
    var placeholder: String = ""

    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 15))
                .foregroundStyle(.white.opacity(0.6))
            Spacer()
            if isEditing {
                TextField(placeholder.isEmpty ? label : placeholder, text: $value)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.trailing)
                    .textFieldStyle(.plain)
                    .padding(.vertical, 4)
                    .padding(.horizontal, 8)
                    .background(AppColors.darkBlue.opacity(0.3))
                    .cornerRadius(6)
                    .frame(maxWidth: 200)
            } else {
                Text(value.isEmpty ? "—" : value)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(value.isEmpty ? .white.opacity(0.3) : .white)
                    .multilineTextAlignment(.trailing)
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 16)
        .background(AppColors.settingsRow)
        .cornerRadius(10)
    }
}

// MARK: - Star Rating Display
/// Displays star rating with filled, half-filled, and empty stars
struct StarRatingDisplay: View {
    let rating: Double
    let starSize: CGFloat
    let showBackground: Bool

    init(rating: Double, starSize: CGFloat = 16, showBackground: Bool = false) {
        self.rating = rating
        self.starSize = starSize
        self.showBackground = showBackground
    }

    var body: some View {
        HStack(spacing: 2) {
            ForEach(1...5, id: \.self) { index in
                starImage(for: index)
                    .font(.system(size: starSize))
                    .foregroundStyle(.yellow)
            }
        }
        .padding(.horizontal, showBackground ? 12 : 0)
        .padding(.vertical, showBackground ? 6 : 0)
        .background(showBackground ? Color.black.opacity(0.4) : Color.clear)
        .cornerRadius(showBackground ? 12 : 0)
    }

    private func starImage(for index: Int) -> Image {
        let threshold = Double(index)
        if rating >= threshold {
            return Image(systemName: "star.fill")
        } else if rating >= threshold - 0.5 {
            return Image(systemName: "star.leadinghalf.filled")
        } else {
            return Image(systemName: "star")
        }
    }
}

// MARK: - Rating Selector Sheet
/// Sheet for selecting a star rating in 0.5 increments
struct RatingSelectorSheet: View {
    @Environment(\.dismiss) private var dismiss
    let currentRating: Double?
    let onSelect: (Double?) -> Void

    // Available ratings: 0 (clear), 0.5, 1.0, 1.5, 2.0, 2.5, 3.0, 3.5, 4.0, 4.5, 5.0
    private let ratings: [Double] = [0.5, 1.0, 1.5, 2.0, 2.5, 3.0, 3.5, 4.0, 4.5, 5.0]

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Rate this aircraft")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.primary)
                    .padding(.top, 10)

                // Star rating options
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 12) {
                    ForEach(ratings, id: \.self) { rating in
                        Button(action: {
                            onSelect(rating)
                            dismiss()
                        }) {
                            VStack(spacing: 4) {
                                StarRatingDisplay(rating: rating, starSize: 16)
                                Text(formatRating(rating))
                                    .font(.system(size: 12))
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .buttonStyle(.plain)
                        .padding(8)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(currentRating == rating ? AppColors.linkBlue.opacity(0.2) : Color.clear)
                        )
                    }
                }
                .padding(.horizontal, 20)

                // Clear rating button
                if currentRating != nil {
                    Button(action: {
                        onSelect(nil)
                        dismiss()
                    }) {
                        Text("Clear Rating")
                            .font(.system(size: 16))
                            .foregroundStyle(AppColors.orange)
                    }
                    .padding(.top, 10)
                }

                Spacer()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func formatRating(_ rating: Double) -> String {
        if rating == rating.rounded() {
            return String(format: "%.0f", rating)
        } else {
            return String(format: "%.1f", rating)
        }
    }
}

// MARK: - Previews
#Preview("Portrait") {
    HangarPage()
        .modelContainer(for: CapturedAircraft.self, inMemory: true)
        .environment(AppState())
}

#Preview("Landscape Left", traits: .landscapeLeft) {
    LandscapeLeftTemplate {
        Text("Hangar - Landscape")
            .foregroundStyle(.white)
    }
    .environment(AppState())
}

#Preview("Landscape Right", traits: .landscapeRight) {
    LandscapeRightTemplate {
        Text("Hangar - Landscape")
            .foregroundStyle(.white)
    }
    .environment(AppState())
}
