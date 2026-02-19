import SwiftUI
import SwiftData

enum ViewMode {
    case all, favorites, recent
}

struct QRLibraryView: View {
    let viewMode: ViewMode

    @Query(sort: \QRCode.createdAt, order: .reverse) private var qrCodes: [QRCode]
    @Query(sort: \Folder.sortOrder) private var folders: [Folder]
    @State private var viewModel = QRLibraryViewModel()
    @State private var selectedQR: QRCode?
    @State private var showDeleteConfirm = false
    @State private var showPaywall = false
    @Environment(\.modelContext) private var modelContext
    @Environment(DeepLinkRouter.self) private var router: DeepLinkRouter?
    @Environment(StoreManager.self) private var storeManager
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
            .background(Color.appBg)
            .navigationTitle(navigationTitle)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    if viewModel.isSelectMode {
                        Button("Done") { viewModel.exitSelectMode() }
                    } else {
                        HStack(spacing: 16) {
                            if storeManager.isProUnlocked {
                                Button { viewModel.isSelectMode = true } label: {
                                    Image(systemName: "checkmark.circle")
                                }
                            }
                            Button {
                                if qrCodes.count >= StoreManager.freeCodeLimit && !storeManager.isProUnlocked {
                                    showPaywall = true
                                } else {
                                    viewModel.showCreateSheet = true
                                }
                            } label: {
                                Image(systemName: "plus")
                            }
                        }
                    }
                }
                ToolbarItem(placement: .topBarLeading) {
                    if viewModel.isSelectMode {
                        Button {
                            if viewModel.selectedIds.count == displayedCodes.count {
                                viewModel.deselectAll()
                            } else {
                                viewModel.selectAll(displayedCodes)
                            }
                        } label: {
                            Text(viewModel.selectedIds.count == displayedCodes.count ? "Deselect All" : "Select All")
                        }
                    } else {
                        NavigationLink {
                            SettingsView()
                        } label: {
                            Image(systemName: "gearshape")
                        }
                    }
                }
            }
            .searchable(text: $viewModel.searchText, prompt: "Search QR codes...")
            .sheet(isPresented: $viewModel.showCreateSheet) {
                CreateQRView(
                    prefillData: viewModel.pendingShareData,
                    prefillType: viewModel.pendingShareType == "url" ? .url : nil
                )
                .onDisappear {
                    viewModel.pendingShareData = nil
                    viewModel.pendingShareType = nil
                }
            }
            .sheet(isPresented: $viewModel.showFilterSheet) {
                QRFilterSheet(viewModel: viewModel, allTags: viewModel.allTags(from: qrCodes))
            }
            .sheet(isPresented: $showPaywall) { PaywallView() }
            .fullScreenCover(item: $selectedQR) { qr in
                QRFullscreenView(
                    qrCode: qr,
                    allQRCodes: displayedCodes
                )
            }
            .onChange(of: router?.showQRCodeId) { _, id in
                if let id, let qr = qrCodes.first(where: { $0.id == id }) {
                    selectedQR = qr
                    router?.showQRCodeId = nil
                }
            }
            .onChange(of: router?.showCreateSheet) { _, show in
                if show == true {
                    if let data = router?.pendingShareData {
                        let type = router?.pendingShareType
                        viewModel.showCreateSheet = false
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            viewModel.pendingShareData = data
                            viewModel.pendingShareType = type
                            viewModel.showCreateSheet = true
                        }
                        router?.pendingShareData = nil
                        router?.pendingShareType = nil
                    } else {
                        viewModel.showCreateSheet = true
                    }
                    router?.showCreateSheet = false
                }
            }
        }
    }

    private var qrGrid: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
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

                    if storeManager.isProUnlocked {
                        Text("\(displayedCodes.count) of \(qrCodes.count)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("\(qrCodes.count) of \(StoreManager.freeCodeLimit)")
                            .font(.caption)
                            .foregroundStyle(qrCodes.count >= StoreManager.freeCodeLimit ? Color.electricViolet : .secondary)
                    }

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
                                .background(Color.electricViolet, in: Circle())
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
                            if viewModel.isSelectMode {
                                viewModel.toggleSelection(qrCode.id)
                            } else {
                                selectedQR = qrCode
                            }
                        }
                        .overlay(alignment: .topLeading) {
                            if viewModel.isSelectMode {
                                Image(systemName: viewModel.selectedIds.contains(qrCode.id) ? "checkmark.circle.fill" : "circle")
                                    .foregroundStyle(viewModel.selectedIds.contains(qrCode.id) ? Color.electricViolet : .secondary)
                                    .font(.title3)
                                    .padding(8)
                            }
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
        .refreshable {
            // SwiftData auto-syncs via iCloud, but this provides pull-to-refresh UX
        }
        .safeAreaInset(edge: .bottom) {
            if viewModel.isSelectMode && !viewModel.selectedIds.isEmpty {
                HStack(spacing: 20) {
                    Button(role: .destructive) {
                        showDeleteConfirm = true
                    } label: {
                        Label("Delete", systemImage: "trash")
                            .font(.subheadline)
                    }

                    if !folders.isEmpty {
                        Menu {
                            Button("None") { batchMoveToFolder("") }
                            ForEach(folders) { folder in
                                Button(folder.name) { batchMoveToFolder(folder.name) }
                            }
                        } label: {
                            Label("Move", systemImage: "folder")
                                .font(.subheadline)
                        }
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
        .alert("Delete Selected?", isPresented: $showDeleteConfirm) {
            Button("Delete", role: .destructive) { batchDelete() }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Delete \(viewModel.selectedIds.count) QR code(s)? This cannot be undone.")
        }
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label("No QR Codes Yet", systemImage: "qrcode")
                .foregroundStyle(Color.electricViolet)
        } description: {
            Text("No QR codes yet \u{2014} tap + to create your first.")
        } actions: {
            Button {
                viewModel.showCreateSheet = true
            } label: {
                Text("Create QR Code")
            }
            .buttonStyle(.borderedProminent)
            .tint(Color.electricViolet)
        }
    }

    private var noResultsState: some View {
        ContentUnavailableView {
            Label("No Results", systemImage: "magnifyingglass")
                .foregroundStyle(Color.electricViolet)
        } description: {
            Text("Try adjusting your search or filters.")
        } actions: {
            Button("Clear Filters") {
                viewModel.clearFilters()
            }
            .buttonStyle(.bordered)
            .tint(Color.electricViolet)
        }
    }

    private func batchDelete() {
        for qr in qrCodes where viewModel.selectedIds.contains(qr.id) {
            modelContext.delete(qr)
        }
        DataSyncManager.syncFavorites(context: modelContext)
        viewModel.exitSelectMode()
        HapticManager.success()
    }

    private func batchMoveToFolder(_ folder: String) {
        for qr in qrCodes where viewModel.selectedIds.contains(qr.id) {
            qr.folderName = folder
            qr.updatedAt = .now
        }
        viewModel.exitSelectMode()
        HapticManager.success()
    }
}
