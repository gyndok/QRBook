import SwiftUI
import UIKit

// MARK: - Color Extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        let scanner = Scanner(string: hex)
        var rgbValue: UInt64 = 0
        scanner.scanHexInt64(&rgbValue)
        self.init(
            red: Double((rgbValue & 0xFF0000) >> 16) / 255.0,
            green: Double((rgbValue & 0x00FF00) >> 8) / 255.0,
            blue: Double(rgbValue & 0x0000FF) / 255.0
        )
    }

    init(light: Color, dark: Color) {
        self.init(UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(dark)
                : UIColor(light)
        })
    }

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

    // Semantic colors
    static var electricViolet: Color {
        let hex = UserDefaults.standard.string(forKey: "accentColorHex") ?? "7C3AED"
        return Color(hex: hex)
    }

    static var deepIndigo: Color {
        let hex = UserDefaults.standard.string(forKey: "accentColorHex") ?? "7C3AED"
        let theme = AccentTheme(rawValue: hex) ?? .violet
        return theme.companionColor
    }

    static let appBg = Color(light: Color(hex: "F8F7FF"), dark: Color(hex: "0F0D1A"))
    static let cardBg = Color(light: .white, dark: Color(hex: "1A1730"))
    static let textPrimary = Color(light: Color(hex: "1E1B4B"), dark: Color(hex: "F1F0F7"))
    static let subtleBorder = Color(light: Color(hex: "E5E3F0"), dark: Color(hex: "2D2A45"))

    static let activeGreen = Color(hex: "10B981")
    static let favoriteAmber = Color(hex: "F59E0B")
}

// MARK: - AppTheme

enum AppTheme {
    static let cardRadius: CGFloat = 16

    static var cardBorderGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color.electricViolet.opacity(0.15),
                Color.deepIndigo.opacity(0.15)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var violetToIndigo: LinearGradient {
        LinearGradient(
            colors: [.electricViolet, .deepIndigo],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var fullscreenRadialGlow: RadialGradient {
        RadialGradient(
            colors: [
                Color.electricViolet.opacity(0.10),
                Color.clear
            ],
            center: .center,
            startRadius: 50,
            endRadius: 300
        )
    }
}

// MARK: - Font Extension

extension Font {
    static let screenTitle: Font = .system(size: 28, weight: .bold, design: .rounded)
    static let cardTitle: Font = .system(size: 17, weight: .semibold, design: .rounded)
}

// MARK: - ThemedCardModifier

struct ThemedCardModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        content
            .background(Color.cardBg)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardRadius))
            .overlay(
                RoundedRectangle(cornerRadius: AppTheme.cardRadius)
                    .stroke(AppTheme.cardBorderGradient, lineWidth: 1)
            )
            .shadow(
                color: colorScheme == .dark
                    ? Color.black.opacity(0.3)
                    : Color.electricViolet.opacity(0.08),
                radius: 8, y: 4
            )
    }
}

// MARK: - PressButtonStyle

struct PressButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

// MARK: - View Extensions

extension View {
    func themedCard() -> some View {
        modifier(ThemedCardModifier())
    }

    func pressStyle() -> some View {
        buttonStyle(PressButtonStyle())
    }
}
