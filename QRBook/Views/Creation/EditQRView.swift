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
        SpotlightIndexer.indexQRCode(qrCode)
        try? modelContext.save()
        HapticManager.success()
        dismiss()
    }
}
