# Feature Implementation Documentation

Detailed documentation for completed features in the Airplane-ID iOS app.

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

## SVG to SwiftUI IP Protection - ROLLED BACK

Attempted to convert SVG icons to compiled SwiftUI Shape code, but the shapes rendered incorrectly (smashed/malformed) due to the complexity of the original SVG paths.

**What Was Tried:**
- Created Python converter (`scripts/svg_to_swiftui.py`) for SVG → SwiftUI Path
- Generated `AircraftShapes.swift` with 71 shapes
- Updated map annotations to use Shape instead of Image

**Why It Failed:**
- SVG paths were too complex for simple conversion
- Many paths used arc commands and complex curves
- Resulting shapes didn't preserve the visual fidelity

**Resolution:**
- Rolled back all changes
- SVG assets remain in `Assets.xcassets/MapIcons/` (original approach)
- Map icons continue to use `Image(iconName)` for rendering

---

## SVG Copyright Protection - IMPLEMENTED

Added embedded copyright metadata and legal warnings to all 71 SVG files.

**Implementation:**
- Created `scripts/add_copyright.py` - Adds copyright to SVG files
- All 71 MapIcons SVGs now contain:
  - XML copyright comment with legal warnings
  - RDF/Dublin Core metadata
  - Unique Asset ID (e.g., `PHI-AID-C172-a853bd28`)
  - Content hash for tracking

**Legal References Cited:**
- 17 U.S.C. § 106 - Exclusive rights of copyright owner
- 17 U.S.C. § 504 - Statutory damages up to $150,000 per work
- 17 U.S.C. § 506 - Criminal penalties for willful infringement

**Copyright Owner:** Passion Highway, Inc. (jim@passionhighway.com)

**To add copyright to new SVGs:**
```bash
python3 scripts/add_copyright.py <svg_file_or_directory>
```

---

## Haptic Feedback - IMPLEMENTED

Added tactile haptic feedback throughout the app for a premium, responsive feel.

**Implementation:** `Haptics` enum in Theme.swift

**Usage:**
```swift
Haptics.navigation()  // Major nav buttons (Home, Maps, Camera, Hangar, Settings, Journey)
Haptics.light()       // Opening sheets, modals, list item taps
Haptics.selection()   // Toggles, pickers, search result selection
Haptics.success()     // Completed actions (capture, save)
Haptics.warning()     // Attention needed
Haptics.error()       // Failed actions
Haptics.capture()     // Camera shutter
Haptics.soft()        // Very subtle interactions
```

**Feedback Types:**
| Type | UIKit Generator | Feel |
|------|----------------|------|
| navigation | Medium Impact | Firm, satisfying tap |
| light | Light Impact | Subtle acknowledgment |
| selection | Selection Changed | Crisp click |
| success | Notification Success | Positive double-tap |
| warning | Notification Warning | Attention-getting |
| error | Notification Error | Sharp negative |
| capture | Medium Impact | Shutter feel |
| soft | Soft Impact | Very subtle |

**Where Haptics Are Used:**
- Footer navigation buttons (Home, Maps, Camera, Hangar, Settings)
- Header person icon (Journey)
- Map search/location buttons
- Map annotation taps
- Hangar list item taps
- Filter button taps
- Search result selection

---

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

### Custom Aircraft Map Icons

**Status:** Production - Using SVG assets in Assets.xcassets

**Source SVGs:** `/Volumes/SoftRAID/Dropbox/sites/SkyboundGear.com/SBGMerch/AirplaneArt/Vectorized/Aircraft Vectors ORIGINAL/`

**Assets Location:** `Assets.xcassets/MapIcons/` (71 imagesets)

---

### SVG Copyright Protection

All SVG artwork is protected with embedded copyright metadata and unique tracking identifiers.

**Copyright Owner:** Passion Highway, Inc.
**Contact:** jim@passionhighway.com
**Asset ID Prefix:** PHI-AID (Passion Highway Inc - Airplane ID)

**Standard Copyright Notice (embedded in all SVGs):**
```
Copyright (c) 2026 Passion Highway, Inc. All Rights Reserved.

This image is digitally signed and the hash recorded.
Unauthorized reproduction, distribution, or use of this
image is strictly prohibited and constitutes copyright
infringement under 17 U.S.C. Section 106.

Violators may be subject to civil liability including
statutory damages up to $150,000 per work (17 U.S.C. Section 504)
and criminal prosecution with fines and imprisonment
(17 U.S.C. Section 506).

Contact: jim@passionhighway.com
Asset ID: PHI-AID-[NAME]-[HASH]
Hash: [content hash]
```

**Legal References:**
- 17 U.S.C. § 106 - Exclusive rights (reproduction, distribution, display)
- 17 U.S.C. § 504 - Statutory damages up to $150,000 per work
- 17 U.S.C. § 506 - Criminal penalties for willful infringement

**How to Add Copyright to New SVG Files:**
```bash
cd /Users/jkerr/dev/projects/Airplane-ID.com/xCode/iOS_APP/Airplane-ID
python3 scripts/add_copyright.py <svg_file_or_directory>
```

**Examples:**
```bash
# Single file
python3 scripts/add_copyright.py Airplane-ID/Assets.xcassets/MapIcons/icao-NEW.imageset/NEW.svg

# All files in directory
python3 scripts/add_copyright.py Airplane-ID/Assets.xcassets/MapIcons/
```

**What the Script Does:**
1. Adds XML declaration and copyright comment at top of file
2. Embeds RDF/Dublin Core metadata with rights information
3. Generates unique Asset ID: `PHI-AID-[NAME]-[8-char hash]`
4. Generates content hash from SVG path data (fingerprint)
5. Skips files that already have copyright (idempotent)

**Metadata Elements Added:**
- `dc:title` - Descriptive title from filename
- `dc:creator` - Passion Highway, Inc.
- `dc:rights` - Full copyright statement with legal references
- `dc:identifier` - Unique asset ID for tracking
- `dc:source` - Airplane-ID.com
- `cc:license` - Link to terms of use

---

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

**How to Back Out to SF Symbols (if custom icons cause issues):**
1. In MapsPage.swift, change `Image(iconName)` to SF Symbol:
```swift
Image(systemName: "airplane")
    .font(.system(size: 16, weight: .bold))
    .foregroundStyle(AppColors.orange)
    .rotationEffect(.degrees(-45))
```
2. Remove `Assets.xcassets/MapIcons/` folder
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

---

### 2026-01-18 (continued)

## Haptic Feedback Expansion - Additional Pages

Extended haptic feedback to all interactive elements throughout the app.

**New Haptics Added:**

| Component | File | Haptic Type | Interaction |
|-----------|------|-------------|-------------|
| AircraftDetailView | HangarPage.swift | light | Photo tap, Back button, Edit button, Cancel button, Rate button |
| AircraftDetailView | HangarPage.swift | success | Save button (successful save feel) |
| RatingSelectorSheet | HangarPage.swift | selection | Star rating selection |
| RatingSelectorSheet | HangarPage.swift | light | Clear Rating, Cancel |
| HomePage | HomePage.swift | light | Recent Sightings aircraft tap |

**MapsPage Footer Position Fix:**

The footer was positioned incorrectly (moved up) on the Maps page. The issue was that the footer was in a VStack with control buttons, instead of using ZStack overlay like other pages.

**Before (incorrect):**
```swift
VStack(spacing: 0) {
    mapsHeader
    Spacer()
    HStack { /* control buttons */ }
        .padding(.bottom, 16)  // This pushed footer up
    BottomMenuView()  // In VStack = pushed by content above
}
```

**After (correct):**
```swift
ZStack {
    mapView
    
    VStack(spacing: 0) {
        mapsHeader
        Spacer()
    }
    
    VStack {
        Spacer()
        HStack { /* control buttons */ }
            .padding(.bottom, 8)
        BottomMenuView()  // In separate VStack with Spacer = always at bottom
    }
}
```

**Footer Position Architecture:**
- Other pages (Home, Hangar, Settings) use PortraitTemplate which has BottomMenuView in a ZStack overlay
- MapsPage now matches this pattern with footer in its own VStack with Spacer, positioned by ZStack
- Control buttons padding reduced from 16 to 8 to maintain proper spacing above footer


---

### 2026-01-18 (Session 2)

## AircraftDetailView Enhancements

### Editable Dropdown Pickers Added

All the following fields now use dropdown pickers instead of text fields:

| Field | Picker Type | Values |
|-------|-------------|--------|
| Category | CategoryPickerRow | Land, Sea, Amphibian |
| Classification | ClassificationPickerRow | STANDARD, LIMITED, RESTRICTED, EXPERIMENTAL, etc. |
| Engine Type | EngineTypePickerRow | None, Reciprocating, Turbo-prop, Turbo-jet, etc. |
| Weight Class | WeightClassPickerRow | Up to 12,499 lbs, 12,500-19,999 lbs, 20,000+ lbs, UAV |
| Owner Type | OwnerTypePickerRow | Individual, Partnership, Corporation, LLC, etc. |
| Country | CountryPickerRow | Searchable list of ~195 countries |

### Lookup Tables Added (Theme.swift - AircraftLookup)

```swift
// Weight Class (1-4)
static let weightClasses: [Int: String] = [
    1: "Up to 12,499 lbs",
    2: "12,500 - 19,999 lbs",
    3: "20,000 lbs and over",
    4: "UAV up to 55g"
]

// Owner Type (1-9, no 6)
static let ownerTypes: [Int: String] = [
    1: "Individual",
    2: "Partnership",
    3: "Corporation",
    4: "Co-Owned",
    5: "Government",
    7: "LLC",
    8: "Non Citizen Corporation",
    9: "Non Citizen Co-Owned"
]
```

### Model Changes (Item.swift)

- `weightClass`: Changed from `String?` to `Int?`
- `ownerType`: Changed from `String?` to `Int?`
- Added `CountryLookup` model for country code lookup

### Country Lookup System

Similar to ICAO lookup:
- **CountryLookup model**: `code` (2-letter ISO), `name` (full name)
- **CountryCodes.csv**: ~195 countries bundled with app
- **CountrySearchSheet**: Searchable by name or code
- **CountryPickerRow**: Shows "Country Name (XX)" format

### Clickable Location Coordinates

- "Location" renamed to "Spotted LOC" (original capture location)
- Added "Current LOC" (last known position from server)
- Both are clickable - tap navigates to Maps page centered on that coordinate
- Uses `appState.navigateToMap(latitude:longitude:aircraftICAO:)` for navigation

### Haptic Feedback Extended

Added haptics to:
- AircraftDetailView (photo tap, toolbar buttons, rating)
- RatingSelectorSheet (star selection)
- All new picker rows (selection feedback on choose)

### Important: Schema Migration

When changing field types (String? to Int?), must delete app and reinstall to clear old database. SwiftData cannot auto-migrate type changes.

### Files Modified

- `Theme.swift` - Added weightClasses, ownerTypes lookup tables
- `Item.swift` - Changed weightClass/ownerType types, added CountryLookup
- `HangarPage.swift` - Added all picker row components and search sheets
- `Airplane_IDApp.swift` - Added CountryLookup to schema, country CSV loader
- `CountryCodes.csv` - New file with country data

### 2026-01-18
**App Preferences Implementation:**
- Built complete App Preferences UI in SettingsPage.swift
  - Time Format: System Default, 12 Hour, 24 Hour
  - Date Format: System Default, DMY, MDY, YMD
  - Time Zone: Device, UTC
  - Default Open Page: Home, Hangar, Maps, Journey, Camera
- Created preference enums with display names and examples
- Added AppPreferences class with UserDefaults keys
- Built PreferencePickerRow reusable component

**DateFormatting Integration:**
- Updated Theme.swift DateFormatting enum to read from UserDefaults
- formatDate() now respects date format preference
- formatTime() now respects time format and timezone preferences
- formatDateTime() combines both preferences
- UTC timezone appends " UTC" suffix for clarity

**Default Page Integration:**
- AppState.init() now reads default page from UserDefaults
- App opens to user-selected page on launch

### Files Modified
- `SettingsPage.swift` - AppPreferences class, enums, AppPreferencesView, PreferencePickerRow
- `Theme.swift` - DateFormatting now reads from UserDefaults preferences
- `ContentView.swift` - AppState.init() reads default page preference

**Professional About Page:**
- Rebuilt AboutView with corporate-quality layout
- App logo with gradient background and shadow effect
- Marketing description: "Your Personal Aircraft Identification Companion"
- Highlights Hangar catalog filtering capabilities
- Legal section with external links:
  - Privacy Policy (https://airplane-id.com/privacy.html)
  - Terms of Service (https://airplane-id.com/terms.html)
  - End User License Agreement (https://airplane-id.com/eula.html)
- Support section:
  - Help Center (https://airplane-id.com/support.html)
  - Contact Support (mailto:support@airplane-id.com)
  - Visit Our Website (https://airplane-id.com)
- Company footer: Passion Highway, Inc.
- Copyright notice with "All Rights Reserved"

**Global App Configuration (AppConfig):**
- `appVersion` - "1.0.1.0" (update when releasing)
- `appName` - "Airplane-ID"
- `companyName` - "Passion Highway, Inc."
- `copyrightYear` - "2026"
- `supportEmail` - "support@airplane-id.com"
- URL constants for all legal/support pages
- Version shown in About page reads from this global constant

### 2026-01-18 (continued)

**App Preferences Implementation:**
- Time Format: System Default, 12 Hour, 24 Hour
- Date Format: System Default, DMY, MDY, YMD
- Time Zone: Device, UTC (appends " UTC" suffix)
- Open Page: Home, Hangar, Maps, Journey, Camera
- DateFormatting in Theme.swift reads from UserDefaults preferences
- AppState.init() loads default page on app launch

**Settings Consolidation:**
- Removed System Settings menu item (was placeholder)
- Settings menu now: Account Settings, App Preferences, About, Developer Tools (debug only)
- Added "Reset Preferences" option (restores defaults, keeps data)
- Added "DANGER ZONE" section with red warning styling:
  - Delete All Aircraft
  - Reset App
- Clear visual separation between safe and destructive options

**Professional About Page:**
- Uses app icon from Assets (AirplaneID-icon) instead of system image
- Three-paragraph description highlighting:
  - Camera identification and PlaneSpotter journey
  - Advanced Hangar catalog filtering
  - Interactive map tracking feature
- Legal section: Privacy Policy, Terms of Service, EULA
- Support section: Help Center, Contact Support, Website
- Company footer: Passion Highway, Inc.
- Version reads from AppConfig.appVersion global constant

**Capture Mode Toggle Feature (Camera vs Upload):**

New functionality allowing users to choose between camera capture and photo upload:

*New Files:*
- `UploadPage.swift` - Placeholder page with photo.badge.plus icon

*Footer Center Button Behavior:*
- **Tap**: Navigates to Camera or Upload page based on current mode
- **Long Press (0.5s)**: Toggles mode AND navigates to new page
  - Strong haptic feedback (success pattern)
  - Toast notification: "Switched to Upload Mode" / "Switched to Camera Mode"
  - Toast auto-dismisses after 2 seconds

*App Preferences:*
- "Capture Mode" picker in App Behavior section
  - Camera - Take new photos
  - Upload - Select from library
- Hint text: "Long-press button to toggle"

*Icon Changes:*
- Camera mode: `camera` icon
- Upload mode: `photo.badge.plus` icon

*Technical Implementation:*
- Added `captureModeKey` to AppConfig
- AppState properties: `captureModeIcon`, `captureModeDestination`
- AppState methods: `toggleCaptureMode()`, `setCaptureMode()`
- `CapturePreference` enum with displayName, description, icon
- `CaptureModePickerRow` component syncs with AppState
- Toast overlay in Airplane_IDApp.swift
- Both portrait and landscape BottomMenuView updated
- Reset functions include capture mode

*Preference Labels (shortened for space):*
- "Default Open Page" → "Open Page"
- "Default Capture Mode" → "Capture Mode"
- "Photo Upload" → "Upload"

### Files Modified This Session
- `ContentView.swift` - AppConfig constants, AppState capture mode, BottomMenuView updates
- `SettingsPage.swift` - App Preferences UI, CapturePreference enum, CaptureModePickerRow, About page updates
- `Theme.swift` - DateFormatting reads from UserDefaults
- `Airplane_IDApp.swift` - Upload navigation case, toast overlay
- `UploadPage.swift` - New file (placeholder)

---

### 2026-01-18 (Session 3)

## Upload Feature - Full Implementation

Complete photo upload workflow for manually creating aircraft sighting records.

### User Flow

1. **Select Photo** - Two source options:
   - Photo Library (PHPickerViewController)
   - Files App (UIDocumentPickerViewController)

2. **Enter Details** - Form with:
   - Photo preview (16:9 aspect ratio)
   - Aircraft Type (ICAO search, required)
   - Airline (airline search, optional)
   - Registration (text field, optional)
   - Spotted On (date/time picker)

3. **Scanning** (Placeholder for future AI):
   - Animated radar-style scanner with rotating sweep
   - 2.5 second delay before showing results

4. **Results & Feedback**:
   - Photo display
   - Manufacturer/Model from ICAO lookup
   - Specs: Type, Engine Type, Engine Count
   - Thumbs up/down feedback buttons
   - "Save to Hangar" button
   - "Start Over" option

### State Machine

```swift
enum UploadState {
    case selectPhoto    // Initial - show source buttons
    case enterDetails   // Photo selected - show form
    case scanning       // Processing animation (AI placeholder)
    case results        // Show results with feedback
}
```

### New Components

**PhotoServices.swift:**
- `DocumentPickerView` - UIDocumentPickerViewController wrapper for Files app import

**UploadPage.swift:**
- `UploadState` enum - 4-state workflow
- `UploadFormData` class - @Observable form data holder
- `UploadPage` view - Main upload interface
- `UploadPickerRow` - Tappable picker row (ICAO, Airline)
- `UploadTextField` - Text input with label
- `UploadDateTimeRow` - Date/time picker row
- `UploadResultRow` - Display row for specs

### ICAO Lookup Integration

When user selects an ICAO code:
- Automatically populates: manufacturer, model, icaoClass, aircraftCategoryCode, aircraftType, engineCount, engineType
- Data fetched from ICAOLookup table

### Save Workflow

1. Generate 1280x720 JPEG thumbnail
2. For Files imports: Save image to Photo Library first
3. Add photo to "Airplane-ID" album
4. Create CapturedAircraft record with:
   - All user-entered fields
   - ICAO lookup data
   - Date components
   - Thumbnail data
   - Photo library reference
   - Thumbs up/down feedback
5. Insert into SwiftData
6. Success haptic feedback
7. Reset form

### Technical Notes

- Reuses existing `ICAOSearchSheet` and `AirlineSearchSheet` from HangarPage
- Reuses `PhotoPickerView` and `ThumbnailGenerator` from PhotoServices
- Files picker uses `UTType.image` for supported types
- Haptic feedback on all interactive elements

### Files Modified
- `PhotoServices.swift` - Added DocumentPickerView, UniformTypeIdentifiers import
- `UploadPage.swift` - Complete rewrite from placeholder to full implementation

### 2026-01-18 (continued)
- Fixed UploadPage.swift UI based on user feedback:
  - Added portrait image warning (uses ThumbnailGenerator.isPortrait())
  - Created UploadSourceButton styled like SettingsRowContent (icon, title, subtitle, chevron)
  - Added photo placeholder at top (16:9 aspect ratio, darkBlue.opacity(0.3) background)
  - Made compact form layout with side-by-side pickers (ICAO/Airline, Registration/Date)
  - Added white box with blue header for Submit area (matches HomePage stat boxes)
  - Results box shows: Manufacturer/Model grouped, Type on own line, Engine info grouped
  - Thumbs up/down buttons positioned to left/right of Save button
  - Reduced upload workflow to 3 states (removed selectPhoto, starts at enterDetails)
- Fixed syntax errors: `.padding(.bottom: 25)` → `.padding(.bottom, 25)` (2 instances)

### 2026-01-18 (continued - UI polish and scanning animation)
- **Photo placeholder improvements:**
  - Darker background: changed from darkBlue.opacity(0.3) to 0.6
  - Added horizontal scanlines (1px every 4px) for video/CRT effect using Canvas
- **Orange CLEAR button:**
  - Added below Submit box, styled like Hangar page filter clear button
  - Orange background, white "CLEAR" text, Helvetica-Bold 14pt
  - Only appears when user has input (ICAO, Airline, or Registration text)
  - `hasUserInput` computed property added to UploadFormData
  - Clears all form data including photo
- **Validation popup for missing Aircraft Type:**
  - Shows "Missing Information" alert when clicking submit without ICAO
  - Message explains this helps improve AI accuracy
  - Two buttons: "Return" (stay on form) or "Process Anyway" (proceed anyway)
  - Haptics.warning() feedback on popup
- **Image scanning animation (barcode/grid scanner effect):**
  - New `imageScan` state added to UploadState enum (4 states now)
  - `ScanLinesOverlay` component: diagonal green lines (#00FF00, 2px wide, 40px spacing)
  - Lines animate from top-left to bottom-right over 1.5 seconds
  - White flash overlay for 0.5 seconds after scan completes
  - Then transitions to radar spinner "Identifying Aircraft..." screen
- **State flow:** enterDetails → imageScan → scanning → results
- Build verified in Xcode

### 2026-01-18 (continued - X-pattern scan animation, results layout)
- **X-pattern grid scan animation (replaced static lines):**
  - Sequential line drawing with 25ms delay between each line
  - Phase 1: Diagonal lines top-left → bottom-right
  - Phase 2: Diagonal lines top-right → bottom-left (creates X/grid pattern)
  - Lines are 1pt wide (reduced from 2pt), 30px spacing
  - `ScanPhase` enum: idle, topLeftToBottomRight, topRightToBottomLeft
  - `XPatternScanOverlay` component with `@State` to persist phase1 lines
  - White flash with "PROCESSED" text (40pt Helvetica-Bold, gray at 30% opacity)
  - Status text changes to "Complete!" during flash
- **Start Over button restyled:**
  - Changed from blue link text to orange box button (matches CLEAR button style)
  - Text: "START OVER", Helvetica-Bold 14pt, white on orange background
- **Results page data layout reordered:**
  - Row 1: Manufacturer | Model
  - Row 2: Registration | Classification (uses `AircraftLookup.classificationName`)
  - Row 3: Type (full width for long text like "Fixed Wing Single-Engine")
  - Row 4: Engine Type | Num Engines
  - All fields show "—" when data is missing
- Next: Build and test animation timing

### 2026-01-18 (continued - Registration validation, Category field)
- **Registration field fix:**
  - Removed "N12345" placeholder text (was showing as faint gray text)
  - TextField now has empty string placeholder
- **Validation updated:**
  - `handleSubmitTapped()` now checks for BOTH Aircraft Type AND Registration
  - Missing either triggers "Missing Information" popup
  - User can still proceed with "Process Anyway" button
- **Results page Category field added:**
  - Row 3 changed from full-width Type to Type | Category side-by-side
  - Category shows `formData.icaoClass` (LandPlane, SeaPlane, Amphibian, Helicopter, etc.)
  - Layout now: Row 1 (Mfr|Model), Row 2 (Reg|Class), Row 3 (Type|Category), Row 4 (Engine|Count)
- Next: Test validation flow and category display

### 2026-01-18 (continued - Category display name fix)
- **Fixed Category display showing "LandPlane" instead of "Land":**
  - Added `icaoClasses` dictionary to Theme.swift mapping raw values to display names
  - LandPlane → Land, SeaPlane → Sea, Amphibian → Amphibian, etc.
  - Added `AircraftLookup.icaoClassDisplayName()` function
  - Updated UploadPage.swift to use new function instead of raw `icaoClass` value
- Next: Test category display shows correct names

### 2026-01-18 (continued - HomePage recent sightings fix)
- **Fixed HomePage not showing recently added aircraft:**
  - Added `createdAt: Date` field to CapturedAircraft model for true insertion ordering
  - Field is auto-set to `Date()` in init (not user-editable)
  - Changed HomePage @Query to sort by `createdAt` instead of `captureDate`
  - This ensures last-added records appear first, regardless of user-selected date
- **Schema change:** CapturedAircraft now has `createdAt` field

### 2026-01-18 (continued - Rating validation)
- **Added thumbs up/down rating validation on save:**
  - New `showingMissingRatingAlert` state
  - `handleSaveTapped()` checks if `formData.thumbsUp == nil`
  - If no rating, shows "Rate the Results" popup
  - Buttons: "Return" (stay to rate) or "Save Anyway" (bypass)
  - Renamed `saveAircraft()` to `saveAircraftConfirmed()`
- Next: Test rating validation flow

### 2026-01-18 (continued - GPS extraction from photo metadata)
- **Implemented GPS coordinate extraction for Upload feature:**
  - Added GPS fields to UploadFormData: `gpsLatitude`, `gpsLongitude`, `hasGPS`
  - Added `imageData: Data?` field for storing raw image data (needed for EXIF extraction)

- **PhotoServices.swift additions:**
  - Already had `GPSExtractor.extractGPS(from: Data)` for EXIF extraction
  - Already had `PhotoLibraryManager.getLocation(from: localIdentifier)` for PHAsset GPS
  - Updated `DocumentPickerView` callback to return both `(UIImage, Data)` for EXIF access

- **UploadPage.swift GPS extraction:**
  - Photo Library imports: Extract GPS from PHAsset using `PhotoLibraryManager.shared.getLocation()`
  - Files app imports: Extract GPS from EXIF using `GPSExtractor.extractGPS()`
  - Portrait photo warning: Also extracts GPS when user accepts portrait photo
  - Save function: Now uses `formData.gpsLatitude/gpsLongitude` instead of hardcoded 0s
  - Debug logging: Prints extracted coordinates in DEBUG builds

- **Data flow:**
  1. User selects photo from Photo Library → GPS extracted from PHAsset.location
  2. User imports photo from Files app → GPS extracted from EXIF metadata (CGImageSource)
  3. GPS stored in UploadFormData during photo selection
  4. GPS saved to CapturedAircraft database record on save
  5. GPS coordinates available for MapsPage display

- Next: Test GPS extraction with geotagged photos

### 2026-01-18 (continued - Date extraction and layout fix)
- **Added automatic date extraction from photo metadata:**
  - Photo Library: Uses `PHAsset.creationDate` via `PhotoLibraryManager.getMetadata()`
  - Files app: Extracts from EXIF `DateTimeOriginal` or `DateTimeDigitized`
  - Renamed `GPSExtractor` to `EXIFExtractor` with combined `extractMetadata()` function
  - Added `typealias GPSExtractor = EXIFExtractor` for backward compatibility
  - Date is auto-populated when photo is selected

- **Fixed Registration field layout on smaller screens:**
  - Changed DatePicker from date+time to date-only (`displayedComponents: .date`)
  - Made date picker use `fixedSize(horizontal: true)` so it doesn't expand
  - Registration field now gets `frame(maxWidth: .infinity)` to fill remaining space
  - Removed `.scaleEffect(0.85)` from date picker (no longer needed)

- **Layout change:** Row 2 now has Registration (flexible width) + Date (fixed width, pinned right)
- Next: Test on smaller phone screens
