import SwiftUI
import SwiftData
import PhotosUI

struct CreateQRView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(StoreManager.self) private var storeManager
    @State private var viewModel = QRCreationViewModel()
    @Query(sort: \Folder.sortOrder) private var folders: [Folder]
    @Query private var allQRCodes: [QRCode]
    @State private var isCreating = false
    @State private var showPaywall = false

    var prefillData: String?
    var prefillType: QRType?

    var body: some View {
        NavigationStack {
            Form {
                // Type selector
                Section("QR Code Type") {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                        ForEach(QRType.allCases) { type in
                            TypeCard(
                                type: type,
                                isSelected: viewModel.selectedType == type,
                                isLocked: type.isPro && !storeManager.isProUnlocked
                            ) {
                                if type.isPro && !storeManager.isProUnlocked {
                                    showPaywall = true
                                } else {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        viewModel.selectedType = type
                                        viewModel.data = ""
                                    }
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

                // Folder
                if !folders.isEmpty {
                    Section("Folder") {
                        Picker("Folder", selection: $viewModel.folderName) {
                            Text("None").tag("")
                            ForEach(folders) { folder in
                                Label(folder.name, systemImage: folder.iconName).tag(folder.name)
                            }
                        }
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
                        if storeManager.isProUnlocked {
                            ColorPicker("QR Foreground", selection: $viewModel.foregroundColor, supportsOpacity: false)
                                .onChange(of: viewModel.foregroundColor) { viewModel.syncColors() }
                            ColorPicker("QR Background", selection: $viewModel.backgroundColor, supportsOpacity: false)
                                .onChange(of: viewModel.backgroundColor) { viewModel.syncColors() }
                        } else {
                            Button {
                                showPaywall = true
                            } label: {
                                HStack {
                                    Label("Custom Colors", systemImage: "paintbrush")
                                    Spacer()
                                    Text("PRO")
                                        .font(.caption2)
                                        .fontWeight(.semibold)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Color.electricViolet)
                                        .foregroundStyle(.white)
                                        .clipShape(Capsule())
                                }
                            }
                        }
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
            .scrollContentBackground(.hidden)
            .background(Color.cardBg)
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
        }
        .sheet(isPresented: $showPaywall) { PaywallView() }
        .presentationBackground(Color.cardBg)
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
            PaymentFormView(label: "PayPal.me Link or Email", placeholder: "paypal.me/username or email", hint: "Enter your PayPal.me link or email address", text: $viewModel.data)
        case .cashapp:
            PaymentFormView(label: "CashApp $Cashtag", placeholder: "$username", hint: "Enter your CashApp $cashtag (with or without $)", text: $viewModel.data)
        case .zelle:
            PaymentFormView(label: "Zelle Email or Phone", placeholder: "email or phone", hint: "Enter your Zelle email address or phone number", text: $viewModel.data)
        case .crypto:
            PaymentFormView(label: "Wallet Address", placeholder: "Cryptocurrency wallet address", hint: "Enter your cryptocurrency wallet address", text: $viewModel.data)
        }
    }

    private func createQRCode() {
        if allQRCodes.count >= StoreManager.freeCodeLimit && !storeManager.isProUnlocked {
            showPaywall = true
            return
        }
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
            brightnessBoostDefault: viewModel.brightnessBoostDefault,
            folderName: viewModel.folderName,
            foregroundHex: viewModel.foregroundHex,
            backgroundHex: viewModel.backgroundHex,
            logoImageData: viewModel.logoImageData
        )

        modelContext.insert(qrCode)
        SpotlightIndexer.indexQRCode(qrCode)
        try? modelContext.save()
        DataSyncManager.syncFavorites(context: modelContext)
        HapticManager.success()
        dismiss()
    }
}

struct TypeCard: View {
    let type: QRType
    let isSelected: Bool
    var isLocked: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: type.icon)
                    .font(.subheadline)
                    .frame(width: 28, height: 28)
                    .background(isSelected ? Color.electricViolet : Color.secondary.opacity(0.12))
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

                if isLocked {
                    Spacer()
                    Image(systemName: "lock.fill")
                        .font(.caption2)
                        .foregroundStyle(Color.electricViolet)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(8)
            .background(isSelected ? Color.electricViolet.opacity(0.08) : Color.clear)
            .opacity(isLocked ? 0.6 : 1.0)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? Color.electricViolet : Color.subtleBorder, lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
    }
}
