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
