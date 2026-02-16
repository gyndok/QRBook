# QR Book Phase 2 Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add 17 features to QR Book across 5 waves: themes/styling, core UX, scanner/sharing, system integrations, and new targets (widgets, watch, flyers).

**Architecture:** SwiftUI + MVVM + SwiftData. No external dependencies. New Xcode targets for Widget Extension, watchOS App, and Share Extension. App Group for cross-process data sharing. Deep link router for system integration navigation.

**Tech Stack:** SwiftUI, SwiftData, CoreImage, VisionKit (DataScannerViewController), WidgetKit, WatchConnectivity, CoreSpotlight, App Intents, PhotosUI, ImageRenderer

---

## Wave 1: Data Model & Theme Foundations

### Task 1: Add new fields to QRCode model

**Files:**
- Modify: `QRBook/Models/QRCode.swift`

**Step 1: Add new stored properties**

Add after line 111 (`var lastUsed: Date?`):

```swift
    var folderName: String = ""
    var foregroundHex: String = ""
    var backgroundHex: String = ""
    var logoImageData: Data?
```

**Step 2: Add new parameters to initializer**

Update the init (lines 138-170) to accept the new fields. Add parameters after `lastUsed`:

```swift
    init(
        id: UUID = UUID(),
        title: String,
        data: String,
        type: QRType = .url,
        tags: [String] = [],
        isFavorite: Bool = false,
        errorCorrection: ErrorCorrectionLevel = .M,
        sizePx: Int = 300,
        oneTimeUse: Bool = false,
        expiresAt: Date? = nil,
        scanCount: Int = 0,
        brightnessBoostDefault: Bool = false,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        lastUsed: Date? = nil,
        folderName: String = "",
        foregroundHex: String = "",
        backgroundHex: String = "",
        logoImageData: Data? = nil
    ) {
        self.id = id
        self.title = title
        self.data = data
        self.typeRaw = type.rawValue
        self.tagsRaw = tags.joined(separator: ",")
        self.isFavorite = isFavorite
        self.errorCorrectionRaw = errorCorrection.rawValue
        self.sizePx = sizePx
        self.oneTimeUse = oneTimeUse
        self.expiresAt = expiresAt
        self.scanCount = scanCount
        self.brightnessBoostDefault = brightnessBoostDefault
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.lastUsed = lastUsed
        self.folderName = folderName
        self.foregroundHex = foregroundHex
        self.backgroundHex = backgroundHex
        self.logoImageData = logoImageData
    }
```

**Step 3: Build and verify**

Run: `/Applications/Xcode.app/Contents/Developer/usr/bin/xcodebuild -scheme QRBook -project QRBook.xcodeproj -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.4' -quiet build 2>&1`
Expected: BUILD SUCCEEDED

**Step 4: Commit**

```bash
git add QRBook/Models/QRCode.swift
git commit -m "feat: add folder, color, and logo fields to QRCode model"
```

---

### Task 2: Create Folder and ScanEvent models

**Files:**
- Create: `QRBook/Models/Folder.swift`
- Create: `QRBook/Models/ScanEvent.swift`
- Modify: `QRBook/QRBookApp.swift` (register new models in container)
- Modify: `QRBook.xcodeproj/project.pbxproj` (add file references)

**Step 1: Create Folder.swift**

```swift
import Foundation
import SwiftData

@Model
final class Folder {
    var id: UUID = UUID()
    var name: String = ""
    var iconName: String = "folder.fill"
    var colorHex: String = "7C3AED"
    var createdAt: Date = Date()
    var sortOrder: Int = 0

    init(
        id: UUID = UUID(),
        name: String,
        iconName: String = "folder.fill",
        colorHex: String = "7C3AED",
        createdAt: Date = Date(),
        sortOrder: Int = 0
    ) {
        self.id = id
        self.name = name
        self.iconName = iconName
        self.colorHex = colorHex
        self.createdAt = createdAt
        self.sortOrder = sortOrder
    }
}
```

**Step 2: Create ScanEvent.swift**

```swift
import Foundation
import SwiftData

@Model
final class ScanEvent {
    var id: UUID = UUID()
    var qrCodeId: UUID = UUID()
    var timestamp: Date = Date()

    init(
        id: UUID = UUID(),
        qrCodeId: UUID,
        timestamp: Date = Date()
    ) {
        self.id = id
        self.qrCodeId = qrCodeId
        self.timestamp = timestamp
    }
}
```

**Step 3: Update QRBookApp.swift model container**

Change line 27 from:
```swift
        .modelContainer(for: QRCode.self)
```
to:
```swift
        .modelContainer(for: [QRCode.self, Folder.self, ScanEvent.self])
```

**Step 4: Add file references to project.pbxproj**

Add PBXBuildFile entries (after BB000050):
```
BB000051 /* Folder.swift in Sources */ = {isa = PBXBuildFile; fileRef = CC000051 /* Folder.swift */; };
BB000052 /* ScanEvent.swift in Sources */ = {isa = PBXBuildFile; fileRef = CC000052 /* ScanEvent.swift */; };
```

Add PBXFileReference entries (after CC000050):
```
CC000051 /* Folder.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = Folder.swift; sourceTree = "<group>"; };
CC000052 /* ScanEvent.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = ScanEvent.swift; sourceTree = "<group>"; };
```

Add to Models group DD000001 children (after CC000002):
```
CC000051 /* Folder.swift */,
CC000052 /* ScanEvent.swift */,
```

Add to Sources build phase AA000200 files:
```
BB000051 /* Folder.swift in Sources */,
BB000052 /* ScanEvent.swift in Sources */,
```

**Step 5: Build and verify**

Run: xcodebuild build (same command as Task 1 Step 3)
Expected: BUILD SUCCEEDED

**Step 6: Commit**

```bash
git add QRBook/Models/Folder.swift QRBook/Models/ScanEvent.swift QRBook/QRBookApp.swift QRBook.xcodeproj/project.pbxproj
git commit -m "feat: add Folder and ScanEvent data models"
```

---

### Task 3: Implement dynamic theme system

**Files:**
- Modify: `QRBook/Theme/AppTheme.swift`
- Create: `QRBook/Views/Settings/AppearanceSettingsView.swift`
- Modify: `QRBook/Views/Settings/SettingsView.swift`
- Modify: `QRBook/QRBookApp.swift`
- Modify: `QRBook.xcodeproj/project.pbxproj`

**Step 1: Refactor AppTheme.swift for dynamic accent colors**

Replace `Color.electricViolet` and `Color.deepIndigo` static properties with computed properties that read from UserDefaults. Add an `AccentTheme` enum.

Add after the `Color(light:dark:)` init (after line 25):

```swift
    // Accent theme
    enum AccentTheme: String, CaseIterable, Identifiable {
        case violet = "7C3AED"
        case indigo = "4F46E5"
        case teal = "14B8A6"
        case rose = "F43F5E"
        case orange = "F97316"
        case mono = "6B7280"

        var id: String { rawValue }

        var label: String {
            switch self {
            case .violet: return "Violet"
            case .indigo: return "Indigo"
            case .teal: return "Teal"
            case .rose: return "Rose"
            case .orange: return "Orange"
            case .mono: return "Mono"
            }
        }

        var color: Color { Color(hex: rawValue) }

        var companionHex: String {
            switch self {
            case .violet: return "4F46E5"
            case .indigo: return "6366F1"
            case .teal: return "0D9488"
            case .rose: return "E11D48"
            case .orange: return "EA580C"
            case .mono: return "4B5563"
            }
        }

        var companionColor: Color { Color(hex: companionHex) }
    }
```

Replace the static `electricViolet` and `deepIndigo` (lines 28-29):

```swift
    static var electricViolet: Color {
        let hex = UserDefaults.standard.string(forKey: "accentColorHex") ?? "7C3AED"
        return Color(hex: hex)
    }

    static var deepIndigo: Color {
        let hex = UserDefaults.standard.string(forKey: "accentColorHex") ?? "7C3AED"
        let theme = AccentTheme(rawValue: hex) ?? .violet
        return theme.companionColor
    }
```

**Step 2: Update QRBookApp.swift to support appearance mode**

Replace the `.preferredColorScheme(.dark)` line with dynamic reading:

```swift
@main
struct QRBookApp: App {
    @State private var showSplash = true
    @AppStorage("appearanceMode") private var appearanceMode = "dark"

    private var colorScheme: ColorScheme? {
        switch appearanceMode {
        case "light": return .light
        case "dark": return .dark
        default: return nil  // system
        }
    }

    var body: some Scene {
        WindowGroup {
            ZStack {
                MainTabView()
                    .preferredColorScheme(colorScheme)
                    .tint(Color.electricViolet)

                if showSplash {
                    SplashView()
                        .transition(.opacity)
                }
            }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
                    withAnimation(.easeOut(duration: 0.4)) {
                        showSplash = false
                    }
                }
            }
        }
        .modelContainer(for: [QRCode.self, Folder.self, ScanEvent.self])
    }
}
```

**Step 3: Create AppearanceSettingsView.swift**

```swift
import SwiftUI

struct AppearanceSettingsView: View {
    @AppStorage("accentColorHex") private var accentColorHex = "7C3AED"
    @AppStorage("appearanceMode") private var appearanceMode = "dark"

    var body: some View {
        List {
            Section("Accent Color") {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(Color.AccentTheme.allCases) { theme in
                            Button {
                                withAnimation { accentColorHex = theme.rawValue }
                            } label: {
                                VStack(spacing: 6) {
                                    Circle()
                                        .fill(theme.color)
                                        .frame(width: 44, height: 44)
                                        .overlay {
                                            if accentColorHex == theme.rawValue {
                                                Image(systemName: "checkmark")
                                                    .font(.headline)
                                                    .foregroundStyle(.white)
                                            }
                                        }
                                        .overlay {
                                            Circle()
                                                .stroke(accentColorHex == theme.rawValue ? theme.color : .clear, lineWidth: 3)
                                                .padding(-4)
                                        }
                                    Text(theme.label)
                                        .font(.caption2)
                                        .foregroundStyle(accentColorHex == theme.rawValue ? theme.color : .secondary)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 8)
                }
                .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
            }

            Section("Appearance") {
                Picker("Mode", selection: $appearanceMode) {
                    Text("System").tag("system")
                    Text("Light").tag("light")
                    Text("Dark").tag("dark")
                }
                .pickerStyle(.segmented)
                .listRowInsets(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16))
            }
        }
        .navigationTitle("Appearance")
    }
}
```

**Step 4: Add Appearance link to SettingsView.swift**

Add after the "Default Settings" section (after line 46):

```swift
            Section("Appearance") {
                NavigationLink {
                    AppearanceSettingsView()
                } label: {
                    Label("Accent Color & Theme", systemImage: "paintpalette")
                }
            }
```

**Step 5: Add AppearanceSettingsView to project.pbxproj**

Add PBXBuildFile: `BB000053 /* AppearanceSettingsView.swift in Sources */`
Add PBXFileReference: `CC000053 /* AppearanceSettingsView.swift */`
Add to Settings group DD000009 children.
Add to Sources build phase.

**Step 6: Build and verify**

**Step 7: Commit**

```bash
git add -A && git commit -m "feat: add dynamic theme system with 6 accent colors and light/dark/system mode"
```

---

### Task 4: Implement custom QR colors with CIFalseColor

**Files:**
- Modify: `QRBook/Utilities/QRGenerator.swift`
- Modify: `QRBook/Views/Creation/CreateQRView.swift`
- Modify: `QRBook/ViewModels/QRCreationViewModel.swift`
- Modify: `QRBook/Views/Library/QRCardView.swift`
- Modify: `QRBook/Views/Fullscreen/QRFullscreenView.swift`

**Step 1: Update QRGenerator to support color tinting**

Replace the entire `QRGenerator` struct:

```swift
import CoreImage
import CoreImage.CIFilterBuiltins
import UIKit

struct QRGenerator {
    static func generateQRCode(
        from string: String,
        correctionLevel: ErrorCorrectionLevel = .M,
        size: CGFloat = 512,
        foregroundHex: String = "",
        backgroundHex: String = "",
        logoImageData: Data? = nil
    ) -> UIImage? {
        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()

        guard let data = string.data(using: .utf8) else { return nil }
        filter.message = data
        filter.correctionLevel = correctionLevel.rawValue

        guard var ciImage = filter.outputImage else { return nil }

        // Apply custom colors
        if !foregroundHex.isEmpty || !backgroundHex.isEmpty {
            let fgColor = CIColor(color: UIColor(Color(hex: foregroundHex.isEmpty ? "000000" : foregroundHex)))
            let bgColor = CIColor(color: UIColor(Color(hex: backgroundHex.isEmpty ? "FFFFFF" : backgroundHex)))
            let colorFilter = CIFilter.falseColor()
            colorFilter.inputImage = ciImage
            colorFilter.color0 = fgColor
            colorFilter.color1 = bgColor
            if let colored = colorFilter.outputImage {
                ciImage = colored
            }
        }

        let scaleX = size / ciImage.extent.size.width
        let scaleY = size / ciImage.extent.size.height
        let scaledImage = ciImage.transformed(by: CGAffineTransform(scaleX: scaleX, y: scaleY))

        guard let cgImage = context.createCGImage(scaledImage, from: scaledImage.extent) else {
            return nil
        }

        var result = UIImage(cgImage: cgImage)

        // Composite logo overlay
        if let logoData = logoImageData, let logo = UIImage(data: logoData) {
            result = compositeLogoOnQR(qrImage: result, logo: logo)
        }

        return result
    }

    static func generateQRImage(for qrCode: QRCode) -> UIImage? {
        generateQRCode(
            from: qrCode.data,
            correctionLevel: qrCode.errorCorrection,
            size: CGFloat(qrCode.sizePx),
            foregroundHex: qrCode.foregroundHex,
            backgroundHex: qrCode.backgroundHex,
            logoImageData: qrCode.logoImageData
        )
    }

    private static func compositeLogoOnQR(qrImage: UIImage, logo: UIImage) -> UIImage {
        let qrSize = qrImage.size
        let logoSize = CGSize(width: qrSize.width * 0.2, height: qrSize.height * 0.2)
        let logoOrigin = CGPoint(
            x: (qrSize.width - logoSize.width) / 2,
            y: (qrSize.height - logoSize.height) / 2
        )

        let renderer = UIGraphicsImageRenderer(size: qrSize)
        return renderer.image { ctx in
            qrImage.draw(in: CGRect(origin: .zero, size: qrSize))

            // White background circle behind logo
            let padding: CGFloat = 4
            let bgRect = CGRect(
                x: logoOrigin.x - padding,
                y: logoOrigin.y - padding,
                width: logoSize.width + padding * 2,
                height: logoSize.height + padding * 2
            )
            UIColor.white.setFill()
            UIBezierPath(roundedRect: bgRect, cornerRadius: bgRect.width * 0.2).fill()

            // Draw logo
            let logoRect = CGRect(origin: logoOrigin, size: logoSize)
            let clipPath = UIBezierPath(roundedRect: logoRect, cornerRadius: logoRect.width * 0.15)
            clipPath.addClip()
            logo.draw(in: logoRect)
        }
    }
}
```

**Step 2: Add color and logo fields to QRCreationViewModel**

Add new properties after `brightnessBoostDefault` (line 14):

```swift
    var foregroundHex = ""
    var backgroundHex = ""
    var foregroundColor: Color = .black
    var backgroundColor: Color = .white
    var logoImageData: Data?
    var showLogoPicker = false
```

Add method:

```swift
    func syncColors() {
        if let components = UIColor(foregroundColor).cgColor.components, components.count >= 3 {
            foregroundHex = String(format: "%02X%02X%02X", Int(components[0] * 255), Int(components[1] * 255), Int(components[2] * 255))
        }
        if let components = UIColor(backgroundColor).cgColor.components, components.count >= 3 {
            backgroundHex = String(format: "%02X%02X%02X", Int(components[0] * 255), Int(components[1] * 255), Int(components[2] * 255))
        }
    }
```

**Step 3: Add color pickers and logo picker to CreateQRView Advanced Options**

Inside the DisclosureGroup in CreateQRView (after the Brightness Boost toggle, line 85), add:

```swift
                        ColorPicker("QR Foreground", selection: $viewModel.foregroundColor, supportsOpacity: false)
                            .onChange(of: viewModel.foregroundColor) { viewModel.syncColors() }
                        ColorPicker("QR Background", selection: $viewModel.backgroundColor, supportsOpacity: false)
                            .onChange(of: viewModel.backgroundColor) { viewModel.syncColors() }

                        HStack {
                            Text("Logo Overlay")
                            Spacer()
                            if viewModel.logoImageData != nil {
                                Button("Remove") {
                                    viewModel.logoImageData = nil
                                }
                                .foregroundStyle(.red)
                            }
                            PhotosPicker(selection: Binding(
                                get: { nil },
                                set: { item in
                                    Task {
                                        if let data = try? await item?.loadTransferable(type: Data.self) {
                                            viewModel.logoImageData = data
                                            // Auto-bump error correction for logo readability
                                            if viewModel.errorCorrection.rawValue < "Q" {
                                                viewModel.errorCorrection = .Q
                                            }
                                        }
                                    }
                                }
                            ), matching: .images) {
                                Text(viewModel.logoImageData == nil ? "Add Logo" : "Change")
                            }
                        }
```

Also add `import PhotosUI` at top of CreateQRView.swift.

**Step 4: Pass new fields when creating QR code**

Update `createQRCode()` in CreateQRView.swift — add to the QRCode init call:

```swift
            folderName: viewModel.folderName,
            foregroundHex: viewModel.foregroundHex,
            backgroundHex: viewModel.backgroundHex,
            logoImageData: viewModel.logoImageData
```

**Step 5: Update QRCardView to pass colors to generator**

Replace the QR preview generation in QRCardView (lines 37-40):

```swift
                if let uiImage = QRGenerator.generateQRCode(
                    from: qrCode.data,
                    correctionLevel: qrCode.errorCorrection,
                    size: 120,
                    foregroundHex: qrCode.foregroundHex,
                    backgroundHex: qrCode.backgroundHex,
                    logoImageData: qrCode.logoImageData
                ) {
```

**Step 6: Update QRFullscreenView to pass colors to generator**

Replace the QR generation in QRFullscreenView (lines 75-78):

```swift
                if let uiImage = QRGenerator.generateQRCode(
                    from: currentQR.data,
                    correctionLevel: currentQR.errorCorrection,
                    size: 320,
                    foregroundHex: currentQR.foregroundHex,
                    backgroundHex: currentQR.backgroundHex,
                    logoImageData: currentQR.logoImageData
                ) {
```

Also update `saveToPhotos()` similarly.

**Step 7: Build and verify**

**Step 8: Commit**

```bash
git add -A && git commit -m "feat: add custom QR colors and logo overlay support"
```

---

### Task 5: Implement folders system

**Files:**
- Create: `QRBook/Views/Folders/ManageFoldersView.swift`
- Modify: `QRBook/Views/Library/QRLibraryView.swift` (folder filter bar)
- Modify: `QRBook/ViewModels/QRLibraryViewModel.swift` (folder filter)
- Modify: `QRBook/ViewModels/QRCreationViewModel.swift` (folder picker state)
- Modify: `QRBook/Views/Creation/CreateQRView.swift` (folder picker)
- Modify: `QRBook/Views/Library/QRCardView.swift` (move to folder context menu)
- Modify: `QRBook/Views/Settings/SettingsView.swift` (manage folders link)
- Modify: `QRBook.xcodeproj/project.pbxproj`

**Step 1: Create ManageFoldersView.swift**

```swift
import SwiftUI
import SwiftData

struct ManageFoldersView: View {
    @Query(sort: \Folder.sortOrder) private var folders: [Folder]
    @Environment(\.modelContext) private var modelContext
    @State private var newFolderName = ""
    @State private var editingFolder: Folder?

    var body: some View {
        List {
            Section("Create Folder") {
                HStack {
                    TextField("Folder name...", text: $newFolderName)
                    Button {
                        createFolder()
                    } label: {
                        Image(systemName: "plus.circle.fill")
                    }
                    .disabled(newFolderName.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }

            Section("Folders") {
                if folders.isEmpty {
                    Text("No folders yet")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(folders) { folder in
                        HStack {
                            Image(systemName: folder.iconName)
                                .foregroundStyle(Color(hex: folder.colorHex))
                            Text(folder.name)
                            Spacer()
                        }
                        .contextMenu {
                            Button(role: .destructive) {
                                modelContext.delete(folder)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                    .onDelete { indexSet in
                        for index in indexSet {
                            modelContext.delete(folders[index])
                        }
                    }
                }
            }
        }
        .navigationTitle("Manage Folders")
    }

    private func createFolder() {
        let name = newFolderName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }
        guard !folders.contains(where: { $0.name == name }) else { return }

        let folder = Folder(name: name, sortOrder: folders.count)
        modelContext.insert(folder)
        newFolderName = ""
    }
}
```

**Step 2: Add folder filter to QRLibraryViewModel**

Add property after `filterTags` (line 18):

```swift
    var filterFolder: String? = nil
```

In `filteredAndSorted()`, add folder filter after the tag filter block (after line 62):

```swift
        // Folder filter
        if let filterFolder {
            result = result.filter { $0.folderName == filterFolder }
        }
```

Update `activeFilterCount` to include folder:

```swift
    var activeFilterCount: Int {
        var count = 0
        if filterType != nil { count += 1 }
        if filterFavoritesOnly { count += 1 }
        if !filterTags.isEmpty { count += 1 }
        if filterFolder != nil { count += 1 }
        return count
    }
```

Update `clearFilters()`:

```swift
    func clearFilters() {
        searchText = ""
        filterType = nil
        filterFavoritesOnly = false
        filterTags = []
        filterFolder = nil
    }
```

**Step 3: Add folder bar to QRLibraryView**

Add `@Query(sort: \Folder.sortOrder) private var folders: [Folder]` at top of QRLibraryView.

Add a horizontal folder scroll bar above the sort/filter bar in qrGrid (before the HStack at line 76):

```swift
                // Folder bar
                if !folders.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            FilterChip(
                                label: "All",
                                isSelected: viewModel.filterFolder == nil
                            ) {
                                viewModel.filterFolder = nil
                            }
                            ForEach(folders) { folder in
                                FilterChip(
                                    label: folder.name,
                                    isSelected: viewModel.filterFolder == folder.name
                                ) {
                                    viewModel.filterFolder = viewModel.filterFolder == folder.name ? nil : folder.name
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.vertical, 4)
                }
```

**Step 4: Add folder picker to CreateQRView and QRCreationViewModel**

Add `var folderName = ""` to QRCreationViewModel.

In CreateQRView, add a Folder picker section after the Tags section:

```swift
                // Folder
                Section("Folder") {
                    Picker("Folder", selection: $viewModel.folderName) {
                        Text("None").tag("")
                        ForEach(folders) { folder in
                            Label(folder.name, systemImage: folder.iconName).tag(folder.name)
                        }
                    }
                }
```

Add `@Query(sort: \Folder.sortOrder) private var folders: [Folder]` to CreateQRView.

**Step 5: Add "Move to Folder" to QRCardView context menu**

This requires passing folders into QRCardView or using @Query inside it. Add `@Query(sort: \Folder.sortOrder) private var folders: [Folder]` to QRCardView.

Add to context menu (before the Delete divider):

```swift
            Menu("Move to Folder") {
                Button("None") { qrCode.folderName = "" }
                ForEach(folders) { folder in
                    Button(folder.name) { qrCode.folderName = folder.name }
                }
            }
```

**Step 6: Add Manage Folders link to SettingsView**

Add in the Data section:

```swift
                NavigationLink {
                    ManageFoldersView()
                } label: {
                    Label("Manage Folders", systemImage: "folder")
                }
```

**Step 7: Add ManageFoldersView to project.pbxproj**

Create Folders group DD000011 under Views DD000003. Add file reference CC000054, build file BB000054.

**Step 8: Build and verify**

**Step 9: Commit**

```bash
git add -A && git commit -m "feat: add folders system with create, assign, filter, and manage"
```

---

## Wave 2: Core UX Features

### Task 6: Create HapticManager utility

**Files:**
- Create: `QRBook/Utilities/HapticManager.swift`
- Modify: `QRBook.xcodeproj/project.pbxproj`

**Step 1: Create HapticManager.swift**

```swift
import UIKit

enum HapticManager {
    static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }

    static func success() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    static func error() {
        UINotificationFeedbackGenerator().notificationOccurred(.error)
    }

    static func selection() {
        UISelectionFeedbackGenerator().selectionChanged()
    }
}
```

**Step 2: Add to project.pbxproj**

PBXFileReference CC000055, PBXBuildFile BB000055. Add to Utilities group DD000004 and Sources build phase.

**Step 3: Replace scattered haptic calls throughout codebase**

In CreateQRView.swift line 175, replace:
```swift
        UINotificationFeedbackGenerator().notificationOccurred(.success)
```
with:
```swift
        HapticManager.success()
```

In QRFullscreenView.swift lines 102/106, replace:
```swift
                                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
```
with:
```swift
                                            HapticManager.impact()
```

In QRFullscreenView.swift line 171, replace:
```swift
        UINotificationFeedbackGenerator().notificationOccurred(.success)
```
with:
```swift
        HapticManager.success()
```

**Step 4: Add haptics to favorite toggle in QRCardView**

After `qrCode.isFavorite.toggle()` (line 24), add:
```swift
                            HapticManager.impact(.light)
```

**Step 5: Build, verify, commit**

```bash
git add -A && git commit -m "feat: add HapticManager and wire haptics throughout app"
```

---

### Task 7: Create QRDataDecoder for edit support

**Files:**
- Create: `QRBook/Utilities/QRDataDecoder.swift`
- Modify: `QRBook.xcodeproj/project.pbxproj`

**Step 1: Create QRDataDecoder.swift**

```swift
import Foundation

enum QRDataDecoder {

    static func decodeWiFi(from data: String) -> WiFiData? {
        // Format: WIFI:T:WPA;S:MyNetwork;P:MyPass;H:false;;
        guard data.hasPrefix("WIFI:") else { return nil }
        var ssid = "", password = "", hidden = false
        var security: WiFiData.Security = .WPA

        let content = data.dropFirst(5) // Remove "WIFI:"
        let parts = content.components(separatedBy: ";")
        for part in parts {
            if part.hasPrefix("T:") {
                let val = String(part.dropFirst(2))
                security = WiFiData.Security(rawValue: val) ?? .WPA
            } else if part.hasPrefix("S:") {
                ssid = String(part.dropFirst(2))
            } else if part.hasPrefix("P:") {
                password = String(part.dropFirst(2))
            } else if part.hasPrefix("H:") {
                hidden = String(part.dropFirst(2)).lowercased() == "true"
            }
        }
        return WiFiData(ssid: ssid, password: password, security: security, hidden: hidden)
    }

    static func decodeContact(from data: String) -> ContactData? {
        guard data.contains("BEGIN:VCARD") else { return nil }
        var contact = ContactData()
        let lines = data.components(separatedBy: "\n")
        for line in lines {
            if line.hasPrefix("FN:") {
                contact.name = String(line.dropFirst(3))
            } else if line.hasPrefix("TEL") {
                if let colonIdx = line.firstIndex(of: ":") {
                    contact.phone = String(line[line.index(after: colonIdx)...])
                }
            } else if line.hasPrefix("EMAIL:") {
                contact.email = String(line.dropFirst(6))
            } else if line.hasPrefix("ORG:") {
                contact.organization = String(line.dropFirst(4))
            } else if line.hasPrefix("URL:") {
                contact.url = String(line.dropFirst(4))
            }
        }
        return contact
    }

    static func decodeCalendarEvent(from data: String) -> CalendarEventData? {
        guard data.contains("BEGIN:VEVENT") else { return nil }
        var event = CalendarEventData()
        let lines = data.components(separatedBy: "\n")
        let dateFormatter = DateFormatter()

        for line in lines {
            if line.hasPrefix("SUMMARY:") {
                event.title = String(line.dropFirst(8))
            } else if line.hasPrefix("LOCATION:") {
                event.location = String(line.dropFirst(9))
            } else if line.hasPrefix("DESCRIPTION:") {
                event.eventDescription = String(line.dropFirst(12))
            } else if line.hasPrefix("DTSTART;VALUE=DATE:") {
                event.allDay = true
                dateFormatter.dateFormat = "yyyyMMdd"
                if let d = dateFormatter.date(from: String(line.dropFirst(19))) {
                    event.startDate = d
                }
            } else if line.hasPrefix("DTEND;VALUE=DATE:") {
                dateFormatter.dateFormat = "yyyyMMdd"
                if let d = dateFormatter.date(from: String(line.dropFirst(17))) {
                    event.endDate = d
                }
            } else if line.hasPrefix("DTSTART:") {
                dateFormatter.dateFormat = "yyyyMMdd'T'HHmmss"
                if let d = dateFormatter.date(from: String(line.dropFirst(8))) {
                    event.startDate = d
                    event.startTime = d
                }
            } else if line.hasPrefix("DTEND:") {
                dateFormatter.dateFormat = "yyyyMMdd'T'HHmmss"
                if let d = dateFormatter.date(from: String(line.dropFirst(6))) {
                    event.endDate = d
                    event.endTime = d
                }
            }
        }
        return event
    }

    static func decodePayment(from data: String, type: QRType) -> String {
        switch type {
        case .venmo:
            return data.replacingOccurrences(of: "https://venmo.com/", with: "")
        case .paypal:
            return data.replacingOccurrences(of: "https://www.paypal.com/paypalme/", with: "")
        case .cashapp:
            return data.replacingOccurrences(of: "https://cash.app/$", with: "")
        case .zelle:
            return data.replacingOccurrences(of: "Zelle: ", with: "")
        default:
            return data
        }
    }
}
```

**Step 2: Add to project.pbxproj**

CC000056 / BB000056, add to Utilities group and Sources phase.

**Step 3: Build, verify, commit**

```bash
git add -A && git commit -m "feat: add QRDataDecoder for parsing encoded QR data back into form structs"
```

---

### Task 8: Implement Edit QR Code

**Files:**
- Create: `QRBook/Views/Creation/EditQRView.swift`
- Modify: `QRBook/Views/Library/QRCardView.swift` (add Edit to context menu)
- Modify: `QRBook/Views/Fullscreen/QRFullscreenView.swift` (add Edit button)
- Modify: `QRBook.xcodeproj/project.pbxproj`

**Step 1: Create EditQRView.swift**

This view reuses the same form structure as CreateQRView but pre-populates from an existing QRCode and updates it in-place.

```swift
import SwiftUI
import SwiftData
import PhotosUI

struct EditQRView: View {
    @Bindable var qrCode: QRCode
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Folder.sortOrder) private var folders: [Folder]
    @State private var viewModel: QRCreationViewModel

    init(qrCode: QRCode) {
        self.qrCode = qrCode
        let vm = QRCreationViewModel()
        vm.selectedType = qrCode.type
        vm.title = qrCode.title
        vm.tags = qrCode.tags
        vm.isFavorite = qrCode.isFavorite
        vm.errorCorrection = qrCode.errorCorrection
        vm.sizePx = qrCode.sizePx
        vm.oneTimeUse = qrCode.oneTimeUse
        vm.brightnessBoostDefault = qrCode.brightnessBoostDefault
        vm.folderName = qrCode.folderName
        vm.foregroundHex = qrCode.foregroundHex
        vm.backgroundHex = qrCode.backgroundHex
        vm.logoImageData = qrCode.logoImageData

        if !qrCode.foregroundHex.isEmpty {
            vm.foregroundColor = Color(hex: qrCode.foregroundHex)
        }
        if !qrCode.backgroundHex.isEmpty {
            vm.backgroundColor = Color(hex: qrCode.backgroundHex)
        }

        // Decode type-specific data back into form fields
        switch qrCode.type {
        case .wifi:
            if let wifi = QRDataDecoder.decodeWiFi(from: qrCode.data) {
                vm.wifiData = wifi
            }
        case .contact:
            if let contact = QRDataDecoder.decodeContact(from: qrCode.data) {
                vm.contactData = contact
            }
        case .calendar:
            if let event = QRDataDecoder.decodeCalendarEvent(from: qrCode.data) {
                vm.calendarData = event
            }
        case .venmo, .paypal, .cashapp, .zelle, .crypto:
            vm.data = QRDataDecoder.decodePayment(from: qrCode.data, type: qrCode.type)
        default:
            vm.data = qrCode.data
        }

        _viewModel = State(initialValue: vm)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Title") {
                    TextField("Give your QR code a name...", text: $viewModel.title)
                }

                typeSpecificFields

                Section("Tags") {
                    if !viewModel.tags.isEmpty {
                        FlowLayout(spacing: 6) {
                            ForEach(viewModel.tags, id: \.self) { tag in
                                HStack(spacing: 4) {
                                    Text(tag).font(.caption)
                                    Button { viewModel.removeTag(tag) } label: {
                                        Image(systemName: "xmark.circle.fill").font(.caption2)
                                    }
                                    .buttonStyle(.plain)
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.electricViolet.opacity(0.10))
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

                Section("Folder") {
                    Picker("Folder", selection: $viewModel.folderName) {
                        Text("None").tag("")
                        ForEach(folders) { folder in
                            Label(folder.name, systemImage: folder.iconName).tag(folder.name)
                        }
                    }
                }

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
                        ColorPicker("QR Foreground", selection: $viewModel.foregroundColor, supportsOpacity: false)
                            .onChange(of: viewModel.foregroundColor) { viewModel.syncColors() }
                        ColorPicker("QR Background", selection: $viewModel.backgroundColor, supportsOpacity: false)
                            .onChange(of: viewModel.backgroundColor) { viewModel.syncColors() }
                    }
                }

                if let error = viewModel.validationError {
                    Section {
                        Text(error).foregroundStyle(.red).font(.caption)
                    }
                }
            }
            .navigationTitle("Edit QR Code")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveChanges() }
                        .fontWeight(.semibold)
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.cardBg)
        }
        .presentationBackground(Color.cardBg)
    }

    @ViewBuilder
    private var typeSpecificFields: some View {
        switch viewModel.selectedType {
        case .url:
            Section("URL") {
                TextField("https://...", text: $viewModel.data)
                    .keyboardType(.URL).textContentType(.URL).autocapitalization(.none)
            }
        case .text:
            Section("Text Content") {
                TextEditor(text: $viewModel.data).frame(minHeight: 100)
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
                    .keyboardType(.URL).autocapitalization(.none)
            }
        case .venmo:
            PaymentFormView(label: "Venmo Username", placeholder: "@username", hint: "Enter your Venmo username", text: $viewModel.data)
        case .paypal:
            PaymentFormView(label: "PayPal.me Link or Email", placeholder: "paypal.me/username", hint: "Enter your PayPal.me link or email", text: $viewModel.data)
        case .cashapp:
            PaymentFormView(label: "CashApp $Cashtag", placeholder: "$username", hint: "Enter your CashApp $cashtag", text: $viewModel.data)
        case .zelle:
            PaymentFormView(label: "Zelle Email or Phone", placeholder: "email or phone", hint: "Enter your Zelle email or phone", text: $viewModel.data)
        case .crypto:
            PaymentFormView(label: "Wallet Address", placeholder: "Wallet address", hint: "Enter your wallet address", text: $viewModel.data)
        }
    }

    private func saveChanges() {
        guard viewModel.validate() else { return }
        qrCode.title = viewModel.title.trimmingCharacters(in: .whitespacesAndNewlines)
        qrCode.data = viewModel.generateQRData()
        qrCode.tags = viewModel.tags
        qrCode.isFavorite = viewModel.isFavorite
        qrCode.errorCorrection = viewModel.errorCorrection
        qrCode.sizePx = viewModel.sizePx
        qrCode.oneTimeUse = viewModel.oneTimeUse
        qrCode.brightnessBoostDefault = viewModel.brightnessBoostDefault
        qrCode.folderName = viewModel.folderName
        qrCode.foregroundHex = viewModel.foregroundHex
        qrCode.backgroundHex = viewModel.backgroundHex
        qrCode.logoImageData = viewModel.logoImageData
        qrCode.updatedAt = .now
        try? modelContext.save()
        HapticManager.success()
        dismiss()
    }
}
```

**Step 2: Add Edit to QRCardView context menu**

Add `@State private var showEditSheet = false` to QRCardView.

In the context menu (before "Copy Data"), add:

```swift
            Button { showEditSheet = true } label: { Label("Edit", systemImage: "pencil") }
```

Add sheet modifier after `.contextMenu`:

```swift
        .sheet(isPresented: $showEditSheet) {
            EditQRView(qrCode: qrCode)
        }
```

**Step 3: Add Edit button to QRFullscreenView top bar**

Add `@State private var showEditSheet = false` to QRFullscreenView.

Add an edit button in the top bar (after the close button, before the title):

```swift
                    Button { showEditSheet = true } label: {
                        Image(systemName: "pencil")
                            .font(.title3)
                            .foregroundStyle(.white)
                            .padding(8)
                    }
```

Add sheet modifier to the ZStack:

```swift
        .sheet(isPresented: $showEditSheet) {
            EditQRView(qrCode: currentQR)
        }
```

**Step 4: Add to project.pbxproj**

CC000057 / BB000057 for EditQRView.swift. Add to Creation group DD000007 and Sources phase.

**Step 5: Build, verify, commit**

```bash
git add -A && git commit -m "feat: add edit QR code with data decoding back into form fields"
```

---

### Task 9: Implement Duplicate QR Code

**Files:**
- Modify: `QRBook/Views/Library/QRCardView.swift`

**Step 1: Add duplicate to context menu**

In QRCardView's context menu, add after the Edit button:

```swift
            Button {
                let copy = QRCode(
                    title: qrCode.title + " (Copy)",
                    data: qrCode.data,
                    type: qrCode.type,
                    tags: qrCode.tags,
                    isFavorite: qrCode.isFavorite,
                    errorCorrection: qrCode.errorCorrection,
                    sizePx: qrCode.sizePx,
                    brightnessBoostDefault: qrCode.brightnessBoostDefault,
                    folderName: qrCode.folderName,
                    foregroundHex: qrCode.foregroundHex,
                    backgroundHex: qrCode.backgroundHex,
                    logoImageData: qrCode.logoImageData
                )
                modelContext.insert(copy)
                HapticManager.success()
            } label: {
                Label("Duplicate", systemImage: "plus.square.on.square")
            }
```

**Step 2: Build, verify, commit**

```bash
git add QRBook/Views/Library/QRCardView.swift && git commit -m "feat: add duplicate QR code via context menu"
```

---

### Task 10: Implement batch operations

**Files:**
- Modify: `QRBook/ViewModels/QRLibraryViewModel.swift`
- Modify: `QRBook/Views/Library/QRLibraryView.swift`
- Modify: `QRBook/Views/Library/QRCardView.swift`

**Step 1: Add batch state to QRLibraryViewModel**

Add properties:

```swift
    var isSelectMode = false
    var selectedIds: Set<UUID> = []

    func toggleSelection(_ id: UUID) {
        if selectedIds.contains(id) {
            selectedIds.remove(id)
        } else {
            selectedIds.insert(id)
        }
    }

    func selectAll(_ codes: [QRCode]) {
        selectedIds = Set(codes.map(\.id))
    }

    func deselectAll() {
        selectedIds.removeAll()
    }

    func exitSelectMode() {
        isSelectMode = false
        selectedIds.removeAll()
    }
```

**Step 2: Add Select button and batch toolbar to QRLibraryView**

Add a "Select" toolbar button. When in select mode, show a bottom bar with batch actions (Delete, Move to Folder, Export).

In the toolbar section, add:

```swift
                ToolbarItem(placement: .primaryAction) {
                    if viewModel.isSelectMode {
                        Button("Done") { viewModel.exitSelectMode() }
                    } else {
                        HStack {
                            Button { viewModel.isSelectMode = true } label: {
                                Image(systemName: "checkmark.circle")
                            }
                            Button { viewModel.showCreateSheet = true } label: {
                                Label("Create", systemImage: "plus")
                            }
                        }
                    }
                }
```

Add batch action bar overlay at bottom of qrGrid (inside the ScrollView, or as a safeAreaInset):

```swift
        .safeAreaInset(edge: .bottom) {
            if viewModel.isSelectMode && !viewModel.selectedIds.isEmpty {
                HStack(spacing: 20) {
                    Button {
                        showDeleteConfirm = true
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                    .foregroundStyle(.red)

                    Menu {
                        Button("None") { batchMoveToFolder("") }
                        ForEach(folders) { folder in
                            Button(folder.name) { batchMoveToFolder(folder.name) }
                        }
                    } label: {
                        Label("Move", systemImage: "folder")
                    }

                    Button {
                        batchExport()
                    } label: {
                        Label("Export", systemImage: "square.and.arrow.up")
                    }

                    Spacer()

                    Text("\(viewModel.selectedIds.count) selected")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding()
                .background(.ultraThinMaterial)
            }
        }
```

Add helper methods to QRLibraryView:

```swift
    @State private var showDeleteConfirm = false

    private func batchDelete() {
        for qr in qrCodes where viewModel.selectedIds.contains(qr.id) {
            modelContext.delete(qr)
        }
        viewModel.exitSelectMode()
        HapticManager.success()
    }

    private func batchMoveToFolder(_ folder: String) {
        for qr in qrCodes where viewModel.selectedIds.contains(qr.id) {
            qr.folderName = folder
        }
        viewModel.exitSelectMode()
        HapticManager.success()
    }

    private func batchExport() {
        let selected = qrCodes.filter { viewModel.selectedIds.contains($0.id) }
        // Reuse export logic from SettingsView
        let items: [[String: Any]] = selected.map { qr in
            ["id": qr.id.uuidString, "title": qr.title, "data": qr.data, "type": qr.typeRaw, "tags": qr.tags]
        }
        guard let jsonData = try? JSONSerialization.data(withJSONObject: items, options: .prettyPrinted),
              let jsonString = String(data: jsonData, encoding: .utf8) else { return }
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("qrbook-export.json")
        try? jsonString.write(to: url, atomically: true, encoding: .utf8)
        let vc = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let root = scene.windows.first?.rootViewController {
            root.present(vc, animated: true)
        }
        viewModel.exitSelectMode()
    }
```

Add `.alert` for delete confirmation.

**Step 3: Update QRCardView for select mode**

Add properties:

```swift
    var isSelectMode: Bool = false
    var isSelected: Bool = false
    var onSelect: (() -> Void)? = nil
```

Wrap the card in a checkbox overlay when in select mode. In `body`, add overlay:

```swift
        .overlay(alignment: .topLeading) {
            if isSelectMode {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isSelected ? Color.electricViolet : .secondary)
                    .font(.title3)
                    .padding(8)
            }
        }
```

Override the tap action when in select mode — wrap the Button's action:

In QRLibraryView, update the ForEach to pass select mode state and use `onSelect` callback.

**Step 4: Build, verify, commit**

```bash
git add -A && git commit -m "feat: add batch select with delete, move to folder, and export"
```

---

## Wave 3: Scanner & Share Extension

### Task 11: Implement QR Code Scanner

**Files:**
- Create: `QRBook/Views/Scanner/ScannerView.swift`
- Modify: `QRBook/Views/MainTabView.swift` (add Scan tab)
- Modify: `QRBook.xcodeproj/project.pbxproj`

**Step 1: Create ScannerView.swift**

```swift
import SwiftUI
import VisionKit

struct ScannerView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var scannedCode: String?
    @State private var detectedType: QRType = .text
    @State private var showSaveSheet = false
    @State private var isScannerAvailable = DataScannerViewController.isSupported

    var body: some View {
        NavigationStack {
            ZStack {
                if isScannerAvailable {
                    DataScannerRepresentable(scannedCode: $scannedCode)
                        .ignoresSafeArea()
                } else {
                    ContentUnavailableView(
                        "Scanner Unavailable",
                        systemImage: "camera.fill",
                        description: Text("This device does not support camera scanning.")
                    )
                }

                // Scanned result sheet
                if let code = scannedCode {
                    VStack {
                        Spacer()
                        VStack(spacing: 12) {
                            HStack {
                                Image(systemName: detectedType.icon)
                                    .foregroundStyle(Color.electricViolet)
                                Text("QR Code Detected")
                                    .font(.headline)
                                Spacer()
                                Button {
                                    scannedCode = nil
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundStyle(.secondary)
                                }
                            }

                            Text(code)
                                .font(.subheadline)
                                .lineLimit(3)
                                .frame(maxWidth: .infinity, alignment: .leading)

                            HStack(spacing: 12) {
                                Button {
                                    showSaveSheet = true
                                } label: {
                                    Label("Save to Library", systemImage: "square.and.arrow.down")
                                }
                                .buttonStyle(.borderedProminent)
                                .tint(Color.electricViolet)

                                Button {
                                    UIPasteboard.general.string = code
                                    HapticManager.success()
                                } label: {
                                    Label("Copy", systemImage: "doc.on.doc")
                                }
                                .buttonStyle(.bordered)

                                if code.hasPrefix("http") {
                                    Button {
                                        if let url = URL(string: code) {
                                            UIApplication.shared.open(url)
                                        }
                                    } label: {
                                        Label("Open", systemImage: "safari")
                                    }
                                    .buttonStyle(.bordered)
                                }
                            }
                        }
                        .padding()
                        .background(.ultraThickMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .padding()
                    }
                }
            }
            .navigationTitle("Scan")
            .navigationBarTitleDisplayMode(.inline)
            .onChange(of: scannedCode) {
                if let code = scannedCode {
                    detectedType = detectType(code)
                    HapticManager.success()
                }
            }
            .sheet(isPresented: $showSaveSheet) {
                if let code = scannedCode {
                    CreateQRView(prefillData: code, prefillType: detectedType)
                }
            }
        }
    }

    private func detectType(_ data: String) -> QRType {
        if data.hasPrefix("WIFI:") { return .wifi }
        if data.contains("BEGIN:VCARD") { return .contact }
        if data.contains("BEGIN:VCALENDAR") { return .calendar }
        if data.hasPrefix("http://") || data.hasPrefix("https://") { return .url }
        return .text
    }
}

struct DataScannerRepresentable: UIViewControllerRepresentable {
    @Binding var scannedCode: String?

    func makeUIViewController(context: Context) -> DataScannerViewController {
        let scanner = DataScannerViewController(
            recognizedDataTypes: [.barcode(symbologies: [.qr])],
            qualityLevel: .balanced,
            isHighlightingEnabled: true
        )
        scanner.delegate = context.coordinator
        try? scanner.startScanning()
        return scanner
    }

    func updateUIViewController(_ uiViewController: DataScannerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    class Coordinator: NSObject, DataScannerViewControllerDelegate {
        let parent: DataScannerRepresentable

        init(_ parent: DataScannerRepresentable) { self.parent = parent }

        func dataScanner(_ dataScanner: DataScannerViewController, didTapOn item: RecognizedItem) {
            if case .barcode(let barcode) = item {
                parent.scannedCode = barcode.payloadStringValue
            }
        }
    }
}
```

**Step 2: Add prefill support to CreateQRView**

Add optional init parameters to CreateQRView:

```swift
    var prefillData: String?
    var prefillType: QRType?

    init(prefillData: String? = nil, prefillType: QRType? = nil) {
        self.prefillData = prefillData
        self.prefillType = prefillType
    }
```

In the body's onAppear (or as a task), pre-fill the viewModel:

```swift
            .onAppear {
                if let type = prefillType {
                    viewModel.selectedType = type
                }
                if let data = prefillData {
                    switch viewModel.selectedType {
                    case .wifi:
                        if let wifi = QRDataDecoder.decodeWiFi(from: data) {
                            viewModel.wifiData = wifi
                        }
                    case .contact:
                        if let contact = QRDataDecoder.decodeContact(from: data) {
                            viewModel.contactData = contact
                        }
                    case .calendar:
                        if let cal = QRDataDecoder.decodeCalendarEvent(from: data) {
                            viewModel.calendarData = cal
                        }
                    default:
                        viewModel.data = data
                    }
                }
            }
```

**Step 3: Add Scan tab to MainTabView**

Update the Tab enum to add `scan` case between library and favorites:

```swift
    enum Tab: String, CaseIterable {
        case library, scan, favorites, recent, flyers

        var label: String {
            switch self {
            case .library: "Library"
            case .scan: "Scan"
            case .favorites: "Favorites"
            case .recent: "Recent"
            case .flyers: "Flyers"
            }
        }

        var icon: String {
            switch self {
            case .library: "square.grid.2x2"
            case .scan: "camera.viewfinder"
            case .favorites: "heart"
            case .recent: "clock"
            case .flyers: "doc.text"
            }
        }
    }
```

Add the scan case to the switch in body:

```swift
                    case .scan:
                        ScannerView()
```

**Step 4: Add NSCameraUsageDescription to Info.plist**

Add to both Debug and Release build settings in project.pbxproj:

```
INFOPLIST_KEY_NSCameraUsageDescription = "QR Book uses the camera to scan QR codes.";
```

**Step 5: Add ScannerView to project.pbxproj**

Create Scanner group DD000012 under Views DD000003. CC000058 / BB000058.

**Step 6: Build, verify, commit**

```bash
git add -A && git commit -m "feat: add QR code scanner with camera viewfinder and auto-detect"
```

---

### Task 12: Implement Share Extension

**Files:**
- Create: `QRBookShareExtension/` directory with ShareViewController.swift and Info.plist
- Modify: `QRBook.xcodeproj/project.pbxproj` (new target)
- Modify: `QRBook/QRBookApp.swift` (check for pending share imports)

**Step 1: Create App Group entitlement**

Add `com.apple.security.application-groups` with value `group.com.gyndok.QRBook` to `QRBook/QRBook.entitlements`.

**Step 2: Create ShareViewController.swift**

```swift
import SwiftUI
import UniformTypeIdentifiers

class ShareViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        guard let extensionItem = extensionContext?.inputItems.first as? NSExtensionItem,
              let itemProviders = extensionItem.attachments else {
            close()
            return
        }

        for provider in itemProviders {
            if provider.hasItemConformingToTypeIdentifier(UTType.url.identifier) {
                provider.loadItem(forTypeIdentifier: UTType.url.identifier) { [weak self] item, _ in
                    if let url = item as? URL {
                        self?.saveSharedItem(data: url.absoluteString, type: "url")
                    }
                }
            } else if provider.hasItemConformingToTypeIdentifier(UTType.plainText.identifier) {
                provider.loadItem(forTypeIdentifier: UTType.plainText.identifier) { [weak self] item, _ in
                    if let text = item as? String {
                        self?.saveSharedItem(data: text, type: "text")
                    }
                }
            }
        }
    }

    private func saveSharedItem(data: String, type: String) {
        guard let containerURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: "group.com.gyndok.QRBook"
        ) else {
            close()
            return
        }

        let payload: [String: String] = ["data": data, "type": type, "timestamp": ISO8601DateFormatter().string(from: .now)]

        if let jsonData = try? JSONSerialization.data(withJSONObject: payload) {
            let fileURL = containerURL.appendingPathComponent("shared-import-\(UUID().uuidString).json")
            try? jsonData.write(to: fileURL)
        }

        DispatchQueue.main.async { [weak self] in
            self?.close()
        }
    }

    private func close() {
        extensionContext?.completeRequest(returningItems: nil)
    }
}
```

**Step 3: Add pending share import check to QRBookApp.swift**

Add to the `.onAppear` block:

```swift
                checkPendingShareImports()
```

Add method:

```swift
    private func checkPendingShareImports() {
        guard let containerURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: "group.com.gyndok.QRBook"
        ) else { return }

        let fm = FileManager.default
        guard let files = try? fm.contentsOfDirectory(at: containerURL, includingPropertiesForKeys: nil) else { return }

        for file in files where file.lastPathComponent.hasPrefix("shared-import-") {
            if let data = try? Data(contentsOf: file),
               let payload = try? JSONSerialization.jsonObject(with: data) as? [String: String],
               let qrData = payload["data"],
               let typeStr = payload["type"] {
                // Will be picked up by a notification or processed on next library view
                // For now, store in UserDefaults as pending
                UserDefaults.standard.set(qrData, forKey: "pendingShareData")
                UserDefaults.standard.set(typeStr, forKey: "pendingShareType")
                try? fm.removeItem(at: file)
            }
        }
    }
```

**Step 4: Configure the Share Extension target in project.pbxproj**

This is a complex pbxproj change — add a new PBXNativeTarget for the share extension with its own build configurations, Info.plist, and entitlements. The extension needs:
- Product type: `com.apple.product-type.app-extension`
- Bundle identifier: `com.gyndok.QRBook.ShareExtension`
- App Group entitlement
- NSExtension configuration in Info.plist

**Step 5: Build, verify, commit**

```bash
git add -A && git commit -m "feat: add Share Extension for importing URLs and text as QR codes"
```

---

## Wave 4: System Integrations

### Task 13: Create DeepLinkRouter

**Files:**
- Create: `QRBook/ViewModels/DeepLinkRouter.swift`
- Modify: `QRBook/Views/MainTabView.swift`
- Modify: `QRBook/QRBookApp.swift`
- Modify: `QRBook.xcodeproj/project.pbxproj`

**Step 1: Create DeepLinkRouter.swift**

```swift
import SwiftUI

@Observable
class DeepLinkRouter {
    var selectedTab: MainTabView.Tab = .library
    var showQRCodeId: UUID?
    var showCreateSheet = false

    func handleQuickAction(_ shortcutType: String) {
        switch shortcutType {
        case "CreateQR":
            selectedTab = .library
            showCreateSheet = true
        case "ScanQR":
            selectedTab = .scan
        case "Favorites":
            selectedTab = .favorites
        default:
            break
        }
    }

    func showQRCode(id: UUID) {
        selectedTab = .library
        showQRCodeId = id
    }
}
```

**Step 2: Wire into QRBookApp.swift and MainTabView**

Add `@State private var router = DeepLinkRouter()` to QRBookApp and pass via `.environment()`.

MainTabView reads router for tab selection and deep link handling.

**Step 3: Add to project.pbxproj**

CC000059 / BB000059 for DeepLinkRouter.swift in ViewModels group.

**Step 4: Build, verify, commit**

```bash
git add -A && git commit -m "feat: add DeepLinkRouter for system integration navigation"
```

---

### Task 14: Implement Quick Actions

**Files:**
- Modify: `QRBook/QRBookApp.swift`

**Step 1: Add UIApplicationShortcutItems to build settings**

Add to both Debug and Release target build settings in project.pbxproj:

In Info.plist (via build settings or a physical Info.plist), add shortcut items. Since the app uses generated Info.plist, add a physical Info.plist file with:

```xml
<key>UIApplicationShortcutItems</key>
<array>
    <dict>
        <key>UIApplicationShortcutItemType</key>
        <string>CreateQR</string>
        <key>UIApplicationShortcutItemTitle</key>
        <string>Create QR</string>
        <key>UIApplicationShortcutItemIconSymbolName</key>
        <string>plus.circle.fill</string>
    </dict>
    <dict>
        <key>UIApplicationShortcutItemType</key>
        <string>ScanQR</string>
        <key>UIApplicationShortcutItemTitle</key>
        <string>Scan QR</string>
        <key>UIApplicationShortcutItemIconSymbolName</key>
        <string>camera.viewfinder</string>
    </dict>
    <dict>
        <key>UIApplicationShortcutItemType</key>
        <string>Favorites</string>
        <key>UIApplicationShortcutItemTitle</key>
        <string>Favorites</string>
        <key>UIApplicationShortcutItemIconSymbolName</key>
        <string>star.fill</string>
    </dict>
</array>
```

**Step 2: Handle shortcut items in QRBookApp**

Add scene phase handling and `onOpenURL` for shortcut actions. Use the DeepLinkRouter to dispatch.

**Step 3: Build, verify, commit**

```bash
git add -A && git commit -m "feat: add home screen quick actions for Create, Scan, and Favorites"
```

---

### Task 15: Implement Spotlight Search

**Files:**
- Create: `QRBook/Utilities/SpotlightIndexer.swift`
- Modify: `QRBook/Views/Creation/CreateQRView.swift` (index on create)
- Modify: `QRBook/Views/Creation/EditQRView.swift` (index on edit)
- Modify: `QRBook/Views/Library/QRCardView.swift` (remove from index on delete)
- Modify: `QRBook/QRBookApp.swift` (handle Spotlight continuation)
- Modify: `QRBook.xcodeproj/project.pbxproj`

**Step 1: Create SpotlightIndexer.swift**

```swift
import CoreSpotlight
import UIKit

enum SpotlightIndexer {
    static func indexQRCode(_ qr: QRCode) {
        let attributes = CSSearchableItemAttributeSet(contentType: .text)
        attributes.title = qr.title
        attributes.contentDescription = "\(qr.type.label) QR Code: \(qr.data.prefix(100))"
        attributes.keywords = qr.tags + [qr.type.label]

        if let image = QRGenerator.generateQRCode(from: qr.data, size: 120) {
            attributes.thumbnailData = image.pngData()
        }

        let item = CSSearchableItem(
            uniqueIdentifier: qr.id.uuidString,
            domainIdentifier: "com.gyndok.QRBook.qrcodes",
            attributeSet: attributes
        )
        CSSearchableIndex.default().indexSearchableItems([item])
    }

    static func removeQRCode(id: UUID) {
        CSSearchableIndex.default().deleteSearchableItems(withIdentifiers: [id.uuidString])
    }

    static func reindexAll(_ codes: [QRCode]) {
        CSSearchableIndex.default().deleteSearchableItems(withDomainIdentifiers: ["com.gyndok.QRBook.qrcodes"]) { _ in
            let items = codes.map { qr -> CSSearchableItem in
                let attrs = CSSearchableItemAttributeSet(contentType: .text)
                attrs.title = qr.title
                attrs.contentDescription = "\(qr.type.label): \(qr.data.prefix(100))"
                attrs.keywords = qr.tags
                return CSSearchableItem(uniqueIdentifier: qr.id.uuidString, domainIdentifier: "com.gyndok.QRBook.qrcodes", attributeSet: attrs)
            }
            CSSearchableIndex.default().indexSearchableItems(items)
        }
    }
}
```

**Step 2: Call indexQRCode on create and edit, removeQRCode on delete**

**Step 3: Handle Spotlight tap in QRBookApp.swift**

```swift
        .onContinueUserActivity(CSSearchableItemActionType) { activity in
            if let id = activity.userInfo?[CSSearchableItemActivityIdentifier] as? String,
               let uuid = UUID(uuidString: id) {
                router.showQRCode(id: uuid)
            }
        }
```

**Step 4: Add to project.pbxproj, build, verify, commit**

```bash
git add -A && git commit -m "feat: add Spotlight search indexing for QR codes"
```

---

### Task 16: Implement Siri Shortcuts

**Files:**
- Create: `QRBook/Intents/AppShortcuts.swift`
- Create: `QRBook/Intents/ShowQRCodeIntent.swift`
- Create: `QRBook/Intents/CreateQRCodeIntent.swift`
- Modify: `QRBook.xcodeproj/project.pbxproj`

**Step 1: Create ShowQRCodeIntent.swift**

```swift
import AppIntents
import SwiftData

struct ShowQRCodeIntent: AppIntent {
    static var title: LocalizedStringResource = "Show QR Code"
    static var description = IntentDescription("Opens a QR code in fullscreen view")
    static var openAppWhenRun = true

    @Parameter(title: "QR Code")
    var qrCode: QRCodeEntity

    func perform() async throws -> some IntentResult {
        return .result()
    }
}

struct QRCodeEntity: AppEntity {
    static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "QR Code")
    static var defaultQuery = QRCodeEntityQuery()

    var id: UUID
    var title: String

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(title)")
    }
}

struct QRCodeEntityQuery: EntityQuery {
    func entities(for identifiers: [UUID]) async throws -> [QRCodeEntity] {
        // Fetch from SwiftData
        return []
    }

    func suggestedEntities() async throws -> [QRCodeEntity] {
        return []
    }
}
```

**Step 2: Create CreateQRCodeIntent.swift**

```swift
import AppIntents

struct CreateQRCodeIntent: AppIntent {
    static var title: LocalizedStringResource = "Create QR Code"
    static var description = IntentDescription("Opens QR Book to create a new QR code")
    static var openAppWhenRun = true

    func perform() async throws -> some IntentResult {
        return .result()
    }
}
```

**Step 3: Create AppShortcuts.swift**

```swift
import AppIntents

struct QRBookShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: ShowQRCodeIntent(),
            phrases: [
                "Show \(\.$qrCode) in \(.applicationName)",
                "Open \(\.$qrCode) in \(.applicationName)"
            ],
            shortTitle: "Show QR Code",
            systemImageName: "qrcode"
        )

        AppShortcut(
            intent: CreateQRCodeIntent(),
            phrases: [
                "Create a QR code in \(.applicationName)",
                "Make a QR code in \(.applicationName)"
            ],
            shortTitle: "Create QR Code",
            systemImageName: "plus.circle"
        )
    }
}
```

**Step 4: Add Intents group and files to project.pbxproj**

Create Intents group. Add CC000060-62 / BB000060-62.

**Step 5: Build, verify, commit**

```bash
git add -A && git commit -m "feat: add Siri Shortcuts for showing and creating QR codes"
```

---

### Task 17: Implement QR History

**Files:**
- Create: `QRBook/Views/Fullscreen/QRHistoryView.swift`
- Modify: `QRBook/Views/Fullscreen/QRFullscreenView.swift`
- Modify: `QRBook/Views/Library/QRCardView.swift`
- Modify: `QRBook/Views/Settings/SettingsView.swift`
- Modify: `QRBook.xcodeproj/project.pbxproj`

**Step 1: Create QRHistoryView.swift**

```swift
import SwiftUI
import SwiftData

struct QRHistoryView: View {
    let qrCodeId: UUID
    @Query private var allEvents: [ScanEvent]

    private var events: [ScanEvent] {
        allEvents.filter { $0.qrCodeId == qrCodeId }.sorted { $0.timestamp > $1.timestamp }
    }

    var body: some View {
        List {
            Section("Summary") {
                LabeledContent("Total Views", value: "\(events.count)")
                if let first = events.last {
                    LabeledContent("First Viewed", value: first.timestamp.relativeFormatted)
                }
                if let last = events.first {
                    LabeledContent("Last Viewed", value: last.timestamp.relativeFormatted)
                }
            }

            Section("Timeline") {
                if events.isEmpty {
                    Text("No scan history yet")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(events) { event in
                        HStack {
                            Image(systemName: "eye")
                                .foregroundStyle(Color.electricViolet)
                            Text(event.timestamp, style: .date)
                            Text(event.timestamp, style: .time)
                                .foregroundStyle(.secondary)
                        }
                        .font(.subheadline)
                    }
                }
            }
        }
        .navigationTitle("Scan History")
    }
}
```

**Step 2: Log ScanEvent in QRFullscreenView**

Update `recordScan()` to also create a ScanEvent. Add `@Environment(\.modelContext) private var modelContext` to QRFullscreenView.

```swift
    private func recordScan() {
        currentQR.scanCount += 1
        currentQR.lastUsed = .now
        let event = ScanEvent(qrCodeId: currentQR.id)
        modelContext.insert(event)
    }
```

Add a history button to the bottom info area and a "View History" context menu item.

**Step 3: Add "View History" to QRCardView context menu**

```swift
            NavigationLink { QRHistoryView(qrCodeId: qrCode.id) } label: {
                Label("View History", systemImage: "clock.arrow.circlepath")
            }
```

Note: Context menus don't support NavigationLink well. Instead add `@State private var showHistory = false` and use a sheet.

**Step 4: Add "Clear All History" to SettingsView**

In the Data section:

```swift
                Button(role: .destructive) {
                    clearHistory()
                } label: {
                    Label("Clear Scan History", systemImage: "clock.arrow.circlepath")
                }
```

With helper:

```swift
    @Query private var scanEvents: [ScanEvent]

    private func clearHistory() {
        for event in scanEvents {
            modelContext.delete(event)
        }
    }
```

**Step 5: Add to project.pbxproj, build, verify, commit**

```bash
git add -A && git commit -m "feat: add QR scan history with timeline and summary stats"
```

---

## Wave 5: New Targets

### Task 18: Implement Widget Extension

**Files:**
- Create: `QRBookWidget/` directory
- Create: `QRBookWidget/QRBookWidget.swift`
- Modify: `QRBook.xcodeproj/project.pbxproj` (new target)
- Modify: `QRBook/QRBookApp.swift` (write widget data on changes)

**Step 1: Create shared data writer in main app**

Create `QRBook/Utilities/WidgetDataWriter.swift`:

```swift
import Foundation
import WidgetKit

enum WidgetDataWriter {
    static func writeWidgetData(favorites: [QRCode]) {
        guard let containerURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: "group.com.gyndok.QRBook"
        ) else { return }

        let items = favorites.map { qr -> [String: String] in
            [
                "id": qr.id.uuidString,
                "title": qr.title,
                "data": qr.data,
                "type": qr.typeRaw,
                "foregroundHex": qr.foregroundHex,
                "backgroundHex": qr.backgroundHex
            ]
        }

        let url = containerURL.appendingPathComponent("widget-data.json")
        if let jsonData = try? JSONSerialization.data(withJSONObject: items) {
            try? jsonData.write(to: url)
        }
        WidgetCenter.shared.reloadAllTimelines()
    }
}
```

**Step 2: Create QRBookWidget.swift**

```swift
import WidgetKit
import SwiftUI

struct QRCodeWidgetEntry: TimelineEntry {
    let date: Date
    let title: String
    let data: String
    let foregroundHex: String
    let backgroundHex: String
}

struct QRBookWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> QRCodeWidgetEntry {
        QRCodeWidgetEntry(date: .now, title: "QR Code", data: "https://example.com", foregroundHex: "", backgroundHex: "")
    }

    func getSnapshot(in context: Context, completion: @escaping (QRCodeWidgetEntry) -> Void) {
        completion(placeholder(in: context))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<QRCodeWidgetEntry>) -> Void) {
        let entries = loadEntries()
        let entry = entries.first ?? placeholder(in: context)
        completion(Timeline(entries: [entry], policy: .never))
    }

    private func loadEntries() -> [QRCodeWidgetEntry] {
        guard let url = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.com.gyndok.QRBook")?
            .appendingPathComponent("widget-data.json"),
              let data = try? Data(contentsOf: url),
              let items = try? JSONSerialization.jsonObject(with: data) as? [[String: String]] else {
            return []
        }

        return items.compactMap { item in
            guard let title = item["title"], let qrData = item["data"] else { return nil }
            return QRCodeWidgetEntry(
                date: .now,
                title: title,
                data: qrData,
                foregroundHex: item["foregroundHex"] ?? "",
                backgroundHex: item["backgroundHex"] ?? ""
            )
        }
    }
}

struct QRBookWidgetSmallView: View {
    let entry: QRCodeWidgetEntry

    var body: some View {
        VStack(spacing: 4) {
            // Generate QR as a simple black-and-white image for widget
            if let image = generateWidgetQR(from: entry.data, size: 100) {
                Image(uiImage: image)
                    .interpolation(.none)
                    .resizable()
                    .scaledToFit()
            }
            Text(entry.title)
                .font(.caption2)
                .lineLimit(1)
        }
        .padding(8)
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

struct QRBookWidgetMediumView: View {
    let entry: QRCodeWidgetEntry

    var body: some View {
        HStack {
            if let image = generateWidgetQR(from: entry.data, size: 120) {
                Image(uiImage: image)
                    .interpolation(.none)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)
                    .background(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(entry.title)
                    .font(.headline)
                    .lineLimit(2)
                Text("QR Code")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding()
        .containerBackground(.fill.tertiary, for: .widget)
    }
}

@main
struct QRBookWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "QRBookWidget", provider: QRBookWidgetProvider()) { entry in
            QRBookWidgetSmallView(entry: entry)
        }
        .configurationDisplayName("QR Book")
        .description("Display a QR code for quick access.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// Minimal QR generator for widget (no CoreImage filter dependency)
func generateWidgetQR(from string: String, size: CGFloat) -> UIImage? {
    let context = CIContext()
    let filter = CIFilter.qrCodeGenerator()
    guard let data = string.data(using: .utf8) else { return nil }
    filter.message = data
    filter.correctionLevel = "M"
    guard let ciImage = filter.outputImage else { return nil }
    let scale = size / ciImage.extent.size.width
    let scaled = ciImage.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
    guard let cgImage = context.createCGImage(scaled, from: scaled.extent) else { return nil }
    return UIImage(cgImage: cgImage)
}
```

**Step 3: Add widget target to project.pbxproj**

New PBXNativeTarget for QRBookWidget with:
- Product type: `com.apple.product-type.app-extension`
- Bundle identifier: `com.gyndok.QRBook.Widget`
- App Group entitlement
- WidgetKit and SwiftUI framework links

**Step 4: Build, verify, commit**

```bash
git add -A && git commit -m "feat: add home screen widgets (small and medium) for QR codes"
```

---

### Task 19: Implement Apple Watch App

**Files:**
- Create: `QRBookWatch/` directory
- Create: `QRBookWatch/QRBookWatchApp.swift`
- Create: `QRBookWatch/FavoritesListView.swift`
- Create: `QRBookWatch/WatchQRFullscreenView.swift`
- Create: `QRBook/Utilities/WatchConnector.swift`
- Modify: `QRBook.xcodeproj/project.pbxproj` (new watchOS target)

**Step 1: Create WatchConnector.swift (iOS side)**

```swift
import WatchConnectivity

class WatchConnector: NSObject, ObservableObject, WCSessionDelegate {
    static let shared = WatchConnector()

    override init() {
        super.init()
        if WCSession.isSupported() {
            WCSession.default.delegate = self
            WCSession.default.activate()
        }
    }

    func sendFavorites(_ favorites: [QRCode]) {
        guard WCSession.default.isReachable else { return }
        let items = favorites.map { qr -> [String: String] in
            ["id": qr.id.uuidString, "title": qr.title, "data": qr.data, "type": qr.typeRaw]
        }
        guard let data = try? JSONSerialization.data(withJSONObject: items) else { return }
        WCSession.default.sendMessageData(data, replyHandler: nil)
    }

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {}
    func sessionDidBecomeInactive(_ session: WCSession) {}
    func sessionDidDeactivate(_ session: WCSession) {
        WCSession.default.activate()
    }
}
```

**Step 2: Create watchOS app files**

QRBookWatchApp.swift:
```swift
import SwiftUI

@main
struct QRBookWatchApp: App {
    var body: some Scene {
        WindowGroup {
            FavoritesListView()
        }
    }
}
```

FavoritesListView.swift:
```swift
import SwiftUI
import WatchConnectivity

struct FavoritesListView: View {
    @State private var favorites: [[String: String]] = []

    var body: some View {
        NavigationStack {
            List(favorites, id: \..["id"]) { item in
                NavigationLink {
                    WatchQRFullscreenView(data: item["data"] ?? "", title: item["title"] ?? "")
                } label: {
                    Text(item["title"] ?? "QR Code")
                }
            }
            .navigationTitle("QR Book")
        }
        .onAppear { loadFavorites() }
    }

    private func loadFavorites() {
        // Load from local file synced via WatchConnectivity
        guard let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?
            .appendingPathComponent("favorites.json"),
              let data = try? Data(contentsOf: url),
              let items = try? JSONSerialization.jsonObject(with: data) as? [[String: String]] else { return }
        favorites = items
    }
}
```

WatchQRFullscreenView.swift:
```swift
import SwiftUI
import CoreImage
import CoreImage.CIFilterBuiltins

struct WatchQRFullscreenView: View {
    let data: String
    let title: String

    var body: some View {
        VStack {
            if let image = generateQR(from: data, size: 150) {
                Image(uiImage: image)
                    .interpolation(.none)
                    .resizable()
                    .scaledToFit()
                    .background(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            Text(title)
                .font(.caption)
                .lineLimit(1)
        }
        .onAppear {
            WKInterfaceDevice.current().play(.click)
        }
    }

    private func generateQR(from string: String, size: CGFloat) -> UIImage? {
        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()
        guard let data = string.data(using: .utf8) else { return nil }
        filter.message = data
        filter.correctionLevel = "M"
        guard let ciImage = filter.outputImage else { return nil }
        let scale = size / ciImage.extent.size.width
        let scaled = ciImage.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
        guard let cgImage = context.createCGImage(scaled, from: scaled.extent) else { return nil }
        return UIImage(cgImage: cgImage)
    }
}
```

**Step 3: Add watchOS target to project.pbxproj**

New PBXNativeTarget with `com.apple.product-type.application.watchapp2` product type.

**Step 4: Build, verify, commit**

```bash
git add -A && git commit -m "feat: add Apple Watch companion app with favorites list and QR display"
```

---

### Task 20: Implement Flyers

**Files:**
- Create: `QRBook/Views/Flyers/FlyerGalleryView.swift`
- Create: `QRBook/Views/Flyers/FlyerEditorView.swift`
- Create: `QRBook/Views/Flyers/FlyerTemplates.swift`
- Modify: `QRBook/Views/MainTabView.swift` (replace placeholder)
- Modify: `QRBook.xcodeproj/project.pbxproj`

**Step 1: Create FlyerTemplates.swift**

```swift
import SwiftUI

enum FlyerTemplate: String, CaseIterable, Identifiable {
    case clean, banner, poster, minimal, card

    var id: String { rawValue }

    var label: String {
        switch self {
        case .clean: return "Clean"
        case .banner: return "Banner"
        case .poster: return "Poster"
        case .minimal: return "Minimal"
        case .card: return "Card"
        }
    }

    var description: String {
        switch self {
        case .clean: return "Centered QR with title and subtitle"
        case .banner: return "QR right, bold title left"
        case .poster: return "Large QR centered with gradient"
        case .minimal: return "Subtle QR, clean whitespace"
        case .card: return "Horizontal card layout"
        }
    }

    var icon: String {
        switch self {
        case .clean: return "rectangle.portrait"
        case .banner: return "rectangle.split.2x1"
        case .poster: return "rectangle.portrait.fill"
        case .minimal: return "rectangle"
        case .card: return "rectangle.landscape"
        }
    }
}
```

**Step 2: Create FlyerEditorView.swift**

```swift
import SwiftUI
import SwiftData

struct FlyerEditorView: View {
    let template: FlyerTemplate
    @Query private var qrCodes: [QRCode]
    @Environment(\.dismiss) private var dismiss
    @State private var selectedQR: QRCode?
    @State private var title = "Your Title"
    @State private var subtitle = "Your subtitle text here"
    @State private var callToAction = "Scan Me!"
    @State private var backgroundColor: Color = .white
    @State private var accentColor: Color = Color.electricViolet

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Live preview
                    flyerPreview
                        .frame(width: 300, height: 400)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .shadow(radius: 8)

                    // Edit fields
                    VStack(spacing: 12) {
                        Section {
                            Picker("QR Code", selection: $selectedQR) {
                                Text("Select a QR Code").tag(nil as QRCode?)
                                ForEach(qrCodes) { qr in
                                    Text(qr.title).tag(qr as QRCode?)
                                }
                            }
                        }

                        TextField("Title", text: $title)
                            .textFieldStyle(.roundedBorder)
                        TextField("Subtitle", text: $subtitle)
                            .textFieldStyle(.roundedBorder)
                        TextField("Call to Action", text: $callToAction)
                            .textFieldStyle(.roundedBorder)

                        ColorPicker("Background", selection: $backgroundColor, supportsOpacity: false)
                        ColorPicker("Accent", selection: $accentColor, supportsOpacity: false)
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .navigationTitle("Edit Flyer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Export") { exportFlyer() }
                        .fontWeight(.semibold)
                        .disabled(selectedQR == nil)
                }
            }
        }
    }

    @ViewBuilder
    private var flyerPreview: some View {
        let qrData = selectedQR?.data ?? "https://example.com"

        switch template {
        case .clean:
            ZStack {
                backgroundColor
                VStack(spacing: 16) {
                    Text(title).font(.title2).fontWeight(.bold).foregroundStyle(accentColor)
                    if let img = QRGenerator.generateQRCode(from: qrData, size: 160) {
                        Image(uiImage: img).interpolation(.none).resizable().scaledToFit().frame(width: 160, height: 160)
                    }
                    Text(subtitle).font(.subheadline).foregroundStyle(.secondary)
                    Text(callToAction).font(.caption).fontWeight(.semibold).foregroundStyle(accentColor)
                }
                .padding()
            }

        case .banner:
            ZStack {
                backgroundColor
                HStack {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(title).font(.title).fontWeight(.bold).foregroundStyle(accentColor)
                        Text(subtitle).font(.subheadline).foregroundStyle(.secondary)
                        Spacer()
                        Text(callToAction).font(.caption).fontWeight(.bold).foregroundStyle(accentColor)
                    }
                    Spacer()
                    if let img = QRGenerator.generateQRCode(from: qrData, size: 120) {
                        Image(uiImage: img).interpolation(.none).resizable().scaledToFit().frame(width: 120, height: 120)
                    }
                }
                .padding()
            }

        case .poster:
            ZStack {
                LinearGradient(colors: [accentColor.opacity(0.15), backgroundColor], startPoint: .top, endPoint: .bottom)
                VStack(spacing: 16) {
                    Text(title).font(.title).fontWeight(.black).foregroundStyle(accentColor)
                    Spacer()
                    if let img = QRGenerator.generateQRCode(from: qrData, size: 180) {
                        Image(uiImage: img).interpolation(.none).resizable().scaledToFit().frame(width: 180, height: 180)
                            .padding(16).background(.white).clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    Spacer()
                    Text(callToAction).font(.headline).foregroundStyle(.white)
                        .padding(.horizontal, 24).padding(.vertical, 10)
                        .background(accentColor).clipShape(Capsule())
                }
                .padding()
            }

        case .minimal:
            ZStack {
                backgroundColor
                VStack {
                    HStack {
                        Text(title).font(.headline).foregroundStyle(accentColor)
                        Spacer()
                    }
                    Spacer()
                    HStack {
                        Spacer()
                        if let img = QRGenerator.generateQRCode(from: qrData, size: 100) {
                            Image(uiImage: img).interpolation(.none).resizable().scaledToFit().frame(width: 100, height: 100)
                        }
                    }
                }
                .padding()
            }

        case .card:
            ZStack {
                backgroundColor
                HStack(spacing: 16) {
                    if let img = QRGenerator.generateQRCode(from: qrData, size: 140) {
                        Image(uiImage: img).interpolation(.none).resizable().scaledToFit().frame(width: 140, height: 140)
                    }
                    VStack(alignment: .leading, spacing: 8) {
                        Text(title).font(.headline).foregroundStyle(accentColor)
                        Text(subtitle).font(.caption).foregroundStyle(.secondary)
                        Spacer()
                        Text(callToAction).font(.caption2).fontWeight(.bold).foregroundStyle(accentColor)
                    }
                    Spacer()
                }
                .padding()
            }
        }
    }

    @MainActor
    private func exportFlyer() {
        let renderer = ImageRenderer(content: flyerPreview.frame(width: 600, height: 800))
        renderer.scale = 3.0
        guard let image = renderer.uiImage else { return }

        let activityVC = UIActivityViewController(activityItems: [image], applicationActivities: nil)
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let root = scene.windows.first?.rootViewController {
            root.present(activityVC, animated: true)
        }
        HapticManager.success()
    }
}
```

**Step 3: Create FlyerGalleryView.swift**

```swift
import SwiftUI

struct FlyerGalleryView: View {
    @State private var selectedTemplate: FlyerTemplate?

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    ForEach(FlyerTemplate.allCases) { template in
                        Button {
                            selectedTemplate = template
                        } label: {
                            VStack(spacing: 8) {
                                Image(systemName: template.icon)
                                    .font(.largeTitle)
                                    .frame(height: 80)
                                    .frame(maxWidth: .infinity)
                                    .background(Color.electricViolet.opacity(0.08))
                                    .clipShape(RoundedRectangle(cornerRadius: 12))

                                Text(template.label)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                Text(template.description)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(2)
                            }
                            .padding()
                            .themedCard()
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding()
            }
            .background(Color.appBg)
            .navigationTitle("Flyers")
            .sheet(item: $selectedTemplate) { template in
                FlyerEditorView(template: template)
            }
        }
        .tint(Color.electricViolet)
    }
}
```

**Step 4: Replace FlyersPlaceholderView in MainTabView**

In MainTabView body, change the `.flyers` case:

```swift
                    case .flyers:
                        FlyerGalleryView()
```

Remove the `FlyersPlaceholderView` struct entirely.

**Step 5: Add Flyers group and files to project.pbxproj**

Create Flyers group DD000013 under Views. Add CC000063-65 / BB000063-65.

**Step 6: Build, verify, commit**

```bash
git add -A && git commit -m "feat: add flyer creation with 5 templates and image export"
```

---

## Final Verification

After all 20 tasks:

1. Clean build: `xcodebuild clean build`
2. Verify all 5 tabs work: Library, Scan, Favorites, Recent, Flyers
3. Test create, edit, duplicate, delete QR codes
4. Test folder create/assign/filter
5. Test custom colors and logo overlay
6. Test batch select/delete/move
7. Test scanner detects QR codes
8. Test flyer template selection and export
9. Test appearance settings (accent color + light/dark)
10. Verify Spotlight indexing
11. Verify home screen quick actions
12. Verify widget displays QR code
