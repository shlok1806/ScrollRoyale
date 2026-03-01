import SwiftUI

enum NeonTheme {
    static let bgStart    = Color(hex: "07070B")
    static let bgEnd      = Color(hex: "0A0A12")
    static let purple     = Color(hex: "7C3AED")
    static let purpleLight = Color(hex: "8B5CF6")
    static let purpleDark  = Color(hex: "7B2CBF")
    static let purpleMid   = Color(hex: "9D4EDD")
    static let green      = Color(hex: "39FF14")
    static let cyan       = Color(hex: "4CC9F0")
    static let magenta    = Color(hex: "FF3D81")
    static let pink       = Color(hex: "FF006E")
    static let yellow     = Color(hex: "FFD60A")
    static let orange     = Color(hex: "FF6B35")
    static let blue       = Color(hex: "4895EF")
    static let text       = Color(hex: "F2F3F7")
    static let textMuted  = Color(hex: "A7AAB5")
    static let card       = Color.white.opacity(0.04)
    static let cardBorder = Color.white.opacity(0.08)

    static let bgGradient = LinearGradient(
        colors: [bgStart, bgEnd],
        startPoint: .top,
        endPoint: .bottom
    )

    // Stripe pattern background colors
    static let stripeLight = Color(hex: "1A0A2E")
    static let stripeDark  = Color(hex: "0F0520")
}

// MARK: - Color + Hex Init

extension Color {
    init(hex: String) {
        var hex = hex.trimmingCharacters(in: .alphanumerics.inverted)
        if hex.count == 6 { hex = "FF" + hex }
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a = Double((int >> 24) & 0xFF) / 255
        let r = Double((int >> 16) & 0xFF) / 255
        let g = Double((int >> 8) & 0xFF) / 255
        let b = Double(int & 0xFF) / 255
        self.init(.sRGB, red: r, green: g, blue: b, opacity: a)
    }
}

// MARK: - Neon Text Shadow Modifier

struct NeonTextShadow: ViewModifier {
    let color: Color
    let radius: CGFloat
    let x: CGFloat
    let y: CGFloat

    func body(content: Content) -> some View {
        content
            .shadow(color: color.opacity(0.8), radius: radius)
            .shadow(color: .black.opacity(0.5), radius: 0, x: x, y: y)
    }
}

extension View {
    func neonShadow(_ color: Color = NeonTheme.green, radius: CGFloat = 10, x: CGFloat = 3, y: CGFloat = 3) -> some View {
        modifier(NeonTextShadow(color: color, radius: radius, x: x, y: y))
    }
}

// MARK: - Thick-bordered card style

struct NeonCard: ViewModifier {
    let backgroundColor: Color
    let borderColor: Color
    let shadowY: CGFloat

    init(bg: Color = Color.black.opacity(0.6), border: Color = .black, shadowY: CGFloat = 6) {
        backgroundColor = bg
        borderColor = border
        self.shadowY = shadowY
    }

    func body(content: Content) -> some View {
        content
            .background(backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(borderColor, lineWidth: 4)
            )
            .shadow(color: .black.opacity(0.8), radius: 0, x: 0, y: shadowY)
    }
}

extension View {
    func neonCard(bg: Color = Color.black.opacity(0.6), border: Color = .black, shadowY: CGFloat = 6) -> some View {
        modifier(NeonCard(bg: bg, border: border, shadowY: shadowY))
    }
}

// MARK: - Stripe Background
// Uses drawingGroup() to composite stripes into a single Metal-backed layer,
// preventing repeated Canvas cache invalidation (fopen errno=2 warnings).

struct StripedBackground: View {
    var body: some View {
        ZStack {
            NeonTheme.bgGradient
            StripesLayer()
                .drawingGroup()
        }
    }
}

private struct StripesLayer: View {
    var body: some View {
        Canvas { context, size in
            let stripeWidth: CGFloat = 20
            let count = Int(size.width + size.height) / Int(stripeWidth) + 2
            for i in 0..<count {
                let x = CGFloat(i) * stripeWidth - size.height
                var path = Path()
                path.move(to: CGPoint(x: x, y: 0))
                path.addLine(to: CGPoint(x: x + size.height, y: size.height))
                path.addLine(to: CGPoint(x: x + size.height + stripeWidth * 0.5, y: size.height))
                path.addLine(to: CGPoint(x: x + stripeWidth * 0.5, y: 0))
                path.closeSubpath()
                context.fill(path, with: .color(i % 2 == 0
                    ? Color.white.opacity(0.03)
                    : Color.white.opacity(0.015)))
            }
        }
    }
}
