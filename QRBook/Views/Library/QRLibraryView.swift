import SwiftUI
import SwiftData

enum ViewMode {
    case all, favorites, recent
}

struct QRLibraryView: View {
    let viewMode: ViewMode

    @Query(sort: \QRCode.createdAt, order: .reverse) private var qrCodes: [QRCode]
    @State private var viewModel = QRLibraryViewModel()
    @State private var selectedQR: QRCode?
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
            .fullScreenCover(item: $selectedQR) { qr in
                QRFullscreenView(
                    qrCode: qr,
                    allQRCodes: displayedCodes
                )
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
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
        .refreshable {
            // SwiftData auto-syncs via iCloud, but this provides pull-to-refresh UX
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
