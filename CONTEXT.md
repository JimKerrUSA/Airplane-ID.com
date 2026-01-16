# Project Context

## Overview
Project: Airplane-ID iOS App
Created: 2026-01-15
Purpose: iOS app for identifying and tracking aircraft sightings

## Current State
- SwiftUI app with SwiftData for persistence
- **Full navigation system working:** Home, Maps, Camera, Hangar, Settings, Journey pages
- Three orientation templates: PortraitTemplate, LandscapeLeftTemplate, LandscapeRightTemplate
- Portrait view fully working with data boxes, progress bar, and recent sightings
- **Landscape views now have full content matching mockups:**
  - Two stat boxes on left (270w x 103h each, 14px gap between)
  - Latest Sightings on right (270w x 220h, shows 3 items with 2-line format)
  - Progress bar at bottom (240 label + 346 bar = 586w x 40h)
- Landscape Left template: footer offset x: 20, content padding leading: 120
- Landscape Right template: footer offset x: 100, content padding trailing: 120
- Landscape header person icon positioned (trailing padding: 86)
- Test data loading working via Airplane_IDApp.swift onAppear
- **Level progression system:** NEWBIE → SPOTTER → ENTHUSIAST → EXPERT → ACE → LEGEND
- **JourneyPage:** Tap person icon to view level, stats, badges (coming soon), leaderboard (coming soon)
- **Database-driven stats:** Aircraft count, unique types, and level all computed from SwiftData

## Key Files
- `ContentView.swift` - All reusable components and templates
  - `NavigationDestination` enum - All app screens (home, maps, camera, hangar, settings, journey)
  - `AppState` - Global observable state (status, counts, currentScreen, etc.)
  - TopMenuView / TopMenuViewLandscape - Header components (with person icon tap)
  - BottomMenuView / BottomMenuViewLandscape - Footer/nav components (with nav taps)
  - **PortraitTemplate** - Portrait orientation template
  - **LandscapeLeftTemplate** - Landscape with footer on LEFT edge
  - **LandscapeRightTemplate** - Landscape with footer on RIGHT edge
  - OrientationAwarePage - Wrapper that switches templates based on geometry
- `HomePage.swift` - Main home screen content with data boxes and recent sightings
  - Level progression computed properties (currentStatus, nextLevel, levelProgress)
  - uniqueTypesCount - Counts unique ICAO codes
- `Item.swift` - Contains CapturedAircraft SwiftData model
- `Airplane_IDApp.swift` - App entry point and navigation
  - MainView - Navigation router (switches pages based on currentScreen)
  - PlaceholderPage - Generic "Coming Soon" page
  - JourneyPage - User profile/progress page
  - SettingsPage - Settings page (portrait only, dark theme)
  - SettingsRow - Reusable settings menu row component

## Recent Decisions

### Avoid UIKit
- Problem: Needed to detect landscape left vs right orientation
- Solution: DO NOT use UIKit - causes build errors every time
- Why: UIKit imports in #if os(iOS) blocks cause schema build failures

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

### Colors
- Background blue: #1D58A4
- Dark blue (headers): #082A49
- Orange (icons/accent): #F27C31
- Yellow (numbers): #FBBD1C
- Text dark: #082A49

### Recent Sightings Styling
- Airplane icon: 28pt, color #F27C31
- Manufacturer: 23pt SF Pro Regular, ALL CAPS
- Registration/Model: 19pt SF Pro Regular
- Text padding: 3px left of icon

### CapturedAircraft Model Properties
- captureDate, gpsLongitude, gpsLatitude
- year, month, day, timeUTC
- icao, manufacturer, model
- engine, numberOfEngines, registration
- rating, thumbsUp, iPhotoReference

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
| Destination | Icon | Tap Location | Page |
|-------------|------|--------------|------|
| home | house | Footer | HomePage |
| maps | map | Footer | PlaceholderPage |
| camera | camera | Footer (center) | PlaceholderPage |
| hangar | airplane.departure | Footer | PlaceholderPage |
| settings | gearshape | Footer | SettingsPage |
| journey | person | Header (top right) | JourneyPage |

**Implementation:**
- `NavigationDestination` enum in ContentView.swift
- `appState.currentScreen` tracks active page
- `MainView` in Airplane_IDApp.swift switches views based on currentScreen
- All nav buttons have `onTapGesture` handlers

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
Settings page with dark theme - **portrait only** (does not rotate).

**Design:**
- Background color: #121516 (dark)
- Row background: #1E2328 (slightly lighter)
- Uses same header (TopMenuView) and footer (BottomMenuView) as portrait template
- Does NOT use OrientationAwarePage - stays portrait regardless of device rotation

**Current menu items (placeholders):**
- Account - Manage your account
- Notifications - Configure alerts
- Sync - Cloud backup settings
- Help - FAQ and support
- About - Version and credits

**Components:**
- `SettingsPage` - Main settings view
- `SettingsRow` - Reusable row component with icon, title, subtitle, chevron

## Next Steps

1. Build out Maps page content
2. Build out Hangar page content
3. Build out Settings page content
4. Add proper orientation detection for runtime (without UIKit)
5. Test on physical device

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
