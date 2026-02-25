import SwiftUI

// MARK: - App Layout

/// Centralized spacing, corner radii, and shadow parameters.
enum AppLayout {

    // MARK: - Corner Radii

    static let cornerRadiusSmall: CGFloat = 8
    static let cornerRadiusButton: CGFloat = 12
    static let cornerRadiusCard: CGFloat = 16
    static let cornerRadiusSheet: CGFloat = 20

    // MARK: - Shadow

    static let shadowRadius: CGFloat = 10
    static let shadowY: CGFloat = 4
    static let shadowOpacity: Double = 0.10

    // MARK: - Content Width

    static let maxContentWidth: CGFloat = 760

    // MARK: - Spacing Scale

    static let spacing4: CGFloat = 4
    static let spacing8: CGFloat = 8
    static let spacing12: CGFloat = 12
    static let spacing16: CGFloat = 16
    static let spacing20: CGFloat = 20
    static let spacing24: CGFloat = 24
    static let spacing32: CGFloat = 32
}
