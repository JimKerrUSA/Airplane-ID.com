# Airplane-ID Project Context

## Project Overview
An iOS app for identifying and tracking aircraft. The app uses a custom navigation system with a prominent camera button and displays user statistics and progress.

## Architecture Overview

### Three Template System
The app is designed to work in three orientations, each with its own template:

1. **Portrait** (`HomePagePortrait`) - ✅ Currently in development
   - Vertical layout optimized for phone portrait mode
   - Uses `TopMenuView` (header) and `BottomMenuView` (footer)

2. **Landscape Left** (`HomePageLeftHorizontal`) - 📋 Not started
   - Horizontal layout for left landscape orientation
   - Uses reduced-height header (85px vs 140px portrait)
   - Footer menu positioned on LEFT SIDE (vertical layout)
   - Icons in footer rotated to be upright
   - "Latest Sightings" replaces "Recent Finds" box
   - Content arranged horizontally to utilize width

3. **Landscape Right** (`HomePageRightHorizontal`) - 📋 Not started
   - Horizontal layout for right landscape orientation
   - Uses reduced-height header (85px vs 140px portrait)
   - Footer menu positioned on RIGHT SIDE (vertical layout)
   - Icons in footer rotated to be upright
   - "Latest Sightings" replaces "Recent Finds" box
   - Content arranged horizontally to utilize width

### Global Reusable Components

#### Top Header Menu (`TopMenuView`)
- **Current Version**: Portrait only (140px height)
- **Location**: ContentView.swift
- **Features**:
  - Search bar with magnifying glass icon
  - User status indicator (shows "EXPERT" with person icon)
  - Dark blue background (#082A49)
- **Versions**:
  - **Portrait**: 140px height
  - **Landscape** (Left & Right): 85px height, spans edge-to-edge
  - Same content arrangement (search bar center, status right)

#### Bottom Footer Menu (`BottomMenuView`)
- **Current Version**: Portrait only (bottom-positioned)
- **Location**: ContentView.swift
- **Features**:
  - Navigation with 5 sections: Home, Hangar, Camera, Maps, Settings
  - Center camera button (100px circle) with icon that changes based on `captureMode`
  - Dark blue navigation bar (#082A49)
- **Versions**:
  - **Portrait**: Bottom-positioned, horizontal layout, 100px height, -5px padding
  - **Landscape Left**: Left side-positioned, vertical layout, icons rotated upright
  - **Landscape Right**: Right side-positioned, vertical layout, icons rotated upright
- **Future Implementation**: Create separate `BottomMenuViewLandscapeLeft` and `BottomMenuViewLandscapeRight`

### Orientation System (`OrientationAwarePage`)
- Automatically detects device orientation using GeometryReader
- Routes content to appropriate template (Portrait, Left, or Right)
- Currently defaults to Left template for all landscape orientations
- Located in ContentView.swift

## Global Variables (AppState)

The `AppState` class (marked with `@Observable`) contains all global application state. Located in `ContentView.swift`:

```swift
@Observable
class AppState {
    var status: String = "EXPERT"
    var search: String = ""
    var captureMode: String = "camera"
    var totalAircraftCount: Int = 1234
    var totalTypes: Int = 142
    var levelProgress: Double = 0.78
}
```

### Variable Details

| Variable | Type | Current Value | Purpose | Usage |
|----------|------|---------------|---------|-------|
| `status` | String | "EXPERT" | User's current level/rank | Displayed in TopMenuView header with person icon |
| `search` | String | "" | Search bar text input | Bound to TextField in TopMenuView search bar |
| `captureMode` | String | "camera" | Camera/photo mode selector | Changes icon in center button of BottomMenuView. Options: "camera" or "photo.stack" |
| `totalAircraftCount` | Int | 1234 | Total aircraft identified by user | Displayed in first data box (HomePage), formatted with commas |
| `totalTypes` | Int | 142 | Total unique aircraft types found | Displayed in second data box (HomePage), formatted with commas |
| `levelProgress` | Double | 0.78 | Progress to next level (0.0-1.0) | Controls progress bar width (78% = 244px of 313px bar) |

### How Variables Are Used

1. **status**: 
   - Displayed in top-right of header
   - Shows user's expertise level (e.g., "EXPERT", "ACE", etc.)
   - Could be used for unlocking features or content

2. **search**:
   - Two-way binding with search TextField
   - Will be used to filter aircraft database
   - Updates in real-time as user types

3. **captureMode**:
   - Toggles between camera modes
   - "camera" = Show camera icon in center button
   - "photo.stack" = Show photo stack icon in center button
   - Likely toggles between live camera capture vs photo library

4. **totalAircraftCount**:
   - Tracks total number of individual aircraft spotted/identified
   - Displayed with gold color (#FBBD1C) and comma formatting
   - Currently placeholder value (1234)

5. **totalTypes**:
   - Tracks unique aircraft types (models) identified
   - Different from totalAircraftCount (can see same type multiple times)
   - Displayed with gold color (#FBBD1C) and comma formatting
   - Currently placeholder value (142)

6. **levelProgress**:
   - Range: 0.0 (0%) to 1.0 (100%)
   - Dynamically updates progress bar in "Progress to ACE" box
   - Visual feedback for user advancement
   - Tested and verified at multiple values (43%, 78%)

## Design System

### Color Palette
- **Primary Blue Background**: `#1D58A4` - Main app background
- **Dark Blue (Headers/Nav)**: `#082A49` - Top/bottom menus, box headers
- **White**: `#FFFFFF` - Data box backgrounds, text, camera button
- **Border Blue**: `#124A93` - Box borders (1px)
- **Yellow/Gold (Numbers)**: `#FBBD1C` - All numeric displays
- **Progress Bar Blue**: `#2B81C5` - Completed portion of progress bar
- **Progress Bar Gray**: `#B9C6D1` - Incomplete portion of progress bar
- **Dark Gray (Camera Icon)**: `#3A3A3C` - Icon inside camera button
- **Border Gray (Camera)**: `#313131` - Camera button border (5px)
- **Black**: `#000000` - Progress bar border, text shadows

### Spacing & Layout
- **Box Spacing**: 13px between all content boxes
- **Corner Radius**: 10px for all rounded corners
- **Border Width**: 1px for borders (except camera: 5px)
- **Footer Position**: -5px bottom padding (extends slightly into safe area)
- **Top Box Padding**: 13px from top menu to first content box

### Typography
- **Headers**: 26pt, Bold, White with 4-direction black shadow
- **Numbers**: 40pt, Regular, Gold (#FBBD1C) with 4-direction black shadow
- **Navigation Labels**: 12pt, Regular, White
- **Icons**: 35pt (navigation), 45pt (status icon), 30pt (search icon)

### Component Dimensions

#### Top Menu (`TopMenuView`)
- **Portrait**: 140px height
- **Landscape**: 85px height (reduced for space efficiency)
- Search Bar: 240w x 50h, 10px corner radius (portrait), will need to scale for landscape
- Status Icon: 45pt with label below
- Background: Dark Blue (#082A49)
- Layout: Search bar centered, Status indicator top-right

#### Bottom Navigation (`BottomMenuView`)
- **Portrait Mode**:
  - Position: Bottom of screen, horizontal layout
  - Total Height: 100px
  - Navigation Bar: 385w x 65h, 50px corner radius
  - Camera Button: 100w x 100h (circle), 5px gray border
  - Icon Spacing: 4px between icon and label
  - Sections: Left (142.5px), Center (100px), Right (142.5px)
  - Padding: -5px bottom
- **Landscape Mode (Left & Right)**:
  - Position: LEFT or RIGHT edge, vertical layout
  - Icons rotated to be upright
  - Camera button stays at center of vertical menu
  - Order (top to bottom): Settings, Maps, Camera, Hangar, Home (for LEFT)
  - Order (top to bottom): Home, Hangar, Camera, Maps, Settings (for RIGHT)
  - Width: TBD
  - Background: Dark Blue (#082A49)

#### Data Boxes (Top Two - Portrait)
- Left Section: 125w x 106h (Dark Blue, text right-aligned)
- Right Section: 222w x 106h (White, number centered)
- Total Width: 347px
- Corner Radius: 10px (selective corners)

#### Progress Box (Portrait)
- Header: 347w x 39h (Dark Blue, rounded top corners)
- Content: 347w x 56h (White with 1px blue border, rounded bottom corners)
- Progress Bar: 313w x 25h, 1px black border
- Progress calculation: `width = 313 * levelProgress`

#### Recent Finds Box (Portrait)
- Header: 347w x 39h (Dark Blue, rounded top corners)
- Content: 347w x 211h (White with 1px blue border, rounded bottom corners)
- Content: To be implemented

#### Latest Sightings Box (Landscape Left & Right)
- Replaces "Recent Finds" in landscape orientations
- Header: "Latest Sightings" (Dark Blue, rounded top corners)
- Content: White box with 1px blue border, rounded bottom corners
- Shows list of aircraft with icons:
  - CESSNA C172
  - GULFSTREAM G700
  - HONDA JET HA420
  - UAL BOEING 777-300ER
- Orange airplane icons before each entry
- Dimensions: TBD based on available space

## Key Design Decisions

### 1. SwiftUI Native Implementation
- **Decision**: Replaced UIKit types (`UIRectCorner`, `UIBezierPath`) with pure SwiftUI implementation
- **Reason**: System crashed due to UIKit/SwiftUI incompatibility
- **Solution**: Created custom `RectCorner` OptionSet and `RoundedCorner` Shape using SwiftUI Path
- **Impact**: Works seamlessly across all Apple platforms

### 2. Custom Rounded Corners
- Implemented selective corner rounding (top-only, bottom-only, specific corners)
- Used for data boxes, headers, and bordered sections
- Ensures consistent visual hierarchy
- Created `RectCorner` with options: `.topLeft`, `.topRight`, `.bottomLeft`, `.bottomRight`, `.allCorners`

### 3. Progress Bar System
- **Dynamic**: Automatically updates based on `levelProgress` variable
- **Visual**: Shows completion percentage with color-coded sections
- **Calculation**: Width = `313 * levelProgress`
- **Tested**: Verified at 43% and 78% to ensure accuracy
- **Method**: Uses ZStack with background rectangle and overlaid progress rectangle

### 4. Number Formatting
- All numeric displays use comma formatting via `formatNumber()` function
- Handles values above 999 automatically
- Example: 1234 displays as "1,234"
- Uses `NumberFormatter` with `.decimal` style

### 5. Footer Positioning
- **Final Setting**: `.padding(.bottom, -5)`
- **Reason**: Provides optimal visual positioning near bottom of screen
- **Note**: Extends slightly into safe area but doesn't interfere with system UI
- **Alternatives Tested**: 
  - Positive padding (2px, 3px, 6px) - didn't look right
  - Offset (y: -3) - moved wrong direction
  - Negative padding worked best for visual appeal

### 6. Text Styling with Shadows
- Headers: 26pt bold, white with black shadow (4-direction stroke effect)
- Numbers: 40pt regular, gold (#FBBD1C) with black shadow (4-direction stroke effect)
- Shadow technique: 4 shadows at (±1, ±1) creates outline effect for legibility
- Consistent across all text for depth and readability

### 7. Three-Template Approach
- **Decision**: Build separate templates for Portrait, Landscape Left, and Landscape Right
- **Reason**: Optimal user experience requires different layouts per orientation
- **Status**: Portrait complete, landscapes pending
- **Key Differences**:
  - **Portrait**: Bottom menu (horizontal), 140px header, "Recent Finds" box
  - **Landscape Left**: Left side menu (vertical, upright icons), 85px header, "Latest Sightings" box
  - **Landscape Right**: Right side menu (vertical, upright icons), 85px header, "Latest Sightings" box
- **Implementation Notes**:
  - Header height reduces from 140px to 85px in landscape
  - Footer changes from horizontal bottom bar to vertical side bar
  - Icons in side menu rotate to stay upright
  - Content boxes rearrange horizontally to utilize width
  - "Recent Finds" becomes "Latest Sightings" with different content layout

## File Structure

### Core Files
- `Airplane_IDApp.swift` - App entry point, initializes AppState and ModelContainer
- `ContentView.swift` - Global AppState, templates, reusable components (TopMenuView, BottomMenuView)
- `HomePage.swift` - Main home screen implementation with all data boxes
- `Item.swift` - SwiftData model (placeholder for future data models)

### Templates (in ContentView.swift)
- `PageTemplate` - Basic template with top/bottom menus (used for simple pages)
- `HomePagePortrait` - ✅ Portrait orientation layout (ACTIVE)
- `HomePageLeftHorizontal` - 📋 Left landscape layout (PLACEHOLDER)
- `HomePageRightHorizontal` - 📋 Right landscape layout (PLACEHOLDER)
- `OrientationAwarePage` - Automatic orientation detection and template routing

### Reusable Components (in ContentView.swift)
- `TopMenuView` - Global header with search and status
- `BottomMenuView` - Global footer with navigation
- `RoundedCorner` - Custom Shape for selective corner rounding
- `RectCorner` - OptionSet for corner selection
- `Color(hex:)` - Extension for hex color support
- `View.cornerRadius(_:corners:)` - Extension for selective corner rounding

### Helper Functions (in HomePage.swift)
- `formatNumber(_ number: Int) -> String` - Formats integers with comma separators

## Current Status

### HomePage Portrait - IN PROGRESS ✅

**Completed:**
- [x] Top data box: "Total Aircraft Found" displaying `totalAircraftCount` (1,234)
- [x] Second data box: "Total Aircraft Types" displaying `totalTypes` (142)
- [x] Progress box: "Progress to ACE" with dynamic progress bar (78%)
- [x] Bottom box: "Recent Finds" structure (347x250 total)
- [x] All spacing set to 13px between boxes
- [x] All number formatting working with commas
- [x] Progress bar tested and verified at multiple percentages

**Pending:**
- [ ] Recent Finds content implementation (what to show in the white area)
- [ ] Navigation button functionality (tap handlers)
- [ ] Search functionality implementation
- [ ] Camera/photo mode toggle functionality

### Landscape Orientations - NOT STARTED 📋

**Landscape Left:**
- [ ] Create landscape header with 85px height
- [ ] Create left-side vertical footer menu with upright icons
- [ ] Rearrange data boxes horizontally
- [ ] Implement "Latest Sightings" box with aircraft list
- [ ] Test icon rotation and layout
- [ ] Icon order (top to bottom): Settings, Maps, Camera, Hangar, Home

**Landscape Right:**
- [ ] Create landscape header with 85px height (can share with left)
- [ ] Create right-side vertical footer menu with upright icons
- [ ] Rearrange data boxes horizontally (can share with left)
- [ ] Implement "Latest Sightings" box with aircraft list (can share with left)
- [ ] Test icon rotation and layout
- [ ] Icon order (top to bottom): Home, Hangar, Camera, Maps, Settings

## Testing Notes
- ✅ Progress bar tested at 43% and 78% - works correctly
- ✅ Footer positioning tested with padding values: 1, 2, 3, 6, -2, -5
- ✅ Footer positioning tested with offset - didn't work as expected
- ✅ All spacing verified at 13px between boxes
- ✅ Number formatting verified with 3-digit (142) and 4-digit (1,234) values
- ✅ Custom rounded corners working on all boxes
- ✅ UIKit to SwiftUI conversion successful - no crashes

## Known Issues
- None currently

## Next Steps

### Immediate (Portrait):
1. Design and implement "Recent Finds" content
2. Add tap handlers for navigation buttons
3. Implement search functionality
4. Implement camera mode toggle

### Short Term (Landscape):
1. Design landscape layout mockups
2. Build landscape-specific header menu
3. Build left and right footer menus
4. Adapt HomePage content for landscape layouts

### Long Term:
1. Connect to actual aircraft database
2. Implement camera capture functionality
3. Build additional pages (Hangar, Maps, Settings)
4. Replace placeholder data with real user data
5. Implement level progression system

## Development Environment
- Platform: iOS
- Framework: SwiftUI
- Data: SwiftData
- Minimum Target: iOS 17+ (uses @Observable macro)
- Language: Swift

## Questions & Clarifications

### Answered:
- ✅ **Landscape footers**: Will be on LEFT or RIGHT sides (vertical layout with upright icons)
- ✅ **Landscape header**: Stays at top but reduces from 140px to 85px height
- ✅ **Landscape content**: Data boxes arrange horizontally, "Recent Finds" becomes "Latest Sightings"
- ✅ **Latest Sightings**: Shows list of aircraft names with orange airplane icons

### Still Need Clarification:
- **Q**: Exact width for landscape side menus?
- **Q**: Exact dimensions for landscape data boxes?
- **Q**: Should "Latest Sightings" aircraft be clickable/tappable?
- **Q**: How are aircraft added to "Latest Sightings" list? (Most recent? Favorites?)
- **Q**: Should navigation buttons show active state when on that page?
- **Q**: What happens when camera button is tapped?
- **Q**: Progress bar dimensions in landscape - same as portrait or adjusted?

---
*Last Updated: January 15, 2026*
*Project Started: January 15, 2026*
