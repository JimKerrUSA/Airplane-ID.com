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

- **Airline Lookup System:**
  - Created Python scraper (`Data/scrape_airline_codes.py`) to extract airline codes from airlinecodes.info
  - Generated `AirlineCodes.csv` with 5,316 unique airlines (bundled with app)
  - CSV columns: airlineCode (3-letter ICAO), iata (2-letter IATA), airlineName
  - **SwiftData model:** `AirlineLookup` with unique airlineCode constraint
  - Added AirlineLookup to schema in Airplane_IDApp.swift
  - **Auto-loading on first launch:**
    - `MainView.loadReferenceDataIfNeeded()` runs on app startup
    - Checks if AirlineLookup table is empty
    - If empty, automatically imports from bundled `AirlineCodes.csv`
    - Users never need to manually import - data is always available
    - Future updates: Bundle updated CSV, users get new data on fresh install/reset
  - **Model change:** CapturedAircraft `iata` field renamed to `airlineCode` (3-letter code)
  - **HangarPage updates:**
    - Removed IATA text field from edit mode
    - Added `AirlinePickerRow` component showing airline name (tappable in edit mode)
    - Added `AirlineSearchSheet` with typeahead search (filters by name, code, or IATA)
    - User must select from lookup list (no freeform entry)
    - Filter state updated: `selectedIATA` → `selectedAirlineCode`
  - **HomePage updates:**
    - All `aircraft.iata` references changed to `aircraft.airlineCode`
    - Display format comments updated to "[AIRLINE CODE]" instead of "[IATA]"
  - **Developer Tools:** "Import Airline Codes" button for manual refresh (deletes existing, then imports)

### Session Summary - 2026-01-17 (afternoon)

**Goal:** Enable airline selection from a curated lookup table instead of free-form text entry.

**Why:**
- IATA codes are only a subset of airline codes (2-letter vs 3-letter)
- Users shouldn't have to know/remember airline codes
- Ensures data consistency across all captured aircraft
- Reference data can be updated via app store updates

**What was built:**
1. Scraped 5,316 airline codes from airlinecodes.info (Python script)
2. Created `AirlineLookup` SwiftData model with unique constraint on airlineCode
3. Renamed `CapturedAircraft.iata` to `airlineCode` (3-letter code is more universal)
4. Built typeahead search UI - user searches by airline name, code, or IATA
5. Auto-loads airline data on first app launch from bundled CSV
6. Added manual import button in Developer Tools for testing/refresh

**Files changed:**
- `Airplane_IDApp.swift` - Auto-load logic in MainView
- `HomePage.swift` - Updated iata → airlineCode references
- `SettingsPage.swift` - Added Reference Data section with import button
- `AirlineCodes.csv` - Bundled reference data (5,316 airlines)
- `Item.swift` - AirlineLookup model, renamed field
- `HangarPage.swift` - AirlinePickerRow and AirlineSearchSheet components

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

## Photo Library Integration - COMPLETED

### Overview
Integrated iOS Photos library to allow users to attach aircraft photos to their sightings. Photos are a core feature - library access is REQUIRED to use the app.

**Commit:** 27b1723

### Requirements Summary

| Requirement | Implementation |
|-------------|----------------|
| **Permission Level** | Full library access (`.readWrite`) - REQUIRED |
| **Permission Timing** | Check on EVERY app launch, before login |
| **Denial Handling** | Block app access until granted |
| **Thumbnail Size** | 1280x720 (16:9 HD) |
| **Image Format** | JPEG ~0.75 quality |
| **Storage** | `thumbnailData: Data?` in CapturedAircraft |
| **Photo Reference** | `iPhotoReference` stores PHAsset.localIdentifier |
| **Photo Picker** | PHPickerViewController (native iOS search UI) |
| **Full-Size Viewer** | In-app viewer with pinch-zoom, "Open in Photos" option |

### Permission Flow

1. **On Every App Launch:**
   - Check `PHPhotoLibrary.authorizationStatus(for: .readWrite)`
   - If `.authorized` or `.limited` → proceed to app
   - If `.notDetermined` → request authorization
   - If `.denied` or `.restricted` → show permission required screen

2. **Permission Required Screen:**
   - Message: "Photo library access is required for our app to function. Please grant full access to your iPhoto library."
   - **OK button** → closes app
   - **Settings button** → opens Airplane-ID permissions in Settings, closes app
   - Endless loop until access granted

3. **Info.plist Required:**
   - `NSPhotoLibraryUsageDescription` - explain why we need photo access

### Photo Selection Flow (Edit Mode)

1. **No Photo Exists:**
   - Tap photo placeholder → immediately opens PHPicker
   - Native iOS search UI for finding photos
   - Select image → process and save

2. **Photo Already Exists:**
   - Must click Edit first
   - Then tap existing photo → opens PHPicker
   - Select new image → replaces existing

3. **Portrait Photo Handling:**
   - Detect portrait orientation on selection
   - Show warning: "You are attempting to upload a photo in portrait orientation. Our app is optimized for landscape images. Would you like to continue or upload a different image?"
   - **Continue** → Scale height to fit, add black letterbox bars on sides
   - **Cancel** → Return to photo picker

### Thumbnail Generation

1. **Target Size:** 1280x720 (16:9 HD ratio)
2. **Landscape Photos:** Scale to fit 1280x720
3. **Portrait Photos:** Scale height to 720, center horizontally with black bars
4. **Format:** JPEG at 0.75 quality (~100-200KB per image)
5. **Save:** Store in `thumbnailData: Data?` field

### Photo Display (View Mode)

1. **Thumbnail Display:**
   - Show 1280x720 thumbnail from database
   - Fits photo area edge-to-edge (16:9)

2. **Tap to View Full-Size:**
   - Fetch original from Photos library using `iPhotoReference`
   - Open in-app full-screen viewer
   - Features: pinch-to-zoom, double-tap zoom, swipe to dismiss
   - "Open in Photos" button to jump to Photos app

3. **Deleted Photo Handling:**
   - If original photo deleted from Photos library:
   - Show dialog: "Photo no longer on device. Would you like to view the thumbnail?"
   - **Yes** → Show thumbnail in viewer
   - **No** → Close dialog
   - Keep `iPhotoReference` (user may restore library)

### Data Model Changes

```swift
// Add to CapturedAircraft model
var thumbnailData: Data?  // JPEG thumbnail 1280x720

// Existing field - will store PHAsset.localIdentifier
var iPhotoReference: String
```

**NOTE:** This is a schema change - requires app reinstall.

### Components Created (PhotoServices.swift)

1. **PhotoLibraryManager** - Singleton for authorization checks, asset fetching, opening Photos app
2. **PhotoPermissionView** - Blocking overlay when permission denied (OK/Settings buttons)
3. **PhotoPickerView** - UIViewControllerRepresentable wrapping PHPicker
4. **FullScreenPhotoViewer** - Zoomable viewer with pinch-zoom, "Open in Photos" button
5. **ThumbnailGenerator** - Generates 1280x720 JPEG thumbnails with letterboxing
6. **ThumbnailImageView** - Reusable component for displaying thumbnails

### Files Modified

- `Info.plist` - Created with NSPhotoLibraryUsageDescription
- `Airplane_IDApp.swift` - Added permission gatekeeper overlay at app entry
- `Item.swift` - Added `thumbnailData: Data?` field to CapturedAircraft
- `HangarPage.swift` - Integrated photo display/selection in AircraftDetailView
- `PhotoServices.swift` - New file with all photo-related utilities (~500 lines)

### Additional Fixes (after feature complete)

1. **Build warning fixes:**
   - Added `_ =` before `checkAndRequestAuthorization()` to fix unused result warning
   - Changed `guard let asset = fetchAsset(...)` to `guard fetchAsset(...) != nil` to fix unused variable warning
   - Commit: 7642adc

2. **Info.plist conflict resolution:**
   - Deleted manual Info.plist file (Xcode generates its own from project settings)
   - NSPhotoLibraryUsageDescription must be added via Xcode: Target > Info > Custom iOS Target Properties
   - Value: "Airplane-ID needs access to your Photo Library to store and display aircraft photos you capture."

3. **Missing import fix:**
   - Added `import Combine` to PhotoServices.swift for ObservableObject support

### Airplane-ID Album Feature

**Commits:** 68716b8, 6c29848

#### The Problem

When users tap "View in Photos" to see their full-resolution aircraft photo, iOS opens the Photos app but doesn't navigate to the specific image. Apple doesn't provide a public API to deep-link to a specific photo or album using `PHAsset.localIdentifier`. The `photos-redirect://` URL scheme just opens Photos to wherever the user was last viewing.

This left users stranded in their photo library with thousands of images, unsure where to find the aircraft photo they wanted to see.

#### The Solution

Create a dedicated **"Airplane-ID" album** in the user's Photos library. When users select a photo for an aircraft sighting, we automatically add that photo to our album. This gives users a single, predictable location to find all their aircraft photos.

#### How It Works

1. **Album Creation (automatic):**
   - First time a user selects a photo, we check if "Airplane-ID" album exists
   - If not, we create it using `PHAssetCollectionChangeRequest.creationRequestForAssetCollection`
   - Album persists in user's Photos library

2. **Adding Photos to Album:**
   - When photo is selected in our app, we save the thumbnail to our database
   - In background, we add a *reference* to the photo in the Airplane-ID album
   - No duplication - the album contains references, not copies
   - Same photo can exist in multiple albums (Recents, Airplane-ID, user albums)

3. **"View in Photos" Button:**
   - Renamed from "Open in Photos" for clarity
   - Shows alert with message: **"Find this photo in the Airplane-ID album"**
   - User taps "Open Photos" → Photos app opens
   - User navigates to Albums → Airplane-ID → finds their photo

#### Why This Approach

| Alternative Considered | Why We Didn't Use It |
|------------------------|----------------------|
| Deep-link to photo | iOS doesn't support this via public API |
| Write metadata/tags | iOS doesn't expose API to write photo captions or tags |
| Copy photo to app sandbox | Wastes storage, loses edits user makes in Photos |
| Just open Photos app | Users couldn't find their photos among thousands |

The album approach is the best available solution because:
- Users know exactly where to look (Albums → Airplane-ID)
- No storage duplication
- Photos stay in user's library (can be backed up, edited, shared normally)
- Clear, simple messaging that non-technical users understand

#### PhotoLibraryManager Functions Added

```swift
static let albumName = "Airplane-ID"

func fetchAppAlbum() -> PHAssetCollection?           // Find existing album
func createAppAlbum() async -> PHAssetCollection?    // Create new album
func getOrCreateAppAlbum() async -> PHAssetCollection?  // Get or create
func addPhotoToAppAlbum(localIdentifier: String) async -> Bool  // Add photo
func openPhotosApp()  // Open Photos app
```

#### User Experience Flow

```
User taps "View in Photos" button
        ↓
Alert appears: "Find this photo in the Airplane-ID album"
        ↓
User taps "Open Photos"
        ↓
Photos app opens
        ↓
User goes to Albums tab → Airplane-ID album
        ↓
All their aircraft photos are there, organized together
```

### Photo Display Fix - Responsive Layout

**Commits:** 0599493, b27b9a3

#### The Problem

The photo display in AircraftDetailView was causing layout issues on smaller iPhone screens:
1. Fixed 220px height forced width reduction to maintain aspect ratio
2. `.fill` mode with `.clipped()` caused image width to push layout wider than screen
3. Black bars appeared on left/right sides of images

#### The Solution

Used `GeometryReader` to measure exact available width and calculate dimensions explicitly:

```swift
GeometryReader { geometry in
    ZStack(alignment: .bottomLeading) {
        Image(uiImage: uiImage)
            .resizable()
            .aspectRatio(contentMode: .fill)
            .frame(width: geometry.size.width, height: geometry.size.width * 9/16)
            .clipped()
        // ... overlays
    }
}
.aspectRatio(16/9, contentMode: .fit)
```

#### How It Works

| Property | Value |
|----------|-------|
| **Width** | 100% of container (measured by GeometryReader) |
| **Height** | Calculated as `width * 9/16` (maintains 16:9) |
| **Aspect Mode** | `.fill` with `.clipped()` - no gaps |
| **Responsive** | Scales to any screen size |

#### Key Changes

1. **Removed fixed height** - No more `frame(height: 220)`
2. **GeometryReader for exact width** - Measures actual available space
3. **Explicit frame calculation** - `width: geometry.size.width, height: width * 9/16`
4. **Fill mode** - Image fills frame completely, overflow clipped
5. **Consistent placeholder** - Same sizing logic for empty state

**Note:** Existing photos with black bars baked into thumbnail data will still show bars. Re-selecting the photo regenerates the thumbnail correctly.

---

## Code Review & Bug Fixes - 2026-01-17 (ongoing)

### Overview

Comprehensive code review identified 26 issues across security, best practices, thread safety, error handling, and code organization. Fixes being implemented in small batches with testing between each batch.

### Batch 1: Critical Security Fixes ✅

**Commits:** (part of ongoing session)

1. **Removed `exit(0)` call (App Store rejection risk)**
   - `exit(0)` violates Apple's Human Interface Guidelines
   - Changed `PhotoPermissionView`: removed "OK" button that called exit, kept only "Open Settings" button
   - App now stays on permission screen until user grants access and returns

2. **Changed `developerToolsEnabled` to compile-time check**
   - Was: `static let developerToolsEnabled = true` (exposed in release builds)
   - Now: `static var developerToolsEnabled: Bool { #if DEBUG return true #else return false #endif }`
   - Developer Tools completely excluded from release builds

### Batch 2: Thread Safety Fixes ✅

1. **Added `@MainActor` to data loading functions (Airplane_IDApp.swift)**
   - `loadReferenceDataIfNeeded()` - ensures main thread
   - `loadAirlineCodesIfNeeded()` - SwiftData ModelContext is not thread-safe
   - `loadICAOCodesIfNeeded()` - SwiftData ModelContext is not thread-safe
   - Added `scenePhase` monitoring to re-check permissions when returning from Settings

2. **Fixed CSV import thread safety (SettingsPage.swift)**
   - Created `ParsedAircraftData` struct marked `Sendable` for thread-safe data transfer
   - Created `CSVParser` enum with static `parseLine()` function
   - Refactored `importFromCSV()` to use Swift concurrency:
     - Parse CSV on background thread via `Task.detached`
     - Insert into SwiftData on `MainActor.run`
   - Updated `importUserFromCSV()` to use `CSVParser.parseLine()`
   - Removed duplicate private `parseCSVLine()` function

3. **Fixed PHImageManager continuation double-call (PhotoServices.swift)**
   - **Problem:** `PHImageManager.requestImage` can call its handler twice - first with degraded image, then full quality
   - **Risk:** Calling `continuation.resume()` twice crashes the app
   - **Fix:** Check `info?[PHImageResultIsDegradedKey]` and skip degraded callbacks
   - Applied to:
     - `fetchFullSizeImage(localIdentifier:)`
     - `ThumbnailGenerator.generateThumbnail(from asset:)`

4. **Added proper Error type for CSV import (SettingsPage.swift)**
   - Created `CSVImportError` enum conforming to `Error` and `LocalizedError`
   - Cases: `.fileNotFound`, `.emptyFile`, `.parseError(String)`
   - Swift's `Result` type requires `Failure` to conform to `Error`

5. **Made CSVParser explicitly nonisolated (SettingsPage.swift)**
   - Added `Sendable` conformance to `CSVParser` enum
   - Marked `parseLine()` as `nonisolated` for use from `Task.detached`

**Commits:** 56a604d, b8c2ff7, 74b1d6c, 85ab907

**Known Warning (acceptable):**
- ContentView.swift: "@preconcurrency on conformance to 'OptionSet' has no effect"
- This is harmless - removing it causes worse Swift 6 actor isolation errors

### Batch 3: Error Handling Improvements ✅

1. **Removed force unwrapping in test data generation (SettingsPage.swift)**
   - Changed `randomElement()!` to `randomElement() ?? nil`
   - Safer pattern even though arrays are non-empty literals

2. **Added user feedback for save errors (HangarPage.swift)**
   - Added `@State showingSaveError` and `saveErrorMessage` to AircraftDetailView
   - Added "Save Failed" alert to display errors to user
   - Updated `saveChanges()` with do-catch and error alert
   - Updated rating save with do-catch and error alert
   - Updated photo save with do-catch and error alert
   - User now sees alert if database save fails instead of silent failure

### Batch 4: Code Deduplication ✅

1. **Consolidated CSV parsing (Airplane_IDApp.swift)**
   - Removed duplicate `parseCSVLine()` function
   - Updated to use shared `CSVParser.parseLine()` from SettingsPage.swift
   - Both airline and ICAO loading now use the shared parser

2. **Consolidated date formatting (Theme.swift)**
   - Added `DateFormatting` enum with shared utilities:
     - `formatDate()` - medium date style
     - `formatDateTime()` - medium date + short time
     - `formatCoordinates()` - lat/lon formatting
   - Removed duplicate `formatDate()` from HangarPage.swift
   - Removed duplicate `formatDate()` from SettingsPage.swift
   - Removed duplicate `formatDateTime()` from HangarPage.swift
   - Removed duplicate `formatCoordinates()` from HangarPage.swift
   - All usages updated to `DateFormatting.formatDate()`, etc.

### Batch 5: File Organization ✅

1. **Created Utilities.swift for shared code**
   - Moved `ParsedAircraftData` struct from SettingsPage.swift
   - Moved `CSVParser` enum from SettingsPage.swift
   - Moved `CSVImportError` enum from SettingsPage.swift
   - These utilities are used by both Airplane_IDApp.swift and SettingsPage.swift
   - Centralizes shared parsing code in one location

2. **File structure after reorganization:**
   - `Utilities.swift` - Shared parsing utilities (new)
   - `Theme.swift` - Colors, fonts, spacing, date formatting, lookup tables
   - `PhotoServices.swift` - Photo library management
   - `Item.swift` - SwiftData models
   - `Airplane_IDApp.swift` - App entry point, data loading
   - `ContentView.swift` - Templates, app state, footer
   - Page files: `HomePage.swift`, `HangarPage.swift`, `SettingsPage.swift`, etc.

**Note:** New file `Utilities.swift` must be added to the Xcode project.

### Batch 6: Polish & Standards ✅

1. **Wrapped debug print statements in `#if DEBUG`**
   - Airplane_IDApp.swift: 6 print statements wrapped
     - CSV file not found warnings
     - Loaded record count confirmations
     - Error loading data messages
   - PhotoServices.swift: 4 print statements wrapped
     - Album creation errors
     - Asset not found warnings
     - Add photo to album errors
   - Production builds now have cleaner console output

2. **Verified code standards:**
   - File headers: Consistent across all 12 Swift files
   - No TODO/FIXME/HACK comments remaining
   - MARK comments used consistently for code organization
   - Naming conventions followed throughout

---

## Code Review Summary - Complete ✅

All 6 batches implemented and tested:
- **Batch 1:** Critical Security Fixes (exit(0), developer tools)
- **Batch 2:** Thread Safety (MainActor, CSV parsing, PHImageManager)
- **Batch 3:** Error Handling (force unwraps, save feedback)
- **Batch 4:** Code Deduplication (CSV parser, date formatting)
- **Batch 5:** File Organization (Utilities.swift)
- **Batch 6:** Polish & Standards (debug logging)

---

### 2026-01-18

## MapsPage Implementation - COMPLETED

Full Apple Maps integration with aircraft location display and search capabilities.

### Files Created/Modified

| File | Action | Description |
|------|--------|-------------|
| `LocationServices.swift` | **CREATED** | LocationManager singleton for CLLocationManager |
| `MapsPage.swift` | **MODIFIED** | Complete rewrite with full map implementation |
| `Info.plist` | **REQUIRES MANUAL** | Add NSLocationWhenInUseUsageDescription in Xcode |

### Features Implemented

1. **Full-Screen Map Display**
   - Map takes full screen below header, above footer
   - User location shown as blue dot (UserAnnotation)
   - Map controls: compass, scale view
   - Pan/zoom gestures work natively

2. **Aircraft Annotations**
   - All aircraft with GPS coordinates shown on map
   - Orange airplane icons with -45° rotation
   - Annotation labels show: Registration, Manufacturer, Model
   - Location priority: `gpsLatitudeNow/gpsLongitudeNow` > `gpsLatitude/gpsLongitude`

3. **Control Buttons (right side)**
   - **Location button** (top): White circle, blue icon, returns to user location
   - **Search button** (bottom): Gray circle, white magnifying glass, opens search sheet

4. **Search Sheet** (bottom-up modal)
   - Segmented picker: Locations | Aircraft
   - Search text field with clear button and loading indicator
   - **Location search:** Uses MKLocalSearch with 300ms debounce
     - Searches cities, airports, countries, regions
     - Shows up to 20 results
   - **Aircraft search:** Filters aircraft database
     - Searches ICAO, manufacturer, model, registration
     - Only shows aircraft with GPS coordinates
     - Multi-keyword AND search
   - **Recent searches:** Persisted in UserDefaults (max 6 items)
     - Swipe to delete individual items
     - Shows icon indicating location/aircraft type

5. **Map Navigation**
   - Selecting location/aircraft pans map with animation
   - Zoom level: 0.05 lat/lon delta (appropriate detail)
   - Location button returns to user position

### CapturedAircraft Extensions (MapsPage.swift)

```swift
extension CapturedAircraft {
    var hasValidLocation: Bool    // Checks for non-zero GPS coords
    var displayCoordinate: CLLocationCoordinate2D  // Priority: now > capture
    var mapDisplayLabel: String   // "Registration, Manufacturer, Model"
}
```

### New Classes

**LocationManager** (LocationServices.swift)
- Singleton pattern: `LocationManager.shared`
- `@MainActor` with `@Observable` for SwiftUI
- Handles authorization, location updates
- CLLocationManagerDelegate implementation

**MapsSearchState** (MapsPage.swift)
- `@Observable` class for search state
- SearchMode enum: `.location`, `.aircraft`
- UserDefaults persistence for recent searches
- Add/remove/clear recent searches

**RecentSearch** (MapsPage.swift)
- Codable struct for persistence
- Fields: id, text, type, timestamp

### Manual Step Required

**Add to Info.plist in Xcode:**
1. Open Xcode project
2. Select target > Info tab > Custom iOS Target Properties
3. Add row: `NSLocationWhenInUseUsageDescription`
4. Value: "Airplane-ID uses your location to show aircraft sightings near you."

### Verification Checklist

- [x] Map displays full-screen below header
- [x] User location shows as blue dot
- [x] Pan/zoom gestures work
- [x] Aircraft show as orange airplane icons
- [x] Search button opens bottom sheet
- [x] Segmented control toggles Location/Aircraft
- [x] Location search finds cities, airports, countries
- [x] Aircraft search finds by ICAO, manufacturer, model, registration
- [x] Only aircraft with GPS coords appear in results
- [x] Selecting location pans map to spot
- [x] Selecting aircraft pans map to aircraft location
- [x] Location button returns to user position
- [x] Recent searches persist (max 6)
- [x] Footer navigation works

### How to Navigate to Map from Other Pages

To pan the map to a specific aircraft location from any page:

```swift
// 1. Set the aircraft to show on map (add to AppState if needed)
// 2. Navigate to maps page
appState.currentScreen = .maps

// Future enhancement: Add selectedAircraftForMap to AppState
// appState.selectedAircraftForMap = aircraft
// Then MapsPage can check this on appear and pan to that location
```

**Current pattern for linking:**
- From HangarPage: User taps aircraft → detail view → future "Show on Map" button
- From HomePage: Recent sightings → tap → detail view → future "Show on Map" button
- Direct navigation: Footer tap on map icon

### iOS 26 Compatibility Notes

**MKMapItem API Changes:**
- `placemark` property deprecated → use `location` (CLLocation) instead
- `placemark.coordinate` → `mapItem.location.coordinate`
- `MKAddress` properties changed - `locality`/`country` not available
- Current implementation shows only `mapItem.name` for search results
- Future: Investigate `MKAddress` properties available in iOS 26

**ForEach with MKMapItem:**
- `MKMapItem` Hashable conformance changed in iOS 26
- Use index-based ForEach: `ForEach(Array(items.enumerated()), id: \.offset)`
- Avoid `ForEach(items, id: \.self)` with MKMapItem

### Architecture Decisions

1. **ZStack Overlay Approach** (not OrientationAwarePage)
   - Map needs to ignore safe areas for full-screen display
   - Header/footer/buttons overlaid on top of map
   - Allows map to extend edge-to-edge

2. **LocationManager Singleton**
   - Similar pattern to PhotoLibraryManager
   - `@MainActor` + `@Observable` for SwiftUI compatibility
   - Handles all CLLocationManager delegate callbacks

3. **Search State Separation**
   - MapsSearchState is `@Observable` class (not struct)
   - Allows mutation and UserDefaults persistence
   - Passed to sheet as `@Bindable` for two-way binding on searchText

4. **Aircraft Location Priority**
   - `gpsLatitudeNow/gpsLongitudeNow` (current position from server) takes precedence
   - Falls back to `gpsLatitude/gpsLongitude` (capture location)
   - Only aircraft with valid (non-zero) coordinates shown on map

### Aircraft Search Results Display Format

**Line 1 (always shown):** Model + Manufacturer
- Example: "G450 Gulfstream Aerospace Corp"

**Line 2 (if registration OR owner exists):** Registration + Owner
- Example: "N119JE John Smith, Inc."
- If only registration: "N119JE"
- If only owner: "John Smith, Inc."

**Line 2 fallback (if NO registration AND NO owner):** Aircraft Type + Engine Type
- Example: "Fixed Wing Multi-Engine Turbo-Jet"
- Uses `AircraftLookup.typeName()` and `AircraftLookup.engineTypeName()` from Theme.swift

**Map Annotation Label (`mapDisplayLabel`):**
- With registration: "G450 Gulfstream Aerospace Corp (N119JE)"
- Without registration: "G450 Gulfstream Aerospace Corp"

**Helper function:** `aircraftSearchSecondLine(_:)` in MapsSearchSheet
- Returns the appropriate second line based on available data
- Returns nil if no data available for any line

### Custom Aircraft Map Icons (EXPERIMENTAL)

**Status:** Testing - may be removed if icons don't display well at small sizes

**Source SVGs:** `/Volumes/SoftRAID/Dropbox/sites/SkyboundGear.com/SBGMerch/AirplaneArt/Vectorized/Aircraft Vectors ORIGINAL/`

**Assets Location:** `Assets.xcassets/MapIcons/`

| Icon Name | Source SVG | Used For |
|-----------|-----------|----------|
| `icon-balloon` | BALL.svg | Balloon, Blimp, Powered Parachute |
| `icon-single-prop` | C172.svg | Single-engine, Glider, Weight Shift, Default |
| `icon-twin-prop` | C310.svg | Multi-engine prop (Recip, Turbo-prop) |
| `icon-helicopter` | R44.svg | Rotorcraft, Gyroplane |
| `icon-jet` | SF50.svg | Multi-engine jet (Turbo-jet, Turbo-fan), Hybrid Lift |

**Aircraft Type to Icon Mapping** (in `mapIconName` property):

| Aircraft Type Code | Description | Icon |
|-------------------|-------------|------|
| "2" | Balloon | icon-balloon |
| "3" | Blimp/Dirigible | icon-balloon |
| "8" | Powered Parachute | icon-balloon |
| "4" | Fixed Wing Single-Engine | icon-single-prop |
| "1" | Glider | icon-single-prop |
| "7" | Weight Shift Control | icon-single-prop |
| "5" + engineType 4/5 | FW Multi-Engine Jet | icon-jet |
| "5" + other engine | FW Multi-Engine Prop | icon-twin-prop |
| "6" | Rotorcraft | icon-helicopter |
| "9" | Gyroplane | icon-helicopter |
| "H" | Hybrid Lift | icon-jet |
| "O" or unknown | Other | icon-single-prop |

**Icon Configuration:**
- Size: 32x32 pixels on map
- Color: AppColors.orange (template rendering)
- SVG format with `preserves-vector-representation: true`

**How to Back Out if Needed:**
1. Delete `Assets.xcassets/MapIcons/` folder
2. Revert MapsPage.swift annotation back to SF Symbol:
```swift
Image(systemName: "airplane")
    .font(.system(size: 16, weight: .bold))
    .foregroundStyle(AppColors.orange)
    .rotationEffect(.degrees(-45))
```
3. Remove `mapIconName` property from CapturedAircraft extension

### ICAO-Specific Icons with Prefix Interpolation

**Status:** Implemented - 65 ICAO-specific icons available

**How It Works:**
1. Try exact ICAO match (e.g., `C172` → `icao-C172`)
2. Try prefix interpolation (e.g., `M20J` → no exact match → try `M20` → finds `icao-M20T` or `icao-M20P`)
3. Fall back to generic type icon (e.g., `icon-single-prop`)

**Example Matching:**
| Aircraft ICAO | Matching Logic | Result Icon |
|--------------|----------------|-------------|
| C172 | Exact match | icao-C172 |
| C172S | No exact → prefix C172 exists | icao-C172 |
| M20J | No exact → prefix M20 → finds M20T | icao-M20T |
| B737 | No match at any level | icon-jet (generic) |

**MapIconHelper Class:**
```swift
enum MapIconHelper {
    static let availableICAOs: Set<String> = [...]  // 65 codes
    static func findICAOIcon(for icao: String) -> String?
}
```

**Available ICAO Icons (65 total):**
- Cessna: C140, C150, C172, C180, C182, C185, C206, C207, C208, C210, C310, C421
- Piper: PA11-PA46, P28A, P28R, P46T
- Beechcraft: BE23, BE35, BE55, BE58
- Mooney: M20P, M20T, M600
- Robinson: R22, R44, R66
- Cirrus: SR22, SF50
- Van's RV: RV6, RV10, RV12
- Others: DA40, DR40, PC12, J3, JAB4, GA7, CH60, HDJT, etc.

**Adding New ICAO Icons:**
1. Copy SVG to source folder
2. Run copy script to create imageset
3. Add ICAO code AND manufacturer to `MapIconHelper.icaoToManufacturer` dictionary
4. Rebuild

### Icon Matching Logic (Updated)

**Problem:** Previous prefix interpolation was too loose - a Boeing 737 might match a Cessna icon because "B7" prefix matched something unrelated.

**Solution:** Manufacturer verification required for all ICAO matching

**Matching Priority:**
1. **Exact ICAO match** with manufacturer verification
2. **Prefix match** with manufacturer verification (e.g., M20J → M20T if both are Mooney)
3. **Airliner detection** → SF Symbol airplane icon
4. **Generic type fallback** → type-based icons

**Airliner Detection:**
Aircraft uses SF Symbol (`airplane`) instead of custom icon if:
- Manufacturer is a major airliner producer (Boeing, Airbus, Embraer, etc.)
- OR it's a multi-engine jet with 15+ seats

**Airliner Manufacturers:** Boeing, Airbus, Embraer, Bombardier, McDonnell Douglas, Lockheed, ATR, Fokker, Saab, BAE, British Aerospace, Tupolev, Ilyushin, Antonov, Comac, Sukhoi, Mitsubishi

**Icon Return Values:**
- `"sf.airplane"` - SF Symbol for airliners (special prefix)
- `"MapIcons/icao-C172"` - Specific ICAO asset
- `"MapIcons/icon-jet"` - Generic type asset

**Example Matching:**
| Aircraft | ICAO | Manufacturer | Result |
|----------|------|--------------|--------|
| Cessna 172 | C172 | Cessna | `icao-C172` (exact match) |
| Mooney M20J | M20J | Mooney | `icao-M20T` (prefix match, same mfg) |
| Boeing 737 | B738 | Boeing | `sf.airplane` (airliner) |
| Gulfstream G450 | G450 | Gulfstream | `icon-jet` (generic, no match) |
| Unknown Jet | XXXX | Unknown | `icon-jet` (generic fallback) |

**MapIconHelper Changes:**
```swift
// Old: Just ICAO set
static let availableICAOs: Set<String>

// New: ICAO → Manufacturer mapping
static let icaoToManufacturer: [String: String]
static let airlinerManufacturers: Set<String>
static func isAirlinerManufacturer(_ manufacturer: String) -> Bool
static func findICAOIcon(for icao: String, manufacturer: String) -> String?
```

### Manual ICAO Override System

**Purpose:** Fix icon mismatches that automatic matching can't handle

**Location:** `MapsPage.swift` → `MapIconHelper.icaoOverrides` (near line 137)

**Format:**
```swift
static let icaoOverrides: [String: String] = [
    "AIRCRAFT_ICAO": "ICON_ICAO",  // Comment explaining why
    "AT3T": "AT5T",   // Air Tractor AT-301 → use AT-502 icon
    // Add more as needed...
]
```

**How It Works:**
1. Overrides are checked FIRST, before any other matching logic
2. Bypasses manufacturer verification (for cross-manufacturer matches)
3. If override icon doesn't exist in `icaoToManufacturer`, falls through to normal matching

**When to Add an Override:**
- Aircraft shows wrong icon (e.g., AT3T showing as C172)
- Aircraft from same family should share an icon (e.g., all Air Tractors → AT5T)
- Manufacturer matching fails due to naming variations

**To Add a New Override:**
1. Open `MapsPage.swift`
2. Find `icaoOverrides` dictionary (search for "MANUAL ICAO OVERRIDES")
3. Add: `"WRONG_ICAO": "CORRECT_ICON_ICAO",`
4. Rebuild app

### Drone/Quadcopter Detection

**Problem:** DJI Phantoms and commercial drones (Amazon, etc.) are classified as "rotorcraft" but showing helicopter icons.

**Solution:** Auto-detect quadcopters based on engine count

**Logic in `genericTypeIcon`:**
```swift
case "6":  // Rotorcraft
    // Quadcopter/drone has 4+ motors
    if let engines = engineCount, engines >= 4 {
        return "MapIcons/icao-F4"  // Drone icon
    }
    return "MapIcons/icon-helicopter"
```

**Drone Icon (icao-F4):**
- Custom quadcopter SVG with 4 propeller discs
- DJI Phantom-style silhouette
- Located at: `Assets.xcassets/MapIcons/icao-F4.imageset/drone.svg`

**Detection Criteria:**
| Aircraft Type | Engine Count | Icon Used |
|---------------|--------------|-----------|
| Rotorcraft (6) | 4+ | Drone (icao-F4) |
| Rotorcraft (6) | 1-3 or nil | Helicopter |
| Any other type | Any | Normal matching |

**Why This Matters:**
- DJI drones appearing in FAA registrations
- Amazon/commercial delivery drones increasing
- Test data already shows multiple DJI aircraft
- Future-proofs for UAV growth

**Covered Automatically:**
- DJI Phantom (ICAO: F4) - also has direct ICAO match
- Amazon Prime Air drones
- Commercial inspection drones
- Any rotorcraft with 4+ engines

### Experimental Aircraft Handling

**Problem:** Experimental/homebuilt aircraft often list the builder's name as manufacturer in FAA records, not the kit manufacturer. This breaks manufacturer verification.

**Example:** An RV6 built by John Smith has manufacturer "SMITH JOHN" instead of "VANS AIRCRAFT"

**Solution:** If `aircraftClassification == 4` (EXPERIMENTAL), bypass manufacturer verification entirely.

**Classification Values:**
| Value | Meaning |
|-------|---------|
| 1 | STANDARD |
| 2 | LIMITED |
| 3 | RESTRICTED |
| 4 | EXPERIMENTAL ← Skip mfg verification |
| 5-9 | Other categories |

**How It Works:**
```swift
let isExperimental = aircraftClassification == 4
MapIconHelper.findICAOIcon(for: icao, manufacturer: manufacturer, isExperimental: isExperimental)
```

When `isExperimental == true`:
- Direct ICAO match attempted (no manufacturer check)
- Prefix matching attempted (no manufacturer check)
- Falls through to generic if no match

**Why This Matters:**
- Covers ALL experimental/homebuilt aircraft automatically
- RVs, Glasairs, Lancairs, Long-EZs, Cozys, etc.
- One-off homebuilts with unique ICAOs use generic fallback
- Override dictionary available for special cases

### Van's RV Aircraft Special Handling

**Problem:** RV homebuilts (RV-6, RV-10, etc.) are so common they get additional special handling beyond the experimental flag.

**Solution:** If ICAO starts with "RV", bypass manufacturer check and use RV icons directly (even if not marked experimental)

**Logic:**
```swift
if code.hasPrefix("RV") {
    // Try exact match (RV6, RV10, RV12)
    // Try prefix match
    // Fall back to RV6 as generic RV silhouette
}
```

**Available RV Icons:** RV6, RV10, RV12

**Matching Examples:**
| ICAO | Manufacturer | Result |
|------|--------------|--------|
| RV6 | SMITH JOHN | `icao-RV6` ✓ |
| RV7 | DOE JANE | `icao-RV6` (fallback) |
| RV10 | VANS AIRCRAFT | `icao-RV10` ✓ |
| RV14 | ANYONE | `icao-RV6` (fallback) |

**Why This Matters:**
- RV aircraft are extremely popular among aviation enthusiasts
- Many app users will fly or spot RVs
- Distinctive low-wing appearance - wrong icon would be obvious
- Homebuilt registration quirk requires special handling

### Complete Icon Matching Flow

```
1. isAirliner check
   ├─ YES → return "sf.airplane" (SF Symbol)
   └─ NO → continue

2. Check icaoOverrides dictionary
   ├─ FOUND → return override icon
   └─ NOT FOUND → continue

3. Van's RV special handling (ICAO starts with "RV")
   ├─ Exact RV match (RV6, RV10, RV12) → return that icon
   ├─ Other RV variant → return RV6 as fallback
   └─ NOT an RV → continue

4. Experimental aircraft (classification == 4)
   ├─ Exact ICAO match → return icon (NO mfg check)
   ├─ Prefix match → return icon (NO mfg check)
   └─ No match → continue to generic

5. Exact ICAO match (with manufacturer verification)
   ├─ FOUND + manufacturer matches → return ICAO icon
   └─ NOT FOUND or mfg mismatch → continue

6. Prefix ICAO match (with manufacturer verification)
   ├─ FOUND + manufacturer matches → return matched icon
   └─ NOT FOUND → continue

7. Generic type fallback
   ├─ Balloon/Blimp/Parachute → icon-balloon
   ├─ Single-engine FW → icon-single-prop
   ├─ Multi-engine FW + jet → icon-jet
   ├─ Multi-engine FW + prop → icon-twin-prop
   ├─ Rotorcraft + 4+ engines → icao-F4 (drone)
   ├─ Rotorcraft + <4 engines → icon-helicopter
   ├─ Hybrid lift → sf.airplane
   └─ Unknown → icon-single-prop
```

**Troubleshooting Wrong Icons:**
1. Check if aircraft is an airliner (Boeing/Airbus) → should show SF Symbol
2. Check `icaoOverrides` for existing override
3. Check if ICAO exists in `icaoToManufacturer`
4. Check if manufacturer normalization is working
5. Add override if automatic matching fails

**Future Enhancements:**
- Create simplified silhouette versions if detail is lost at small sizes
- Add icon for glider with longer wingspan silhouette
- Add more ICAO-specific icons as SVGs become available

### Icon Styling & Clustering (Apple Maps-style)

**Status:** Implemented - Icons match Apple Maps design patterns

**Features Implemented:**

1. **Black Outline Effect**
   - Multiple shadow layers create black outline around icons
   - Makes icons "pop" against any map background
   - Implementation: 5 `.shadow(color: .black, radius: 0.5)` modifiers at different offsets

2. **Increased Icon Size**
   - Size increased from 32x32 to 34x34 pixels
   - Better visibility without losing detail

3. **Side-Positioned Labels**
   - Labels appear to the RIGHT of icons (not below like default Annotation)
   - White text with black outline (no background box)
   - Font: 15pt bold
   - Shows ICAO code (more recognizable to aviation enthusiasts than registration)

4. **Zoom-Level Label Visibility**
   - Labels automatically hide when zoomed out
   - Threshold: `mapSpan < 0.15` (approximately 10 miles)
   - Uses `onMapCameraChange` to track zoom level
   - Prevents overlapping labels in dense areas

5. **Aircraft Clustering**
   - Groups nearby aircraft when zoomed out
   - Cluster threshold scales with zoom level: `mapSpan * 0.1`
   - Cluster annotation: Orange circle (44px) with white aircraft icon and blue count badge
   - Tapping cluster zooms in 3x to show individual aircraft

**Components:**

| Component | Purpose |
|-----------|---------|
| `AircraftMapAnnotation` | Single aircraft with icon + optional label |
| `ClusterAnnotation` | Grouped aircraft with count badge |
| `AircraftCluster` | Model for cluster data |
| `AircraftClusterHelper` | Clustering algorithm |

**Cluster Logic:**
- Uses simple distance-based clustering (lat/lon comparison)
- Iteratively groups aircraft within threshold distance
- Calculates center as average of all member coordinates
- Re-clusters dynamically as user zooms in/out

**Example Cluster Tap Behavior:**
```
User zoomed out → sees cluster "5" at LAX
Tap cluster → map zooms to (currentSpan / 3)
Now individual aircraft visible with labels
```

**Styling Reference (matches Apple Maps):**
- Icon with black outline/shadow for visibility
- ICAO label in white text with black outline (no background box)
- Side positioning (HStack) vs below (default)
- Labels hidden when map density would cause overlap

### Performance Optimizations

**Problem:** Rendering 2000+ aircraft annotations caused map to be sluggish and unresponsive.

**Solution:** Viewport-based filtering with limits

1. **Viewport Filtering**
   - Only render aircraft within the visible map region
   - Buffer zone (1.5x viewport) for smoother panning
   - Aircraft outside viewport are not rendered at all

2. **Aircraft Limit**
   - Maximum 150 aircraft rendered at once (`maxVisibleAircraft = 150`)
   - Prevents overload even when zoomed out over dense areas
   - Sufficient for typical viewing without performance impact

3. **Camera Change Optimization**
   - Uses `.onMapCameraChange(frequency: .onEnd)` instead of continuous
   - Only recalculates when user stops panning/zooming
   - Prevents constant re-rendering during gestures

4. **Cleaner Map Style**
   - Uses `.mapStyle(.standard(pointsOfInterest: .excludingAll))`
   - Removes POI clutter (restaurants, shops, etc.)
   - Reduces visual noise so aircraft stand out better

**Performance Constants:**
```swift
private let maxVisibleAircraft = 150      // Max annotations rendered
private let viewportBuffer: Double = 1.5  // Extend visible region by 50%
```

**Computed Properties:**
- `allAircraftWithLocation` - All aircraft with valid GPS (unchanged by viewport)
- `visibleAircraft` - Filtered to viewport + limited count
- `aircraftClusters` - Uses `visibleAircraft` (not all aircraft)
- `filteredAircraft` - Search still queries ALL aircraft (user expects full search)

**Label Display:**
- Shows ICAO code (e.g., "C172", "PA28") - always available
- White text with black outline (no background box)
- More recognizable to aviation enthusiasts than registration numbers
