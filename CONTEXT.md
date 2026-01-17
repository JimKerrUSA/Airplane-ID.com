# Project Context

## Overview
Project: Airplane-ID iOS App
Created: 2026-01-15
Purpose: iOS app for identifying and tracking aircraft sightings

## Current State
- SwiftUI app with SwiftData for persistence
- **Full navigation system working:** Home, Maps, Camera, Hangar, Settings, Journey pages
- **PORTRAIT-ONLY MODE:** App locked to portrait orientation (like Uber/Instagram)
  - AppDelegate with `supportedInterfaceOrientationsFor` returns `.portrait`
  - Landscape templates kept in code but not used
- Portrait view fully working with data boxes, progress bar, and recent sightings
  - Two stat boxes side-by-side with bold numbers (Helvetica-Bold headers)
  - Recent Sightings shows 6 results (240px minHeight)
  - Top menu: 90px height
  - Footer: 80px camera button, centered icons
- **NO TEST DATA** - App uses actual database (delete data function coming to Settings)
- **Level progression system:** NEWBIE → SPOTTER → ENTHUSIAST → EXPERT → ACE → LEGEND
- **JourneyPage:** Tap person icon to view level, stats, badges (coming soon), leaderboard (coming soon)
- **Database-driven stats:** Aircraft count, unique types, and level all computed from SwiftData
- **Centralized theming:** Theme.swift contains all colors, fonts, and styling utilities

## Key Files

### App Entry Point
- `Airplane_IDApp.swift` - App entry point and ModelContainer setup
  - MainView - Navigation router (switches pages based on currentScreen)
  - Clean startup - no test data loading

### Core Components
- `ContentView.swift` - All reusable components and templates
  - `NavigationDestination` enum - All app screens (home, maps, camera, hangar, settings, journey)
  - `AppState` - Global observable state (status, counts, currentScreen, etc.)
  - TopMenuView / TopMenuViewLandscape - Header components (with person icon tap)
  - BottomMenuView / BottomMenuViewLandscape - Footer/nav components (with nav taps)
  - **PortraitTemplate** - Portrait orientation template
  - **LandscapeLeftTemplate** - Landscape with footer on LEFT edge
  - **LandscapeRightTemplate** - Landscape with footer on RIGHT edge
  - OrientationAwarePage - Wrapper that switches templates based on geometry
- `Item.swift` - Contains CapturedAircraft SwiftData model with UUID index
- `Theme.swift` - **NEW** Centralized colors, fonts, spacing, and utilities
  - AppColors - All app color constants
  - AppFonts - Typography helpers
  - AppSpacing - Layout spacing constants
  - Color(hex:) extension, RoundedCorner shape, TextShadow modifier

### Page Files (each with #Preview for Portrait, Landscape Left, Landscape Right)
- `HomePage.swift` - Main home screen content with data boxes and recent sightings
  - Level progression computed properties (currentStatus, nextLevel, levelProgress)
  - uniqueTypesCount - Counts unique ICAO codes
  - **HomePageLandscapeContent** - Consolidated parameterized landscape view (footerOnLeft param)
- `SettingsPage.swift` - Settings page with dark theme (#121516) in all orientations
  - Custom orientation handling (not OrientationAwarePage)
  - SettingsPortraitView, SettingsLandscapeLeftView, SettingsLandscapeRightView
  - SettingsContent, SettingsScrollContent, SettingsRow components
  - Scrollable in landscape mode
- `JourneyPage.swift` - User profile/progress page
  - Dynamic title based on level
  - Level descriptions and stats
- `HangarPage.swift` - Aircraft collection page with filtering
  - HangarFilterState - Observable filter state with UserDefaults persistence
  - HangarPage - Main view with filter bar and scrollable grouped list
  - HangarSectionHeader - Sticky year/month headers (blue background)
  - HangarListItem - 3-line aircraft display with graceful omission (tappable)
  - HangarFilterSheet - Filter form with dynamic dropdown options
  - AircraftDetailView - Full-screen detail view for individual aircraft
  - DetailRow - Reusable label/value row component
- `MapsPage.swift` - Map view page (placeholder)
- `CameraPage.swift` - Camera capture page (placeholder)

## Recent Decisions

### UIKit for Orientation Detection (Working Solution)
- **Problem:** Safe area insets proved unreliable for detecting landscape left vs right
- **Solution:** Use `UIDevice.current.orientation` with NotificationCenter
- **Key insight:** Direct `import UIKit` works fine - previous build errors were from `#if os(iOS)` conditional blocks
- **Implementation pattern:**
  ```swift
  import UIKit

  struct MyView: View {
      @State private var deviceOrientation: UIDeviceOrientation = UIDevice.current.orientation

      var body: some View {
          // ... view content ...
          .onAppear {
              UIDevice.current.beginGeneratingDeviceOrientationNotifications()
              deviceOrientation = UIDevice.current.orientation
          }
          .onReceive(NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)) { _ in
              deviceOrientation = UIDevice.current.orientation
          }
      }
  }
  ```
- **IMPORTANT - UIDeviceOrientation naming is counterintuitive:**
  - `.landscapeRight` = device rotated so camera is on RIGHT side (user perceives as "Landscape Left")
  - `.landscapeLeft` = device rotated so camera is on LEFT side (user perceives as "Landscape Right")
  - Must swap template selection accordingly

### Separate Previews for Templates
- Problem: Both landscape orientations were using same template, couldn't adjust independently
- Solution: Added separate #Preview blocks for "Landscape Left" and "Landscape Right"
- Why: Allows independent testing/positioning of each template in Xcode preview

### Footer Vertical Centering Formula
- Problem: Footer bars were pinned to top in landscape
- Solution: Use formula `(geometry.size.height + geometry.size.width) / 4 - 82` for y position
- Why: This formula centers the footer vertically accounting for various screen sizes

### Left Landscape Footer Positioning
- Problem: Footer hitting safe area on left edge
- Solution: Use `.ignoresSafeArea()` with `offset(x: 5)` and `position(x: 50, ...)`
- Why: Pushes footer to far left edge past the safe area

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

## Next Steps

1. Build out Maps page content
2. ~~Build out Hangar page content~~ ✅ COMPLETED
   - ~~Bi-directional filter logic~~ ✅ COMPLETED
   - ~~Filter sheet toolbar (Clear/Search buttons)~~ ✅ COMPLETED
3. Build out remaining Settings page functionality
4. Implement password encryption/decryption
5. Implement FaceID authentication
6. Implement offline mode with capture limits
7. Build server sync infrastructure
8. Add proper orientation detection for runtime (without UIKit)
9. Test on physical device
10. ~~Gradually migrate hardcoded colors to use AppColors constants~~ ✅ COMPLETED

### Code Quality Tasks (from code review)
- [x] Phase 2A: Fix UIDevice orientation listener cleanup (battery drain) ✅
- [x] Phase 2B: Add database indexes to models ⚠️ (requires iOS 18+, deferred)
- [x] Phase 2C: Fix background thread SwiftData access in CSV import ✅
- [ ] Phase 2D: Add pagination to HomePage query (low priority)

## Session Log

### 2026-01-15
- Rebuilt CapturedAircraft model after git reset incident
- Rebuilt test data loading in HomePage.onAppear
- Fixed Recent Sightings display with proper styling
- Created TopMenuViewLandscape and BottomMenuViewLandscape components
- Created landscape templates with proper footer positioning
- Positioned left landscape footer: offset(x: 20) with ignoresSafeArea
- Positioned right landscape footer: offset(x: 100) with ignoresSafeArea
- Positioned landscape header person icon: trailing padding 86
- Added separate Xcode previews for each landscape template (with traits)
- Renamed templates for clarity:
  - HomePagePortrait → PortraitTemplate
  - HomePageLeftHorizontal → LandscapeLeftTemplate
  - HomePageRightHorizontal → LandscapeRightTemplate
- Added 1px gray border to footer nav bars (both portrait and landscape)
- Added 1px gray bottom line to header components (both portrait and landscape)
  - Uses overlay with Rectangle and ignoresSafeArea to extend to edges
- Confirmed component-based architecture works: changes propagate to all templates
- IMPORTANT: Do not use UIKit - causes build failures
- Built out landscape content areas with stat boxes, latest sightings, and progress bar
- Added `latestSightings` computed property (4 items for landscape vs 3 for portrait)
- Landscape layout dimensions:
  - Stat boxes: 347w (125 label + 222 value) x 106h each
  - Latest Sightings: 221w x 250h (39h header + 211h content)
  - Progress to ACE: 648w x 46h (200 label + 448 bar)
- Both landscape templates now have matching content with appropriate padding for footer position
- Refined landscape layout proportions:
  - Made stat boxes and Latest Sightings equal width (270w each)
  - Increased stat box heights to 103h for tighter gap (14px)
  - Added 3px padding between columns for visual separation
  - Progress bar widened (240 label) to fit "Progress to ENTHUSIAST"
  - Progress bar moved down 5px from boxes
- Fixed Latest Sightings data display:
  - Changed from @Query in content views to receiving data as parameter from HomePage
  - Now properly shows manufacturer, registration, and model
  - Format: Line 1 = Manufacturer (ALL CAPS), Line 2 = Registration + Model
  - Icon: 22pt, Manufacturer: 19pt, Reg/Model: 15pt
- Added level progression logic (nextLevel computed property):
  - NOVICE → SPOTTER → ENTHUSIAST → EXPERT → ACE
  - Progress bar label shows "Progress to {nextLevel}"
- Changed landscape sightings from 4 to 3 items
- Fixed landscape right preview to use LandscapeRightTemplate directly
- Swapped Home/Settings positions in landscape footer for better ergonomics:
  - Old order (top to bottom): Settings, Maps, Camera, Hangar, Home
  - New order (top to bottom): Home, Maps, Camera, Hangar, Settings
- Adjusted Latest Sightings spacing in landscape:
  - Left padding increased from 8 to 23px (pushed 15px right)
  - Spacing between results: 6 → 9px
- Added sample preview data for landscape previews (previewSampleAircraft array)
- **Navigation system implemented:**
  - Added NavigationDestination enum (home, maps, camera, hangar, settings)
  - Added currentScreen property to AppState
  - All footer buttons now have onTapGesture handlers for navigation
  - Created MainView as navigation router (switches views based on currentScreen)
  - Created PlaceholderPage for screens not yet built (Maps, Camera, Hangar, Settings)
- **Level progression logic updated:**
  - Corrected level names: NEWBIE → SPOTTER → ENTHUSIAST → EXPERT → ACE → LEGEND
  - Thresholds: 0=NEWBIE, 10=SPOTTER, 100=ENTHUSIAST, 250=EXPERT, 500=ACE, 1100=LEGEND
  - Status now computed from database aircraft count (allAircraft.count)
  - Progress bar percentage calculated based on progress toward next threshold
  - AppState.status and totalAircraftCount updated dynamically from database
  - Added uniqueTypesCount (counts unique ICAO codes)
- **JourneyPage added:**
  - Tap person icon in header to access
  - Dynamic title based on status (e.g., "Spotter's Journey")
  - Shows current level, aircraft count, and level description
  - Placeholder sections for Badges and Leaderboard
  - Supports all orientations
- Next: Build out individual page content, test on physical device

### 2026-01-16
- **Refactored pages into separate files:**
  - Created `SettingsPage.swift` with SettingsRow component and preview
  - Created `JourneyPage.swift` with preview
  - Created `HangarPage.swift` with placeholder content and preview
  - Created `MapsPage.swift` with placeholder content and preview
  - Created `CameraPage.swift` with placeholder content and preview
- Cleaned up `Airplane_IDApp.swift`:
  - Now only contains MainView, app entry point, and test data loading
  - Removed PlaceholderPage (pages now have their own files)
  - MainView now routes to actual page files instead of placeholders
- **Added landscape previews to all pages:**
  - Each page now has Portrait, Landscape Left, Landscape Right previews
  - Uses LandscapeLeftTemplate and LandscapeRightTemplate directly in previews
  - Proper padding for footer position (leading: 120 for left, trailing: 120 for right)
- **SettingsPage rebuilt with custom orientation handling:**
  - Dark background (#121516) now covers entire screen including behind footer
  - Created separate views: SettingsPortraitView, SettingsLandscapeLeftView, SettingsLandscapeRightView
  - Uses safe area insets to detect landscape left vs right (safeArea.leading > safeArea.trailing)
  - No UIKit required - pure SwiftUI orientation detection
  - Settings row background: #1D1E21
  - Settings row spacing: 15px
  - ScrollView enables scrolling in landscape mode when menu is longer than screen
  - SettingsScrollContent separated from SettingsContent for proper scroll behavior
- All pages have #Preview blocks for Xcode canvas viewing
- Each page supports all three orientations

- **Code audit and optimization completed:**
  - Removed all test data loading code from Airplane_IDApp.swift
  - Removed duplicate test data loading from HomePage.swift
  - Removed unused `Item` class from Item.swift
  - Added UUID index to CapturedAircraft model
  - Consolidated duplicate landscape views into single `HomePageLandscapeContent` view
  - Created `Theme.swift` with centralized colors, fonts, spacing, and utilities
  - Moved Color(hex:), RoundedCorner, RectCorner from ContentView.swift to Theme.swift
  - Added TextShadow view modifier for consistent text shadow styling
- **Database usage change:** App now uses actual database with no test data
  - Developer Tools section in Settings for testing/reset
  - Before App Store deployment: run delete data to clear test records

- **Real FAA Test Data System:**
  - Created `generate_test_data.py` script in `/Data/` folder
  - Sources: FAA-Registered-Aircraft.csv (309K records) + FAA-Manufacturer-Reference.csv (93K records)
  - ICAO codes matched from PlaneFinder's MasterAircraftList.csv
  - Generated `AirplaneID-TestData.csv` with 2,000 real aircraft records
  - Real N-numbers, real ICAO codes, real manufacturer/model data
  - GPS coordinates near 30 major US airports
  - Dates span 1 year (oldest to now), most recent = import time

- **Developer Tools - Import Options:**
  - Import 25 Aircraft (quick test)
  - Import 100 Aircraft (ENTHUSIAST level)
  - Import 500 Aircraft (ACE level)
  - Import 1,100 Aircraft (LEGEND level)
  - Import All 2,000 Aircraft (full map coverage test)
  - Delete All Aircraft (confirmation required)
  - Reset App (clears ALL data, confirmation required)

- **Test Data Files (bundled with app):**
  - `AirplaneID-TestData.csv` - 2,000 aircraft records
    - Columns: icao, manufacturer, model, registration, engine_type, num_engines, aircraft_type, aircraft_classification, latitude, longitude, capture_date, capture_time, year, month, day, near_airport
    - aircraft_type: FAA TYPE-ACFT code (1-9, H, O)
    - aircraft_classification: FAA AC-CAT code (1-9)
  - `AirplaneID-UserData.csv` - User profile template
    - Columns: name, email, phone, password, passwordRequired, faceIDEnabled, displayName, memberDate, homeAirport, memberLevel
    - Edit this file to add your info before importing

- **Data Generation Script:** `/Data/generate_test_data.py`
  - Usage: `python3 generate_test_data.py --count 2000`
  - Sources: FAA-Registered-Aircraft.csv, FAA-Manufacturer-Reference.csv (includes AC-CAT, TYPE-ACFT)
  - Matches ICAO codes from PlaneFinder MasterAircraftList.csv
  - Run again anytime to regenerate fresh test data

- **User Model added to Item.swift:**
  - Registered in schema (Airplane_IDApp.swift)
  - Import User Profile button in Developer Tools
  - Reset App now clears both aircraft and user data

- **Settings page refactored with sheet overlays:**
  - Account Settings → Shows user profile from database
  - App Preferences → Placeholder (Coming Soon)
  - System → Placeholder (Coming Soon)
  - About → App version and copyright info
  - Developer Tools → All import/delete functions (conditional visibility)
  - AppConfig.developerToolsEnabled flag controls Developer Tools visibility
  - Each sub-page opens as a sheet with Back button

- **Documented authentication and offline mode requirements:**
  - Password encryption/decryption flow
  - FaceID authentication option
  - Offline mode with capture limits (10 for guests)
  - Free vs Premium membership tiers
  - Server sync behavior and Hangar/Map integration plans

- **LEGEND level celebration display:**
  - When user reaches LEGEND status (1100+ aircraft), progress bar shows "You Are a LEGEND!"
  - Progress bar changes from blue (#2B81C5) to green (#28A745) at LEGEND level
  - Applies to Portrait, Landscape Left, and Landscape Right views

- **Fixed Landscape Right footer positioning:**
  - **Root cause found:** `OrientationAwarePage` was ALWAYS using `LandscapeLeftTemplate` for all landscape orientations (code comment said "using left template for now")
  - `OrientationAwarePage` now properly detects landscape left vs right orientation
  - Uses `geometry.safeAreaInsets` to determine which side has the notch/dynamic island
  - When `safeArea.leading > safeArea.trailing` → Landscape Left (footer on left)
  - When `safeArea.trailing > safeArea.leading` → Landscape Right (footer on right)
  - Footer now correctly appears on the RIGHT side when in Landscape Right orientation

- **Added app icon:**
  - Created AirplaneID-icon.png and configured in AppIcon.appiconset
  - Icon appears on iPhone home screen
  - Xcode auto-generates all required sizes from 1024x1024 source

- **Fixed landscape orientation detection (UIDevice approach):**
  - Safe area inset detection proved unreliable for landscape left/right detection
  - Switched to `UIDevice.current.orientation` with NotificationCenter observer
  - Added `import UIKit` to both ContentView.swift and SettingsPage.swift
  - **Key discovery:** UIDeviceOrientation naming is counterintuitive:
    - `.landscapeRight` = device rotated so camera is on RIGHT (user's "Landscape Left")
    - `.landscapeLeft` = device rotated so camera is on LEFT (user's "Landscape Right")
  - Template selection swapped accordingly to place footer opposite camera
  - Final footer positioning:
    - LandscapeLeftTemplate: offset(x: 16)
    - LandscapeRightTemplate: offset(x: 104)
  - Applied to OrientationAwarePage (ContentView.swift) and SettingsPage

- **Settings page orientation fix:**
  - Updated SettingsPage.swift to use UIDevice-based detection (matching other pages)
  - Added @State deviceOrientation with .onAppear and .onReceive observers
  - Updated footer offsets to match main templates (16 for left, 104 for right)
  - Footer now correctly appears on opposite side from camera

- **Fixed Swift 6 concurrency warning:**
  - RectCorner OptionSet was causing "Main actor-isolated conformance" warnings
  - Added `nonisolated init(rawValue:)` to satisfy OptionSet protocol requirements
  - Prevents future build errors when Swift 6 becomes default

- **Implemented responsive scaling system:**
  - Content was being cut off on iPhone 16 Pro (fixed dimensions exceeded available space)
  - Created ScreenScale struct with orientation-aware baseline detection
  - Design baseline: iPhone 14 Pro (393 x 852 points portrait)
  - ScreenScale automatically swaps baseline for landscape orientation
  - Templates inject ScreenScale into environment via GeometryReader
  - HomePage portrait and landscape content use `.scaleEffect(screenScale.scale)`
  - Content now scales proportionally to fit any screen size

- **UI Layout Refinements (after testing on iPhone 16 Pro):**
  - Top menu height: 93px with person icon `.padding(.top, 28)` to clear status bar
  - Footer layout fixed with separate offsets:
    - Blue bar: `barOffset = -25` (positioned higher)
    - Icons/camera: `iconsOffset = -15` (positioned lower, overlapping bar)
    - Added `sideWidth` with min value of 40 to prevent negative frame crash
  - Settings menu rows: smaller fonts (16pt title, 13pt subtitle) with `.lineLimit(1)` to prevent word wrap
  - Matches DevToolButtonContent styling for consistency

- **Account Settings Page - Editable with Security Toggles:**
  - Added `memberNumber` field to User model (primary key for server sync)
  - Account Settings now has Edit/Cancel/Save buttons in toolbar
  - Editable fields: Display Name, Name, Email, Phone, Home Airport
  - Member Since remains read-only
  - Security section now uses toggle switches instead of text:
    - Password Required toggle (saves immediately to database)
    - Face ID Enabled toggle (saves immediately to database)
  - Created new components:
    - `EditableProfileRow` - Text field with blue border for edit mode
    - `SecurityToggleRow` - Toggle switch with blue tint
  - Toggle switches save to database immediately on change
  - Edit mode changes are saved when "Save" is tapped, reverted on "Cancel"

- **CRITICAL PATTERN: fullScreenCover with TextFields:**
  - **Problem:** When using `sheet` or `fullScreenCover` with editable TextFields, tapping a TextField can cause the modal to dismiss unexpectedly
  - **Root cause:** If the @State variable controlling the modal is in a child view (like SettingsScrollContent), SwiftUI may recreate that view when focus changes, resetting the state to false
  - **Solution:** Move the presentation state to the TOP-LEVEL view and pass @Binding down
  - **Implementation pattern for editable modals:**
    ```swift
    // TOP-LEVEL VIEW (e.g., SettingsPage)
    struct SettingsPage: View {
        @State private var showingEditableModal = false  // State lives HERE

        var body: some View {
            ChildView(showingEditableModal: $showingEditableModal)
                .fullScreenCover(isPresented: $showingEditableModal) {
                    EditableModalView()
                }
        }
    }

    // CHILD VIEWS pass binding down
    struct ChildView: View {
        @Binding var showingEditableModal: Bool
        // ...
    }
    ```
  - **Additional requirements:**
    - Use `fullScreenCover` instead of `sheet` for modals with TextFields
    - Add `.scrollDismissesKeyboard(.never)` to ScrollViews containing TextFields
    - Hide Back button during edit mode (force Cancel/Save)
  - **SwiftData migrations:** When adding new non-optional fields, provide default value at property declaration (not just in init) for existing records to migrate

- **Phase 1D: Standardized all colors to use Theme.swift:**
  - All hardcoded hex colors replaced with `AppColors` constants
  - Files updated: HomePage.swift, ContentView.swift, SettingsPage.swift, JourneyPage.swift
  - **Managing colors:** Edit `Theme.swift` to change colors globally
  - Color categories: Primary brand, Background, UI elements, Status, Progress bar
  - Commit: 9f78f43 "Replace hardcoded colors with AppColors constants"

- **Phase 2A: Fixed UIDevice orientation listener cleanup:**
  - Added `.onDisappear` to call `endGeneratingDeviceOrientationNotifications()`
  - Files fixed: ContentView.swift (OrientationAwarePage), SettingsPage.swift
  - Prevents battery drain from continuous orientation monitoring
  - Commit: 5e1f9b7 "Fix UIDevice orientation listener cleanup"

- **Phase 2B: Database indexes deferred (iOS 18+ requirement):**
  - SwiftData `@Index` macro requires iOS 18+
  - Key fields documented in comments for future implementation
  - When targeting iOS 18+, add: `@Index([\.captureDate])`, `@Index([\.icao])`, etc.
  - Commit: ae17a44 "Remove @Index attributes (iOS 18+ only)"

- **Phase 2C: Fixed SwiftData thread safety in CSV import:**
  - Problem: `modelContext.insert()` and `modelContext.save()` called from background thread
  - SwiftData ModelContext is NOT thread-safe
  - Fix: Parse CSV on background thread, dispatch to main thread for SwiftData operations
  - Pattern: Collect raw data in tuples, then create/insert @Model objects on main thread
  - Commit: eba6aad "Fix background thread SwiftData access in CSV import"

- **Privacy preferences added to Account Settings:**
  - New Privacy section below Security with toggle switches
  - UI toggles: Show Online Status, Show Location, Receive Latest News, Receive Activity Summary
  - Additional DB fields for future: receiveUpdates, allowFollow, showInSearch
  - All privacy preferences default to true (on)
  - Toggle changes save immediately to database
  - Commit: f42a7b4 "Add Privacy section to Account Settings"

### 2026-01-17 (continued)

- **UI Improvements:**
  - Moved person icon and status text to LEFT side of header (TopMenuView)
  - Swapped Recent Sightings display: Registration/Model on line 1, Manufacturer on line 2
  - Commit: afcfd3d, 6e2e825

- **CapturedAircraft Model Expansion (31 fields):**
  - Added 18 new fields for full aircraft data support
  - Fields organized into categories: capture metadata, AI recognition, cloud sync, user interaction
  - Required fields: captureTime, captureDate, year, month, day, gpsLongitude, gpsLatitude, iPhotoReference, icao, manufacturer, model
  - Optional fields: iata, registration, all FAA data (populated via cloud sync), rating, thumbsUp
  - Captures flow: User takes photo → AI identifies aircraft → User edits/confirms → Save to DB → Cloud sync adds FAA details
  - Commit: 74912c6

- **Data Type Clarifications:**
  - rating changed from Int to Bool
  - captureTime is full Date timestamp, captureDate is date-only derived
  - year/month/day are Int for filtering queries ("show me October captures")

- **Swift 6 Compatibility:**
  - Fixed RectCorner OptionSet actor isolation warnings (reduced from 10 → 5 → 1)
  - Solution: Added `@preconcurrency` to OptionSet conformance
  - **Remaining warning:** "@preconcurrency on conformance to 'OptionSet' has no effect"
    - This is harmless/informational - app compiles and runs correctly
    - Leaving as-is because removing @preconcurrency brings back 5 MainActor isolation warnings
    - Trade-off: 1 harmless warning vs 5 warnings about Swift 6 errors
  - Also removed unnecessary `nonisolated(unsafe)` markers and nil coalescing on non-optional fields
  - Commits: 86df12c, 2205704, 4aab954

- **Header Page Title Display:**
  - Added page title to right side of header bar (both portrait and landscape)
  - Shows current page name in ALL CAPS (HOME, YOUR HANGAR, SETTINGS, etc.)
  - Bottom-aligned with status text under person icon
  - Implementation: `pageDisplayTitle` computed property in AppState with dictionary lookup
  - New pages default to enum rawValue uppercased as reminder to add to dictionary
  - Commit: f472f2b

- **Recent Sightings Display Redesign:**
  - Line 1: [IATA] MANUFACTURER MODEL (removed registration number)
  - Line 2: [CLASSIFICATION] [Type] - shows aircraft category and type
  - Changed aircraftClassification from String? to Int? (FAA stores as 1-9)
  - Added aircraftType field (String? for codes 1-9, H, O)
  - Added AircraftLookup enum in Theme.swift with classification/type dictionaries
  - Updated test data generator to include TYPE-ACFT and AC-CAT columns
  - Updated CSV import to parse new columns
  - **NOTE:** This was a breaking schema change - required deleting app from device and reinstalling
  - Commit: c7ff940

- **Hangar Page Implementation:**
  - Complete aircraft collection view with scrollable list
  - Year/Month sticky section headers (AppColors.darkBlue background, white text)
  - 3-line aircraft display with graceful omission of missing data:
    - Line 1: [IATA] MANUFACTURER MODEL (bold)
    - Line 2: [CLASSIFICATION] [Type] (if available)
    - Line 3: Registration City State Country (if available)
  - Filter bar with FILTER button, centered result count (white text), CLEAR button (orange, only visible when filters active)
  - Compact button styling for narrow screens (no icons, tight padding)
  - **HangarFilterState class:** Observable filter state with UserDefaults persistence
    - 11 filter fields: searchText, year, month, manufacturer, IATA, ICAO, classification, type, country, state, city
    - Auto-loads saved filters on init, auto-saves on changes
    - `hasActiveFilters` computed property to show/hide CLEAR button
  - **Filter Sheet:** Full-screen form with dynamic dropdowns
    - Search section with text field (searches multiple fields)
    - Date section: Year, Month pickers
    - Aircraft section: Manufacturer, ICAO Type, IATA Airline
    - Classification section: Category, Type
    - Location section: Country, State, City
    - Clear All Filters button (only when filters active)
  - Empty state displays for no aircraft and no filter matches

  - **Bi-directional Filter Logic:** ✅ COMPLETED
    - Each dropdown shows only values from aircraft matching ALL OTHER active filters
    - Implementation: `aircraftExcluding(_ exclude: String)` function filters by all criteria except the specified one
    - Example: Select "Weight Shift Control" type → Year shows only 2025, Month shows only Sep/Oct, ICAO shows only applicable codes
    - Works in any direction - start from any filter and all others update

  - **Filter Sheet Toolbar Pattern (reusable for other sheets):**
    - Uses conditional navigation title and toolbar buttons based on `hasActiveFilters`
    - **No filters active state:**
      - Title: "Filter Aircraft" (center)
      - Right button: "Done" (default gray, `.borderedProminent` style)
    - **Filters active state:**
      - Title: Empty string (hidden)
      - Left button: "Clear" (orange text, standard toolbar button)
      - Right button: "Search" (green via `.tint(Color(hex: "28A745"))`, `.borderedProminent` style)
    - **Implementation pattern:**
      ```swift
      .navigationTitle(filterState.hasActiveFilters ? "" : "Filter Aircraft")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
          ToolbarItem(placement: .topBarLeading) {
              if filterState.hasActiveFilters {
                  Button { /* clear action */ } label: {
                      Text("Clear").foregroundStyle(AppColors.orange)
                  }
              }
          }
          ToolbarItem(placement: .topBarTrailing) {
              Button { /* done/search action */ } label: {
                  Text(filterState.hasActiveFilters ? "Search" : "Done")
                      .fontWeight(.semibold)
              }
              .tint(filterState.hasActiveFilters ? Color(hex: "28A745") : nil)
              .buttonStyle(.borderedProminent)
          }
      }
      ```
    - **Key insight:** Put Clear and Search in SEPARATE ToolbarItems to prevent iOS from merging them into one button

- **Aircraft Detail View (AircraftDetailView):**
  - Full-screen detail view opened by tapping aircraft in Hangar list
  - Uses `.fullScreenCover(item: $selectedAircraft)` pattern with state at HangarPage level
  - **Layout structure:**
    - Photo placeholder (220px height) - ready for actual photos
    - Title block (VStack with 2pt spacing):
      - Line 1: Manufacturer (Helvetica-Bold, size 22, uppercase)
      - Line 2: Model (system font, size 20, medium weight)
    - Type subtitle (e.g., "Fixed Wing Single-Engine") - size 16, white opacity 0.7
    - Aircraft Details section: ICAO Type, IATA Airline, Registration, Classification, Serial Number, Year Manufactured
    - Specifications section: Engine Type, Engine Count, Seat Count, Weight Class (only shows if data exists)
    - Registration section: Owner, Owner Type, Country, Location, Certificate dates (only shows if data exists)
    - Capture Info section: Captured date/time, GPS coordinates
  - **Graceful omission:** Sections and rows only display if they have data
  - **Toolbar pattern (matches Account Settings):**
    - Back button on left (hidden during edit mode)
    - Edit button on right (switches to Cancel/Save during edit mode)
  - **Components:**
    - `DetailRow` - Reusable row with label (left, white 60% opacity) and value (right, white)
    - `detailSection()` - ViewBuilder function for consistent section styling
  - Edit mode scaffolding in place for future implementation

- **Star Rating System:**
  - Rating field changed from `Bool?` to `Double?` (supports 0.5 to 5.0 in 0.5 increments)
  - Added `gpsLatitudeNow` and `gpsLongitudeNow` fields (Double?) for future map tracking
  - **UI Components:**
    - `StarRatingDisplay` - Shows filled, half-filled, and empty stars with yellow color
    - `RatingSelectorSheet` - Grid of 10 rating options (0.5 to 5.0) with visual stars
  - **Rating overlay on photo:**
    - Unrated: Shows "Rate" text (white text on black/opacity background, always tappable)
    - Rated: Shows star display (only tappable when in edit mode)
  - **Edit mode requirement:**
    - Initial rating can be set in view mode (tap "Rate")
    - Changing existing rating requires entering edit mode first
    - Clear Rating option available in selector sheet when rating exists
  - **NOTE:** This was a breaking schema change - required deleting app from device and reinstalling
