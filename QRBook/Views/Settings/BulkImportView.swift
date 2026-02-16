import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct BulkImportView: View {
    @Environment(\.modelContext) private var modelContext

    @State private var importResult: BulkImportResult?
    @State private var showingSuccessAlert = false
    @State private var showingErrorSheet = false
    @State private var showingFileImporter = false
    @State private var showingCopiedToast = false
    @State private var showingParseErrorAlert = false
    @State private var parseErrorMessage = ""

    var body: some View {
        List {
            Section {
                Text("Create many QR codes at once. Export the template, fill it in (or give it to an AI like ChatGPT/Claude), then import the completed JSON.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Section("Step 1: Get Template") {
                Button {
                    shareTemplate()
                } label: {
                    Label("Export Blank Template", systemImage: "square.and.arrow.up")
                }

                Button {
                    copyTemplateToClipboard()
                } label: {
                    Label {
                        HStack {
                            Text("Copy Template to Clipboard")
                            if showingCopiedToast {
                                Spacer()
                                Text("Copied!")
                                    .font(.caption)
                                    .foregroundStyle(Color.activeGreen)
                                    .transition(.opacity)
                            }
                        }
                    } icon: {
                        Image(systemName: "doc.on.doc")
                    }
                }
            }

            Section("Step 2: Import Filled Template") {
                Button {
                    pasteFromClipboard()
                } label: {
                    Label("Paste from Clipboard", systemImage: "doc.on.clipboard")
                }

                Button {
                    showingFileImporter = true
                } label: {
                    Label("Import from File", systemImage: "folder")
                }
            }
        }
        .navigationTitle("Bulk Import")
        .fileImporter(isPresented: $showingFileImporter, allowedContentTypes: [.json]) { result in
            switch result {
            case .success(let url):
                importFromFile(url)
            case .failure(let error):
                parseErrorMessage = "Could not open file: \(error.localizedDescription)"
                showingParseErrorAlert = true
            }
        }
        .alert("Import Complete", isPresented: $showingSuccessAlert) {
            if let result = importResult, !result.errors.isEmpty {
                Button("View Errors") {
                    showingErrorSheet = true
                }
                Button("OK", role: .cancel) { }
            } else {
                Button("OK", role: .cancel) { }
            }
        } message: {
            if let result = importResult {
                if result.errors.isEmpty {
                    Text("Successfully imported \(result.successCount) QR code\(result.successCount == 1 ? "" : "s").")
                } else {
                    Text("Imported \(result.successCount) QR code\(result.successCount == 1 ? "" : "s") with \(result.errors.count) error\(result.errors.count == 1 ? "" : "s").")
                }
            }
        }
        .alert("Import Error", isPresented: $showingParseErrorAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(parseErrorMessage)
        }
        .sheet(isPresented: $showingErrorSheet) {
            errorDetailSheet
        }
    }

    // MARK: - Error Detail Sheet

    private var errorDetailSheet: some View {
        NavigationStack {
            List {
                if let errors = importResult?.errors {
                    ForEach(errors) { error in
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Item #\(error.index)")
                                .font(.headline)
                            if let title = error.title {
                                Text(title)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            Text(error.message)
                                .font(.callout)
                                .foregroundStyle(.red)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle("Import Errors")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        showingErrorSheet = false
                    }
                }
            }
        }
    }

    // MARK: - Template Actions

    private func shareTemplate() {
        let template = BulkImportService.generateTemplate()
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("qrbook-bulk-template.json")
        try? template.write(to: tempURL, atomically: true, encoding: .utf8)

        let activityVC = UIActivityViewController(activityItems: [tempURL], applicationActivities: nil)

        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            // Handle iPad popover
            if let popover = activityVC.popoverPresentationController {
                popover.sourceView = rootVC.view
                popover.sourceRect = CGRect(x: rootVC.view.bounds.midX, y: rootVC.view.bounds.midY, width: 0, height: 0)
                popover.permittedArrowDirections = []
            }
            rootVC.present(activityVC, animated: true)
        }
    }

    private func copyTemplateToClipboard() {
        let template = BulkImportService.generateTemplate()
        UIPasteboard.general.string = template

        withAnimation {
            showingCopiedToast = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation {
                showingCopiedToast = false
            }
        }
    }

    // MARK: - Import Actions

    private func pasteFromClipboard() {
        guard let jsonString = UIPasteboard.general.string, !jsonString.isEmpty else {
            parseErrorMessage = "Clipboard is empty. Copy your filled JSON template first."
            showingParseErrorAlert = true
            return
        }
        performImport(jsonString)
    }

    private func importFromFile(_ url: URL) {
        guard url.startAccessingSecurityScopedResource() else {
            parseErrorMessage = "Could not access the selected file."
            showingParseErrorAlert = true
            return
        }
        defer { url.stopAccessingSecurityScopedResource() }

        do {
            let jsonString = try String(contentsOf: url, encoding: .utf8)
            performImport(jsonString)
        } catch {
            parseErrorMessage = "Could not read file: \(error.localizedDescription)"
            showingParseErrorAlert = true
        }
    }

    private func performImport(_ jsonString: String) {
        let result = BulkImportService.importFromJSON(jsonString, into: modelContext)
        importResult = result

        if result.successCount == 0 && !result.errors.isEmpty {
            // All failed — show errors directly
            showingErrorSheet = true
        } else {
            // Some or all succeeded — show success alert (with option to view errors if any)
            showingSuccessAlert = true
        }
    }
}
