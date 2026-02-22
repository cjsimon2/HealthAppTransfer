import SwiftUI

#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

// MARK: - App Colors

/// Centralized color tokens with light/dark adaptive values.
/// Warm, curated palette — Wes Anderson meets mid-century graphic design.
enum AppColors {

    // MARK: - Brand

    /// Ochre Gold — primary brand color for tint, accents, and interactive elements.
    static let primary = Color(light: .init(hex: 0xC49A2A), dark: .init(hex: 0xE0B84D))

    /// Terracotta — secondary accent for emphasis and alerts.
    static let accent = Color(light: .init(hex: 0xD96B4B), dark: .init(hex: 0xE8907A))

    /// Warm Sage — tertiary accent for positive indicators.
    static let secondary = Color(light: .init(hex: 0x768E6A), dark: .init(hex: 0x9AB88E))

    // MARK: - Surfaces

    /// Aged paper — root background.
    static let surface = Color(light: .init(hex: 0xF5F0E6), dark: .init(hex: 0x1C1916))

    /// Cream — elevated card/sheet backgrounds.
    static let surfaceElevated = Color(light: .init(hex: 0xFAF5ED), dark: .init(hex: 0x26221D))

    /// Slightly darker grouped background.
    static let surfaceGrouped = Color(light: .init(hex: 0xEDE7DB), dark: .init(hex: 0x16130F))

    // MARK: - Text

    /// Warm ink — primary text.
    static let textPrimary = Color(light: .init(hex: 0x2C2418), dark: .init(hex: 0xF2EDDF))

    /// Warm gray — secondary/caption text.
    static let textSecondary = Color(light: .init(hex: 0x7A7068), dark: .init(hex: 0xA09890))

    // MARK: - Shadow

    /// Warm brown-tinted shadow for light mode, pure black for dark mode.
    static let shadow = Color(light: .init(hex: 0x3D2E1A), dark: .init(hex: 0x000000))

    // MARK: - Dark Mode Border

    /// Warm amber at 8% opacity — subtle card edge in dark mode.
    static let darkBorder = Color(light: .clear, dark: .init(hex: 0xE0B84D).opacity(0.08))

    // MARK: - Semantic (kept standard for clinical accuracy)

    static let success = Color.green
    static let warning = Color.orange
    static let danger = Color.red
}

// MARK: - Hex Color Initializer

private extension Color {
    init(hex: UInt, opacity: Double = 1.0) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: opacity
        )
    }
}

// MARK: - Adaptive Color Helper

extension Color {
    /// Creates an adaptive color that responds to light/dark mode.
    init(light: Color, dark: Color) {
        #if canImport(UIKit)
        self.init(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(dark)
                : UIColor(light)
        })
        #elseif canImport(AppKit)
        self.init(nsColor: NSColor(name: nil) { appearance in
            appearance.bestMatch(from: [.darkAqua, .vibrantDark]) != nil
                ? NSColor(dark)
                : NSColor(light)
        })
        #endif
    }
}
