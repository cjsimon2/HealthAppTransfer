import SwiftUI
import CoreGraphics

// MARK: - Warm Card Modifier

/// Elevated surface fill, warm shadow, dark mode amber border stroke.
struct WarmCardModifier: ViewModifier {

    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        content
            .background {
                RoundedRectangle(cornerRadius: AppLayout.cornerRadiusCard)
                    .fill(AppColors.surfaceElevated)
                    .shadow(
                        color: AppColors.shadow.opacity(AppLayout.shadowOpacity),
                        radius: AppLayout.shadowRadius,
                        x: 0,
                        y: AppLayout.shadowY
                    )
            }
            .overlay {
                if colorScheme == .dark {
                    RoundedRectangle(cornerRadius: AppLayout.cornerRadiusCard)
                        .strokeBorder(AppColors.darkBorder, lineWidth: 1)
                }
            }
    }
}

extension View {
    /// Applies warm card styling: elevated surface, warm shadow, dark mode border.
    func warmCard() -> some View {
        modifier(WarmCardModifier())
    }
}

// MARK: - Warm Primary Button Style

/// Ochre gold background, white text, pressed state opacity.
struct WarmPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(.white)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(AppColors.primary, in: RoundedRectangle(cornerRadius: AppLayout.cornerRadiusButton))
            .opacity(configuration.isPressed ? 0.8 : 1.0)
    }
}

extension ButtonStyle where Self == WarmPrimaryButtonStyle {
    static var warmPrimary: WarmPrimaryButtonStyle { WarmPrimaryButtonStyle() }
}

// MARK: - Warm Secondary Button Style

/// Outlined variant with warm border.
struct WarmSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(AppColors.primary)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background {
                RoundedRectangle(cornerRadius: AppLayout.cornerRadiusButton)
                    .strokeBorder(AppColors.primary, lineWidth: 1.5)
            }
            .opacity(configuration.isPressed ? 0.7 : 1.0)
    }
}

extension ButtonStyle where Self == WarmSecondaryButtonStyle {
    static var warmSecondary: WarmSecondaryButtonStyle { WarmSecondaryButtonStyle() }
}

// MARK: - Paper Grain Overlay

/// Subtle noise texture composited at 3% opacity for an analog paper feel.
/// Generated once as a static CGImage, tiled across the view.
/// Automatically disabled when `accessibilityReduceTransparency` is true.
struct PaperGrainOverlay: View {

    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    private static let grainImage: CGImage? = {
        let size = 128
        let bytesPerRow = size
        var pixels = [UInt8](repeating: 0, count: size * size)

        // Deterministic noise pattern using a simple LCG
        var seed: UInt64 = 42
        for i in 0..<pixels.count {
            seed = seed &* 6364136223846793005 &+ 1442695040888963407
            pixels[i] = UInt8((seed >> 33) & 0xFF)
        }

        guard let provider = CGDataProvider(data: Data(pixels) as CFData),
              let image = CGImage(
                  width: size,
                  height: size,
                  bitsPerComponent: 8,
                  bitsPerPixel: 8,
                  bytesPerRow: bytesPerRow,
                  space: CGColorSpaceCreateDeviceGray(),
                  bitmapInfo: CGBitmapInfo(rawValue: 0),
                  provider: provider,
                  decode: nil,
                  shouldInterpolate: false,
                  intent: .defaultIntent
              ) else { return nil }

        return image
    }()

    var body: some View {
        if !reduceTransparency, let grain = Self.grainImage {
            Image(decorative: grain, scale: 2)
                .resizable(resizingMode: .tile)
                .opacity(0.03)
                .blendMode(.multiply)
                .allowsHitTesting(false)
                .accessibilityHidden(true)
        }
    }
}
