# QR Book — Pre-Launch Polish & Completion Prompt for Claude Code

**Repo:** https://github.com/gyndok/QRBook
**Location:** `/Users/gyndok/Developer/QRBook/`
**Platform:** iOS 17+ · SwiftUI · SwiftData · CloudKit
**Architecture:** MVVM, pure Apple frameworks, no external dependencies
**Targets:** QRBook (main), QRBookShareExtension, QRBookWidget, QRBookWatch Watch App

---

## Context

QR Book is a native iOS QR code library app. Phase 1 (core library, creation, fullscreen display, settings) and Phase 2 (17 features across 5 waves: themes, core UX, scanner, system integrations, widgets/watch/flyers) are largely implemented across 41 commits. The app needs pre-launch polish and completion of any gaps before App Store submission.

**Before making any changes, do a full audit:** Clone the repo, examine the current file tree, build the project, and identify what exists vs what's missing or broken. Then proceed through the tasks below in order.

---

## Task 0: Audit & Build Verification

1. Run `xcodebuild -scheme QRBook -project QRBook.xcodeproj -destination 'platform=iOS Simulator,name=iPhone 16,OS=latest' build 2>&1` and fix ALL warnings and errors.
2. List every Swift file in the project, grouped by target.
3. Compare against the Phase 2 design doc file tree (below) and flag anything missing or stubbed out.
4. Fix any build errors before proceeding.

**Expected file tree (main target):**
```
QRBook/
├── QRBookApp.swift
├── Models/
│   ├── QRCode.swift
│   ├── Folder.swift
│   └── ScanEvent.swift
├── ViewModels/
│   ├── QRLibraryViewModel.swift
│   ├── QRCreationViewModel.swift
│   └── DeepLinkRouter.swift
├── Views/
│   ├── MainTabView.swift
│   ├── SplashView.swift
│   ├── Library/
│   │   ├── QRLibraryView.swift
│   │   ├── QRCardView.swift
│   │   └── QRFilterSheet.swift
│   ├── Creation/
│   │   ├── CreateQRView.swift
│   │   ├── EditQRView.swift
│   │   ├── WiFiFormView.swift
│   │   ├── ContactFormView.swift
│   │   ├── CalendarFormView.swift
│   │   └── PaymentFormView.swift
│   ├── Scanner/
│   │   └── ScannerView.swift
│   ├── Fullscreen/
│   │   ├── QRFullscreenView.swift
│   │   └── QRHistoryView.swift
│   ├── Folders/
│   │   └── ManageFoldersView.swift
│   ├── Flyers/
│   │   ├── FlyerGalleryView.swift
│   │   ├── FlyerEditorView.swift
│   │   └── FlyerTemplates.swift
│   └── Settings/
│       ├── SettingsView.swift
│       ├── AppearanceSettingsView.swift
│       └── BulkImportView.swift
├── Utilities/
│   ├── QRGenerator.swift
│   ├── QRDataEncoder.swift
│   ├── QRDataDecoder.swift
│   ├── Validation.swift
│   ├── BulkImportService.swift
│   ├── HapticManager.swift
│   ├── SpotlightIndexer.swift
│   └── WatchConnector.swift
├── Intents/
│   ├── AppShortcuts.swift
│   ├── ShowQRCodeIntent.swift
│   └── CreateQRCodeIntent.swift
├── Theme/
│   └── AppTheme.swift
└── Resources/
    └── Assets.xcassets
```

---

## Task 1: StoreKit 2 Freemium / PRO Unlock

This is critical for monetization. Implement a one-time $6.99 PRO In-App Purchase.

### Free Tier Limits
- Maximum 15 QR codes
- Only URL and Text types available
- No iCloud sync
- No custom QR colors or logo overlay
- No folders
- No batch operations
- No flyer export

### PRO Unlock (Product ID: `com.gyndok.qrbook.pro`)
- Unlimited QR codes
- All 11 QR types (WiFi, Contact, Calendar, Venmo, PayPal, CashApp, Zelle, Crypto, File)
- iCloud sync enabled
- Custom QR colors + logo overlay
- Folders
- Batch operations
- Flyer export

### Implementation

1. **Create `QRBook/Store/StoreManager.swift`** — `@Observable` class using StoreKit 2 (`Product`, `Transaction`):
   - `var isProUnlocked: Bool` (computed from transaction history)
   - `func purchase()` — buy PRO
   - `func restorePurchases()` — restore for new devices
   - `func checkEntitlement()` — verify on launch via `Transaction.currentEntitlements`
   - Listen for transaction updates with `Transaction.updates`

2. **Create `QRBook/Store/PaywallView.swift`** — shown when user hits a PRO gate:
   - Feature comparison (Free vs PRO)
   - $6.99 one-time purchase button (pull price from StoreKit, don't hardcode)
   - "Restore Purchases" link
   - Dismiss button
   - Match the app's violet/indigo theme

3. **Create `QRBook/Store/StoreKit.storekit`** — StoreKit configuration file for testing:
   - Product: `com.gyndok.qrbook.pro`, Non-Consumable, $6.99

4. **Gate PRO features throughout the app:**
   - `CreateQRView`: If not PRO and type is not URL/Text, show paywall
   - `QRLibraryView`: If not PRO and count >= 15, show paywall on "+" tap
   - `CreateQRView` Advanced Options: Hide color pickers and logo picker if not PRO
   - Folder creation: Gate behind PRO
   - Batch operations toolbar: Gate behind PRO
   - Flyer export: Gate behind PRO
   - Show a subtle "PRO" badge on locked features in the UI

5. **Add to SettingsView:**
   - "QR Book PRO" section showing current status
   - Purchase button if free, "PRO Unlocked ✓" if purchased
   - "Restore Purchases" button

### Developer Bypass (Hidden PRO Unlock)

Add a hidden developer unlock so the app creator doesn't have to purchase their own IAP:

1. In `SettingsView`, make the version number (`LabeledContent("Version", value: "1.0.0")`) respond to a **triple-tap gesture**.
2. On triple-tap, show a `SecureField` alert prompting for a code.
3. If the code matches a hardcoded string (use `"qrbook2026"`), set `@AppStorage("devUnlock")` to `true`.
4. In `StoreManager`, the entitlement check becomes:
   ```swift
   var isProUnlocked: Bool {
       UserDefaults.standard.bool(forKey: "devUnlock") || hasStoreKitEntitlement
   }
   ```
5. When `devUnlock` is true, show "PRO Unlocked (Developer)" in the Settings PRO section instead of the purchase button. No visible indication anywhere else.
6. A triple-tap on the same version label when already unlocked should offer to reset (disable dev unlock) for testing the free tier.

### Important
- Use StoreKit 2 APIs only (no original StoreKit)
- Test with StoreKit configuration file in Xcode
- Handle edge cases: no network, purchase pending, refunded
- `StoreManager` should be injected via `.environment()` from `QRBookApp`

---

## Task 2: Export Library as JSON

Add a matching export to complement the existing bulk import feature.

1. In `SettingsView` under the Data section, add "Export Library as JSON" button.
2. Export format should match the bulk import template structure exactly — so exported JSON can be re-imported.
3. Include `_template_info` section in the export.
4. Use `UIActivityViewController` for sharing (same pattern as existing PNG export).
5. Filename: `QRBook-Export-YYYY-MM-DD.json`

---

## Task 3: App Store Metadata Assets

### Privacy Policy
1. Create `QRBook/Resources/privacy-policy.html` — a simple privacy policy page:
   - App name: QR Book
   - Developer: Geffrey Klein
   - No data collection, no analytics, no tracking
   - QR codes stored locally and in user's private iCloud container
   - No third-party services
   - Contact: include a placeholder email

### App Description (create as `docs/appstore-metadata.md`)

```
App Name: QR Book — QR Code Library
Subtitle: Create, Organize & Display QR Codes

Keywords: qr code, qr library, qr generator, qr scanner, icloud sync, qr organizer, medical forms, consent forms, wifi qr, payment qr

Category: Productivity (primary), Utilities (secondary)

Description:
[Write a compelling 4000-char max App Store description. Hit these points:]
- The QR library for people who use QR codes every day
- Create 11 types: URL, Text, WiFi, Contact, Calendar, Venmo, PayPal, CashApp, Zelle, Crypto, File links
- Organize with folders, tags, search, and filters
- Fullscreen display with automatic brightness boost
- iCloud sync across all your devices — no account needed
- One-time purchase, no subscriptions, no ads
- QR scanner built in
- Custom QR colors and logo overlay
- Flyer templates for printing
- Apple Watch companion for quick access to favorites
- Home screen widgets
- Siri Shortcuts and Spotlight search
- Perfect for medical offices, small businesses, and power users
- Built with SwiftUI, runs entirely on-device

Promotional Text (170 chars, can be updated without review):
[Write promotional text emphasizing the one-time purchase angle]

What's New (Version 1.0):
[Write initial release notes]
```

---

## Task 4: README for GitHub

Create a proper `README.md` in the repo root:
- App name, icon placeholder, one-line description
- 3-4 feature highlights with SF Symbol-style emoji
- Screenshots section (placeholder paths)
- Tech stack badges (SwiftUI, SwiftData, CloudKit, iOS 17+)
- Architecture overview (MVVM, no external dependencies)
- Build instructions
- License section (proprietary / all rights reserved)
- Link to App Store (placeholder)

---

## Task 5: Accessibility & Polish Pass

1. **VoiceOver:** Audit every view for accessibility labels. Key areas:
   - QRCardView: label should read title, type, and scan count
   - QR fullscreen: announce QR code title, swipe navigation hints
   - Tab bar items: proper labels
   - Color pickers: descriptive labels
   - Paywall: all buttons labeled

2. **Dynamic Type:** Ensure all text uses system fonts and scales properly. Test with largest accessibility sizes — nothing should truncate or overlap.

3. **Empty States:** Verify every tab has a proper empty state:
   - Library: "No QR codes yet — tap + to create your first"
   - Favorites: "No favorites yet — star a QR code to see it here"
   - Recent: "No recent activity"
   - Flyers: Should work without QR codes (prompt to create one)

4. **Error Handling:**
   - Camera permission denied → clear message + "Open Settings" button
   - iCloud not signed in → graceful degradation message in Settings
   - QR generation failure → user-facing error, not a crash
   - Bulk import with invalid JSON → specific error message

5. **iPad Support:** Ensure the app runs acceptably on iPad (even if not optimized). No crashes, reasonable layout. NavigationSplitView where appropriate.

6. **Haptics Audit:** Verify HapticManager is called on:
   - Save/create QR code (success)
   - Delete (impact)
   - Favorite toggle (selection)
   - Scan detection (success)
   - Bulk import complete (success)
   - Screenshot/save to photos (success)

---

## Task 6: App Icon

Create the `AppIcon` asset in `Assets.xcassets` with a 1024x1024 PNG. Use this concept:
- Background: gradient from deep indigo (#1E1B4B) to electric violet (#7C3AED)
- Foreground: white stylized QR code pattern (simplified 5x5 or 7x7 grid with rounded module corners)
- Small book/page motif subtly integrated into the QR pattern
- Generate programmatically using CoreGraphics in a build script, or provide a placeholder solid-color icon if image generation isn't feasible

---

## Task 7: Final Pre-Submission Checklist

Run through and fix:

1. `xcodebuild clean build` passes with zero warnings for all targets
2. All Info.plist keys present:
   - `NSCameraUsageDescription` (for scanner)
   - `NSPhotoLibraryUsageDescription` (for logo picker + save to photos)
   - Bundle display name: "QR Book"
   - Version: 1.0.0
   - Build: 1
3. App Group configured: `group.com.gyndok.QRBook` (for widget + share extension)
4. CloudKit container: `iCloud.com.gyndok.QRBook`
5. Associated entitlements files exist for all targets
6. No `print()` statements in production code (replace with `os.Logger` or remove)
7. No hardcoded test data
8. Scheme set to Release configuration for archive
9. All targets have correct bundle identifiers:
   - Main: `com.gyndok.QRBook`
   - Widget: `com.gyndok.QRBook.Widget`
   - Share Extension: `com.gyndok.QRBook.ShareExtension`
   - Watch: `com.gyndok.QRBook.watchkitapp`

---

## Build & Commit Strategy

After each task:
1. Build all targets: `xcodebuild -scheme QRBook build`
2. Fix any warnings or errors
3. Commit with descriptive message: `feat:`, `fix:`, `chore:` prefixes
4. Push to `main`

After all tasks complete:
1. Full clean build of all targets
2. Run on simulator — test all 5 tabs, create/edit/delete, scanner, fullscreen, widgets
3. Final commit: `chore: pre-launch polish complete, ready for App Store submission`
