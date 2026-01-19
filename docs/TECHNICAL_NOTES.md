# Technical Notes

This document contains technical implementation details, architecture decisions, and code patterns for the Airplane-ID iOS app.

---

## Technical Notes

### Color Management (Theme.swift)

**All colors are centralized in `Theme.swift`.** Never use hardcoded hex values in view files.

**To change a color globally:** Edit the hex value in Theme.swift
```swift
// Example: Change the gold accent color
static let gold = Color(hex: "FBBD1C")  // Edit this hex value
```

**To add a new color:**
1. Add a new static property to the appropriate section in `AppColors`
2. Use semantic naming (e.g., `buttonBackground`, `errorText`)
3. Use `AppColors.newColorName` in your views

**Color Categories in Theme.swift:**

| Category | Colors | Usage |
|----------|--------|-------|
| Primary Brand | `darkBlue`, `primaryBlue`, `gold`, `orange` | Headers, backgrounds, accents, icons |
| Background | `settingsBackground`, `settingsRow`, `white`, `black` | Page backgrounds, row backgrounds |
| UI Elements | `linkBlue`, `borderBlue`, `darkGray`, `mediumGray`, `lightGray` | Links, borders, icons |
| Status | `success`, `error`, `warning`, `info` | Alerts, validation states |
| Progress Bar | `progressFill`, `progressLegend` | Normal progress, LEGEND level |

**Current Brand Colors (hex values):**
- Primary Blue: #1D58A4 (main backgrounds)
- Dark Blue: #082A49 (headers, labels)
- Gold: #FBBD1C (numbers, highlights)
- Orange: #F27C31 (icons, airplane indicators)
- Link Blue: #639BEC (buttons, toggles)

**Usage in Views:**
```swift
import SwiftUI

struct MyView: View {
    var body: some View {
        Text("Hello")
            .foregroundStyle(AppColors.gold)      // Use color constant
            .background(AppColors.primaryBlue)    // Never use Color(hex: "...")
    }
}
```

### Responsive Scaling System
Design baseline: iPhone 14 Pro (393 x 852 points)

**ScreenScale struct (ContentView.swift):**
- Calculates scale factor based on actual screen dimensions vs baseline
- Automatically detects orientation and uses appropriate baseline (swaps width/height for landscape)
- Uses `min(widthScale, heightScale)` to ensure content fits without clipping
- Injected via `@Environment(\.screenScale)` from templates

**Usage:**
```swift
@Environment(\.screenScale) private var screenScale

// In view body:
VStack { /* content */ }
    .scaleEffect(screenScale.scale)
```

**How it works:**
- Templates (PortraitTemplate, LandscapeLeftTemplate, LandscapeRightTemplate) calculate ScreenScale from GeometryReader
- ScreenScale is injected into environment via `.environment(\.screenScale, screenScale)`
- Content views read the scale and apply `.scaleEffect()` to their root container
- Scale factor ensures content designed for baseline device fits on smaller screens

### Recent Sightings Display Format
**Line 1:** `[IATA] MANUFACTURER MODEL` (bold)
- IATA optional, shown only if present (e.g., "UA")
- Manufacturer in ALL CAPS
- Model as stored (mixed case)
- Example with IATA: "UA BOEING 747"
- Example without IATA: "PIPER PA-46-310P"

**Line 2:** `[CLASSIFICATION] [Type]` (regular, dimmed)
- Classification in ALL CAPS (STANDARD, LIMITED, etc.)
- Type in Title Case (Fixed Wing Single-Engine, Rotorcraft, etc.)
- Either can be omitted if not in database
- Example: "STANDARD Fixed Wing Single-Engine"
- If no data, line 2 is hidden

**Lookup Tables** (Theme.swift - AircraftLookup):
- `classificationName(Int?)` → returns classification string or nil
- `typeName(String?)` → returns type string or nil

### FAA Aircraft Code Lookups (AircraftLookup in Theme.swift)

**Aircraft Classification (AC-CAT)** - stored as Int, displayed in ALL CAPS:
| Code | Display Name |
|------|-------------|
| 1 | STANDARD |
| 2 | LIMITED |
| 3 | RESTRICTED |
| 4 | EXPERIMENTAL |
| 5 | PROVISIONAL |
| 6 | MULTIPLE |
| 7 | PRIMARY |
| 8 | SPECIAL FLIGHT PERMIT |
| 9 | LIGHT SPORT |

**Aircraft Type (TYPE-ACFT)** - stored as String, displayed in Title Case:
| Code | Display Name |
|------|-------------|
| 1 | Glider |
| 2 | Balloon |
| 3 | Blimp/Dirigible |
| 4 | Fixed Wing Single-Engine |
| 5 | Fixed Wing Multi-Engine |
| 6 | Rotorcraft |
| 7 | Weight Shift Control |
| 8 | Powered Parachute |
| 9 | Gyroplane |
| H | Hybrid Lift |
| O | Unclassified |

**Usage in code:**
```swift
// Get display strings from codes
let classification = AircraftLookup.classificationName(aircraft.aircraftClassification) // "STANDARD"
let type = AircraftLookup.typeName(aircraft.aircraftType) // "Fixed Wing Single-Engine"
```

**Data source:** FAA ACFTREF file (FAA-Manufacturer-Reference.csv)
- AC-CAT column → aircraftClassification (Int)
- TYPE-ACFT column → aircraftType (String)

**Styling:**
- Portrait: Helvetica-Bold 15pt (line 1), Helvetica 13pt (line 2)
- Landscape: System 19pt bold (line 1), System 15pt regular (line 2)
- Text color: AppColors.darkBlue (line 2 at 0.7 opacity)

### CapturedAircraft Model Properties (31 fields)

**Required at capture (from device):**
- captureTime (Date) - full timestamp when photo taken/uploaded
- captureDate (Date) - date only, derived from captureTime
- year, month, day (Int) - derived from captureTime for filtering
- gpsLongitude, gpsLatitude (Double) - photo location
- iPhotoReference (String) - link to photo in device iPhoto library

**Required at capture (from AI recognition):**
- icao (String) - ICAO aircraft type code
- manufacturer (String) - aircraft manufacturer
- model (String) - aircraft model name

**Optional (if AI detects in photo):**
- iata (String?) - airline code (AA, UA) - airliners only
- registration (String?) - N-number if visible in photo

**Optional (populated via cloud sync from FAA data):**
- serialNumber, engineType, weightClass (String?)
- aircraftClassification (Int?) - FAA category 1-9 (see AircraftLookup in Theme.swift)
- aircraftType (String?) - FAA type code 1-9, H, O (see AircraftLookup in Theme.swift)
- yearMfg, engineCount, seatCount (Int?)
- country, ownerType (String?)
- airworthinessDate, certificateIssueDate, certificateExpireDate (Date?)
- registeredOwner, registeredAddress1, registeredAddress2 (String?)
- registeredCity, registeredState, registeredZip (String?)

**Future features (for map tracking):**
- gpsLongitudeNow, gpsLatitudeNow (Double?) - Current aircraft position from server sync

**User interaction (null unless user acts):**
- rating (Double?) - Star rating 0.5 to 5.0 in 0.5 increments
- thumbsUp (Bool?) - AI training feedback (not shown in UI)

### User Model Properties
- memberNumber (primary key for server sync)
- name, email, phone
- passwordHash, passwordRequired, faceIDEnabled
- displayName, memberDate, homeAirport, memberLevel
- lastSyncDate, syncToken (for future server sync)
- **Privacy preferences** (all default true):
  - showOnlineStatus, showLocation (visibility settings)
  - receiveNews, receiveUpdates, receiveActivitySummary (notifications)
  - allowFollow, showInSearch (social/discovery - future use)

### Level Progression System
Levels are based on total aircraft captured (database record count).

| Level | Aircraft Required | Progress To | Description |
|-------|------------------|-------------|-------------|
| NEWBIE | 0-9 | SPOTTER | "You're just getting started!" |
| SPOTTER | 10-99 | ENTHUSIAST | "You've got sharp eyes!" |
| ENTHUSIAST | 100-249 | EXPERT | "You're hooked on aviation!" |
| EXPERT | 250-499 | ACE | "Your knowledge is impressive!" |
| ACE | 500-1099 | LEGEND | "You're among the elite!" |
| LEGEND | 1100+ | (max) | "You've reached the pinnacle!" |

**Implementation:**
- `currentStatus` - Computed from `allAircraft.count` using thresholds above
- `nextLevel` - Returns the next level name based on currentStatus
- `levelProgress` - Returns 0.0-1.0 progress toward next threshold
- `uniqueTypesCount` - Counts unique ICAO codes: `Set(allAircraft.compactMap { $0.icao }).count`
- AppState is updated in `onAppear` and `onChange(of: allAircraft.count)`

### Navigation System
| Destination | Icon | Tap Location | Page | Header Title |
|-------------|------|--------------|------|--------------|
| home | house | Footer | HomePage | HOME |
| maps | map | Footer | PlaceholderPage | MAPS |
| camera | camera | Footer (center) | PlaceholderPage | CAMERA |
| hangar | airplane.departure | Footer | PlaceholderPage | HANGAR |
| settings | gearshape | Footer | SettingsPage | SETTINGS |
| journey | person | Header (left) | JourneyPage | STATUS |

**Implementation:**
- `NavigationDestination` enum in ContentView.swift
- `appState.currentScreen` tracks active page
- `appState.pageDisplayTitle` returns display title for header (computed from dictionary)
- `MainView` in Airplane_IDApp.swift switches views based on currentScreen
- All nav buttons have `onTapGesture` handlers

**Header Page Title:**
- Displayed on right side of header, bottom-aligned with status text under person icon
- Font: Helvetica 11pt (portrait) / 10pt (landscape), white, ALL CAPS
- Spacing matches person icon (16px from edge)
- To add new page: Add entry to `pageDisplayTitle` dictionary in AppState
- Default: enum rawValue uppercased (e.g., "NEWPAGE") as reminder to update

### JourneyPage
User profile/progress page accessed by tapping person icon in header.

**Features:**
- Dynamic title: "{Level}'s Journey" (e.g., "Spotter's Journey")
- Current status display (large yellow text)
- Aircraft count
- Level description (explains next milestone)
- Badges section (Coming Soon)
- Leaderboard section (Coming Soon)

**Future enhancements:**
- Badge system for achievements
- Global leaderboard
- Statistics breakdown
- Sharing capabilities

### SettingsPage
Settings page with dark theme - uses sheet overlays for sub-pages.

**Design:**
- Background color: #121516 (dark)
- Row background: #1D1E21
- Tapping a row opens a sheet overlay with Back button
- Developer Tools only visible when `AppConfig.developerToolsEnabled = true`

**Menu Items (open as sheets):**
- Account Settings → `AccountSettingsView` (shows user profile, security, privacy)
- App Preferences → `AppPreferencesView` (Coming Soon)
- System → `SystemSettingsView` (Coming Soon)
- About → `AboutView` (version, copyright)
- Developer Tools → `DeveloperToolsView` (import/delete functions)

**Developer Tools Sections:**
- Import Aircraft (25, 100, 500, 1100, 2000 options)
- User Data (Import User Profile from CSV)
- Danger Zone (Delete All Aircraft, Reset App)

**Global Config Flag (ContentView.swift):**
```swift
struct AppConfig {
    static let developerToolsEnabled = true  // Set false before App Store
}
```

## Database & Performance Architecture

### Data Volume Requirements
The app must handle large datasets efficiently:
- **User's Aircraft Collection:** 2,000+ captured aircraft (displayed in Hangar)
- **Static Reference Data (bundled on device):**
  - Manufacturer list (93K+ records from FAA)
  - ICAO Master list (aircraft type codes)
- **Operations:** Fast lookups, matching captured aircraft to reference data

### Optimization Strategies

**For Hangar Page (2000+ items):**
- SwiftUI `List` is already virtualized (lazy loading)
- Use `@Query` with sort descriptors for efficient ordering
- Consider `fetchLimit` + `fetchOffset` for true pagination if needed
- When targeting iOS 18+, add `@Index` on frequently queried fields

**For Static Reference Data:**
- Option A: Bundle as JSON/CSV, load into memory dictionaries at startup
- Option B: Separate SwiftData models (Manufacturer, ICAOCode) with indexes
- Use `Dictionary<String, Model>` for O(1) lookups by code/key
- Cache frequently accessed lookups in memory

**For Aircraft Matching/Identification:**
- In-memory dictionaries for ICAO → aircraft type lookups
- Registration → aircraft details matching
- Consider background pre-loading of reference data on app launch

**SwiftData Best Practices:**
- All ModelContext operations must be on main thread (or actor-isolated)
- Use `@Query` with predicates to filter at database level
- Batch inserts for large imports (current: 2000 at once works fine)
- When iOS 18+: Add indexes on `captureDate`, `icao`, `registration`, `manufacturer`

## Authentication & Offline Mode (Future Implementation)

### Account Creation Flow
1. User downloads app and is prompted to sign in or create account
2. Account creation connects to servers
3. Password is encrypted on device before storage
4. Password is decrypted locally for validation (never sent in plaintext)

### Password & Security Fields
- `passwordHash` - Encrypted password stored on device
- `passwordRequired` - "Do I need to enter password to open the app?" (separate from having a password)
- `faceIDEnabled` - Use FaceID as alternative to password entry

### Offline Mode Scenarios

**Scenario 1: Account Exists**
- User data cached on device
- App functions fully offline
- Changes sync when connection restored (LTE/WiFi)
- Daily sync job updates aircraft GPS positions from server

**Scenario 2: No Account (Guest Mode)**
- Limited to 10 aircraft captures
- Nag message on every app open encouraging FREE account creation
- Data stored locally but not synced

### Membership Tiers
| Tier | Capture Limit | Features |
|------|---------------|----------|
| Guest (No Account) | 10 aircraft | Local only, nag messages |
| Free | Higher limit (TBD) | Server sync, basic features |
| Premium | Unlimited | All features, priority sync |

### Server Sync Features (Planned)
- Bi-directional sync between iPhone and server
- "Where is this plane now?" - Current GPS position lookup
- Daily background job updates aircraft positions
- Sync over LTE or WiFi

### Hangar/Map Integration (Planned)
- Tap plane in Hangar → Show on Map
- Tap marker on Map → Show Hangar details
- Current location tracking for aircraft
