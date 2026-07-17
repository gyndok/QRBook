import SwiftUI
import UIKit

struct MainTabView: View {
    @Environment(DeepLinkRouter.self) private var router

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

    init() {
        // Tab bar appearance
        let tabAppearance = UITabBarAppearance()
        tabAppearance.configureWithDefaultBackground()
        tabAppearance.backgroundEffect = UIBlurEffect(style: .systemChromeMaterial)
        UITabBar.appearance().standardAppearance = tabAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabAppearance
        UITabBar.appearance().unselectedItemTintColor = .secondaryLabel

        // Navigation bar appearance
        let navAppearance = UINavigationBarAppearance()
        navAppearance.configureWithDefaultBackground()
        if let roundedDescriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: .largeTitle)
            .withDesign(.rounded) {
            navAppearance.largeTitleTextAttributes = [
                .font: UIFont(descriptor: roundedDescriptor.withSymbolicTraits(.traitBold) ?? roundedDescriptor, size: 28)
            ]
        }
        UINavigationBar.appearance().standardAppearance = navAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navAppearance
    }

    var body: some View {
        // Bind directly to the router so manual tab switches and deep links
        // share one source of truth; mirroring into local @State broke repeat
        // deep links to the already-selected value.
        @Bindable var router = router
        TabView(selection: $router.selectedTab) {
            ForEach(Tab.allCases, id: \.self) { tab in
                Group {
                    switch tab {
                    case .library:
                        QRLibraryView(viewMode: .all)
                    case .scan:
                        ScannerView()
                    case .favorites:
                        QRLibraryView(viewMode: .favorites)
                    case .recent:
                        QRLibraryView(viewMode: .recent)
                    case .flyers:
                        FlyerGalleryView()
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


#Preview {
    MainTabView()
        .environment(DeepLinkRouter())
        .environment(StoreManager())
        .modelContainer(for: QRCode.self, inMemory: true)
}
