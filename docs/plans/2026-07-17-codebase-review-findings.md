# QRBook Codebase Review — Findings & Fix Plan (2026-07-17)

Full review of the app, Share Extension, Widget, Watch app, and Store layer.
Severity-ordered. Line numbers are as of commit 95d68cb plus the uncommitted
StoreManager/PDFQRScanner changes (both of which were reviewed and are fine).

## P0 — Ship blockers (packaging / targets)

1. **Extensions are built but never embedded.** The "Embed Foundation
   Extensions" copy phase in `QRBook.xcodeproj/project.pbxproj` (~line 105) has
   `files = ()`. The share extension and widget compile (target dependencies
   exist) but are never copied into `QRBook.app/PlugIns` — on device the share
   sheet entry and the widget do not exist.
   *Fix:* add both `.appex` product refs to the embed phase (Xcode: General →
   Frameworks, Libraries, and Embedded Content, or re-add targets' embed).

2. **Watch app is never embedded and has no target dependency.** No "Embed
   Watch Content" phase and no dependency from the iOS target — the watch app
   only runs standalone from Xcode and will never ship with the iPhone app.
   *Fix:* add target dependency + Embed Watch Content copy phase
   (`dstSubfolderSpec = 16`, dstPath `$(CONTENTS_FOLDER_PATH)/Watch`).

3. **Widget extension has no Info.plist / `NSExtensionPointIdentifier`.**
   Widget target uses `GENERATE_INFOPLIST_FILE = YES` with no way to declare
   `com.apple.widgetkit-extension`; the appex is not a valid WidgetKit
   extension. *Fix:* add `QRBookWidget/Info.plist` with the NSExtension dict
   and set `INFOPLIST_FILE`.

4. **Share extension can never receive PDFs.** `QRBookShareExtension/Info.plist`
   only activates for text and web URLs — the entire PDF share path added in
   commits 0d3750b/95d68cb is unreachable. *Fix:* add
   `NSExtensionActivationSupportsFileWithMaxCount` (or an activation subquery
   for `com.adobe.pdf`).

5. **Even when a PDF reaches the extension, the URL branch swallows it.**
   `ShareViewController.swift:14-21` checks `UTType.url` first; a shared PDF's
   `public.file-url` conforms to `public.url`, so the PDF is saved as a "url"
   QR import (`file:///…` string). *Fix:* check `UTType.pdf` before URL and
   distinguish `fileURL` from web URLs.

## P1 — High-severity functional bugs

6. **Wi-Fi QR payloads do no escaping** — `QRDataEncoder.swift:49-51`,
   `QRDataDecoder.swift:12-24`. SSID/password containing `; , : \ "` produce
   QR codes that join the wrong network/password; decoding compliant external
   codes is also wrong. `test_encodeWiFi_specialCharsInSSID_encodesCorrectly`
   enshrines the broken behavior. *Fix:* escape on encode; escape-aware
   tokenizer on decode; fix the test.

7. **vCard fields not escaped** — `QRDataEncoder.swift:56-89`. Names/orgs with
   `;` or `,` shift vCard components; importers mis-parse.

8. **`DateFormatter` without `en_US_POSIX`** — `QRDataEncoder.swift:95,133`,
   `QRDataDecoder.swift:54`. Users with a 12/24-hour override generate invalid
   iCal timestamps (e.g. `…T20000 PM`) and fail to parse valid ones (dates
   silently fall back to `.now`). BulkImportService already does this right.
   *Fix:* shared formatter utility with `en_US_POSIX` + explicit timezone; also
   accept the `…Z` UTC form.

9. **Grayscale colors encode to garbage hex** — `QRCreationViewModel.swift:100-112`.
   `cgColor.components` for `.white` is `[1.0, 1.0]` → background hex
   `"FFFF00"` (yellow). Any untouched default color corrupts on `syncColors()`.
   *Fix:* `UIColor.getRed(_:green:blue:alpha:)` (colorspace-converting) +
   clamp to 0…1. Also make `Color(hex:)` (`AppTheme.swift:7-17`) validate input.

10. **Quick actions are dead** — `QRBookApp.swift:46,111-126`. `AppDelegate`
    is not `ObservableObject`, so `.onChange(of: appDelegate.shortcutAction)`
    never fires; all three home-screen quick actions do nothing. *Fix:*
    `ObservableObject` + `@Published`, and handle the cold-launch initial value.

11. **Share handoff only checked on cold launch** — `QRBookApp.swift:36-45`.
    No `scenePhase` handling anywhere; sharing while the app is backgrounded
    does nothing until force-quit + relaunch. Multiple queued shares also
    overwrite each other and get deleted (`:93-101`) — only the last survives.
    *Fix:* re-run `checkPendingShareImports()` on `.active`; queue pending
    shares.

12. **Restore Purchases doesn't call `AppStore.sync()`** —
    `StoreManager.swift:82-92`. On a fresh install the local entitlement cache
    is empty, so restore is a no-op (classic App Review rejection). It also
    sets `hasStoreKitEntitlement = false` up front, downgrading a paying user
    on any transient verification failure. *Fix:* `try await AppStore.sync()`
    first; compute into a local and assign once.

13. **`devUnlock` bypasses Observation** — `StoreManager.swift:19-20`.
    `@ObservationIgnored @AppStorage` in an `@Observable` class means toggling
    it (SettingsView) doesn't refresh any `isProUnlocked` UI. *Fix:* plain
    tracked property mirrored to `UserDefaults` in `didSet`.

14. **Export/share crashes or no-ops** — `FlyerEditorView.swift:157-169`
    presents from the root VC while itself presented (silently fails) and,
    like `SettingsView.swift:219-224`, has no iPad popover source (crash on
    iPad; project targets iPad). *Fix:* replace with SwiftUI `ShareLink`.

15. **PDF pages with rotation are scanned blind** — `PDFQRScanner.swift:81-104`
    ignores `/Rotate` and mediaBox origin; rotated scans (common) report "no
    QR codes found". *Fix:* use `page.thumbnail(of:for:)` or apply the page
    transform. Also `:106-114` — the CIDetector fallback only runs when Vision
    *throws*, not when it returns zero results.

## P2 — Medium

16. `SettingsView` "Default Settings" (size, error correction, brightness
    boost, auto-favorite) are written but never read — `QRCreationViewModel`
    hardcodes defaults. Seed the VM from `UserDefaults`.
17. Deep-link presentation races: three live `QRLibraryView` instances all
    respond to `router.showQRCodeId` (`QRLibraryView.swift:118-141`); hoist
    deep-link handling to `MainTabView` and bind `TabView(selection:)` directly
    to `@Bindable router.selectedTab` (`MainTabView.swift:77-81` one-way sync
    breaks repeated identical deep links).
18. Cold-launch PDF handoff lost: `ScannerView.swift:89-93` observes
    `pendingPDFURL` changes but the value is set before the tab exists; also
    check in `.onAppear`.
19. Camera permission never requested — `ScannerView.swift:15` shows "Scanner
    Unavailable" instead of prompting; request when `.notDetermined`.
20. Recent tab ignores search/filters — `QRLibraryViewModel.swift:53-59`
    early-returns before filtering.
21. `BulkImportService.swift:203-205` — `try? context.save()` reports success
    on silent save failure. Surface the error.
22. Share extension hangs (spinner forever) when `loadItem` errors or delivers
    `Data`/`NSAttributedString` — `ShareViewController.swift:16-35`; always
    call `close()`.
23. Medium widget renders the small layout — `QRBookWidget.swift:100-111`
    never switches on `widgetFamily`; `QRBookWidgetMediumView` is dead code.
24. App Intents are stubs — `ShowQRCodeIntent.swift:29-37` returns `[]` from
    the entity query and `perform()` ignores the parameter; back the query
    with the app-group data and route via `DeepLinkRouter`.
25. CRLF handling: decoders split on `"\n"` only (`QRDataDecoder.swift:31,53`);
    external vCard/iCal QR codes leave trailing `\r` and break date parsing.
26. Spotlight index drift: batch delete, duplicate, and PDF import never
    update Spotlight (`QRLibraryView.swift:330-337`, `QRCardView.swift:122-140`,
    `PDFImportViewModel.swift:117-133`); stale entries deep-link to deleted
    codes and `router.showQRCodeId` is never cleared on miss.
27. `normalizeURL` (`Validation.swift:23-29`) is case-sensitive and mangles
    non-http schemes (`mailto:` → `https://mailto:…`).
28. PDF scan task not cancelled on sheet dismissal — `PDFImportView.swift:46-48`.
29. Photos save reports success haptic even when permission is denied —
    `QRFullscreenView.swift:199-210`; use `PHPhotoLibrary.performChanges`.
30. `encodePayPal` builds an invalid PayPal.me URL from an email
    (`QRDataEncoder.swift:168-178`); slugs are usernames, not emails.

## P3 — Low / hygiene

- All-day iCal `DTEND` off-by-one (exclusive-date spec) — encoder/decoder.
- `QRCode` conflicting `sizePx` defaults (512 stored vs 300 in init);
  BulkImport accepts size ≤ 0.
- Orphaned `ScanEvent`s never deleted with their QRCode; `QRHistoryView`
  queries all events and filters in memory — use a relationship w/ cascade
  delete + `#Predicate`.
- Pro gating gaps: scanned Pro-type codes save without paywall; EditQRView
  shows Pro color pickers to free users.
- Watch: first favorites sync dropped before session activation
  (`WatchConnector.swift:15`); `updateApplicationContext` size cap unhandled;
  watch List keyed on optional `["id"]`.
- Paywall hardcodes `"$6.99"` fallback (wrong for non-USD storefronts).
- Widget ignores exported custom QR colors; timeline always shows first
  favorite (no per-widget configuration).
- `EditCandidateView.addTag` (PDF import) skips tag validation; commas corrupt
  `tagsRaw`.
- Accent color reads `UserDefaults` per access, not observable
  (`AppTheme.swift:65-74`).

## Suggested fix order

1. **Phase 1 – Packaging (P0):** embed extensions + watch app, widget
   Info.plist, share-extension activation rule + PDF/URL branch order. Verify
   by installing on device: share sheet entry, widget gallery, watch install.
2. **Phase 2 – Data correctness (P1 #6-9, #15, P2 #21, #25):** escaping,
   POSIX date formatters, grayscale hex, PDF rotation, save-error surfacing,
   CRLF. All are unit-testable — extend the existing test suites first (TDD),
   including fixing the two tests that lock in broken behavior.
3. **Phase 3 – App plumbing (P1 #10-14, P2 #16-20, #22-24, #26):** quick
   actions, scenePhase share handoff, StoreKit restore/devUnlock, ShareLink
   migration, routing consolidation in MainTabView, camera permission.
4. **Phase 4 – Hygiene (P3).**

## Feature suggestions

Quick wins building on existing infrastructure:
- **Finish the medium widget + widget configuration** (pick which favorite;
  render with the user's QR colors — data is already exported).
- **Real Siri/Shortcuts support** — the App Intent scaffolding exists; backing
  the entity query with the app-group JSON makes "Show my gym QR" work.
- **History insights** — `ScanEvent` is already recorded; a per-code usage
  chart and "most used" smart sort are cheap.
- **Batch PDF import** — the app-group handoff currently processes one PDF at
  a time; queue them.

Larger differentiators:
- **iCloud sync (CloudKit + SwiftData)** — the #1 expectation for a library
  app; also fixes the "new device, empty library" story that currently also
  breaks restore purchases testing.
- **Live Activities / Lock-Screen widget** for the "next up" QR (boarding
  pass / ticket use case pairs naturally with PDF import).
- **Apple Wallet export** — generate a PKPass from a QR code for tickets.
- **Watch app parity** — render QR on watch from synced data even when phone
  is unreachable (store payloads locally after sync).
- **Shared folders / export bundles** — export a folder as a `.qrbook` file or
  printable flyer sheet (FlyerEditor already renders composites).
- **Dynamic QR via link shortener** (Pro): editable destinations, scan counts.
