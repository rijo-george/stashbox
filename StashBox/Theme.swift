import SwiftUI

// MARK: - Theme Colors

struct ThemeColors {
    let bg: Color
    let surface: Color
    let headerBg: Color
    let statusBarBg: Color

    let textPrimary: Color
    let textSecondary: Color

    let accent: Color
    let accentSecondary: Color
    let selectedBg: Color
    let borderActive: Color
    let borderInactive: Color

    let modalBg: Color
    let modalTitle: Color

    let warrantyActive: Color
    let warrantyExpiring: Color
    let warrantyExpired: Color
    let warrantySafe: Color

    let cardBg: Color
    let cardBorder: Color
    let destructive: Color
    let categoryTint: Color

    let isDark: Bool
}

// MARK: - Theme Name

enum ThemeName: String, CaseIterable, Identifiable {
    case dark, light, sunset, ocean, forest, rose

    var id: String { rawValue }

    var displayName: String {
        rawValue.capitalized
    }

    var colors: ThemeColors {
        switch self {
        case .dark: return Self.darkColors
        case .light: return Self.lightColors
        case .sunset: return Self.sunsetColors
        case .ocean: return Self.oceanColors
        case .forest: return Self.forestColors
        case .rose: return Self.roseColors
        }
    }

    var colorScheme: ColorScheme {
        switch self {
        case .light: return .light
        default: return .dark
        }
    }

    // MARK: - Dark

    private static let darkColors = ThemeColors(
        bg: Color(red: 0.07, green: 0.07, blue: 0.09),
        surface: Color(red: 0.11, green: 0.11, blue: 0.14),
        headerBg: Color(red: 0.09, green: 0.09, blue: 0.12),
        statusBarBg: Color(red: 0.07, green: 0.07, blue: 0.09),
        textPrimary: Color(red: 0.93, green: 0.93, blue: 0.95),
        textSecondary: Color(red: 0.55, green: 0.55, blue: 0.60),
        accent: Color(red: 0.35, green: 0.61, blue: 0.98),
        accentSecondary: Color(red: 0.58, green: 0.39, blue: 0.98),
        selectedBg: Color(red: 0.15, green: 0.20, blue: 0.30),
        borderActive: Color(red: 0.35, green: 0.61, blue: 0.98).opacity(0.4),
        borderInactive: Color(red: 0.25, green: 0.25, blue: 0.30),
        modalBg: Color(red: 0.10, green: 0.10, blue: 0.13),
        modalTitle: Color(red: 0.35, green: 0.61, blue: 0.98),
        warrantyActive: Color(red: 0.30, green: 0.85, blue: 0.50),
        warrantyExpiring: Color(red: 1.0, green: 0.75, blue: 0.20),
        warrantyExpired: Color(red: 1.0, green: 0.35, blue: 0.35),
        warrantySafe: Color(red: 0.40, green: 0.80, blue: 0.70),
        cardBg: Color(red: 0.12, green: 0.12, blue: 0.15),
        cardBorder: Color(red: 0.20, green: 0.20, blue: 0.25),
        destructive: Color(red: 1.0, green: 0.30, blue: 0.30),
        categoryTint: Color(red: 0.55, green: 0.65, blue: 0.80),
        isDark: true
    )

    // MARK: - Light

    private static let lightColors = ThemeColors(
        bg: Color(red: 0.96, green: 0.96, blue: 0.98),
        surface: Color(red: 1.0, green: 1.0, blue: 1.0),
        headerBg: Color(red: 0.98, green: 0.98, blue: 1.0),
        statusBarBg: Color(red: 0.96, green: 0.96, blue: 0.98),
        textPrimary: Color(red: 0.10, green: 0.10, blue: 0.12),
        textSecondary: Color(red: 0.45, green: 0.45, blue: 0.50),
        accent: Color(red: 0.20, green: 0.45, blue: 0.90),
        accentSecondary: Color(red: 0.45, green: 0.30, blue: 0.85),
        selectedBg: Color(red: 0.88, green: 0.92, blue: 1.0),
        borderActive: Color(red: 0.20, green: 0.45, blue: 0.90).opacity(0.3),
        borderInactive: Color(red: 0.85, green: 0.85, blue: 0.88),
        modalBg: Color(red: 1.0, green: 1.0, blue: 1.0),
        modalTitle: Color(red: 0.20, green: 0.45, blue: 0.90),
        warrantyActive: Color(red: 0.15, green: 0.65, blue: 0.35),
        warrantyExpiring: Color(red: 0.80, green: 0.55, blue: 0.05),
        warrantyExpired: Color(red: 0.80, green: 0.20, blue: 0.20),
        warrantySafe: Color(red: 0.20, green: 0.60, blue: 0.50),
        cardBg: Color(red: 1.0, green: 1.0, blue: 1.0),
        cardBorder: Color(red: 0.90, green: 0.90, blue: 0.92),
        destructive: Color(red: 0.85, green: 0.20, blue: 0.20),
        categoryTint: Color(red: 0.35, green: 0.45, blue: 0.60),
        isDark: false
    )

    // MARK: - Sunset

    private static let sunsetColors = ThemeColors(
        bg: Color(red: 0.10, green: 0.07, blue: 0.07),
        surface: Color(red: 0.15, green: 0.10, blue: 0.10),
        headerBg: Color(red: 0.12, green: 0.08, blue: 0.08),
        statusBarBg: Color(red: 0.10, green: 0.07, blue: 0.07),
        textPrimary: Color(red: 0.95, green: 0.90, blue: 0.88),
        textSecondary: Color(red: 0.60, green: 0.50, blue: 0.48),
        accent: Color(red: 1.0, green: 0.55, blue: 0.30),
        accentSecondary: Color(red: 0.95, green: 0.35, blue: 0.45),
        selectedBg: Color(red: 0.25, green: 0.15, blue: 0.12),
        borderActive: Color(red: 1.0, green: 0.55, blue: 0.30).opacity(0.4),
        borderInactive: Color(red: 0.25, green: 0.18, blue: 0.16),
        modalBg: Color(red: 0.13, green: 0.09, blue: 0.09),
        modalTitle: Color(red: 1.0, green: 0.55, blue: 0.30),
        warrantyActive: Color(red: 0.40, green: 0.85, blue: 0.45),
        warrantyExpiring: Color(red: 1.0, green: 0.75, blue: 0.25),
        warrantyExpired: Color(red: 1.0, green: 0.35, blue: 0.35),
        warrantySafe: Color(red: 0.45, green: 0.78, blue: 0.65),
        cardBg: Color(red: 0.16, green: 0.11, blue: 0.11),
        cardBorder: Color(red: 0.28, green: 0.20, blue: 0.18),
        destructive: Color(red: 1.0, green: 0.30, blue: 0.30),
        categoryTint: Color(red: 0.80, green: 0.55, blue: 0.45),
        isDark: true
    )

    // MARK: - Ocean

    private static let oceanColors = ThemeColors(
        bg: Color(red: 0.05, green: 0.08, blue: 0.12),
        surface: Color(red: 0.08, green: 0.12, blue: 0.18),
        headerBg: Color(red: 0.06, green: 0.10, blue: 0.15),
        statusBarBg: Color(red: 0.05, green: 0.08, blue: 0.12),
        textPrimary: Color(red: 0.88, green: 0.93, blue: 0.98),
        textSecondary: Color(red: 0.45, green: 0.55, blue: 0.65),
        accent: Color(red: 0.20, green: 0.70, blue: 0.90),
        accentSecondary: Color(red: 0.30, green: 0.55, blue: 0.95),
        selectedBg: Color(red: 0.10, green: 0.18, blue: 0.28),
        borderActive: Color(red: 0.20, green: 0.70, blue: 0.90).opacity(0.4),
        borderInactive: Color(red: 0.15, green: 0.22, blue: 0.30),
        modalBg: Color(red: 0.07, green: 0.11, blue: 0.16),
        modalTitle: Color(red: 0.20, green: 0.70, blue: 0.90),
        warrantyActive: Color(red: 0.25, green: 0.88, blue: 0.60),
        warrantyExpiring: Color(red: 1.0, green: 0.78, blue: 0.25),
        warrantyExpired: Color(red: 1.0, green: 0.40, blue: 0.40),
        warrantySafe: Color(red: 0.30, green: 0.75, blue: 0.80),
        cardBg: Color(red: 0.09, green: 0.13, blue: 0.19),
        cardBorder: Color(red: 0.15, green: 0.22, blue: 0.30),
        destructive: Color(red: 1.0, green: 0.35, blue: 0.35),
        categoryTint: Color(red: 0.45, green: 0.65, blue: 0.80),
        isDark: true
    )

    // MARK: - Forest

    private static let forestColors = ThemeColors(
        bg: Color(red: 0.06, green: 0.09, blue: 0.06),
        surface: Color(red: 0.10, green: 0.14, blue: 0.10),
        headerBg: Color(red: 0.08, green: 0.11, blue: 0.08),
        statusBarBg: Color(red: 0.06, green: 0.09, blue: 0.06),
        textPrimary: Color(red: 0.90, green: 0.95, blue: 0.90),
        textSecondary: Color(red: 0.50, green: 0.58, blue: 0.50),
        accent: Color(red: 0.35, green: 0.80, blue: 0.45),
        accentSecondary: Color(red: 0.55, green: 0.75, blue: 0.35),
        selectedBg: Color(red: 0.12, green: 0.20, blue: 0.12),
        borderActive: Color(red: 0.35, green: 0.80, blue: 0.45).opacity(0.4),
        borderInactive: Color(red: 0.18, green: 0.25, blue: 0.18),
        modalBg: Color(red: 0.08, green: 0.12, blue: 0.08),
        modalTitle: Color(red: 0.35, green: 0.80, blue: 0.45),
        warrantyActive: Color(red: 0.30, green: 0.90, blue: 0.50),
        warrantyExpiring: Color(red: 0.95, green: 0.78, blue: 0.25),
        warrantyExpired: Color(red: 1.0, green: 0.38, blue: 0.38),
        warrantySafe: Color(red: 0.35, green: 0.80, blue: 0.65),
        cardBg: Color(red: 0.11, green: 0.15, blue: 0.11),
        cardBorder: Color(red: 0.20, green: 0.28, blue: 0.20),
        destructive: Color(red: 1.0, green: 0.32, blue: 0.32),
        categoryTint: Color(red: 0.50, green: 0.70, blue: 0.50),
        isDark: true
    )

    // MARK: - Rose

    private static let roseColors = ThemeColors(
        bg: Color(red: 0.09, green: 0.06, blue: 0.09),
        surface: Color(red: 0.14, green: 0.10, blue: 0.14),
        headerBg: Color(red: 0.11, green: 0.08, blue: 0.11),
        statusBarBg: Color(red: 0.09, green: 0.06, blue: 0.09),
        textPrimary: Color(red: 0.95, green: 0.90, blue: 0.95),
        textSecondary: Color(red: 0.58, green: 0.48, blue: 0.58),
        accent: Color(red: 0.85, green: 0.40, blue: 0.65),
        accentSecondary: Color(red: 0.70, green: 0.35, blue: 0.85),
        selectedBg: Color(red: 0.22, green: 0.12, blue: 0.20),
        borderActive: Color(red: 0.85, green: 0.40, blue: 0.65).opacity(0.4),
        borderInactive: Color(red: 0.25, green: 0.18, blue: 0.25),
        modalBg: Color(red: 0.12, green: 0.08, blue: 0.12),
        modalTitle: Color(red: 0.85, green: 0.40, blue: 0.65),
        warrantyActive: Color(red: 0.35, green: 0.85, blue: 0.50),
        warrantyExpiring: Color(red: 1.0, green: 0.75, blue: 0.25),
        warrantyExpired: Color(red: 1.0, green: 0.35, blue: 0.40),
        warrantySafe: Color(red: 0.45, green: 0.75, blue: 0.70),
        cardBg: Color(red: 0.15, green: 0.11, blue: 0.15),
        cardBorder: Color(red: 0.28, green: 0.20, blue: 0.28),
        destructive: Color(red: 1.0, green: 0.30, blue: 0.35),
        categoryTint: Color(red: 0.70, green: 0.50, blue: 0.70),
        isDark: true
    )
}

// MARK: - Theme Manager

class ThemeManager: ObservableObject {
    @Published var current: ThemeName {
        didSet { persist() }
    }

    var colors: ThemeColors { current.colors }

    init() {
        let config = AssetStore.AppConfig.load()
        self.current = ThemeName(rawValue: config.theme) ?? .dark
    }

    private func persist() {
        var config = AssetStore.AppConfig.load()
        config.theme = current.rawValue
        config.save()
    }
}

// MARK: - Expiry urgency color helper

extension ExpiryUrgency {
    func color(from theme: ThemeColors) -> Color {
        switch self {
        case .expired: return theme.warrantyExpired
        case .critical: return theme.warrantyExpired
        case .warning: return theme.warrantyExpiring
        case .upcoming: return theme.warrantyExpiring.opacity(0.8)
        case .safe: return theme.warrantyActive
        case .lifetime: return theme.warrantySafe
        case .noWarranty: return theme.textSecondary
        }
    }
}
