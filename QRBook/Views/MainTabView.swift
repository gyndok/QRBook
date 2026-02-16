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

#Preview {
    MainTabView()
        .modelContainer(for: QRCode.self, inMemory: true)
}
