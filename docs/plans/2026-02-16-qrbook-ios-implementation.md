# QR Book iOS — Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Build a native SwiftUI iOS app for creating, organizing, and displaying QR codes with iCloud sync.

**Architecture:** SwiftUI + MVVM + SwiftData with CloudKit sync. No external dependencies. CoreImage for QR generation. iOS 17+ deployment target.

**Tech Stack:** Swift 6.2, SwiftUI, SwiftData, CloudKit, CoreImage, PDFKit (future)

---

### Task 1: Scaffold Xcode Project

**Files:**
- Create: `QRBook.xcodeproj` (via Xcode template generation)
- Create: `QRBook/QRBookApp.swift`
- Create: `QRBook/ContentView.swift`
- Create: `QRBook/Info.plist` (auto-generated)

**Step 1: Create the Xcode project using Swift Package Manager as a starting point, then convert to Xcode project**

Since we're building from the CLI, create the project structure manually. The Xcode project file will be generated.

Create directory structure:
```
QRBook/
├── QRBook/
│   ├── QRBookApp.swift
│   ├── ContentView.swift
│   ├── Models/
│   ├── ViewModels/
│   ├── Views/
│   │   ├── Library/
│   │   ├── Creation/
│   │   ├── Fullscreen/
│   │   └── Settings/
│   ├── Utilities/
│   └── Resources/
│       └── Assets.xcassets/
└── QRBook.xcodeproj/
```

**Step 2: Create QRBookApp.swift entry point**

```swift
import SwiftUI
import SwiftData

@main
struct QRBookApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: QRCode.self)
    }
}
```

**Step 3: Create placeholder ContentView.swift**

```swift
import SwiftUI

struct ContentView: View {
    var body: some View {
        Text("QR Book")
    }
}

#Preview {
    ContentView()
}
```

**Step 4: Generate the Xcode project file**

This requires creating the `.xcodeproj/project.pbxproj` file with the correct build settings for iOS 17+, SwiftUI app lifecycle, and CloudKit capability.

**Step 5: Verify it builds**

```bash
/Applications/Xcode.app/Contents/Developer/usr/bin/xcodebuild -project QRBook.xcodeproj -scheme QRBook -destination 'platform=iOS Simulator,name=iPhone 16' build
```

**Step 6: Commit**

```bash
git add -A
git commit -m "feat: scaffold Xcode project with SwiftUI + SwiftData"
```

---

### Task 2: Data Model — QRCode

**Files:**
- Create: `QRBook/Models/QRCode.swift`

**Step 1: Create the QRCode SwiftData model**

```swift
import Foundation
import SwiftData

enum QRType: String, Codable, CaseIterable, Identifiable {
    case url, text, wifi, contact, file
    case venmo, paypal, cashapp, zelle, crypto, calendar

    var id: String { rawValue }

    var label: String {
        switch self {
        case .url: "URL/Link"
        case .text: "Text"
        case .wifi: "WiFi"
        case .contact: "Contact"
        case .file: "File"
        case .venmo: "Venmo"
        case .paypal: "PayPal"
        case .cashapp: "CashApp"
        case .zelle: "Zelle"
        case .crypto: "Crypto"
        case .calendar: "Calendar"
        }
    }

    var icon: String {
        switch self {
        case .url: "link"
        case .text: "doc.text"
        case .wifi: "wifi"
        case .contact: "person.crop.circle"
        case .file: "folder"
        case .venmo: "dollarsign.circle"
        case .paypal: "creditcard"
        case .cashapp: "banknote"
        case .zelle: "dollarsign.square"
        case .crypto: "bitcoinsign.circle"
        case .calendar: "calendar"
        }
    }

    var description: String {
        switch self {
        case .url: "Website, social media, or any URL"
        case .text: "Plain text message or note"
        case .wifi: "WiFi network credentials"
        case .contact: "vCard contact information"
        case .file: "Link to a file or document"
        case .venmo: "Venmo payment username"
        case .paypal: "PayPal.me link or email"
        case .cashapp: "CashApp $cashtag"
        case .zelle: "Zelle email or phone number"
        case .crypto: "Cryptocurrency wallet address"
        case .calendar: "Add event to calendar"
        }
    }
}

enum ErrorCorrectionLevel: String, Codable, CaseIterable, Identifiable {
    case L, M, Q, H

    var id: String { rawValue }

    var label: String {
        switch self {
        case .L: "Low (~7%)"
        case .M: "Medium (~15%)"
        case .Q: "Quartile (~25%)"
        case .H: "High (~30%)"
        }
    }
}

@Model
final class QRCode {
    var id: UUID
    var title: String
    var data: String
    var typeRaw: String
    var tagsRaw: String
    var isFavorite: Bool
    var errorCorrectionRaw: String
    var sizePx: Int
    var oneTimeUse: Bool
    var expiresAt: Date?
    var scanCount: Int
    var brightnessBoostDefault: Bool
    var createdAt: Date
    var updatedAt: Date
    var lastUsed: Date

    var type: QRType {
        get { QRType(rawValue: typeRaw) ?? .url }
        set { typeRaw = newValue.rawValue }
    }

    var errorCorrection: ErrorCorrectionLevel {
        get { ErrorCorrectionLevel(rawValue: errorCorrectionRaw) ?? .M }
        set { errorCorrectionRaw = newValue.rawValue }
    }

    var tags: [String] {
        get {
            guard !tagsRaw.isEmpty else { return [] }
            return tagsRaw.components(separatedBy: ",")
        }
        set {
            tagsRaw = newValue.joined(separator: ",")
        }
    }

    init(
        title: String,
        data: String,
        type: QRType,
        tags: [String] = [],
        isFavorite: Bool = false,
        errorCorrection: ErrorCorrectionLevel = .M,
        sizePx: Int = 512,
        oneTimeUse: Bool = false,
        expiresAt: Date? = nil,
        brightnessBoostDefault: Bool = true
    ) {
        self.id = UUID()
        self.title = title
        self.data = data
        self.typeRaw = type.rawValue
        self.tagsRaw = tags.joined(separator: ",")
        self.isFavorite = isFavorite
        self.errorCorrectionRaw = errorCorrection.rawValue
        self.sizePx = sizePx
        self.oneTimeUse = oneTimeUse
        self.expiresAt = expiresAt
        self.scanCount = 0
        self.brightnessBoostDefault = brightnessBoostDefault
        let now = Date()
        self.createdAt = now
        self.updatedAt = now
        self.lastUsed = now
    }
}
```

**Step 2: Verify it compiles**

```bash
/Applications/Xcode.app/Contents/Developer/usr/bin/xcodebuild -project QRBook.xcodeproj -scheme QRBook -destination 'platform=iOS Simulator,name=iPhone 16' build
```

**Step 3: Commit**

```bash
git add QRBook/Models/QRCode.swift
git commit -m "feat: add QRCode SwiftData model with all 11 QR types"
```

---

### Task 3: QR Code Generator Utility

**Files:**
- Create: `QRBook/Utilities/QRGenerator.swift`

**Step 1: Create CoreImage-based QR generator**

```swift
import CoreImage
import CoreImage.CIFilterBuiltins
import UIKit

struct QRGenerator {
    static func generateQRCode(
        from string: String,
        correctionLevel: ErrorCorrectionLevel = .M,
        size: CGFloat = 512
    ) -> UIImage? {
        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()

        guard let data = string.data(using: .utf8) else { return nil }
        filter.message = data
        filter.correctionLevel = correctionLevel.rawValue

        guard let ciImage = filter.outputImage else { return nil }

        let scaleX = size / ciImage.extent.size.width
        let scaleY = size / ciImage.extent.size.height
        let scaledImage = ciImage.transformed(by: CGAffineTransform(scaleX: scaleX, y: scaleY))

        guard let cgImage = context.createCGImage(scaledImage, from: scaledImage.extent) else {
            return nil
        }

        return UIImage(cgImage: cgImage)
    }

    static func generateQRImage(for qrCode: QRCode) -> UIImage? {
        generateQRCode(
            from: qrCode.data,
            correctionLevel: qrCode.errorCorrection,
            size: CGFloat(qrCode.sizePx)
        )
    }
}
```

**Step 2: Verify build**

**Step 3: Commit**

```bash
git add QRBook/Utilities/QRGenerator.swift
git commit -m "feat: add CoreImage QR code generator utility"
```

---

### Task 4: QR Data Encoder Utility

**Files:**
- Create: `QRBook/Utilities/QRDataEncoder.swift`

**Step 1: Create encoder for WiFi, vCard, iCal, and payment types**

```swift
import Foundation

struct WiFiData {
    var ssid: String
    var password: String
    var security: Security
    var hidden: Bool = false

    enum Security: String, CaseIterable, Identifiable {
        case WPA, WEP, nopass
        var id: String { rawValue }
        var label: String {
            switch self {
            case .WPA: "WPA/WPA2"
            case .WEP: "WEP"
            case .nopass: "No Password"
            }
        }
    }
}

struct ContactData {
    var name: String = ""
    var phone: String = ""
    var email: String = ""
    var organization: String = ""
    var url: String = ""
}

struct CalendarEventData {
    var title: String = ""
    var startDate: Date = .now
    var endDate: Date = .now
    var startTime: Date = .now
    var endTime: Date = .now
    var location: String = ""
    var eventDescription: String = ""
    var allDay: Bool = false
}

struct QRDataEncoder {
    static func encodeWiFi(_ wifi: WiFiData) -> String {
        "WIFI:T:\(wifi.security.rawValue);S:\(wifi.ssid);P:\(wifi.password);H:\(wifi.hidden ? "true" : "false");;"
    }

    static func encodeContact(_ contact: ContactData) -> String {
        var lines = ["BEGIN:VCARD", "VERSION:3.0"]
        if !contact.name.isEmpty { lines.append("FN:\(contact.name)") }
        if !contact.phone.isEmpty { lines.append("TEL:\(contact.phone)") }
        if !contact.email.isEmpty { lines.append("EMAIL:\(contact.email)") }
        if !contact.organization.isEmpty { lines.append("ORG:\(contact.organization)") }
        if !contact.url.isEmpty { lines.append("URL:\(contact.url)") }
        lines.append("END:VCARD")
        return lines.joined(separator: "\n")
    }

    static func encodeCalendarEvent(_ event: CalendarEventData) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd"
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HHmmss"

        let startDateStr = dateFormatter.string(from: event.startDate)
        let endDateStr = dateFormatter.string(from: event.endDate)

        var lines = [
            "BEGIN:VCALENDAR",
            "VERSION:2.0",
            "PRODID:-//QR Book//EN",
            "BEGIN:VEVENT",
            "SUMMARY:\(event.title)"
        ]

        if event.allDay {
            lines.append("DTSTART;VALUE=DATE:\(startDateStr)")
            lines.append("DTEND;VALUE=DATE:\(endDateStr)")
        } else {
            let startTimeStr = timeFormatter.string(from: event.startTime)
            let endTimeStr = timeFormatter.string(from: event.endTime)
            lines.append("DTSTART:\(startDateStr)T\(startTimeStr)")
            lines.append("DTEND:\(endDateStr)T\(endTimeStr)")
        }

        if !event.location.isEmpty { lines.append("LOCATION:\(event.location)") }
        if !event.eventDescription.isEmpty { lines.append("DESCRIPTION:\(event.eventDescription)") }

        lines.append("END:VEVENT")
        lines.append("END:VCALENDAR")
        return lines.joined(separator: "\n")
    }

    static func encodeVenmo(_ username: String) -> String {
        let clean = username.hasPrefix("@") ? String(username.dropFirst()) : username
        return "https://venmo.com/\(clean)"
    }

    static func encodePayPal(_ input: String) -> String {
        if input.contains("paypal.me") { return input }
        if input.contains("@") { return "mailto:\(input)" }
        return "https://paypal.me/\(input)"
    }

    static func encodeCashApp(_ cashtag: String) -> String {
        let clean = cashtag.hasPrefix("$") ? String(cashtag.dropFirst()) : cashtag
        return "https://cash.app/$\(clean)"
    }

    static func encodeZelle(_ contact: String) -> String {
        "Zelle: \(contact)"
    }
}
```

**Step 2: Verify build**

**Step 3: Commit**

```bash
git add QRBook/Utilities/QRDataEncoder.swift
git commit -m "feat: add QR data encoder for WiFi, vCard, iCal, payments"
```

---

### Task 5: Validation Utility

**Files:**
- Create: `QRBook/Utilities/Validation.swift`

**Step 1: Create input validation**

```swift
import Foundation

struct Validation {
    static func validateTitle(_ title: String) -> String? {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return "Title is required" }
        if trimmed.count > 200 { return "Title must be less than 200 characters" }
        return nil
    }

    static func validateURL(_ url: String) -> String? {
        let trimmed = url.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return "URL is required" }
        if trimmed.count > 2048 { return "URL must be less than 2048 characters" }
        guard URL(string: trimmed) != nil, trimmed.hasPrefix("http://") || trimmed.hasPrefix("https://") else {
            return "Please enter a valid URL"
        }
        return nil
    }

    static func validateText(_ text: String) -> String? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return "Text content is required" }
        if trimmed.count > 4296 { return "Text must be less than 4296 characters" }
        return nil
    }

    static func validateTag(_ tag: String) -> String? {
        let trimmed = tag.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return "Tag cannot be empty" }
        if trimmed.count > 50 { return "Tag must be less than 50 characters" }
        let allowed = CharacterSet.alphanumerics.union(.whitespaces).union(CharacterSet(charactersIn: "-_"))
        if trimmed.unicodeScalars.contains(where: { !allowed.contains($0) }) {
            return "Tags can only contain letters, numbers, spaces, hyphens, and underscores"
        }
        return nil
    }

    static func validateRequired(_ value: String, fieldName: String) -> String? {
        if value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return "\(fieldName) is required"
        }
        return nil
    }
}
```

**Step 2: Verify build**

**Step 3: Commit**

```bash
git add QRBook/Utilities/Validation.swift
git commit -m "feat: add input validation utility"
```

---

### Task 6: Main Tab View

**Files:**
- Create: `QRBook/Views/MainTabView.swift`
- Modify: `QRBook/QRBookApp.swift` — point to MainTabView
- Modify: `QRBook/ContentView.swift` — remove or repurpose

**Step 1: Create MainTabView with 4 tabs**

```swift
import SwiftUI

struct MainTabView: View {
    @State private var selectedTab: Tab = .library

    enum Tab: String, CaseIterable {
        case library, favorites, recent, flyers

        var label: String {
            switch self {
            case .library: "Library"
            case .favorites: "Favorites"
            case .recent: "Recent"
            case .flyers: "Flyers"
            }
        }

        var icon: String {
            switch self {
            case .library: "square.grid.2x2"
            case .favorites: "heart"
            case .recent: "clock"
            case .flyers: "doc.text"
            }
        }
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            ForEach(Tab.allCases, id: \.self) { tab in
                Group {
                    switch tab {
                    case .library:
                        QRLibraryView(viewMode: .all)
                    case .favorites:
                        QRLibraryView(viewMode: .favorites)
                    case .recent:
                        QRLibraryView(viewMode: .recent)
                    case .flyers:
                        FlyersPlaceholderView()
                    }
                }
                .tabItem {
                    Label(tab.label, systemImage: tab.icon)
                }
                .tag(tab)
            }
        }
    }
}

struct FlyersPlaceholderView: View {
    var body: some View {
        NavigationStack {
            ContentUnavailableView(
                "Coming Soon",
                systemImage: "doc.text",
                description: Text("Flyer creation will be available in a future update.")
            )
            .navigationTitle("Flyers")
        }
    }
}
```

**Step 2: Update QRBookApp.swift**

```swift
import SwiftUI
import SwiftData

@main
struct QRBookApp: App {
    var body: some Scene {
        WindowGroup {
            MainTabView()
        }
        .modelContainer(for: QRCode.self)
    }
}
```

**Step 3: Verify build**

**Step 4: Commit**

```bash
git add QRBook/Views/MainTabView.swift QRBook/QRBookApp.swift
git commit -m "feat: add main tab bar with Library, Favorites, Recent, Flyers tabs"
```

---

### Task 7: QR Library View

**Files:**
- Create: `QRBook/Views/Library/QRLibraryView.swift`
- Create: `QRBook/ViewModels/QRLibraryViewModel.swift`

**Step 1: Create QRLibraryViewModel**

```swift
import SwiftUI
import SwiftData

enum ViewMode {
    case all, favorites, recent
}

enum SortOption: String, CaseIterable, Identifiable {
    case lastUsed = "Recent"
    case newest = "Newest"
    case nameAZ = "Name A-Z"
    case mostUsed = "Most Used"

    var id: String { rawValue }
}

@Observable
class QRLibraryViewModel {
    var searchText = ""
    var sortOption: SortOption = .lastUsed
    var filterType: QRType? = nil
    var filterFavoritesOnly = false
    var filterTags: Set<String> = []
    var showFilterSheet = false
    var showCreateSheet = false

    func filteredAndSorted(_ qrCodes: [QRCode], viewMode: ViewMode) -> [QRCode] {
        var result = qrCodes

        // Apply view mode
        switch viewMode {
        case .favorites:
            result = result.filter { $0.isFavorite }
        case .recent:
            result = result.sorted { $0.lastUsed > $1.lastUsed }
            result = Array(result.prefix(10))
            return result
        case .all:
            break
        }

        // Search
        if !searchText.isEmpty {
            let query = searchText.lowercased()
            result = result.filter {
                $0.title.lowercased().contains(query) ||
                $0.data.lowercased().contains(query) ||
                $0.tags.contains(where: { $0.lowercased().contains(query) })
            }
        }

        // Type filter
        if let filterType {
            result = result.filter { $0.type == filterType }
        }

        // Favorites filter
        if filterFavoritesOnly {
            result = result.filter { $0.isFavorite }
        }

        // Tag filter
        if !filterTags.isEmpty {
            result = result.filter { qr in
                filterTags.allSatisfy { qr.tags.contains($0) }
            }
        }

        // Sort
        switch sortOption {
        case .lastUsed:
            result.sort { $0.lastUsed > $1.lastUsed }
        case .newest:
            result.sort { $0.createdAt > $1.createdAt }
        case .nameAZ:
            result.sort { $0.title.localizedCompare($1.title) == .orderedAscending }
        case .mostUsed:
            result.sort { $0.scanCount > $1.scanCount }
        }

        return result
    }

    var activeFilterCount: Int {
        var count = 0
        if !searchText.isEmpty { count += 1 }
        if filterType != nil { count += 1 }
        if filterFavoritesOnly { count += 1 }
        if !filterTags.isEmpty { count += 1 }
        return count
    }

    func clearFilters() {
        searchText = ""
        filterType = nil
        filterFavoritesOnly = false
        filterTags = []
    }

    func allTags(from qrCodes: [QRCode]) -> [String] {
        let tagSet = Set(qrCodes.flatMap { $0.tags })
        return tagSet.sorted()
    }
}
```

**Step 2: Create QRLibraryView**

```swift
import SwiftUI
import SwiftData

struct QRLibraryView: View {
    let viewMode: ViewMode

    @Query(sort: \QRCode.lastUsed, order: .reverse) private var qrCodes: [QRCode]
    @State private var viewModel = QRLibraryViewModel()
    @State private var selectedQR: QRCode?
    @State private var showFullscreen = false
    @Environment(\.modelContext) private var modelContext

    private var displayedCodes: [QRCode] {
        viewModel.filteredAndSorted(qrCodes, viewMode: viewMode)
    }

    private var navigationTitle: String {
        switch viewMode {
        case .all: "QR Library"
        case .favorites: "Favorites"
        case .recent: "Recent"
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if qrCodes.isEmpty {
                    emptyState
                } else if displayedCodes.isEmpty {
                    noResultsState
                } else {
                    qrGrid
                }
            }
            .navigationTitle(navigationTitle)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        viewModel.showCreateSheet = true
                    } label: {
                        Label("Create", systemImage: "plus")
                    }
                }
                ToolbarItem(placement: .topBarLeading) {
                    NavigationLink {
                        SettingsView()
                    } label: {
                        Image(systemName: "gearshape")
                    }
                }
            }
            .searchable(text: $viewModel.searchText, prompt: "Search QR codes...")
            .sheet(isPresented: $viewModel.showCreateSheet) {
                CreateQRView()
            }
            .sheet(isPresented: $viewModel.showFilterSheet) {
                QRFilterSheet(viewModel: viewModel, allTags: viewModel.allTags(from: qrCodes))
            }
            .fullScreenCover(isPresented: $showFullscreen) {
                if let selectedQR {
                    QRFullscreenView(
                        qrCode: selectedQR,
                        allQRCodes: displayedCodes
                    )
                }
            }
        }
    }

    private var qrGrid: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                // Sort and filter bar
                HStack {
                    Menu {
                        ForEach(SortOption.allCases) { option in
                            Button {
                                viewModel.sortOption = option
                            } label: {
                                if viewModel.sortOption == option {
                                    Label(option.rawValue, systemImage: "checkmark")
                                } else {
                                    Text(option.rawValue)
                                }
                            }
                        }
                    } label: {
                        Label(viewModel.sortOption.rawValue, systemImage: "arrow.up.arrow.down")
                            .font(.subheadline)
                    }

                    Spacer()

                    Text("\(displayedCodes.count) of \(qrCodes.count)")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Spacer()

                    Button {
                        viewModel.showFilterSheet = true
                    } label: {
                        Label("Filter", systemImage: "line.3.horizontal.decrease")
                            .font(.subheadline)
                    }
                    .overlay(alignment: .topTrailing) {
                        if viewModel.activeFilterCount > 0 {
                            Text("\(viewModel.activeFilterCount)")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundStyle(.white)
                                .frame(width: 16, height: 16)
                                .background(.red, in: Circle())
                                .offset(x: 8, y: -8)
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 8)

                // QR cards grid
                LazyVGrid(
                    columns: [
                        GridItem(.flexible(), spacing: 12),
                        GridItem(.flexible(), spacing: 12)
                    ],
                    spacing: 12
                ) {
                    ForEach(displayedCodes) { qrCode in
                        QRCardView(qrCode: qrCode) {
                            selectedQR = qrCode
                            showFullscreen = true
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
        .refreshable {
            // SwiftData auto-syncs, but this provides pull-to-refresh UX
        }
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label("No QR Codes Yet", systemImage: "qrcode")
        } description: {
            Text("Create your first QR code to get started. You can generate QR codes for URLs, text, WiFi networks, contacts, and more.")
        } actions: {
            Button {
                viewModel.showCreateSheet = true
            } label: {
                Text("Create QR Code")
            }
            .buttonStyle(.borderedProminent)
        }
    }

    private var noResultsState: some View {
        ContentUnavailableView {
            Label("No Results", systemImage: "magnifyingglass")
        } description: {
            Text("Try adjusting your search or filters.")
        } actions: {
            Button("Clear Filters") {
                viewModel.clearFilters()
            }
            .buttonStyle(.bordered)
        }
    }
}
```

**Step 3: Verify build**

**Step 4: Commit**

```bash
git add QRBook/Views/Library/QRLibraryView.swift QRBook/ViewModels/QRLibraryViewModel.swift
git commit -m "feat: add QR library view with search, sort, and filter"
```

---

### Task 8: QR Card View

**Files:**
- Create: `QRBook/Views/Library/QRCardView.swift`

**Step 1: Create QR card component**

```swift
import SwiftUI

struct QRCardView: View {
    @Bindable var qrCode: QRCode
    let onTap: () -> Void
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header
            HStack(spacing: 6) {
                Image(systemName: qrCode.type.icon)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                VStack(alignment: .leading, spacing: 1) {
                    Text(qrCode.title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .lineLimit(1)

                    Text(qrCode.data)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer()

                Button {
                    withAnimation(.spring(response: 0.3)) {
                        qrCode.isFavorite.toggle()
                        qrCode.updatedAt = .now
                    }
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                } label: {
                    Image(systemName: qrCode.isFavorite ? "heart.fill" : "heart")
                        .foregroundStyle(qrCode.isFavorite ? .red : .secondary)
                        .font(.subheadline)
                }
                .buttonStyle(.plain)
            }

            // QR preview
            if let uiImage = QRGenerator.generateQRCode(
                from: qrCode.data,
                correctionLevel: qrCode.errorCorrection,
                size: 120
            ) {
                Image(uiImage: uiImage)
                    .interpolation(.none)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity)
                    .frame(height: 120)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .onTapGesture(perform: onTap)
            }

            // Tags
            if !qrCode.tags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 4) {
                        ForEach(qrCode.tags.prefix(3), id: \.self) { tag in
                            Text(tag)
                                .font(.caption2)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(.secondary.opacity(0.15))
                                .clipShape(Capsule())
                        }
                        if qrCode.tags.count > 3 {
                            Text("+\(qrCode.tags.count - 3)")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(.secondary.opacity(0.1))
                                .clipShape(Capsule())
                        }
                    }
                }
            }

            // Footer
            HStack {
                Text(qrCode.type.label)
                    .font(.caption2)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(.secondary.opacity(0.1))
                    .clipShape(Capsule())

                if qrCode.scanCount > 0 {
                    Text("\(qrCode.scanCount) scan\(qrCode.scanCount == 1 ? "" : "s")")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Text(qrCode.lastUsed.relativeFormatted)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(12)
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.08), radius: 4, y: 2)
        .contextMenu {
            Button { onTap() } label: { Label("View Fullscreen", systemImage: "arrow.up.left.and.arrow.down.right") }
            Button { UIPasteboard.general.string = qrCode.data } label: { Label("Copy Data", systemImage: "doc.on.doc") }
            ShareLink(item: qrCode.data) { Label("Share", systemImage: "square.and.arrow.up") }
            Divider()
            Button(role: .destructive) {
                modelContext.delete(qrCode)
            } label: { Label("Delete", systemImage: "trash") }
        }
    }
}

extension Date {
    var relativeFormatted: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: self, relativeTo: .now)
    }
}
```

**Step 2: Verify build**

**Step 3: Commit**

```bash
git add QRBook/Views/Library/QRCardView.swift
git commit -m "feat: add QR card view with preview, tags, context menu"
```

---

### Task 9: QR Filter Sheet

**Files:**
- Create: `QRBook/Views/Library/QRFilterSheet.swift`

**Step 1: Create filter sheet**

```swift
import SwiftUI

struct QRFilterSheet: View {
    @Bindable var viewModel: QRLibraryViewModel
    let allTags: [String]
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                // Type filter
                Section("Type") {
                    FlowLayout(spacing: 8) {
                        FilterChip(label: "All", isSelected: viewModel.filterType == nil) {
                            viewModel.filterType = nil
                        }
                        ForEach(QRType.allCases) { type in
                            FilterChip(
                                label: type.label,
                                isSelected: viewModel.filterType == type
                            ) {
                                viewModel.filterType = viewModel.filterType == type ? nil : type
                            }
                        }
                    }
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                }

                // Tags
                if !allTags.isEmpty {
                    Section("Tags") {
                        FlowLayout(spacing: 8) {
                            ForEach(allTags, id: \.self) { tag in
                                FilterChip(
                                    label: tag,
                                    isSelected: viewModel.filterTags.contains(tag)
                                ) {
                                    if viewModel.filterTags.contains(tag) {
                                        viewModel.filterTags.remove(tag)
                                    } else {
                                        viewModel.filterTags.insert(tag)
                                    }
                                }
                            }
                        }
                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    }
                }

                // Favorites only
                Section {
                    Toggle("Favorites Only", isOn: $viewModel.filterFavoritesOnly)
                }
            }
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Clear") { viewModel.clearFilters() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

struct FilterChip: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.caption)
                .fontWeight(isSelected ? .semibold : .regular)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color.accentColor : Color.secondary.opacity(0.12))
                .foregroundStyle(isSelected ? .white : .primary)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrange(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(proposal: ProposedViewSize(width: bounds.width, height: bounds.height), subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y), proposal: .unspecified)
        }
    }

    private func arrange(proposal: ProposedViewSize, subviews: Subviews) -> (positions: [CGPoint], size: CGSize) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var maxX: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth, x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            positions.append(CGPoint(x: x, y: y))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
            maxX = max(maxX, x)
        }

        return (positions, CGSize(width: maxX, height: y + rowHeight))
    }
}
```

**Step 2: Verify build**

**Step 3: Commit**

```bash
git add QRBook/Views/Library/QRFilterSheet.swift
git commit -m "feat: add filter sheet with type, tags, and favorites filters"
```

---

### Task 10: Create QR View — Type Selector & Basic Form

**Files:**
- Create: `QRBook/Views/Creation/CreateQRView.swift`
- Create: `QRBook/ViewModels/QRCreationViewModel.swift`

**Step 1: Create QRCreationViewModel**

```swift
import SwiftUI

@Observable
class QRCreationViewModel {
    var selectedType: QRType = .url
    var title = ""
    var data = ""
    var tags: [String] = []
    var newTag = ""
    var isFavorite = false
    var errorCorrection: ErrorCorrectionLevel = .M
    var sizePx = 512
    var oneTimeUse = false
    var brightnessBoostDefault = true
    var showAdvanced = false

    // Type-specific data
    var wifiData = WiFiData(ssid: "", password: "", security: .WPA)
    var contactData = ContactData()
    var calendarData = CalendarEventData()

    var validationError: String?

    func validate() -> Bool {
        if let error = Validation.validateTitle(title) {
            validationError = error
            return false
        }

        switch selectedType {
        case .url, .file:
            if let error = Validation.validateURL(data) {
                validationError = error
                return false
            }
        case .text:
            if let error = Validation.validateText(data) {
                validationError = error
                return false
            }
        case .wifi:
            if let error = Validation.validateRequired(wifiData.ssid, fieldName: "Network name") {
                validationError = error
                return false
            }
        case .contact:
            if let error = Validation.validateRequired(contactData.name, fieldName: "Contact name") {
                validationError = error
                return false
            }
        case .calendar:
            if let error = Validation.validateRequired(calendarData.title, fieldName: "Event title") {
                validationError = error
                return false
            }
        case .venmo, .paypal, .cashapp, .zelle, .crypto:
            if let error = Validation.validateRequired(data, fieldName: selectedType.label) {
                validationError = error
                return false
            }
        }

        validationError = nil
        return true
    }

    func generateQRData() -> String {
        switch selectedType {
        case .wifi: return QRDataEncoder.encodeWiFi(wifiData)
        case .contact: return QRDataEncoder.encodeContact(contactData)
        case .calendar: return QRDataEncoder.encodeCalendarEvent(calendarData)
        case .venmo: return QRDataEncoder.encodeVenmo(data)
        case .paypal: return QRDataEncoder.encodePayPal(data)
        case .cashapp: return QRDataEncoder.encodeCashApp(data)
        case .zelle: return QRDataEncoder.encodeZelle(data)
        default: return data
        }
    }

    func addTag() {
        let trimmed = newTag.trimmingCharacters(in: .whitespacesAndNewlines)
        guard Validation.validateTag(trimmed) == nil,
              !tags.contains(trimmed) else { return }
        tags.append(trimmed)
        newTag = ""
    }

    func removeTag(_ tag: String) {
        tags.removeAll { $0 == tag }
    }
}
```

**Step 2: Create CreateQRView**

```swift
import SwiftUI
import SwiftData

struct CreateQRView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = QRCreationViewModel()
    @State private var isCreating = false

    var body: some View {
        NavigationStack {
            Form {
                // Type selector
                Section("QR Code Type") {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                        ForEach(QRType.allCases) { type in
                            TypeCard(type: type, isSelected: viewModel.selectedType == type) {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    viewModel.selectedType = type
                                    viewModel.data = ""
                                }
                            }
                        }
                    }
                    .listRowInsets(EdgeInsets(top: 8, leading: 4, bottom: 8, trailing: 4))
                }

                // Title
                Section("Title") {
                    TextField("Give your QR code a name...", text: $viewModel.title)
                }

                // Type-specific fields
                typeSpecificFields

                // Tags
                Section("Tags") {
                    if !viewModel.tags.isEmpty {
                        FlowLayout(spacing: 6) {
                            ForEach(viewModel.tags, id: \.self) { tag in
                                HStack(spacing: 4) {
                                    Text(tag)
                                        .font(.caption)
                                    Button {
                                        viewModel.removeTag(tag)
                                    } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .font(.caption2)
                                    }
                                    .buttonStyle(.plain)
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(.secondary.opacity(0.15))
                                .clipShape(Capsule())
                            }
                        }
                    }
                    HStack {
                        TextField("Add a tag...", text: $viewModel.newTag)
                            .onSubmit { viewModel.addTag() }
                        Button { viewModel.addTag() } label: {
                            Image(systemName: "plus.circle.fill")
                        }
                        .disabled(viewModel.newTag.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                }

                // Advanced
                Section {
                    DisclosureGroup("Advanced Options", isExpanded: $viewModel.showAdvanced) {
                        Picker("Error Correction", selection: $viewModel.errorCorrection) {
                            ForEach(ErrorCorrectionLevel.allCases) { level in
                                Text(level.label).tag(level)
                            }
                        }

                        Picker("Size", selection: $viewModel.sizePx) {
                            Text("256px").tag(256)
                            Text("512px").tag(512)
                            Text("1024px").tag(1024)
                        }

                        Toggle("Add to Favorites", isOn: $viewModel.isFavorite)
                        Toggle("Brightness Boost", isOn: $viewModel.brightnessBoostDefault)
                    }
                }

                // Error
                if let error = viewModel.validationError {
                    Section {
                        Text(error)
                            .foregroundStyle(.red)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle("Create QR Code")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") { createQRCode() }
                        .fontWeight(.semibold)
                        .disabled(isCreating)
                }
            }
        }
    }

    @ViewBuilder
    private var typeSpecificFields: some View {
        switch viewModel.selectedType {
        case .url:
            Section("URL") {
                TextField("https://...", text: $viewModel.data)
                    .keyboardType(.URL)
                    .textContentType(.URL)
                    .autocapitalization(.none)
            }
        case .text:
            Section("Text Content") {
                TextEditor(text: $viewModel.data)
                    .frame(minHeight: 100)
            }
        case .wifi:
            WiFiFormView(data: $viewModel.wifiData)
        case .contact:
            ContactFormView(data: $viewModel.contactData)
        case .calendar:
            CalendarFormView(data: $viewModel.calendarData)
        case .file:
            Section("File URL") {
                TextField("https://...", text: $viewModel.data)
                    .keyboardType(.URL)
                    .autocapitalization(.none)
            }
        case .venmo:
            PaymentFormView(label: "Venmo Username", placeholder: "@username", hint: "Enter your Venmo username (with or without @)", text: $viewModel.data)
        case .paypal:
            PaymentFormView(label: "PayPal.me Link or Email", placeholder: "https://paypal.me/username or email@example.com", hint: "Enter your PayPal.me link or email address", text: $viewModel.data)
        case .cashapp:
            PaymentFormView(label: "CashApp $Cashtag", placeholder: "$username", hint: "Enter your CashApp $cashtag (with or without $)", text: $viewModel.data)
        case .zelle:
            PaymentFormView(label: "Zelle Email or Phone", placeholder: "email@example.com or (555) 123-4567", hint: "Enter your Zelle email address or phone number", text: $viewModel.data)
        case .crypto:
            PaymentFormView(label: "Wallet Address", placeholder: "Cryptocurrency wallet address", hint: "Enter your cryptocurrency wallet address", text: $viewModel.data)
        }
    }

    private func createQRCode() {
        guard viewModel.validate() else { return }
        isCreating = true

        let qrData = viewModel.generateQRData()
        let qrCode = QRCode(
            title: viewModel.title.trimmingCharacters(in: .whitespacesAndNewlines),
            data: qrData,
            type: viewModel.selectedType,
            tags: viewModel.tags,
            isFavorite: viewModel.isFavorite,
            errorCorrection: viewModel.errorCorrection,
            sizePx: viewModel.sizePx,
            oneTimeUse: viewModel.oneTimeUse,
            brightnessBoostDefault: viewModel.brightnessBoostDefault
        )

        modelContext.insert(qrCode)
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        dismiss()
    }
}

struct TypeCard: View {
    let type: QRType
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: type.icon)
                    .font(.subheadline)
                    .frame(width: 28, height: 28)
                    .background(isSelected ? Color.accentColor : Color.secondary.opacity(0.12))
                    .foregroundStyle(isSelected ? .white : .primary)
                    .clipShape(RoundedRectangle(cornerRadius: 6))

                VStack(alignment: .leading, spacing: 1) {
                    Text(type.label)
                        .font(.caption)
                        .fontWeight(.medium)
                    Text(type.description)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(8)
            .background(isSelected ? Color.accentColor.opacity(0.08) : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? Color.accentColor : Color.secondary.opacity(0.2), lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
    }
}
```

**Step 3: Verify build**

**Step 4: Commit**

```bash
git add QRBook/Views/Creation/ QRBook/ViewModels/QRCreationViewModel.swift
git commit -m "feat: add Create QR view with type selector and form"
```

---

### Task 11: Type-Specific Form Views

**Files:**
- Create: `QRBook/Views/Creation/WiFiFormView.swift`
- Create: `QRBook/Views/Creation/ContactFormView.swift`
- Create: `QRBook/Views/Creation/CalendarFormView.swift`
- Create: `QRBook/Views/Creation/PaymentFormView.swift`

**Step 1: WiFiFormView**

```swift
import SwiftUI

struct WiFiFormView: View {
    @Binding var data: WiFiData

    var body: some View {
        Section("WiFi Network") {
            TextField("Network Name (SSID)", text: $data.ssid)
            SecureField("Password", text: $data.password)
            Picker("Security", selection: $data.security) {
                ForEach(WiFiData.Security.allCases) { sec in
                    Text(sec.label).tag(sec)
                }
            }
            Toggle("Hidden Network", isOn: $data.hidden)
        }
    }
}
```

**Step 2: ContactFormView**

```swift
import SwiftUI

struct ContactFormView: View {
    @Binding var data: ContactData

    var body: some View {
        Section("Contact Information") {
            TextField("Full Name", text: $data.name)
                .textContentType(.name)
            TextField("Phone", text: $data.phone)
                .keyboardType(.phonePad)
                .textContentType(.telephoneNumber)
            TextField("Email", text: $data.email)
                .keyboardType(.emailAddress)
                .textContentType(.emailAddress)
                .autocapitalization(.none)
            TextField("Organization", text: $data.organization)
                .textContentType(.organizationName)
            TextField("Website", text: $data.url)
                .keyboardType(.URL)
                .autocapitalization(.none)
        }
    }
}
```

**Step 3: CalendarFormView**

```swift
import SwiftUI

struct CalendarFormView: View {
    @Binding var data: CalendarEventData

    var body: some View {
        Section("Calendar Event") {
            TextField("Event Title", text: $data.title)
            TextField("Location", text: $data.location)
            Toggle("All Day", isOn: $data.allDay)
            DatePicker("Start Date", selection: $data.startDate, displayedComponents: .date)
            if !data.allDay {
                DatePicker("Start Time", selection: $data.startTime, displayedComponents: .hourAndMinute)
            }
            DatePicker("End Date", selection: $data.endDate, displayedComponents: .date)
            if !data.allDay {
                DatePicker("End Time", selection: $data.endTime, displayedComponents: .hourAndMinute)
            }
            TextField("Description", text: $data.eventDescription, axis: .vertical)
                .lineLimit(3...6)
        }
    }
}
```

**Step 4: PaymentFormView**

```swift
import SwiftUI

struct PaymentFormView: View {
    let label: String
    let placeholder: String
    let hint: String
    @Binding var text: String

    var body: some View {
        Section(label) {
            TextField(placeholder, text: $text)
                .autocapitalization(.none)
            Text(hint)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}
```

**Step 5: Verify build**

**Step 6: Commit**

```bash
git add QRBook/Views/Creation/
git commit -m "feat: add WiFi, Contact, Calendar, and Payment form views"
```

---

### Task 12: Fullscreen QR View

**Files:**
- Create: `QRBook/Views/Fullscreen/QRFullscreenView.swift`

**Step 1: Create fullscreen QR display**

```swift
import SwiftUI

struct QRFullscreenView: View {
    @Bindable var qrCode: QRCode
    let allQRCodes: [QRCode]
    @Environment(\.dismiss) private var dismiss
    @State private var currentIndex: Int = 0
    @State private var brightnessBoost = false
    @State private var previousBrightness: CGFloat = 0.5
    @State private var dragOffset: CGFloat = 0

    private var currentQR: QRCode {
        guard currentIndex >= 0, currentIndex < allQRCodes.count else { return qrCode }
        return allQRCodes[currentIndex]
    }

    var body: some View {
        ZStack {
            // Dark background
            Color.black
                .ignoresSafeArea()
                .onTapGesture { dismiss() }

            // QR Code
            VStack(spacing: 0) {
                // Top bar
                HStack {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(.title3)
                            .foregroundStyle(.white)
                            .padding(8)
                    }

                    Text(currentQR.title)
                        .font(.headline)
                        .foregroundStyle(.white)
                        .lineLimit(1)

                    Spacer()

                    Button {
                        toggleBrightness()
                    } label: {
                        Image(systemName: brightnessBoost ? "sun.max.fill" : "sun.max")
                            .font(.title3)
                            .foregroundStyle(brightnessBoost ? .yellow : .white)
                            .padding(8)
                    }

                    ShareLink(item: currentQR.data) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.title3)
                            .foregroundStyle(.white)
                            .padding(8)
                    }

                    Button {
                        saveToPhotos()
                    } label: {
                        Image(systemName: "arrow.down.to.line")
                            .font(.title3)
                            .foregroundStyle(.white)
                            .padding(8)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 8)

                Spacer()

                // QR code card
                if let uiImage = QRGenerator.generateQRCode(
                    from: currentQR.data,
                    correctionLevel: currentQR.errorCorrection,
                    size: 320
                ) {
                    Image(uiImage: uiImage)
                        .interpolation(.none)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 280, height: 280)
                        .padding(32)
                        .background(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .shadow(radius: 20)
                        .offset(x: dragOffset)
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    dragOffset = value.translation.width
                                }
                                .onEnded { value in
                                    let threshold: CGFloat = 50
                                    withAnimation(.spring(response: 0.3)) {
                                        if value.translation.width < -threshold, currentIndex < allQRCodes.count - 1 {
                                            currentIndex += 1
                                            recordScan()
                                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                        } else if value.translation.width > threshold, currentIndex > 0 {
                                            currentIndex -= 1
                                            recordScan()
                                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                        }
                                        dragOffset = 0
                                    }
                                }
                        )
                }

                Spacer()

                // Bottom info
                VStack(spacing: 4) {
                    if allQRCodes.count > 1 {
                        Text("\(currentIndex + 1) of \(allQRCodes.count)")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.8))
                    }
                    Text("Swipe to navigate \u{2022} Tap background to close")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.5))
                }
                .padding(.bottom, 16)
            }
        }
        .onAppear {
            currentIndex = allQRCodes.firstIndex(where: { $0.id == qrCode.id }) ?? 0
            previousBrightness = UIScreen.main.brightness
            if qrCode.brightnessBoostDefault {
                brightnessBoost = true
                UIScreen.main.brightness = 1.0
            }
            UIApplication.shared.isIdleTimerDisabled = true
            recordScan()
        }
        .onDisappear {
            if brightnessBoost {
                UIScreen.main.brightness = previousBrightness
            }
            UIApplication.shared.isIdleTimerDisabled = false
        }
        .statusBarHidden()
    }

    private func toggleBrightness() {
        brightnessBoost.toggle()
        if brightnessBoost {
            previousBrightness = UIScreen.main.brightness
            UIScreen.main.brightness = 1.0
        } else {
            UIScreen.main.brightness = previousBrightness
        }
    }

    private func recordScan() {
        currentQR.scanCount += 1
        currentQR.lastUsed = .now
    }

    private func saveToPhotos() {
        guard let image = QRGenerator.generateQRCode(
            from: currentQR.data,
            correctionLevel: currentQR.errorCorrection,
            size: CGFloat(currentQR.sizePx)
        ) else { return }
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
}
```

**Step 2: Verify build**

**Step 3: Commit**

```bash
git add QRBook/Views/Fullscreen/QRFullscreenView.swift
git commit -m "feat: add fullscreen QR display with brightness boost and swipe nav"
```

---

### Task 13: Settings View

**Files:**
- Create: `QRBook/Views/Settings/SettingsView.swift`

**Step 1: Create settings view**

```swift
import SwiftUI
import SwiftData

struct SettingsView: View {
    @AppStorage("defaultSize") private var defaultSize = 512
    @AppStorage("defaultErrorCorrection") private var defaultErrorCorrection = "M"
    @AppStorage("defaultBrightnessBoost") private var defaultBrightnessBoost = true
    @AppStorage("defaultAutoFavorite") private var defaultAutoFavorite = false

    @Query private var qrCodes: [QRCode]
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        List {
            // Stats
            Section("Account") {
                LabeledContent("Total QR Codes", value: "\(qrCodes.count)")
                LabeledContent("Favorites", value: "\(qrCodes.filter(\.isFavorite).count)")
            }

            // Defaults
            Section("Default Settings") {
                Picker("QR Size", selection: $defaultSize) {
                    Text("256px - Small").tag(256)
                    Text("512px - Medium").tag(512)
                    Text("1024px - Large").tag(1024)
                }

                Picker("Error Correction", selection: $defaultErrorCorrection) {
                    Text("Low (~7%)").tag("L")
                    Text("Medium (~15%)").tag("M")
                    Text("Quartile (~25%)").tag("Q")
                    Text("High (~30%)").tag("H")
                }

                Toggle("Brightness Boost by Default", isOn: $defaultBrightnessBoost)
                Toggle("Auto-Favorite New QR Codes", isOn: $defaultAutoFavorite)
            }

            // Data
            Section("Data") {
                Button {
                    exportData()
                } label: {
                    Label("Export All QR Codes", systemImage: "square.and.arrow.up")
                }
                .disabled(qrCodes.isEmpty)
            }

            // About
            Section("About") {
                LabeledContent("Version", value: "1.0.0")
                LabeledContent("iCloud Sync", value: "Enabled")
            }
        }
        .navigationTitle("Settings")
    }

    private func exportData() {
        let exportItems: [[String: Any]] = qrCodes.map { qr in
            [
                "id": qr.id.uuidString,
                "title": qr.title,
                "data": qr.data,
                "type": qr.typeRaw,
                "tags": qr.tags,
                "isFavorite": qr.isFavorite,
                "scanCount": qr.scanCount,
                "createdAt": ISO8601DateFormatter().string(from: qr.createdAt)
            ]
        }

        guard let jsonData = try? JSONSerialization.data(withJSONObject: exportItems, options: .prettyPrinted),
              let jsonString = String(data: jsonData, encoding: .utf8) else { return }

        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("qrbook-export.json")
        try? jsonString.write(to: tempURL, atomically: true, encoding: .utf8)

        let activityVC = UIActivityViewController(activityItems: [tempURL], applicationActivities: nil)

        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            rootVC.present(activityVC, animated: true)
        }
    }
}
```

**Step 2: Verify build**

**Step 3: Commit**

```bash
git add QRBook/Views/Settings/SettingsView.swift
git commit -m "feat: add settings view with preferences and data export"
```

---

### Task 14: Wire Everything Together & Final Build

**Step 1: Ensure all placeholder references compile**

Make sure QRLibraryView, CreateQRView, QRFullscreenView, and SettingsView are all referenced correctly from MainTabView.

**Step 2: Enable iCloud capability**

Add CloudKit entitlement to the project:
- Add `QRBook.entitlements` file with CloudKit and iCloud Documents
- Add `com.apple.developer.icloud-container-identifiers` with `iCloud.com.gyndok.QRBook`

**Step 3: Full build and verify in simulator**

```bash
/Applications/Xcode.app/Contents/Developer/usr/bin/xcodebuild \
  -project QRBook.xcodeproj \
  -scheme QRBook \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  build
```

**Step 4: Commit**

```bash
git add -A
git commit -m "feat: wire all views together, enable iCloud, initial working build"
```

---

## Summary

| Task | What It Builds |
|------|---------------|
| 1 | Xcode project scaffold |
| 2 | QRCode SwiftData model (all 11 types) |
| 3 | CoreImage QR generator |
| 4 | WiFi/vCard/iCal/payment data encoders |
| 5 | Input validation |
| 6 | Tab bar (Library, Favorites, Recent, Flyers) |
| 7 | QR Library with search/sort/filter |
| 8 | QR Card with preview, tags, context menu |
| 9 | Filter sheet |
| 10 | Create QR form + type selector |
| 11 | WiFi, Contact, Calendar, Payment forms |
| 12 | Fullscreen QR display + brightness + swipe |
| 13 | Settings + preferences + export |
| 14 | Wire together + iCloud + final build |
