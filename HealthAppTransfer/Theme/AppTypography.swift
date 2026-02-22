import SwiftUI

// MARK: - App Typography

/// Serif display fonts + sans body fonts.
/// New York (serif) and SF Pro (sans) are system fonts — no custom font files needed.
enum AppTypography {

    // MARK: - Display (Serif)

    /// Large serif title — hero text, section headers.
    static let displayLarge: Font = .system(.largeTitle, design: .serif).weight(.bold)

    /// Medium serif title — card headers, sheet titles.
    static let displayMedium: Font = .system(.title2, design: .serif).weight(.semibold)

    /// Small serif title — subsection headers.
    static let displaySmall: Font = .system(.title3, design: .serif).weight(.medium)

    // MARK: - Body (SF Pro)

    static let bodyRegular: Font = .body
    static let bodyMedium: Font = .body.weight(.medium)
    static let bodySemibold: Font = .body.weight(.semibold)

    static let subheadline: Font = .subheadline
    static let subheadlineMedium: Font = .subheadline.weight(.medium)

    static let captionRegular: Font = .caption
    static let captionMedium: Font = .caption.weight(.medium)

    static let caption2: Font = .caption2

    // MARK: - Mono Values

    /// Monospaced digits for metric values — prominent.
    static let monoValue: Font = .system(.title3, design: .monospaced).weight(.bold)

    /// Monospaced digits for smaller metric values.
    static let monoValueSmall: Font = .system(.body, design: .monospaced).weight(.semibold)
}
