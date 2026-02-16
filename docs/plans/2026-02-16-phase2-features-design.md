# QR Book Phase 2 Features — Design Document

**Date:** 2026-02-16
**Status:** Approved
**Scope:** 17 new features across 5 implementation waves

---

## Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| QR Scanning | Camera only (no photo library) | Simpler, covers primary use case |
| Edit behavior | Modify in-place | Preserves scan count/history, avoids library clutter |
| QR color styling | Foreground + background color pickers | Flexible without over-engineering |
| Logo source | Photo Library pick | Maximum flexibility for users |
| Widget sizes | Small + Medium | Best coverage without lock screen complexity |
| Watch scope | View-only favorites list | High value, minimal complexity |
| Folders | Alongside existing tags | Folders for organization, tags for cross-cutting labels |
| Flyers | Template-based with QR embed | 3-5 built-in templates, export as image |
| Themes | Accent color + light/dark/system mode | 6 accent colors, appearance toggle |
| Architecture | 5 sequential waves | Respects data model dependencies, allows incremental testing |

---

## Data Model Changes

### QRCode model additions

```
New fields on QRCode (@Model):
  folderName: String       = ""     (folder assignment, empty = unfiled)
  foregroundHex: String    = ""     (custom QR foreground color, empty = default black)
  backgroundHex: String   = ""     (custom QR background color, empty = default white)
  logoImageData: Data?     = nil    (PNG data for center logo overlay)
```

All fields have CloudKit-compatible defaults.

### New Folder model

```
Folder (@Model):
  id: UUID
  name: String             (unique, max 50 chars)
  iconName: String         = "folder.fill"  (SF Symbol name)
  colorHex: String         = "7C3AED"       (accent color for folder)
  createdAt: Date
  sortOrder: Int           = 0
```

No SwiftData relationship — match `QRCode.folderName == Folder.name` to avoid CloudKit relationship issues.

### New ScanEvent model (for History)

```
ScanEvent (@Model):
  id: UUID
  qrCodeId: UUID           (links to QRCode.id)
  timestamp: Date
```

Lightweight log table. One row per fullscreen view event, linked by UUID.

### UserDefaults additions (for Themes)

```
@AppStorage keys:
  "accentColorHex"         default: "7C3AED" (electric violet)
  "appearanceMode"         default: "dark"   (system/light/dark)
```

---

## Wave 1: Data Model & Theme Foundations

### Themes (#20)

**Accent colors:**

| Name | Hex |
|------|-----|
| Violet (default) | #7C3AED |
| Indigo | #4F46E5 |
| Teal | #14B8A6 |
| Rose | #F43F5E |
| Orange | #F97316 |
| Mono | #6B7280 |

**Implementation:**
- `Color.electricViolet` becomes computed, reads `@AppStorage("accentColorHex")`
- `Color.deepIndigo` derives from accent via companion color map
- `Color.appBg` switches based on `appearanceMode` (system/light/dark)
- New "Appearance" section in Settings: horizontal scroll of color circles + light/dark/system segmented control
- `.preferredColorScheme` in `QRBookApp.swift` reads from AppStorage

### Custom QR Colors (#5)

- Two `ColorPicker` controls in Advanced Options section of CreateQRView/EditQRView
- Default: empty strings = standard black-on-white
- `QRGenerator` updated to apply `CIFalseColor` filter for tinting
- Live preview in creation form

### Logo Overlay (#6)

- "Add Logo" button in Advanced Options, triggers `PhotosPicker` (PhotosUI)
- Image cropped to square, resized to ~20% of QR size, stored as PNG Data
- `QRGenerator` composites logo centered on QR after generation
- Error correction auto-bumps to Q or H when logo present
- Clear/remove button when logo is set

### Folders (#9)

- New `Folder` model (see data model section)
- Horizontal scroll of folder chips at top of QRLibraryView ("All" first, then folders, then "+ New Folder")
- Folder picker in CreateQRView/EditQRView, also via context menu "Move to Folder..."
- Manage Folders screen in Settings: rename, reorder, delete, change icon/color

---

## Wave 2: Core UX Features

### Edit QR (#2)

- "Edit" option in QRCardView context menu
- `EditQRView` reuses CreateQRView form components, pre-populated
- New `QRDataDecoder` utility: reverse of `QRDataEncoder` — parses WiFi, vCard, iCal, payment data back into form structs
- Updates record in-place (updatedAt refreshed, scanCount/createdAt preserved)
- Presented as sheet from library or fullscreen view

### Duplicate QR (#3)

- "Duplicate" option in QRCardView context menu
- Creates new QRCode with same fields except: new UUID, title + " (Copy)", scanCount = 0, fresh timestamps
- Inserts immediately, no form shown
- Success haptic + brief confirmation

### Haptic Feedback (#4)

- `HapticManager` utility with static methods:
  - `.impact()` — `UIImpactFeedbackGenerator(.medium)` — on save, duplicate, favorite toggle, delete
  - `.success()` — `UINotificationFeedbackGenerator(.success)` — on save to photos, bulk import, scan success
  - `.selection()` — `UISelectionFeedbackGenerator` — on tab switch, filter/sort changes

### Batch Operations (#15)

- "Select" button in library toolbar toggles multi-select mode
- Checkbox overlay on each QRCardView in select mode
- Bottom toolbar: Delete, Move to Folder, Add Tag, Export
- Select All / Deselect All in toolbar
- Confirm destructive actions with alert

---

## Wave 3: Scanner & Share Extension

### QR Code Scanner (#1)

- New "Scan" tab in MainTabView (5th tab position: Library | Scan | Favorites | Recent | Flyers)
- `ScannerView` wraps `DataScannerViewController` (VisionKit) via `UIViewControllerRepresentable`
- Recognizes `.barcode(symbologies: [.qr])`
- On detection: haptic, bottom sheet with decoded data, auto-detected type
- Bottom sheet actions: "Save to Library" (opens pre-filled CreateQRView), "Copy", "Open" (URLs)
- `NSCameraUsageDescription` in Info.plist
- Permission denied state with "Open Settings" button

### Share Extension (#13)

- New Share Extension target: `QRBookShareExtension`
- Accepts: `public.url` and `public.plain-text`
- Compact SwiftUI UI: shared text/URL, title field, "Save as QR" button
- Uses App Group (`group.com.gyndok.QRBook`) — writes JSON to shared container
- Main app checks for pending imports on launch/foreground, ingests into SwiftData
- Avoids sharing SwiftData store across processes

---

## Wave 4: System Integrations

### Quick Actions (#10)

- 3 static home screen shortcuts via Info.plist:
  - "Create QR" (`plus.circle.fill`) → Create tab
  - "Scan QR" (`camera.viewfinder`) → Scan tab
  - "Favorites" (`star.fill`) → Favorites tab
- `@Observable DeepLinkRouter` handles navigation, observed by MainTabView

### Spotlight Search (#11)

- `SpotlightIndexer` utility using `CSSearchableIndex` (CoreSpotlight)
- Methods: `indexQRCode`, `removeQRCode`, `reindexAll`
- Index on create/edit/duplicate, remove on delete
- Handle tap via `onContinueUserActivity(CSSearchableItemActionType)` → fullscreen view
- `DeepLinkRouter` gains `showQRCode(id: UUID)` action

### Siri Shortcuts (#12)

- `AppShortcutsProvider` with App Intents framework:
  - `ShowQRCodeIntent` — parameter: QR title (entity query), opens fullscreen
  - `CreateQRCodeIntent` — opens Create tab
- `QRCodeEntity` conforms to `AppEntity` with title-based `EntityQuery`
- Navigation intents only, no data mutation via Siri

### QR History (#14)

- Log `ScanEvent` on each fullscreen view (alongside existing scanCount increment)
- History view: timeline list with relative timestamps, summary stats
- Accessible via context menu "View History" or info button in fullscreen
- "Clear All History" option in Settings > Data Management

---

## Wave 5: New Targets

### Widgets (#7)

- Widget Extension target: `QRBookWidget`
- App Group (`group.com.gyndok.QRBook`) for data sharing
- Main app writes `widget-data.json` to App Group on create/edit/delete/favorite changes
- `WidgetCenter.shared.reloadAllTimelines()` on each write

**Small widget (systemSmall):**
- Single QR code display, title below
- Tap opens fullscreen via deep link
- Configurable via `SelectQRCodeIntent`

**Medium widget (systemMedium):**
- QR on left (~40%), title + type icon + tags on right
- Tap opens fullscreen
- Configurable via `SelectQRCodeIntent`

### Apple Watch (#8)

- watchOS App target: `QRBookWatch`
- Watch Connectivity (`WCSession`) syncs favorites from iPhone
- iPhone sends favorites (title, data, type, colors) on changes
- Watch stores in local JSON file (no SwiftData on watch)
- Watch UI: `NavigationStack` > `List` of favorites > tap for fullscreen QR
- QR generated on-watch via CoreImage, max brightness on display
- View-only, no creation/editing/scanning

### Flyers (#16)

- `Views/Flyers/` directory in main target (not a separate extension)
- Replaces "Coming Soon" placeholder

**Templates:**

| Template | Layout |
|----------|--------|
| Clean | Centered QR, title above, subtitle below, solid background |
| Banner | QR right, large title left, accent stripe |
| Poster | Large QR centered, bold title top, CTA bottom, gradient bg |
| Minimal | Small QR bottom-right, title top-left, whitespace |
| Card | Horizontal card, QR left, text right, rounded corners |

**Flow:**
1. Pick template (visual preview grid)
2. Pick QR code from library (or create new)
3. Edit text fields (title, subtitle, CTA — varies by template)
4. Pick background/accent color
5. Preview
6. Export as PNG via `ImageRenderer` → share sheet or save to Photos

No persistence for flyer configs — generated and exported on-the-fly.

---

## New Project Structure

```
QRBook/
├── QRBookApp.swift                    (edit: deep link handling, appearance mode)
├── Models/
│   ├── QRCode.swift                   (edit: new fields)
│   ├── Folder.swift                   (new)
│   └── ScanEvent.swift                (new)
├── ViewModels/
│   ├── QRLibraryViewModel.swift       (edit: folder filter, batch select)
│   ├── QRCreationViewModel.swift      (edit: colors, logo, folder)
│   └── DeepLinkRouter.swift           (new)
├── Views/
│   ├── MainTabView.swift              (edit: Scan tab, deep link routing)
│   ├── SplashView.swift
│   ├── Library/
│   │   ├── QRLibraryView.swift        (edit: folders bar, batch mode)
│   │   ├── QRCardView.swift           (edit: edit/duplicate/move context menu, batch checkbox)
│   │   └── QRFilterSheet.swift
│   ├── Creation/
│   │   ├── CreateQRView.swift         (edit: colors, logo, folder picker)
│   │   ├── EditQRView.swift           (new)
│   │   ├── WiFiFormView.swift
│   │   ├── ContactFormView.swift
│   │   ├── CalendarFormView.swift
│   │   └── PaymentFormView.swift
│   ├── Scanner/
│   │   └── ScannerView.swift          (new)
│   ├── Fullscreen/
│   │   ├── QRFullscreenView.swift     (edit: edit button, history)
│   │   └── QRHistoryView.swift        (new)
│   ├── Folders/
│   │   └── ManageFoldersView.swift    (new)
│   ├── Flyers/
│   │   ├── FlyerGalleryView.swift     (new)
│   │   ├── FlyerEditorView.swift      (new)
│   │   └── FlyerTemplates.swift       (new)
│   └── Settings/
│       ├── SettingsView.swift         (edit: appearance, manage folders, clear history)
│       ├── AppearanceSettingsView.swift (new)
│       └── BulkImportView.swift
├── Utilities/
│   ├── QRGenerator.swift              (edit: color tinting, logo compositing)
│   ├── QRDataEncoder.swift
│   ├── QRDataDecoder.swift            (new)
│   ├── Validation.swift
│   ├── BulkImportService.swift
│   ├── HapticManager.swift            (new)
│   ├── SpotlightIndexer.swift         (new)
│   └── WatchConnector.swift           (new)
├── Intents/
│   ├── AppShortcuts.swift             (new)
│   ├── ShowQRCodeIntent.swift         (new)
│   └── CreateQRCodeIntent.swift       (new)
├── Resources/
│   └── Assets.xcassets
├── Theme/
│   └── AppTheme.swift                 (edit: dynamic accent, appearance mode)
├── QRBookShareExtension/              (new target)
│   ├── ShareViewController.swift
│   └── Info.plist
├── QRBookWidget/                      (new target)
│   ├── QRBookWidget.swift
│   ├── SelectQRCodeIntent.swift
│   └── Info.plist
└── QRBookWatch/                       (new target)
    ├── QRBookWatchApp.swift
    ├── FavoritesListView.swift
    ├── WatchQRFullscreenView.swift
    └── Info.plist
```
