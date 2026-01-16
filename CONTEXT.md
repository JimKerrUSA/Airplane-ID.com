# Project Context

## Overview
Project: Airplane-ID iOS App
Created: 2026-01-15
Purpose: iOS app for identifying and tracking aircraft sightings

## Current State
- SwiftUI app with SwiftData for persistence
- Three orientation templates: Portrait, Landscape Left, Landscape Right
- Portrait view fully working with data boxes, progress bar, and recent sightings
- Landscape Left template positioned correctly (footer on left edge)
- Landscape Right template needs footer repositioned (currently on wrong side)
- Test data loading working via HomePage.onAppear

## Key Files
- `ContentView.swift` - All reusable components and templates
  - TopMenuView / TopMenuViewLandscape - Header components
  - BottomMenuView / BottomMenuViewLandscape - Footer/nav components
  - HomePagePortrait - Portrait template
  - HomePageLeftHorizontal - Landscape with footer on LEFT
  - HomePageRightHorizontal - Landscape with footer on RIGHT
  - OrientationAwarePage - Wrapper that switches templates based on geometry
- `HomePage.swift` - Main home screen content with data boxes and recent sightings
- `Item.swift` - Contains CapturedAircraft SwiftData model
- `Airplane_IDApp.swift` - App entry point with test data loading

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

## Next Steps

1. Fix Landscape Right footer - move to RIGHT edge (currently on left)
2. Add proper orientation detection for runtime (without UIKit)
3. Build out landscape content areas
4. Test on physical device

## Session Log

### 2026-01-15
- Rebuilt CapturedAircraft model after git reset incident
- Rebuilt test data loading in HomePage.onAppear
- Fixed Recent Sightings display with proper styling
- Created TopMenuViewLandscape and BottomMenuViewLandscape components
- Created HomePageLeftHorizontal and HomePageRightHorizontal templates
- Positioned left landscape footer correctly with ignoresSafeArea and offset(x: 5)
- Added separate Xcode previews for each landscape template
- IMPORTANT: Do not use UIKit - causes build failures
- Next: Fix right landscape footer positioning
