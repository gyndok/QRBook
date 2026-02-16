# QR Book iOS App — Design Document

**Date:** 2026-02-16
**Status:** Approved
**Scope:** Phase 1 Core (Auth-free QR Library + Create + Fullscreen + Settings)

---

## Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Framework | SwiftUI | Native iOS, best UX |
| Data | SwiftData + CloudKit | Auto iCloud sync, no external backend |
| Auth | None (iCloud identity) | Zero-friction, Apple ID handles it |
| QR Generation | CoreImage CIQRCodeGenerator | Native, fast, no dependencies |
| Min iOS | 17+ | Required for SwiftData @Observable |
| Location | /Users/gyndok/Developer/QRBook/ | Standalone repo |

## Architecture

SwiftUI + MVVM + SwiftData. No external dependencies. Pure Apple frameworks.

## Data Model

**QRCode** (@Model)
- id: UUID
- title: String
- data: String
- type: String (enum raw value: url/text/wifi/contact/file/venmo/paypal/cashapp/zelle/crypto/calendar)
- isFavorite: Bool
- errorCorrection: String (L/M/Q/H)
- sizePx: Int (256/512/1024)
- oneTimeUse: Bool
- expiresAt: Date?
- scanCount: Int
- brightnessBoostDefault: Bool
- createdAt: Date
- updatedAt: Date
- lastUsed: Date
- tagsRaw: String (comma-separated, CloudKit-compatible)

Tags stored as comma-separated string because SwiftData+CloudKit doesn't support arrays or relationships well.

## Project Structure

```
QRBook/
├── QRBookApp.swift
├── Models/
│   └── QRCode.swift
├── ViewModels/
│   ├── QRLibraryViewModel.swift
│   └── QRCreationViewModel.swift
├── Views/
│   ├── MainTabView.swift
│   ├── Library/
│   │   ├── QRLibraryView.swift
│   │   ├── QRCardView.swift
│   │   └── QRFilterSheet.swift
│   ├── Creation/
│   │   ├── CreateQRView.swift
│   │   ├── WiFiFormView.swift
│   │   ├── ContactFormView.swift
│   │   ├── CalendarFormView.swift
│   │   └── PaymentFormView.swift
│   ├── Fullscreen/
│   │   └── QRFullscreenView.swift
│   └── Settings/
│       └── SettingsView.swift
├── Utilities/
│   ├── QRGenerator.swift
│   ├── QRDataEncoder.swift
│   └── Validation.swift
└── Resources/
    └── Assets.xcassets
```

## Screens

1. MainTabView — 4 bottom tabs (Library, Favorites, Recent, Flyers placeholder)
2. QRLibraryView — search, sort, filter, grid of QRCardViews
3. QRCardView — QR preview, title, type, tags, scan count, favorite, context menu
4. CreateQRView — type selector, type-specific forms, tags, advanced options
5. QRFullscreenView — large QR, dark overlay, brightness boost, swipe nav
6. SettingsView — preferences, export, about

## Key Behaviors

- Brightness boost: UIScreen.main.brightness = 1.0 in fullscreen
- Screen stays awake in fullscreen
- Haptic feedback on interactions
- Native share sheet
- Save QR as PNG to Photos
- Pull-to-refresh
- Swipe actions on list items
- Long-press context menus

## Phase 2 (deferred)

- Flyers (PDF upload, QR overlay, export)
- Camera QR scanning
- Widgets
- Siri Shortcuts
