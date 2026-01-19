# FAA Code Reference

Reference tables for FAA aircraft codes used in the Airplane-ID app.

---

## FAA Code Reference

### FAA Engine Type Codes (TYPE-ENG)
| Code | Description |
|------|-------------|
| 0 | None |
| 1 | Reciprocating (Piston) |
| 2 | Turbo-prop |
| 3 | Turbo-shaft |
| 4 | Turbo-jet |
| 5 | Turbo-fan |
| 6 | Ramjet |
| 7 | 2-cycle |
| 8 | 4-cycle |
| 9 | Unknown |
| 10 | Electric |
| 11 | Rotary |

### FAA Aircraft Type Codes (TYPE-ACFT)
| Code | Description |
|------|-------------|
| 1 | Glider |
| 2 | Balloon |
| 3 | Blimp/Dirigible |
| 4 | Fixed Wing Single-Engine |
| 5 | Fixed Wing Multi-Engine |
| 6 | Rotorcraft |
| 7 | Weight-shift-control |
| 8 | Powered Parachute |
| 9 | Gyroplane |
| H | Hybrid Lift |
| O | Other |

### FAA Aircraft Category Codes
| Code | Description |
|------|-------------|
| 1 | Land |
| 2 | Sea |
| 3 | Amphibian |

---

### Session Summary - 2026-01-17 (evening)

**Goal:** Create ICAO aircraft type lookup table with FAA-compatible codes.

**Why:**
- Enable auto-population of aircraft specs when user selects ICAO code
- Ensure data consistency with FAA database imports
- 2,757 aircraft types available offline - covers 98% of use cases

**ICAO to FAA Mapping:**

| ICAO Engine Type | → FAA Code |
|------------------|------------|
| Piston | 1 (Reciprocating) |
| Jet | 4 (Turbo-jet) |
| Turboprop | 2 (Turbo-prop) |
| Turboshaft | 3 (Turbo-shaft) |
| Turboprop/Turboshaft | 3 (Turbo-shaft) |
| Electric | 10 (Electric) |
| Rocket | 9 (Unknown) |
| Glider | 0 (None) |

| ICAO Class | → FAA Type | → FAA Category |
|------------|------------|----------------|
| LandPlane (1 eng) | 4 (FW Single) | 1 (Land) |
| LandPlane (2+ eng) | 5 (FW Multi) | 1 (Land) |
| SeaPlane (1 eng) | 4 (FW Single) | 2 (Sea) |
| SeaPlane (2+ eng) | 5 (FW Multi) | 2 (Sea) |
| Amphibian (1 eng) | 4 (FW Single) | 3 (Amphibian) |
| Amphibian (2+ eng) | 5 (FW Multi) | 3 (Amphibian) |
| Helicopter | 6 (Rotorcraft) | 1 (Land) |
| Gyrocopter | 9 (Gyroplane) | 1 (Land) |
| Tiltrotor | H (Hybrid Lift) | 1 (Land) |

**What was built:**
1. Created `generate_icao_codes.py` to parse ICAOList.csv and map to FAA codes
2. Generated `ICAOCodes.csv` with 2,757 aircraft types
3. Created `ICAOLookup` SwiftData model with fields:
   - `icao` (unique) - ICAO type designator
   - `manufacturer` - Aircraft manufacturer
   - `model` - Aircraft model
   - `icaoClass` - Original ICAO class (LandPlane, Helicopter, etc.)
   - `aircraftCategoryCode` - FAA category (1=Land, 2=Sea, 3=Amphibian)
   - `aircraftType` - FAA TYPE-ACFT code ("4", "5", "6", "9", "H")
   - `engineCount` - Number of engines
   - `engineType` - FAA TYPE-ENG code (0-11)
4. Auto-loads ICAO data on first app launch
5. Added Developer Tools import button for manual refresh

**Distribution:**
- Category: Land=2666, Sea=8, Amphibian=83
- Type: FW Single=1847, FW Multi=676, Rotorcraft=180, Gyroplane=47, Hybrid=4, Glider=3
- Engine: Reciprocating=1890, Turbo-jet=434, Turbo-shaft=402, Electric=26, Turbo-prop=2, Unknown=2, None=1

**Files changed:**
- `Data/generate_icao_codes.py` - Python script with FAA mapping
- `Data/ICAOCodes.csv` - Generated reference data
- `ICAOCodes.csv` - Copied to app bundle
- `Item.swift` - ICAOLookup model with FAA-compatible fields
- `Airplane_IDApp.swift` - Auto-load logic for ICAO codes
- `SettingsPage.swift` - Developer Tools import button

**Next:** Create ICAO search UI for selecting aircraft type and auto-populating fields

### Session Summary - 2026-01-17 (late evening)

**Goal:** Add searchable ICAO filter to HangarPage and clean up Developer Tools.

**What was done:**

1. **Removed manual import buttons from Developer Tools:**
   - Removed "Reference Data" section entirely
   - Removed `importAirlineCodesFromCSV()` function
   - Removed `importICAOCodesFromCSV()` function
   - Data now auto-loads on first app launch - no manual import needed

2. **Added ICAO search to HangarPage filter:**
   - Replaced static Picker with searchable button in `HangarFilterSheet`
   - Created `ICAOSearchSheet` component:
     - Queries `ICAOLookup` table (2,757 aircraft types)
     - Searches by ICAO code, manufacturer, or model
     - Shows: Manufacturer + Model, ICAO code (blue), icaoClass, engine count
     - Limits to 50 results for performance
     - Clear button to remove filter
     - Example hints for user guidance

**User flow:**
1. Hangar → Filter button → "ICAO Type" row
2. Search sheet opens with search box
3. Type "Cessna 310" or "B738" etc.
4. Results narrow down as you type
5. Tap to select → returns to filter with ICAO selected

**Files changed:**
- `SettingsPage.swift` - Removed Reference Data section and import functions
- `HangarPage.swift` - Added `ICAOSearchSheet`, updated `HangarFilterSheet`

**Schema change:** ICAOLookup model updated with FAA-compatible fields - requires app reinstall

3. **Enhanced keyword-based search:**
   - Search now splits input by spaces and treats each word as an AND filter
   - "Cessna 172" finds aircraft matching both "cessna" AND "172"
   - Applied to both `ICAOSearchSheet` and `AirlineSearchSheet`
   - Implementation: Split on spaces, filter with `allSatisfy` on keywords
   - Commit: 45336c3

4. **Added searchable Manufacturer filter:**
   - Replaced long Picker dropdown with `ManufacturerSearchSheet`
   - Shows all manufacturers from user's aircraft collection on open
   - Supports keyword search (same AND logic as ICAO/Airline)
   - Respects bi-directional filtering (only shows manufacturers matching other active filters)
   - Note: FAA data has inconsistencies (e.g., 4 different Mooney entries)
   - Commit: 2552349

5. **Shortened filter placeholder text to prevent word wrap:**
   - Search fields: "Search MFG", "Search ICAO", "Search Airline"
   - Select fields: "Select Year/Month/Category/Type/Country/State/City"
   - Commit: b50a5a2

6. **Standardized search box styling across all search sheets:**
   - White background with blue border (AppColors.borderBlue)
   - Darker magnifying glass icon (AppColors.darkGray)
   - Applied to: ManufacturerSearchSheet, ICAOSearchSheet, AirlineSearchSheet
   - Commits: 8f9325c, cc53140

7. **Recent Sightings tappable on HomePage:**
   - Click aircraft in Recent Sightings to open detail view
   - Reuses `AircraftDetailView` component from HangarPage.swift
   - Single component - edit once, updates everywhere
   - Commit: 0cb5d6a

8. **ICAO auto-populate and editable fields in AircraftDetailView:**
   - **Model changes (Item.swift):**
     - Added `aircraftCategoryCode: Int?` (1=Land, 2=Sea, 3=Amphibian)
     - Changed `engineType` from `String?` to `Int?` for FAA consistency
   - **Lookup functions (Theme.swift):**
     - Added `categoryName()` for Land/Sea/Amphibian
     - Added `engineTypeName()` for engine type codes (0=None, 1=Recip, 2=Turbo-prop, etc.)
   - **ICAO selection auto-populates:**
     - manufacturer, model, aircraftCategoryCode, aircraftType, engineType, engineCount
   - **Editable fields:** Country, Owner, Owner Type, Address, City, State, Zip, Serial Number, Year Mfg, Engine Count, Seat Count, Weight Class, Sighting Date/Time
   - **Read-only fields:** GPS location, Airworthiness Date, Certificate dates
   - **New components:** `EditableIntRow`, `LookupDisplayRow`, `ICAOPickerRow`
   - Commit: 4cb0f65
   - **Schema change** - requires app reinstall

9. **Fixed build error from engineType type change:**
   - SettingsPage.swift test data import was still using String for engineType
   - Changed tuple type and CSV parsing to use Int? instead of String?
   - Commit: 91cb0cd

10. **Fixed date/time formatting in edit mode:**
    - "Date & Time" label was pushed to the left side next to picker (formatting issue)
    - Restructured to VStack with label on top, DatePicker controls below
    - Uses `.labelsHidden()` on DatePicker with separate Text label above
    - Matches layout pattern of other editable fields
    - Commit: f588732

---
