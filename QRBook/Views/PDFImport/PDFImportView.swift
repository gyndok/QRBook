import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct PDFImportView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(StoreManager.self) private var storeManager
    @Query private var existingCodes: [QRCode]

    @State private var viewModel = PDFImportViewModel()
    @State private var showDocumentPicker = false
    @State private var showPaywall = false
    @State private var editingCandidate: ImportCandidate?
    @State private var pickerScanTask: Task<Void, Never>?

    /// Optional pre-loaded PDF URL (from Share Extension).
    var preloadedPDFURL: URL?

    var body: some View {
        NavigationStack {
            Group {
                switch viewModel.state {
                case .idle:
                    idleView
                case .scanning(let current, let total):
                    scanningView(current: current, total: total)
                case .results:
                    resultsView
                case .empty:
                    emptyView
                case .error(let message):
                    errorView(message: message)
                case .saved(let count):
                    savedView(count: count)
                }
            }
            .background(Color.appBg)
            .navigationTitle(navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .sheet(isPresented: $showDocumentPicker) {
                DocumentPicker { url in
                    pickerScanTask = Task { await viewModel.scanPDF(url: url) }
                }
            }
            .onDisappear {
                // Without this, dismissing mid-scan leaves page rendering and
                // Vision detection running in the background.
                pickerScanTask?.cancel()
            }
            .sheet(isPresented: $showPaywall) { PaywallView() }
            .sheet(item: $editingCandidate) { candidate in
                EditCandidateView(candidate: candidate)
            }
            .task {
                if let url = preloadedPDFURL {
                    await viewModel.scanPDF(url: url)
                }
            }
        }
    }

    private var navigationTitle: String {
        if case .results = viewModel.state {
            return "\(viewModel.candidates.count) QR Code\(viewModel.candidates.count == 1 ? "" : "s") Found"
        }
        return "Import from PDF"
    }

    // MARK: - State Views

    private var idleView: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "doc.text.viewfinder")
                .font(.system(size: 56))
                .foregroundStyle(Color.electricViolet.opacity(0.6))
            Text("Select a PDF to scan for QR codes")
                .font(.headline)
            Text("Boarding passes, tickets, reservations, and more")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Button {
                showDocumentPicker = true
            } label: {
                Text("Choose PDF")
                    .fontWeight(.semibold)
                    .frame(maxWidth: 200)
            }
            .buttonStyle(.borderedProminent)
            .tint(Color.electricViolet)
            .padding(.top, 8)
            Spacer()
        }
        .padding()
    }

    private func scanningView(current: Int, total: Int) -> some View {
        VStack(spacing: 16) {
            Spacer()
            ProgressView()
                .scaleEffect(1.5)
                .tint(Color.electricViolet)
            Text("Scanning PDF...")
                .font(.headline)
            if total > 0 {
                Text("Page \(current) of \(total)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            if !viewModel.pdfFilename.isEmpty {
                Label(viewModel.pdfFilename, systemImage: "doc.fill")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.cardBg, in: RoundedRectangle(cornerRadius: 8))
            }
            Spacer()
        }
        .padding()
    }

    private var resultsView: some View {
        VStack(spacing: 0) {
            List {
                ForEach(viewModel.candidates) { candidate in
                    CandidateRow(candidate: candidate) {
                        viewModel.toggleSelection(candidate.id)
                    } onEdit: {
                        editingCandidate = candidate
                    }
                }
            }
            .listStyle(.plain)

            // Save bar
            VStack(spacing: 8) {
                if viewModel.selectedCount > 0 {
                    let overflow = viewModel.codesOverFreeLimit(
                        currentCodeCount: existingCodes.count,
                        isProUnlocked: storeManager.isProUnlocked
                    )
                    if overflow > 0 {
                        Text("Free limit: \(overflow) code\(overflow == 1 ? "" : "s") over the \(StoreManager.freeCodeLimit)-code limit")
                            .font(.caption)
                            .foregroundStyle(Color.electricViolet)
                    }
                }

                Button {
                    let overflow = viewModel.codesOverFreeLimit(
                        currentCodeCount: existingCodes.count,
                        isProUnlocked: storeManager.isProUnlocked
                    )
                    if overflow > 0 {
                        showPaywall = true
                    } else {
                        let count = viewModel.saveSelected(to: modelContext)
                        HapticManager.success()
                        if count > 0 {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                                dismiss()
                            }
                        }
                    }
                } label: {
                    Text("Save \(viewModel.selectedCount) Selected")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(Color.electricViolet)
                .disabled(viewModel.selectedCount == 0)
            }
            .padding()
            .background(.ultraThinMaterial)
        }
    }

    private var emptyView: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "magnifyingglass")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text("No QR Codes Found")
                .font(.headline)
            Text("This PDF doesn't contain any QR codes.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Button {
                viewModel.reset()
                showDocumentPicker = true
            } label: {
                Text("Try Another PDF")
                    .fontWeight(.medium)
            }
            .buttonStyle(.bordered)
            .tint(Color.electricViolet)
            Spacer()
        }
        .padding()
    }

    private func errorView(message: String) -> some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text("Couldn't Read PDF")
                .font(.headline)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button {
                viewModel.reset()
                showDocumentPicker = true
            } label: {
                Text("Try Another PDF")
                    .fontWeight(.medium)
            }
            .buttonStyle(.bordered)
            .tint(Color.electricViolet)
            Spacer()
        }
        .padding()
    }

    private func savedView(count: Int) -> some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 56))
                .foregroundStyle(Color.activeGreen)
            Text("Saved \(count) QR Code\(count == 1 ? "" : "s")")
                .font(.headline)
            Text("Added to your library")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
        }
        .padding()
    }
}

// MARK: - Candidate Row

private struct CandidateRow: View {
    @Bindable var candidate: ImportCandidate
    let onToggle: () -> Void
    let onEdit: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Button {
                onToggle()
            } label: {
                Image(systemName: candidate.isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(candidate.isSelected ? Color.electricViolet : .secondary)
                    .font(.title3)
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Image(systemName: candidate.detectedType.icon)
                        .font(.caption)
                    Text(candidate.title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .lineLimit(1)
                }

                Text(candidate.payload)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                HStack(spacing: 4) {
                    Text(candidate.detectedType.label)
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.electricViolet.opacity(0.15))
                        .foregroundStyle(Color.electricViolet)
                        .clipShape(Capsule())

                    ForEach(candidate.tags, id: \.self) { tag in
                        Text(tag)
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.blue.opacity(0.15))
                            .foregroundStyle(.blue)
                            .clipShape(Capsule())
                    }

                    Text("pg \(candidate.pageNumbers.map(String.init).joined(separator: ", "))")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
            .contentShape(Rectangle())
            .onTapGesture { onEdit() }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Edit Candidate View

private struct EditCandidateView: View {
    @Bindable var candidate: ImportCandidate
    @Environment(\.dismiss) private var dismiss
    @State private var newTag = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Title") {
                    TextField("Title", text: $candidate.title)
                }
                Section("Tags") {
                    ForEach(candidate.tags, id: \.self) { tag in
                        HStack {
                            Text(tag)
                            Spacer()
                            Button {
                                candidate.tags.removeAll { $0 == tag }
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    HStack {
                        TextField("Add tag", text: $newTag)
                            .onSubmit { addTag() }
                        Button("Add") { addTag() }
                            .disabled(newTag.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                }
                Section("Type") {
                    HStack {
                        Image(systemName: candidate.detectedType.icon)
                        Text(candidate.detectedType.label)
                        Spacer()
                        Text("Auto-detected")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                Section("Data") {
                    Text(candidate.payload)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Edit Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private func addTag() {
        let trimmed = newTag.trimmingCharacters(in: .whitespacesAndNewlines)
        guard Validation.validateTag(trimmed) == nil,
              !candidate.tags.contains(trimmed) else { return }
        candidate.tags.append(trimmed)
        newTag = ""
    }
}

// MARK: - Document Picker

private struct DocumentPicker: UIViewControllerRepresentable {
    let onPick: (URL) -> Void

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.pdf])
        picker.delegate = context.coordinator
        picker.allowsMultipleSelection = false
        return picker
    }

    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(onPick: onPick) }

    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let onPick: (URL) -> Void
        init(onPick: @escaping (URL) -> Void) { self.onPick = onPick }

        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let url = urls.first else { return }
            guard url.startAccessingSecurityScopedResource() else { return }
            // Copy to temp location so we can release the security-scoped resource immediately
            let tempURL = FileManager.default.temporaryDirectory
                .appendingPathComponent("pdf-import-\(UUID().uuidString).pdf")
            do {
                try FileManager.default.copyItem(at: url, to: tempURL)
                url.stopAccessingSecurityScopedResource()
                onPick(tempURL)
            } catch {
                url.stopAccessingSecurityScopedResource()
            }
        }
    }
}
