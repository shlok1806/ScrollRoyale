import SwiftUI

// MARK: - Brain Character View

struct BrainCharacterView: View {
    var customization: BrainCustomization = BrainCustomization()
    var rotLevel: Int = 20
    var size: CGFloat = 80
    var showArms: Bool = false
    var animated: Bool = true

    @State private var floatOffset: CGFloat = 0
    @State private var blinkOpacity: Double = 1

    private var skinColor: Color { ScrollClash.skinColor(for: customization.skin) }
    private var expressionData: ExpressionData { expression(for: customization.expression, rotLevel: rotLevel) }

    var body: some View {
        ZStack {
            BrainShape(size: size, skinColor: skinColor)
                .overlay(alignment: .center) {
                    EyesView(
                        size: size,
                        expressionData: expressionData,
                        blinkOpacity: blinkOpacity
                    )
                }

            if showArms {
                ArmsView(size: size, skinColor: skinColor)
            }

            HatOverlayView(hatId: customization.hat, size: size)
                .offset(y: -size * 0.52)

            AccessoryView(accessoryId: customization.accessory, size: size)
                .offset(x: size * 0.45, y: size * 0.1)
        }
        .frame(width: size, height: size * (showArms ? 1.2 : 1))
        .offset(y: animated ? floatOffset : 0)
        .onAppear {
            if animated {
                withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) {
                    floatOffset = -4
                }
                startBlinking()
            }
        }
    }

    private func startBlinking() {
        let blinkDelay = Double.random(in: 2...5)
        DispatchQueue.main.asyncAfter(deadline: .now() + blinkDelay) {
            withAnimation(.easeInOut(duration: 0.08)) { blinkOpacity = 0 }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                withAnimation(.easeInOut(duration: 0.08)) { blinkOpacity = 1 }
                startBlinking()
            }
        }
    }
}

// MARK: - Brain Shape

struct BrainShape: View {
    let size: CGFloat
    let skinColor: Color

    private var darkerColor: Color {
        skinColor.opacity(0.7)
    }

    var body: some View {
        ZStack {
            // Main brain body - large rounded shape
            RoundedRectangle(cornerRadius: size * 0.45)
                .fill(skinColor)
                .frame(width: size * 0.82, height: size * 0.75)
                .overlay(
                    RoundedRectangle(cornerRadius: size * 0.45)
                        .stroke(Color.black, lineWidth: max(2, size * 0.028))
                )

            // Brain lobe bumps
            ForEach(Array(brainBumps(size: size).enumerated()), id: \.offset) { _, bump in
                Circle()
                    .fill(skinColor)
                    .frame(width: bump.diameter, height: bump.diameter)
                    .offset(x: bump.x, y: bump.y)
                    .overlay(
                        Circle().stroke(Color.black, lineWidth: max(1.5, size * 0.022))
                            .offset(x: bump.x, y: bump.y)
                    )
            }
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Brain Bump Data

struct BrainBump {
    let x: CGFloat
    let y: CGFloat
    let diameter: CGFloat
}

func brainBumps(size: CGFloat) -> [BrainBump] {
    let s = size
    return [
        .init(x: -s * 0.25, y: -s * 0.26, diameter: s * 0.38),
        .init(x:  s * 0.25, y: -s * 0.26, diameter: s * 0.38),
        .init(x: -s * 0.36, y: -s * 0.06, diameter: s * 0.28),
        .init(x:  s * 0.36, y: -s * 0.06, diameter: s * 0.28),
        .init(x:  0,        y: -s * 0.32, diameter: s * 0.30),
    ]
}

// MARK: - Expression Data

struct ExpressionData {
    let leftEyeScale: CGFloat
    let rightEyeScale: CGFloat
    let eyeOffsetY: CGFloat
    let mouthCurve: CGFloat // positive = smile, negative = frown, 0 = flat
    let eyeColor: Color
}

func expression(for id: String, rotLevel: Int) -> ExpressionData {
    let isRotted = rotLevel > 70
    switch id {
    case "happy", "confident":
        return .init(leftEyeScale: 1, rightEyeScale: 1, eyeOffsetY: -0.05, mouthCurve: 0.6, eyeColor: .black)
    case "determined", "focused":
        return .init(leftEyeScale: 0.7, rightEyeScale: 0.7, eyeOffsetY: -0.05, mouthCurve: 0.1, eyeColor: .black)
    case "angry":
        return .init(leftEyeScale: 0.6, rightEyeScale: 0.6, eyeOffsetY: -0.04, mouthCurve: -0.5, eyeColor: .black)
    case "sleepy", "hypnotized":
        return .init(leftEyeScale: 0.4, rightEyeScale: 0.4, eyeOffsetY: -0.02, mouthCurve: 0.2, eyeColor: isRotted ? Color(hex: "FF3D81") : .black)
    case "smirk":
        return .init(leftEyeScale: 0.8, rightEyeScale: 1, eyeOffsetY: -0.05, mouthCurve: 0.3, eyeColor: .black)
    default:
        return .init(leftEyeScale: 1, rightEyeScale: 1, eyeOffsetY: -0.05, mouthCurve: 0.5, eyeColor: .black)
    }
}

// MARK: - Eyes View

struct EyesView: View {
    let size: CGFloat
    let expressionData: ExpressionData
    let blinkOpacity: Double

    private var eyeSize: CGFloat { size * 0.15 }
    private var eyeSpacing: CGFloat { size * 0.24 }

    var body: some View {
        ZStack {
            // Left eye
            Ellipse()
                .fill(expressionData.eyeColor)
                .frame(width: eyeSize, height: eyeSize * expressionData.leftEyeScale)
                .opacity(blinkOpacity)
                .offset(x: -eyeSpacing * 0.5, y: size * expressionData.eyeOffsetY)

            // Left eye shine
            Circle()
                .fill(Color.white)
                .frame(width: eyeSize * 0.3, height: eyeSize * 0.3)
                .opacity(blinkOpacity)
                .offset(x: -eyeSpacing * 0.5 + eyeSize * 0.15, y: size * expressionData.eyeOffsetY - eyeSize * 0.15)

            // Right eye
            Ellipse()
                .fill(expressionData.eyeColor)
                .frame(width: eyeSize, height: eyeSize * expressionData.rightEyeScale)
                .opacity(blinkOpacity)
                .offset(x: eyeSpacing * 0.5, y: size * expressionData.eyeOffsetY)

            // Right eye shine
            Circle()
                .fill(Color.white)
                .frame(width: eyeSize * 0.3, height: eyeSize * 0.3)
                .opacity(blinkOpacity)
                .offset(x: eyeSpacing * 0.5 + eyeSize * 0.15, y: size * expressionData.eyeOffsetY - eyeSize * 0.15)

            // Mouth
            MouthShape(curve: expressionData.mouthCurve, size: size)
                .offset(y: size * 0.08)
        }
    }
}

// MARK: - Mouth Shape

struct MouthShape: View {
    let curve: CGFloat
    let size: CGFloat

    var body: some View {
        let w = size * 0.28
        let h = abs(curve) * size * 0.12

        Path { path in
            if curve >= 0 {
                path.move(to: CGPoint(x: -w/2, y: 0))
                path.addQuadCurve(
                    to: CGPoint(x: w/2, y: 0),
                    control: CGPoint(x: 0, y: h)
                )
            } else {
                path.move(to: CGPoint(x: -w/2, y: h))
                path.addQuadCurve(
                    to: CGPoint(x: w/2, y: h),
                    control: CGPoint(x: 0, y: 0)
                )
            }
        }
        .stroke(Color.black, style: StrokeStyle(lineWidth: max(1.5, size * 0.022), lineCap: .round))
        .frame(width: w, height: max(h, 4))
    }
}

// MARK: - Arms View

struct ArmsView: View {
    let size: CGFloat
    let skinColor: Color

    var body: some View {
        ZStack {
            // Left arm
            Capsule()
                .fill(skinColor)
                .overlay(Capsule().stroke(Color.black, lineWidth: max(1.5, size * 0.022)))
                .frame(width: size * 0.15, height: size * 0.4)
                .rotationEffect(.degrees(-30))
                .offset(x: -size * 0.52, y: size * 0.05)

            // Right arm
            Capsule()
                .fill(skinColor)
                .overlay(Capsule().stroke(Color.black, lineWidth: max(1.5, size * 0.022)))
                .frame(width: size * 0.15, height: size * 0.4)
                .rotationEffect(.degrees(30))
                .offset(x: size * 0.52, y: size * 0.05)
        }
    }
}

// MARK: - Hat Overlay

struct HatOverlayView: View {
    let hatId: String
    let size: CGFloat

    var body: some View {
        switch hatId {
        case "crown":
            CrownHat(size: size * 0.55)
        case "beanie":
            BeanieHat(size: size * 0.5)
        case "wizard":
            WizardHat(size: size * 0.55)
        case "tophat":
            TopHat(size: size * 0.5)
        case "headset":
            HeadsetHat(size: size * 0.6)
        case "helmet":
            HelmetHat(size: size * 0.55)
        default:
            EmptyView()
        }
    }
}

struct CrownHat: View {
    let size: CGFloat
    var body: some View {
        ZStack {
            // Crown band
            RoundedRectangle(cornerRadius: 2)
                .fill(Color(hex: "FFD700"))
                .overlay(RoundedRectangle(cornerRadius: 2).stroke(Color.black, lineWidth: 2))
                .frame(width: size, height: size * 0.2)
                .offset(y: size * 0.2)

            // Crown points
            ForEach([-0.38, -0.1, 0.18], id: \.self) { xFrac in
                Triangle()
                    .fill(Color(hex: "FFD700"))
                    .overlay(Triangle().stroke(Color.black, lineWidth: 2))
                    .frame(width: size * 0.22, height: size * 0.28)
                    .offset(x: size * xFrac, y: 0)
            }

            // Jewels
            ForEach([-0.38, 0.18], id: \.self) { xFrac in
                Circle()
                    .fill(Color.red)
                    .overlay(Circle().stroke(Color.black, lineWidth: 1.5))
                    .frame(width: size * 0.12, height: size * 0.12)
                    .offset(x: size * xFrac, y: 0)
            }
        }
        .frame(width: size, height: size * 0.5)
    }
}

struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        Path { p in
            p.move(to: CGPoint(x: rect.midX, y: rect.minY))
            p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
            p.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
            p.closeSubpath()
        }
    }
}

struct BeanieHat: View {
    let size: CGFloat
    var body: some View {
        ZStack {
            Ellipse()
                .fill(Color(hex: "FF6B35"))
                .overlay(Ellipse().stroke(Color.black, lineWidth: 2))
                .frame(width: size, height: size * 0.6)
            Circle()
                .fill(Color(hex: "FF6B35"))
                .overlay(Circle().stroke(Color.black, lineWidth: 2))
                .frame(width: size * 0.25, height: size * 0.25)
                .offset(y: -size * 0.22)
        }
    }
}

struct WizardHat: View {
    let size: CGFloat
    var body: some View {
        ZStack {
            Triangle()
                .fill(NeonTheme.purpleMid)
                .overlay(Triangle().stroke(Color.black, lineWidth: 2))
                .frame(width: size * 0.7, height: size)
            RoundedRectangle(cornerRadius: 2)
                .fill(Color(hex: "FFD60A"))
                .overlay(RoundedRectangle(cornerRadius: 2).stroke(Color.black, lineWidth: 1.5))
                .frame(width: size * 0.6, height: size * 0.15)
                .offset(y: size * 0.4)
        }
    }
}

struct TopHat: View {
    let size: CGFloat
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 3)
                .fill(Color.black)
                .overlay(RoundedRectangle(cornerRadius: 3).stroke(Color.black, lineWidth: 2))
                .frame(width: size * 0.55, height: size * 0.7)
                .offset(y: -size * 0.1)
            Ellipse()
                .fill(Color.black)
                .overlay(Ellipse().stroke(Color.black, lineWidth: 2))
                .frame(width: size, height: size * 0.25)
                .offset(y: size * 0.25)
            Rectangle()
                .fill(NeonTheme.pink)
                .frame(width: size * 0.55, height: size * 0.1)
                .offset(y: 0)
        }
    }
}

struct HeadsetHat: View {
    let size: CGFloat
    var body: some View {
        ZStack {
            Arc(startAngle: .degrees(190), endAngle: .degrees(350))
                .stroke(NeonTheme.cyan, style: StrokeStyle(lineWidth: size * 0.1, lineCap: .round))
                .frame(width: size * 0.8, height: size * 0.5)
                .offset(y: size * 0.05)
            // Ear cups
            ForEach([-0.4, 0.4], id: \.self) { xFrac in
                RoundedRectangle(cornerRadius: 4)
                    .fill(NeonTheme.cyan)
                    .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color.black, lineWidth: 1.5))
                    .frame(width: size * 0.22, height: size * 0.3)
                    .offset(x: size * xFrac, y: size * 0.15)
            }
        }
    }
}

struct Arc: Shape {
    var startAngle: Angle
    var endAngle: Angle
    func path(in rect: CGRect) -> Path {
        Path { p in
            p.addArc(center: CGPoint(x: rect.midX, y: rect.midY),
                     radius: rect.width / 2,
                     startAngle: startAngle, endAngle: endAngle,
                     clockwise: false)
        }
    }
}

struct HelmetHat: View {
    let size: CGFloat
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.3)
                .fill(Color(hex: "C0C0C0"))
                .overlay(RoundedRectangle(cornerRadius: size * 0.3).stroke(Color.black, lineWidth: 2))
                .frame(width: size * 0.9, height: size * 0.6)
            RoundedRectangle(cornerRadius: 3)
                .fill(Color(hex: "4A1A2C"))
                .frame(width: size * 0.3, height: size * 0.22)
                .offset(y: size * 0.05)
        }
    }
}

// MARK: - Accessory View

struct AccessoryView: View {
    let accessoryId: String
    let size: CGFloat

    var body: some View {
        switch accessoryId {
        case "spoon":
            SpoonAccessory(size: size * 0.35)
        case "sword":
            SwordAccessory(size: size * 0.45)
        case "shield":
            ShieldAccessory(size: size * 0.3)
        case "lighter":
            LighterAccessory(size: size * 0.25)
        default:
            EmptyView()
        }
    }
}

struct SpoonAccessory: View {
    let size: CGFloat
    var body: some View {
        ZStack {
            Capsule()
                .fill(Color.gray)
                .overlay(Capsule().stroke(Color.black, lineWidth: 1.5))
                .frame(width: size * 0.2, height: size * 0.8)
            Circle()
                .fill(Color.gray)
                .overlay(Circle().stroke(Color.black, lineWidth: 1.5))
                .frame(width: size * 0.35, height: size * 0.35)
                .offset(y: -size * 0.3)
        }
        .frame(width: size, height: size)
    }
}

struct SwordAccessory: View {
    let size: CGFloat
    var body: some View {
        ZStack {
            Capsule()
                .fill(Color(hex: "C0C0C0"))
                .overlay(Capsule().stroke(Color.black, lineWidth: 1.5))
                .frame(width: size * 0.12, height: size * 0.85)
            Rectangle()
                .fill(Color(hex: "8B5A00"))
                .overlay(Rectangle().stroke(Color.black, lineWidth: 1))
                .frame(width: size * 0.45, height: size * 0.1)
                .offset(y: size * 0.2)
        }
        .frame(width: size, height: size)
        .rotationEffect(.degrees(30))
    }
}

struct ShieldAccessory: View {
    let size: CGFloat
    var body: some View {
        Image(systemName: "shield.fill")
            .font(.system(size: size))
            .foregroundColor(NeonTheme.cyan)
            .overlay(
                Image(systemName: "shield")
                    .font(.system(size: size))
                    .foregroundColor(.black)
            )
    }
}

struct LighterAccessory: View {
    let size: CGFloat
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 3)
                .fill(Color(hex: "FFD60A"))
                .overlay(RoundedRectangle(cornerRadius: 3).stroke(Color.black, lineWidth: 1.5))
                .frame(width: size * 0.5, height: size * 0.8)
            // Flame
            Ellipse()
                .fill(NeonTheme.orange)
                .frame(width: size * 0.3, height: size * 0.35)
                .offset(y: -size * 0.5)
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Skin Color Helper

func skinColor(for skin: String) -> Color {
    switch skin {
    case "default", "classic": return Color(hex: "FFB3D1")
    case "toxic":              return Color(hex: "39FF14")
    case "purple", "royal":    return Color(hex: "9D4EDD")
    case "cyber":              return Color(hex: "4CC9F0")
    case "lava", "retro":      return Color(hex: "FF6B35")
    case "frozen":             return Color(hex: "B8E0F6")
    case "chrome":             return Color(hex: "C0C0C0")
    case "shadow", "galaxy":   return Color(hex: "2D1B69")
    default:                   return Color(hex: "FFB3D1")
    }
}
