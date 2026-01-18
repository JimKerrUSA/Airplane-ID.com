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
    var selectedAirlineCode: String?
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
        selectedAirlineCode != nil ||
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
        selectedAirlineCode = nil
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
        defaults.set(selectedAirlineCode, forKey: keyPrefix + "iata")
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
        selectedAirlineCode = defaults.string(forKey: keyPrefix + "iata")
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
                    (aircraft.airlineCode?.lowercased().contains(search) ?? false) ||
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

            // Airline filter
            if let code = filterState.selectedAirlineCode, aircraft.airlineCode != code {
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

    // Line 1: [AIRLINE CODE] MANUFACTURER MODEL
    private var line1: String {
        var parts: [String] = []
        if let code = aircraft.airlineCode, !code.isEmpty {
            parts.append(code.uppercased())
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
    @State private var showingICAOSearch = false
    @State private var showingManufacturerSearch = false

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
            // Airline filter (skip if excluding airlineCode)
            if exclude != "airlineCode", let code = filterState.selectedAirlineCode, aircraft.airlineCode != code {
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

    private var availableAirlineCodes: [String] {
        Array(Set(aircraftExcluding("airlineCode").compactMap { $0.airlineCode }.filter { !$0.isEmpty })).sorted()
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
                        Text("Searches: manufacturer, model, ICAO, registration, airline, city, state, country")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                // Date Filters
                Section("Date") {
                    Picker("Year", selection: $filterState.selectedYear) {
                        Text("Select Year").tag(nil as Int?)
                        ForEach(availableYears, id: \.self) { year in
                            Text(String(year)).tag(year as Int?)
                        }
                    }

                    Picker("Month", selection: $filterState.selectedMonth) {
                        Text("Select Month").tag(nil as Int?)
                        ForEach(availableMonths, id: \.self) { month in
                            Text(monthNames[month]).tag(month as Int?)
                        }
                    }
                }

                // Aircraft Filters
                Section("Aircraft") {
                    // Manufacturer - opens search sheet
                    Button(action: { showingManufacturerSearch = true }) {
                        HStack {
                            Text("Manufacturer")
                                .foregroundStyle(.primary)
                            Spacer()
                            if let mfr = filterState.selectedManufacturer {
                                Text(mfr)
                                    .foregroundStyle(.secondary)
                            } else {
                                Text("Search MFG")
                                    .foregroundStyle(.secondary)
                            }
                            Image(systemName: "chevron.right")
                                .font(.system(size: 13))
                                .foregroundStyle(.tertiary)
                        }
                    }
                    .buttonStyle(.plain)

                    // ICAO Type - opens search sheet
                    Button(action: { showingICAOSearch = true }) {
                        HStack {
                            Text("ICAO Type")
                                .foregroundStyle(.primary)
                            Spacer()
                            if let icao = filterState.selectedICAO {
                                Text(icao)
                                    .foregroundStyle(.secondary)
                            } else {
                                Text("Search ICAO")
                                    .foregroundStyle(.secondary)
                            }
                            Image(systemName: "chevron.right")
                                .font(.system(size: 13))
                                .foregroundStyle(.tertiary)
                        }
                    }
                    .buttonStyle(.plain)

                    // Always show Airline picker (even if empty, for when data is added)
                    Picker("Airline", selection: $filterState.selectedAirlineCode) {
                        Text("Search Airline").tag(nil as String?)
                        ForEach(availableAirlineCodes, id: \.self) { code in
                            Text(code).tag(code as String?)
                        }
                    }
                }

                // Classification Filters
                Section("Classification") {
                    Picker("Category", selection: $filterState.selectedClassification) {
                        Text("Select Category").tag(nil as Int?)
                        ForEach(availableClassifications, id: \.self) { code in
                            Text(AircraftLookup.classificationName(code) ?? "Unknown")
                                .tag(code as Int?)
                        }
                    }

                    Picker("Type", selection: $filterState.selectedType) {
                        Text("Select Type").tag(nil as String?)
                        ForEach(availableTypes, id: \.self) { code in
                            Text(AircraftLookup.typeName(code) ?? code)
                                .tag(code as String?)
                        }
                    }
                }

                // Location Filters
                Section("Location") {
                    Picker("Country", selection: $filterState.selectedCountry) {
                        Text("Select Country").tag(nil as String?)
                        ForEach(availableCountries, id: \.self) { country in
                            Text(country).tag(country as String?)
                        }
                    }

                    Picker("State", selection: $filterState.selectedState) {
                        Text("Select State").tag(nil as String?)
                        ForEach(availableStates, id: \.self) { state in
                            Text(state).tag(state as String?)
                        }
                    }

                    Picker("City", selection: $filterState.selectedCity) {
                        Text("Select City").tag(nil as String?)
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
            .sheet(isPresented: $showingICAOSearch) {
                ICAOSearchSheet(selectedICAO: $filterState.selectedICAO)
            }
            .sheet(isPresented: $showingManufacturerSearch) {
                ManufacturerSearchSheet(
                    selectedManufacturer: $filterState.selectedManufacturer,
                    availableManufacturers: availableManufacturers
                )
            }
        }
    }
}

// MARK: - Manufacturer Search Sheet
/// Searchable sheet for selecting a manufacturer from the user's aircraft collection
struct ManufacturerSearchSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedManufacturer: String?
    let availableManufacturers: [String]
    @State private var searchText = ""

    private var filteredManufacturers: [String] {
        if searchText.isEmpty {
            // Show all available manufacturers when not searching
            return availableManufacturers
        }

        // Split search into keywords - each word is an AND filter
        let keywords = searchText.lowercased()
            .split(separator: " ")
            .map { String($0) }
            .filter { !$0.isEmpty }

        guard !keywords.isEmpty else { return availableManufacturers }

        return availableManufacturers.filter { manufacturer in
            let searchableText = manufacturer.lowercased()
            return keywords.allSatisfy { keyword in
                searchableText.contains(keyword)
            }
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search field
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(AppColors.darkGray)
                    TextField("Search manufacturers...", text: $searchText)
                        .textFieldStyle(.plain)
                        .foregroundStyle(AppColors.darkGray)
                        .autocorrectionDisabled()
                    if !searchText.isEmpty {
                        Button(action: { searchText = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(12)
                .background(Color.white)
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(AppColors.borderBlue, lineWidth: 1)
                )
                .padding()

                // Results
                if filteredManufacturers.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 40))
                            .foregroundStyle(.secondary)
                        Text("No manufacturers found")
                            .font(.system(size: 16))
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxHeight: .infinity)
                } else {
                    List(filteredManufacturers, id: \.self) { manufacturer in
                        Button(action: {
                            selectedManufacturer = manufacturer
                            dismiss()
                        }) {
                            HStack {
                                Text(manufacturer)
                                    .font(.system(size: 16))
                                    .foregroundStyle(.primary)
                                Spacer()
                                if selectedManufacturer == manufacturer {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(.blue)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                    .listStyle(.plain)
                }

                Spacer(minLength: 0)
            }
            .navigationTitle("Select Manufacturer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    if selectedManufacturer != nil {
                        Button("Clear") {
                            selectedManufacturer = nil
                            dismiss()
                        }
                        .foregroundStyle(AppColors.orange)
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
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
    // Aircraft Identification
    @State private var editManufacturer = ""
    @State private var editModel = ""
    @State private var editRegistration = ""
    @State private var editICAO = ""
    @State private var editCountry = ""

    // Operator
    @State private var editAirlineCode: String? = nil
    @State private var editOwner = ""
    @State private var editOwnerType = ""
    @State private var editAddress1 = ""
    @State private var editAddress2 = ""
    @State private var editCity = ""
    @State private var editState = ""
    @State private var editZip = ""

    // Specifications
    @State private var editSerialNumber = ""
    @State private var editYearMfg: Int? = nil
    @State private var editAircraftCategoryCode: Int? = nil
    @State private var editAircraftClassification: Int? = nil
    @State private var editAircraftType: String? = nil
    @State private var editEngineType: Int? = nil
    @State private var editEngineCount: Int? = nil
    @State private var editSeatCount: Int? = nil
    @State private var editWeightClass = ""

    // Sighting
    @State private var editCaptureTime: Date = Date()

    // Search sheets
    @State private var showingAirlineSearch = false
    @State private var showingICAOSearch = false

    // Photo handling
    @State private var showingPhotoPicker = false
    @State private var showingPhotoViewer = false
    @State private var showingPortraitWarning = false
    @State private var showingDeletedPhotoAlert = false
    @State private var pendingPhoto: (image: UIImage, identifier: String)?

    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.settingsBackground.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 0) {
                        // Photo area with rating overlay
                        ZStack(alignment: .bottomLeading) {
                            // Photo display or placeholder
                            if let thumbnailData = aircraft.thumbnailData,
                               let uiImage = UIImage(data: thumbnailData) {
                                // Show thumbnail image - 100% width, height scales with 16:9 aspect ratio
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .aspectRatio(16/9, contentMode: .fit)
                                    .frame(maxWidth: .infinity)
                            } else {
                                // Show placeholder - 16:9 aspect ratio
                                Rectangle()
                                    .fill(AppColors.darkBlue.opacity(0.3))
                                    .aspectRatio(16/9, contentMode: .fit)
                                    .overlay {
                                        VStack(spacing: 12) {
                                            Image(systemName: isEditing || aircraft.thumbnailData == nil ? "photo.badge.plus" : "photo")
                                                .font(.system(size: 60))
                                                .foregroundStyle(.white.opacity(0.5))
                                            Text(isEditing || aircraft.thumbnailData == nil ? "Add Photo" : "Aircraft Photo")
                                                .font(.custom("Helvetica", size: 14))
                                                .foregroundStyle(.white.opacity(0.5))
                                        }
                                    }
                            }

                            // Edit overlay (shown when in edit mode and has photo)
                            if isEditing && aircraft.thumbnailData != nil {
                                VStack {
                                    Spacer()
                                    HStack {
                                        Spacer()
                                        Image(systemName: "pencil.circle.fill")
                                            .font(.system(size: 36))
                                            .foregroundStyle(.white)
                                            .shadow(radius: 4)
                                            .padding(12)
                                    }
                                }
                            }

                            // Star rating overlay at bottom-left
                            starRatingOverlay
                                .padding(.leading, 2)
                                .padding(.bottom, 2)
                        }
                        .frame(maxWidth: .infinity)
                        .onTapGesture {
                            handlePhotoTap()
                        }

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
                            ICAOPickerRow(
                                selectedICAO: $editICAO,
                                isEditing: isEditing,
                                onTap: { showingICAOSearch = true }
                            )
                            // Registration only shown if has data or editing
                            if !editRegistration.isEmpty || isEditing {
                                EditableDetailRow(label: "Registration", value: $editRegistration, isEditing: isEditing, placeholder: "e.g. N12345")
                            }
                            // Country
                            if !editCountry.isEmpty || isEditing {
                                EditableDetailRow(label: "Country", value: $editCountry, isEditing: isEditing, placeholder: "e.g. US")
                            }
                        }

                        // Operator Section
                        if hasOperatorData || isEditing {
                            detailSection(title: "Operator") {
                                if editAirlineCode != nil || isEditing {
                                    AirlinePickerRow(
                                        selectedAirlineCode: $editAirlineCode,
                                        isEditing: isEditing,
                                        onTap: { showingAirlineSearch = true }
                                    )
                                }
                                if !editOwner.isEmpty || isEditing {
                                    EditableDetailRow(label: "Owner", value: $editOwner, isEditing: isEditing)
                                }
                                if !editOwnerType.isEmpty || isEditing {
                                    EditableDetailRow(label: "Owner Type", value: $editOwnerType, isEditing: isEditing)
                                }
                                if !editAddress1.isEmpty || isEditing {
                                    EditableDetailRow(label: "Address", value: $editAddress1, isEditing: isEditing)
                                }
                                if !editAddress2.isEmpty || isEditing {
                                    EditableDetailRow(label: "Address 2", value: $editAddress2, isEditing: isEditing)
                                }
                                if !editCity.isEmpty || isEditing {
                                    EditableDetailRow(label: "City", value: $editCity, isEditing: isEditing)
                                }
                                if !editState.isEmpty || isEditing {
                                    EditableDetailRow(label: "State", value: $editState, isEditing: isEditing)
                                }
                                if !editZip.isEmpty || isEditing {
                                    EditableDetailRow(label: "Zip", value: $editZip, isEditing: isEditing)
                                }
                            }
                        }

                        // Aircraft Specifications Section
                        if hasSpecificationsData || isEditing {
                            detailSection(title: "Aircraft Specifications") {
                                // Category (Land/Sea/Amphibian) - auto-populated from ICAO
                                if editAircraftCategoryCode != nil || isEditing {
                                    LookupDisplayRow(
                                        label: "Category",
                                        displayValue: AircraftLookup.categoryName(editAircraftCategoryCode),
                                        isEditing: isEditing
                                    )
                                }
                                // Classification - editable
                                if editAircraftClassification != nil || isEditing {
                                    LookupDisplayRow(
                                        label: "Classification",
                                        displayValue: AircraftLookup.classificationName(editAircraftClassification),
                                        isEditing: isEditing
                                    )
                                }
                                // Type - auto-populated from ICAO
                                if editAircraftType != nil || isEditing {
                                    LookupDisplayRow(
                                        label: "Type",
                                        displayValue: AircraftLookup.typeName(editAircraftType),
                                        isEditing: isEditing
                                    )
                                }
                                // Serial Number - editable
                                if !editSerialNumber.isEmpty || isEditing {
                                    EditableDetailRow(label: "Serial Number", value: $editSerialNumber, isEditing: isEditing)
                                }
                                // Year Manufactured - editable
                                if editYearMfg != nil || isEditing {
                                    EditableIntRow(label: "Year Manufactured", value: $editYearMfg, isEditing: isEditing, placeholder: "e.g. 1975")
                                }
                                // Engine Type - auto-populated from ICAO
                                if editEngineType != nil || isEditing {
                                    LookupDisplayRow(
                                        label: "Engine Type",
                                        displayValue: AircraftLookup.engineTypeName(editEngineType),
                                        isEditing: isEditing
                                    )
                                }
                                // Engine Count - editable (also auto-populated from ICAO)
                                if editEngineCount != nil || isEditing {
                                    EditableIntRow(label: "Engine Count", value: $editEngineCount, isEditing: isEditing, placeholder: "e.g. 2")
                                }
                                // Seat Count - editable
                                if editSeatCount != nil || isEditing {
                                    EditableIntRow(label: "Seat Count", value: $editSeatCount, isEditing: isEditing, placeholder: "e.g. 4")
                                }
                                // Weight Class - editable
                                if !editWeightClass.isEmpty || isEditing {
                                    EditableDetailRow(label: "Weight Class", value: $editWeightClass, isEditing: isEditing)
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

                        // Sighting Details Section - always visible
                        detailSection(title: "Sighting Details") {
                            // Date/Time - editable
                            if isEditing {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Date & Time")
                                        .font(.system(size: 15))
                                        .foregroundStyle(.white.opacity(0.6))

                                    DatePicker("", selection: $editCaptureTime, displayedComponents: [.date, .hourAndMinute])
                                        .labelsHidden()
                                        .font(.system(size: 15))
                                        .foregroundStyle(.white)
                                        .tint(.white)
                                }
                                .padding(.vertical, 10)
                                .padding(.horizontal, 16)
                                .background(AppColors.settingsRow)
                                .cornerRadius(10)
                            } else {
                                DetailRow(label: "Date", value: formatDateTime(aircraft.captureTime))
                            }
                            // Location - read-only (GPS data should not be manually edited)
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
            .sheet(isPresented: $showingAirlineSearch) {
                AirlineSearchSheet(
                    selectedAirlineCode: $editAirlineCode
                )
                .presentationDetents([.large])
            }
            .sheet(isPresented: $showingICAOSearch) {
                ICAOEditSearchSheet(
                    selectedICAO: $editICAO
                )
                .presentationDetents([.large])
            }
            .sheet(isPresented: $showingPhotoPicker) {
                PhotoPickerView(
                    onSelect: { image, identifier in
                        handlePhotoSelected(image: image, identifier: identifier)
                    },
                    onCancel: { }
                )
            }
            .fullScreenCover(isPresented: $showingPhotoViewer) {
                FullScreenPhotoViewer(
                    localIdentifier: aircraft.iPhotoReference,
                    thumbnailData: aircraft.thumbnailData
                )
            }
            .alert("Portrait Photo", isPresented: $showingPortraitWarning) {
                Button("Continue") {
                    savePortraitPhoto()
                }
                Button("Choose Different", role: .cancel) {
                    pendingPhoto = nil
                    showingPhotoPicker = true
                }
            } message: {
                Text("You are attempting to upload a photo in portrait orientation. Our app is optimized for landscape images. Would you like to continue or upload a different image?")
            }
            .alert("Photo Unavailable", isPresented: $showingDeletedPhotoAlert) {
                Button("View Thumbnail") {
                    showingPhotoViewer = true
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("The original photo is no longer on this device. Would you like to view the thumbnail?")
            }
            .onChange(of: editICAO) { oldValue, newValue in
                // Auto-populate fields when ICAO is changed during editing
                if isEditing && !newValue.isEmpty && newValue != oldValue {
                    populateFromICAO(newValue)
                }
            }
            .onAppear {
                populateEditValues()
            }
        }
    }

    // MARK: - Populate Edit Values
    private func populateEditValues() {
        // Aircraft Identification
        editManufacturer = aircraft.manufacturer
        editModel = aircraft.model
        editICAO = aircraft.icao
        editRegistration = aircraft.registration ?? ""
        editCountry = aircraft.country ?? ""

        // Operator
        editAirlineCode = aircraft.airlineCode
        editOwner = aircraft.registeredOwner ?? ""
        editOwnerType = aircraft.ownerType ?? ""
        editAddress1 = aircraft.registeredAddress1 ?? ""
        editAddress2 = aircraft.registeredAddress2 ?? ""
        editCity = aircraft.registeredCity ?? ""
        editState = aircraft.registeredState ?? ""
        editZip = aircraft.registeredZip ?? ""

        // Specifications
        editSerialNumber = aircraft.serialNumber ?? ""
        editYearMfg = aircraft.yearMfg
        editAircraftCategoryCode = aircraft.aircraftCategoryCode
        editAircraftClassification = aircraft.aircraftClassification
        editAircraftType = aircraft.aircraftType
        editEngineType = aircraft.engineType
        editEngineCount = aircraft.engineCount
        editSeatCount = aircraft.seatCount
        editWeightClass = aircraft.weightClass ?? ""

        // Sighting
        editCaptureTime = aircraft.captureTime
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
        (aircraft.airlineCode != nil && !aircraft.airlineCode!.isEmpty) ||
        (aircraft.registeredOwner != nil && !aircraft.registeredOwner!.isEmpty) ||
        (aircraft.ownerType != nil && !aircraft.ownerType!.isEmpty) ||
        (aircraft.registeredAddress1 != nil && !aircraft.registeredAddress1!.isEmpty) ||
        (aircraft.registeredCity != nil && !aircraft.registeredCity!.isEmpty) ||
        (aircraft.registeredState != nil && !aircraft.registeredState!.isEmpty) ||
        (aircraft.registeredZip != nil && !aircraft.registeredZip!.isEmpty)
    }

    private var hasSpecificationsData: Bool {
        aircraft.aircraftCategoryCode != nil ||
        aircraft.aircraftClassification != nil ||
        aircraft.aircraftType != nil ||
        (aircraft.serialNumber != nil && !aircraft.serialNumber!.isEmpty) ||
        aircraft.yearMfg != nil ||
        aircraft.engineType != nil ||
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

    // MARK: - Photo Handling Functions

    /// Handle tap on photo area
    private func handlePhotoTap() {
        if aircraft.thumbnailData == nil {
            // No photo - always open picker (no edit mode required for first photo)
            showingPhotoPicker = true
        } else if isEditing {
            // Has photo + edit mode - open picker to change
            showingPhotoPicker = true
        } else {
            // Has photo + view mode - open viewer (check if original exists)
            checkAndShowPhotoViewer()
        }
    }

    /// Check if original photo exists and show appropriate viewer
    private func checkAndShowPhotoViewer() {
        if PhotoLibraryManager.shared.fetchAsset(localIdentifier: aircraft.iPhotoReference) != nil {
            showingPhotoViewer = true
        } else if aircraft.thumbnailData != nil {
            // Original deleted but we have thumbnail
            showingDeletedPhotoAlert = true
        }
    }

    /// Handle photo selection from picker
    private func handlePhotoSelected(image: UIImage, identifier: String) {
        // Check if portrait
        if ThumbnailGenerator.isPortrait(image) {
            pendingPhoto = (image, identifier)
            showingPortraitWarning = true
        } else {
            // Landscape - save directly
            savePhoto(image: image, identifier: identifier)
        }
    }

    /// Save portrait photo after user confirms
    private func savePortraitPhoto() {
        if let photo = pendingPhoto {
            savePhoto(image: photo.image, identifier: photo.identifier)
            pendingPhoto = nil
        }
    }

    /// Save photo to aircraft model and add to Airplane-ID album
    private func savePhoto(image: UIImage, identifier: String) {
        // Generate thumbnail
        if let thumbnailData = ThumbnailGenerator.generateThumbnail(from: image) {
            aircraft.thumbnailData = thumbnailData
            aircraft.iPhotoReference = identifier
            try? modelContext.save()

            // Add photo to Airplane-ID album in background
            Task {
                _ = await PhotoLibraryManager.shared.addPhotoToAppAlbum(localIdentifier: identifier)
            }
        }
    }

    /// Auto-populate fields from ICAO lookup when user selects an aircraft type
    private func populateFromICAO(_ icaoCode: String) {
        // Query for the ICAO lookup data (we need modelContext for this)
        let descriptor = FetchDescriptor<ICAOLookup>(
            predicate: #Predicate { $0.icao == icaoCode }
        )
        guard let icaoData = try? modelContext.fetch(descriptor).first else { return }

        // Update edit fields from ICAO data
        editManufacturer = icaoData.manufacturer
        editModel = icaoData.model
        editAircraftCategoryCode = icaoData.aircraftCategoryCode
        editAircraftType = icaoData.aircraftType
        editEngineType = icaoData.engineType
        editEngineCount = icaoData.engineCount
    }

    private func saveChanges() {
        // Aircraft Identification
        aircraft.manufacturer = editManufacturer
        aircraft.model = editModel
        aircraft.icao = editICAO
        aircraft.registration = editRegistration.isEmpty ? nil : editRegistration
        aircraft.country = editCountry.isEmpty ? nil : editCountry

        // Operator
        aircraft.airlineCode = editAirlineCode
        aircraft.registeredOwner = editOwner.isEmpty ? nil : editOwner
        aircraft.ownerType = editOwnerType.isEmpty ? nil : editOwnerType
        aircraft.registeredAddress1 = editAddress1.isEmpty ? nil : editAddress1
        aircraft.registeredAddress2 = editAddress2.isEmpty ? nil : editAddress2
        aircraft.registeredCity = editCity.isEmpty ? nil : editCity
        aircraft.registeredState = editState.isEmpty ? nil : editState
        aircraft.registeredZip = editZip.isEmpty ? nil : editZip

        // Specifications
        aircraft.serialNumber = editSerialNumber.isEmpty ? nil : editSerialNumber
        aircraft.yearMfg = editYearMfg
        aircraft.aircraftCategoryCode = editAircraftCategoryCode
        aircraft.aircraftClassification = editAircraftClassification
        aircraft.aircraftType = editAircraftType
        aircraft.engineType = editEngineType
        aircraft.engineCount = editEngineCount
        aircraft.seatCount = editSeatCount
        aircraft.weightClass = editWeightClass.isEmpty ? nil : editWeightClass

        // Sighting - update date components too
        aircraft.captureTime = editCaptureTime
        aircraft.captureDate = Calendar.current.startOfDay(for: editCaptureTime)
        aircraft.year = Calendar.current.component(.year, from: editCaptureTime)
        aircraft.month = Calendar.current.component(.month, from: editCaptureTime)
        aircraft.day = Calendar.current.component(.day, from: editCaptureTime)

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

// MARK: - Editable Int Row Component
/// Row for editing optional Int values (year, count, etc.)
struct EditableIntRow: View {
    let label: String
    @Binding var value: Int?
    let isEditing: Bool
    var placeholder: String = ""

    @State private var textValue: String = ""

    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 15))
                .foregroundStyle(.white.opacity(0.6))
            Spacer()
            if isEditing {
                TextField(placeholder.isEmpty ? label : placeholder, text: $textValue)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.trailing)
                    .textFieldStyle(.plain)
                    .keyboardType(.numberPad)
                    .padding(.vertical, 4)
                    .padding(.horizontal, 8)
                    .background(AppColors.darkBlue.opacity(0.3))
                    .cornerRadius(6)
                    .frame(maxWidth: 120)
                    .onChange(of: textValue) { _, newValue in
                        value = Int(newValue)
                    }
            } else {
                Text(value != nil ? String(value!) : "—")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(value != nil ? .white : .white.opacity(0.3))
                    .multilineTextAlignment(.trailing)
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 16)
        .background(AppColors.settingsRow)
        .cornerRadius(10)
        .onAppear {
            textValue = value != nil ? String(value!) : ""
        }
        .onChange(of: value) { _, newValue in
            textValue = newValue != nil ? String(newValue!) : ""
        }
    }
}

// MARK: - Lookup Display Row Component
/// Row that displays a lookup value (editable via ICAO auto-populate)
struct LookupDisplayRow: View {
    let label: String
    let displayValue: String?
    let isEditing: Bool

    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 15))
                .foregroundStyle(.white.opacity(0.6))
            Spacer()
            Text(displayValue ?? "—")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(displayValue != nil ? .white : .white.opacity(0.3))
                .multilineTextAlignment(.trailing)
            if isEditing {
                // Indicate this is auto-populated from ICAO
                Image(systemName: "link")
                    .font(.system(size: 10))
                    .foregroundStyle(.white.opacity(0.3))
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

// MARK: - Airline Picker Row
/// Row that displays selected airline and opens search when tapped
struct AirlinePickerRow: View {
    @Binding var selectedAirlineCode: String?
    let isEditing: Bool
    let onTap: () -> Void

    @Query private var airlines: [AirlineLookup]

    var body: some View {
        HStack {
            Text("Airline")
                .font(.system(size: 15))
                .foregroundStyle(.white.opacity(0.6))
            Spacer()
            if isEditing {
                Button(action: onTap) {
                    HStack(spacing: 4) {
                        Text(selectedAirlineName)
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(selectedAirlineCode == nil ? .white.opacity(0.3) : .white)
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12))
                            .foregroundStyle(.white.opacity(0.3))
                    }
                }
            } else {
                Text(selectedAirlineName)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(selectedAirlineCode == nil ? .white.opacity(0.3) : .white)
                    .multilineTextAlignment(.trailing)
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 16)
        .background(AppColors.settingsRow)
        .cornerRadius(10)
    }

    private var selectedAirlineName: String {
        guard let code = selectedAirlineCode,
              let airline = airlines.first(where: { $0.airlineCode == code }) else {
            return "—"
        }
        return airline.airlineName
    }
}

// MARK: - ICAO Picker Row
/// Row that displays selected ICAO and opens search when tapped (for edit form)
struct ICAOPickerRow: View {
    @Binding var selectedICAO: String
    let isEditing: Bool
    let onTap: () -> Void

    var body: some View {
        HStack {
            Text("ICAO")
                .font(.system(size: 15))
                .foregroundStyle(.white.opacity(0.6))
            Spacer()
            if isEditing {
                Button(action: onTap) {
                    HStack(spacing: 4) {
                        Text(displayText)
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(selectedICAO.isEmpty ? .white.opacity(0.3) : .white)
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12))
                            .foregroundStyle(.white.opacity(0.3))
                    }
                }
            } else {
                Text(displayText)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(selectedICAO.isEmpty ? .white.opacity(0.3) : .white)
                    .multilineTextAlignment(.trailing)
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 16)
        .background(AppColors.settingsRow)
        .cornerRadius(10)
    }

    private var displayText: String {
        selectedICAO.isEmpty ? "—" : selectedICAO
    }
}

// MARK: - ICAO Search Sheet
/// Searchable sheet for selecting an ICAO aircraft type from the lookup table
/// Users can search by ICAO code, manufacturer name, or model
struct ICAOSearchSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedICAO: String?

    @Query(sort: \ICAOLookup.manufacturer) private var allAircraft: [ICAOLookup]
    @State private var searchText = ""

    private var filteredAircraft: [ICAOLookup] {
        if searchText.isEmpty {
            return []  // Don't show all 2700+ aircraft when search is empty
        }

        // Split search into keywords - each word is an AND filter
        // "Cessna 172" → must contain "cessna" AND "172"
        let keywords = searchText.lowercased()
            .split(separator: " ")
            .map { String($0) }
            .filter { !$0.isEmpty }

        guard !keywords.isEmpty else { return [] }

        return allAircraft.filter { aircraft in
            // Combine all searchable fields into one string
            let searchableText = "\(aircraft.icao) \(aircraft.manufacturer) \(aircraft.model)".lowercased()
            // ALL keywords must be found somewhere in the combined text
            return keywords.allSatisfy { keyword in
                searchableText.contains(keyword)
            }
        }
        .prefix(50)  // Limit results for performance
        .map { $0 }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search field
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(AppColors.darkGray)
                    TextField("Search aircraft types...", text: $searchText)
                        .textFieldStyle(.plain)
                        .foregroundStyle(AppColors.darkGray)
                        .autocorrectionDisabled()
                    if !searchText.isEmpty {
                        Button(action: { searchText = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(12)
                .background(Color.white)
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(AppColors.borderBlue, lineWidth: 1)
                )
                .padding()

                // Results or instructions
                if searchText.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "airplane")
                            .font(.system(size: 40))
                            .foregroundStyle(.secondary)
                        Text("Start typing to search aircraft")
                            .font(.system(size: 16))
                            .foregroundStyle(.secondary)
                        Text("Search by ICAO code, manufacturer, or model")
                            .font(.system(size: 14))
                            .foregroundStyle(.tertiary)
                        Text("Example: \"Cessna 172\" or \"B738\"")
                            .font(.system(size: 13))
                            .foregroundStyle(.tertiary)
                    }
                    .frame(maxHeight: .infinity)
                } else if filteredAircraft.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 40))
                            .foregroundStyle(.secondary)
                        Text("No aircraft found")
                            .font(.system(size: 16))
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxHeight: .infinity)
                } else {
                    List(filteredAircraft, id: \.icao) { aircraft in
                        Button(action: {
                            selectedICAO = aircraft.icao
                            dismiss()
                        }) {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("\(aircraft.manufacturer) \(aircraft.model)")
                                        .font(.system(size: 16))
                                        .foregroundStyle(.primary)
                                    HStack(spacing: 8) {
                                        Text(aircraft.icao)
                                            .font(.system(size: 12, weight: .bold))
                                            .foregroundStyle(.blue)
                                        Text(aircraft.icaoClass)
                                            .font(.system(size: 12))
                                            .foregroundStyle(.secondary)
                                        Text("\(aircraft.engineCount) engine\(aircraft.engineCount == 1 ? "" : "s")")
                                            .font(.system(size: 12))
                                            .foregroundStyle(.tertiary)
                                    }
                                }
                                Spacer()
                                if selectedICAO == aircraft.icao {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(.blue)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                    .listStyle(.plain)
                }

                Spacer(minLength: 0)
            }
            .navigationTitle("Select Aircraft Type")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    if selectedICAO != nil {
                        Button("Clear") {
                            selectedICAO = nil
                            dismiss()
                        }
                        .foregroundStyle(AppColors.orange)
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - ICAO Edit Search Sheet
/// Searchable sheet for selecting an ICAO type in edit mode (takes String binding, not optional)
struct ICAOEditSearchSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedICAO: String

    @Query(sort: \ICAOLookup.manufacturer) private var allAircraft: [ICAOLookup]
    @State private var searchText = ""

    private var filteredAircraft: [ICAOLookup] {
        if searchText.isEmpty {
            return []  // Don't show all 2700+ aircraft when search is empty
        }

        // Split search into keywords - each word is an AND filter
        let keywords = searchText.lowercased()
            .split(separator: " ")
            .map { String($0) }
            .filter { !$0.isEmpty }

        guard !keywords.isEmpty else { return [] }

        return allAircraft.filter { aircraft in
            let searchableText = "\(aircraft.icao) \(aircraft.manufacturer) \(aircraft.model)".lowercased()
            return keywords.allSatisfy { keyword in
                searchableText.contains(keyword)
            }
        }
        .prefix(50)
        .map { $0 }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search field
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(AppColors.darkGray)
                    TextField("Search aircraft types...", text: $searchText)
                        .textFieldStyle(.plain)
                        .foregroundStyle(AppColors.darkGray)
                        .autocorrectionDisabled()
                    if !searchText.isEmpty {
                        Button(action: { searchText = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(12)
                .background(Color.white)
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(AppColors.borderBlue, lineWidth: 1)
                )
                .padding()

                // Results or instructions
                if searchText.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "airplane")
                            .font(.system(size: 40))
                            .foregroundStyle(.secondary)
                        Text("Start typing to search aircraft")
                            .font(.system(size: 16))
                            .foregroundStyle(.secondary)
                        Text("Search by ICAO code, manufacturer, or model")
                            .font(.system(size: 14))
                            .foregroundStyle(.tertiary)
                        Text("Example: \"Cessna 172\" or \"B738\"")
                            .font(.system(size: 13))
                            .foregroundStyle(.tertiary)
                    }
                    .frame(maxHeight: .infinity)
                } else if filteredAircraft.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 40))
                            .foregroundStyle(.secondary)
                        Text("No aircraft found")
                            .font(.system(size: 16))
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxHeight: .infinity)
                } else {
                    List(filteredAircraft, id: \.icao) { aircraft in
                        Button(action: {
                            selectedICAO = aircraft.icao
                            dismiss()
                        }) {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("\(aircraft.manufacturer) \(aircraft.model)")
                                        .font(.system(size: 16))
                                        .foregroundStyle(.primary)
                                    HStack(spacing: 8) {
                                        Text(aircraft.icao)
                                            .font(.system(size: 12, weight: .bold))
                                            .foregroundStyle(.blue)
                                        Text(aircraft.icaoClass)
                                            .font(.system(size: 12))
                                            .foregroundStyle(.secondary)
                                        Text("\(aircraft.engineCount) engine\(aircraft.engineCount == 1 ? "" : "s")")
                                            .font(.system(size: 12))
                                            .foregroundStyle(.tertiary)
                                    }
                                }
                                Spacer()
                                if selectedICAO == aircraft.icao {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(.blue)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                    .listStyle(.plain)
                }

                Spacer(minLength: 0)
            }
            .navigationTitle("Select Aircraft Type")
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
}

// MARK: - Airline Search Sheet
/// Searchable sheet for selecting an airline from the lookup table
struct AirlineSearchSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedAirlineCode: String?

    @Query(sort: \AirlineLookup.airlineName) private var allAirlines: [AirlineLookup]
    @State private var searchText = ""

    private var filteredAirlines: [AirlineLookup] {
        if searchText.isEmpty {
            return []  // Don't show all 5000+ airlines when search is empty
        }

        // Split search into keywords - each word is an AND filter
        // "United Airlines" → must contain "united" AND "airlines"
        let keywords = searchText.lowercased()
            .split(separator: " ")
            .map { String($0) }
            .filter { !$0.isEmpty }

        guard !keywords.isEmpty else { return [] }

        return allAirlines.filter { airline in
            // Combine all searchable fields into one string
            let searchableText = "\(airline.airlineName) \(airline.airlineCode) \(airline.iata ?? "")".lowercased()
            // ALL keywords must be found somewhere in the combined text
            return keywords.allSatisfy { keyword in
                searchableText.contains(keyword)
            }
        }
        .prefix(50)  // Limit results for performance
        .map { $0 }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search field
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(AppColors.darkGray)
                    TextField("Search airlines...", text: $searchText)
                        .textFieldStyle(.plain)
                        .foregroundStyle(AppColors.darkGray)
                        .autocorrectionDisabled()
                    if !searchText.isEmpty {
                        Button(action: { searchText = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(12)
                .background(Color.white)
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(AppColors.borderBlue, lineWidth: 1)
                )
                .padding()

                // Results or instructions
                if searchText.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "airplane")
                            .font(.system(size: 40))
                            .foregroundStyle(.secondary)
                        Text("Start typing to search airlines")
                            .font(.system(size: 16))
                            .foregroundStyle(.secondary)
                        Text("Search by name, code, or IATA")
                            .font(.system(size: 14))
                            .foregroundStyle(.tertiary)
                    }
                    .frame(maxHeight: .infinity)
                } else if filteredAirlines.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 40))
                            .foregroundStyle(.secondary)
                        Text("No airlines found")
                            .font(.system(size: 16))
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxHeight: .infinity)
                } else {
                    List(filteredAirlines, id: \.airlineCode) { airline in
                        Button(action: {
                            selectedAirlineCode = airline.airlineCode
                            dismiss()
                        }) {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(airline.airlineName)
                                        .font(.system(size: 16))
                                        .foregroundStyle(.primary)
                                    HStack(spacing: 8) {
                                        Text(airline.airlineCode)
                                            .font(.system(size: 12, weight: .medium))
                                            .foregroundStyle(.secondary)
                                        if let iata = airline.iata, !iata.isEmpty {
                                            Text("IATA: \(iata)")
                                                .font(.system(size: 12))
                                                .foregroundStyle(.tertiary)
                                        }
                                    }
                                }
                                Spacer()
                                if selectedAirlineCode == airline.airlineCode {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(.blue)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                    .listStyle(.plain)
                }

                Spacer(minLength: 0)
            }
            .navigationTitle("Select Airline")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    if selectedAirlineCode != nil {
                        Button("Clear") {
                            selectedAirlineCode = nil
                            dismiss()
                        }
                        .foregroundStyle(AppColors.orange)
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
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
