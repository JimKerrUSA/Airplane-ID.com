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
- `Theme.swift` - Centralized colors, fonts, spacing, haptics, and utilities
  - AppColors - All app color constants
  - AppFonts - Typography helpers
  - AppSpacing - Layout spacing constants
  - Haptics - Tactile feedback manager (see below)
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

---

## Documentation Files

This project's documentation is split into smaller files for easier management:

| File | Description |
|------|-------------|
| [CONTEXT.md](../CONTEXT.md) | This file - current state, key files, next steps |
| [docs/TECHNICAL_NOTES.md](docs/TECHNICAL_NOTES.md) | Architecture, code patterns, technical decisions |
| [docs/SESSION_LOG.md](docs/SESSION_LOG.md) | Historical development session logs |
| [docs/FAA_REFERENCE.md](docs/FAA_REFERENCE.md) | FAA aircraft code reference tables |
| [docs/FEATURES.md](docs/FEATURES.md) | Feature implementation documentation |

### Recent Session Summary (2026-01-18)

**Upload Feature - Complete Implementation:**
- Full 4-state upload workflow: Select Photo → Enter Details → Scanning Animation → Results
- Photo import from Photo Library (PHPicker) and Files app (DocumentPicker)
- Searchable ICAO and Airline pickers (reused from HangarPage)
- X-pattern grid scanning animation with "PROCESSED" flash
- Thumbs up/down feedback for AI training
- GPS extraction from photo metadata (PHAsset location or EXIF data)
- Date extraction from photo metadata (auto-populates "Spotted On" field)
- Validation popups for missing data and ratings
- Layout fixes for smaller screens (date-only picker, flexible Registration field)

