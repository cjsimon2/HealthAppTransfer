import SwiftUI

// MARK: - Chart Colors

extension HealthDataCategory {

    /// Category-specific chart colors — warm, muted, analog-feeling palette.
    var chartColor: Color {
        switch self {
        case .activity:          return Color(light: .init(hex: 0xCC8833), dark: .init(hex: 0xE0A050)) // Warm amber
        case .heart:             return Color(light: .init(hex: 0xBF4040), dark: .init(hex: 0xD96666)) // Muted crimson
        case .vitals:            return Color(light: .init(hex: 0x8B6AAE), dark: .init(hex: 0xAA8ACC)) // Dusty plum
        case .bodyMeasurements:  return Color(light: .init(hex: 0x5A7FA5), dark: .init(hex: 0x7CA0C4)) // Slate blue
        case .metabolic:         return Color(light: .init(hex: 0x5C5FA0), dark: .init(hex: 0x7E80BF)) // Muted indigo
        case .nutrition:         return Color(light: .init(hex: 0x6B9E5C), dark: .init(hex: 0x8FBF7A)) // Fern green
        case .respiratory:       return Color(light: .init(hex: 0x4A9E9E), dark: .init(hex: 0x6FBFBF)) // Muted teal
        case .mobility:          return Color(light: .init(hex: 0x3D8E8E), dark: .init(hex: 0x60ADAD)) // Deep teal
        case .fitness:           return Color(light: .init(hex: 0x5BAA8C), dark: .init(hex: 0x7CC8A8)) // Jade
        case .audioExposure:     return Color(light: .init(hex: 0xC4A335), dark: .init(hex: 0xDDBB55)) // Warm ochre
        case .sleep:             return Color(light: .init(hex: 0x7B6B9E), dark: .init(hex: 0x9D8DBF)) // Lavender
        case .mindfulness:       return Color(light: .init(hex: 0x6BA38E), dark: .init(hex: 0x8FC4AA)) // Sage mint
        case .reproductiveHealth: return Color(light: .init(hex: 0xC47A8E), dark: .init(hex: 0xDB99AA)) // Dusty rose
        case .symptoms:          return Color(light: .init(hex: 0xC45A5A), dark: .init(hex: 0xDB7A7A)) // Soft red
        case .other:             return Color(light: .init(hex: 0x8A8078), dark: .init(hex: 0xA8A098)) // Warm gray
        case .workout:           return Color(light: .init(hex: 0x6B9E5C), dark: .init(hex: 0x8FBF7A)) // Fern green
        case .characteristics:   return Color(light: .init(hex: 0x5A7FA5), dark: .init(hex: 0x7CA0C4)) // Slate blue
        }
    }
}

// MARK: - Hex Init (internal for chart colors)

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
