# QR Book

Native iOS QR code manager built with SwiftUI, SwiftData, and iCloud sync.

## Features

- **Create QR Codes** — 11 types: URL, text, Wi-Fi, contact (vCard), calendar (iCal), file, Venmo, PayPal, Cash App, Zelle, and crypto
- **Custom Styling** — Foreground/background colors with logo overlay support
- **QR Scanner** — Camera-based scanner with automatic type detection
- **Library Management** — Search, filter by type/tags/folder, sort by name/date/usage, batch operations
- **Folders & Tags** — Organize QR codes with folders and multi-tag support
- **Favorites** — Quick access to frequently used codes
- **Flyer Generator** — Create printable posters from QR codes with 5 built-in templates
- **Bulk Import/Export** — JSON-based import and export for library backup
- **iCloud Sync** — Automatic sync across devices via CloudKit
- **Apple Watch** — Companion app displaying favorite QR codes
- **Home Screen Widgets** — Small and medium widgets for quick access
- **Share Extension** — Import QR data from other apps
- **Siri Shortcuts** — Create and show QR codes via voice
- **Spotlight Search** — Find QR codes from system search
- **Quick Actions** — 3D Touch shortcuts for create, scan, and favorites

## Tech Stack

- **UI:** SwiftUI
- **Data:** SwiftData + CloudKit
- **Architecture:** MVVM with `@Observable` view models
- **Targets:** iOS app, Widget extension, Watch app, Share extension
- **Min Deployment:** iOS 17.0 / watchOS 10.0
- **Dependencies:** None — pure Apple frameworks

## Project Structure

```
QRBook/
├── Models/          # QRCode, Folder, ScanEvent (@Model)
├── ViewModels/      # QRLibraryViewModel, QRCreationViewModel, DeepLinkRouter
├── Views/           # Library, Creation, Scanner, Fullscreen, Settings, Folders, Flyers
├── Utilities/       # QR generation, encoding/decoding, validation, sync services
├── Theme/           # AppTheme, accent colors, card styles
└── Intents/         # Siri Shortcuts integration

QRBookTests/         # 181 unit tests across 8 test classes
QRBookShareExtension/
QRBookWidget/
QRBookWatch Watch App/
```

## Building

Open `QRBook.xcodeproj` in Xcode 16+ and build the **QRBook** scheme.

## Testing

Run the test suite from Xcode (Cmd+U) or via command line:

```bash
xcodebuild test \
  -scheme QRBook \
  -destination 'platform=iOS Simulator,name=iPhone 16'
```

181 tests covering validation, encoding/decoding, model logic, and ViewModel business logic.

## License

All rights reserved.
