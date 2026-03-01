import SwiftUI

enum NeonTheme {
    static let backgroundTop = Color(hex: "120B2D")
    static let backgroundBottom = Color(hex: "070410")
    static let surface = Color.white.opacity(0.08)
    static let surfaceStrong = Color.white.opacity(0.14)
    static let textPrimary = Color.white
    static let textSecondary = Color.white.opacity(0.74)
    static let accent = Color(hex: "8B5CF6")
    static let accentStrong = Color(hex: "7C3AED")
    static let danger = Color(hex: "EF4444")
}

extension Color {
    init(hex: String) {
        let cleaned = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var value: UInt64 = 0
        Scanner(string: cleaned).scanHexInt64(&value)
        let red = Double((value >> 16) & 0xFF) / 255.0
        let green = Double((value >> 8) & 0xFF) / 255.0
        let blue = Double(value & 0xFF) / 255.0
        self.init(red: red, green: green, blue: blue)
    }
}

extension LinearGradient {
    static let neonBackground = LinearGradient(
        colors: [NeonTheme.backgroundTop, NeonTheme.backgroundBottom],
        startPoint: .top,
        endPoint: .bottom
    )
}
