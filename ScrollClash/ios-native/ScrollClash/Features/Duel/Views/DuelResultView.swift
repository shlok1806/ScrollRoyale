import SwiftUI

struct DuelResultView: View {
    @EnvironmentObject private var appState: AppState
    let opponent: DuelOpponent
    let onDismiss: () -> Void

    private let isVictory: Bool = Bool.random()

    @State private var showConfetti = false
    @State private var animateNumbers = false
    @State private var xpProgress: Double = 0.52

    private var yourHP: Int  { isVictory ? 742 : 0 }
    private var oppHP: Int   { isVictory ? 0 : 823 }
    private var trophyChange: Int { isVictory ? 30 : -18 }
    private var xpGained: Int    { isVictory ? 185 : 95 }

    private let stats: [(label: String, value: Int, icon: String)] = [
        ("Damage Dealt", 258, "bolt.fill"),
        ("Quizzes",       4,  "questionmark.circle.fill"),
        ("Damage Taken",  258, "shield.fill"),
        ("Focus Gained",  28,  "eye.fill"),
        ("Highest Combo", 5,   "star.fill"),
        ("Focus Spent",   24,  "eye.slash.fill"),
        ("Videos Done",   7,   "play.rectangle.fill"),
        ("Boosts Used",   6,   "rectangle.stack.fill"),
        ("Discovery",     3,   "diamond.fill"),
        ("Best Streak",   4,   "flame.fill"),
    ]

    private let timelineEvents: [(type: String, time: String)] = [
        ("damage",       "0:08"),
        ("quiz-correct", "0:22"),
        ("combo",        "0:35"),
        ("boost",        "0:47"),
        ("discovery",    "1:05"),
        ("damage",       "1:18"),
        ("quiz-wrong",   "1:31"),
        ("boost",        "1:44"),
    ]

    var body: some View {
        ZStack {
            StripedBackground().ignoresSafeArea()
                .overlay(
                    LinearGradient(
                        colors: [Color.black.opacity(0.6), Color.black.opacity(0.4), Color.black.opacity(0.6)],
                        startPoint: .top, endPoint: .bottom
                    )
                    .ignoresSafeArea()
                )

            if showConfetti {
                ConfettiView()
            }

            // Defeat cracks
            if !isVictory {
                Canvas { context, size in
                    let lines = [
                        (CGPoint(x: 0, y: 0), CGPoint(x: size.width, y: size.height)),
                        (CGPoint(x: size.width, y: 0), CGPoint(x: 0, y: size.height)),
                        (CGPoint(x: size.width * 0.5, y: 0), CGPoint(x: size.width * 0.2, y: size.height)),
                    ]
                    for (from, to) in lines {
                        var p = Path()
                        p.move(to: from)
                        p.addLine(to: to)
                        context.stroke(p, with: .color(NeonTheme.pink.opacity(0.3)), lineWidth: 2)
                    }
                }
                .ignoresSafeArea()
            }

            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    Color.clear.frame(height: 48)

                    // VICTORY / DEFEAT header
                    resultHeader

                    // VS section
                    vsSection
                        .padding(.horizontal, 20)

                    // HP towers
                    hpTowers
                        .padding(.horizontal, 20)

                    // Match stats
                    matchStats
                        .padding(.horizontal, 20)

                    // Timeline
                    battleTimeline
                        .padding(.horizontal, 20)

                    // Rewards
                    rewardsSection
                        .padding(.horizontal, 20)

                    // MVP boost
                    mvpBoostCard
                        .padding(.horizontal, 20)

                    // Action buttons
                    actionButtons
                        .padding(.horizontal, 20)
                        .padding(.bottom, 40)
                }
            }
        }
        .onAppear {
            if isVictory {
                showConfetti = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) { showConfetti = false }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation(.easeOut(duration: 1.2)) {
                    animateNumbers = true
                    xpProgress = 0.78
                }
            }
        }
    }

    // MARK: Result Header

    private var resultHeader: some View {
        ZStack {
            // Glow
            Circle()
                .fill(isVictory ? NeonTheme.green.opacity(0.3) : NeonTheme.pink.opacity(0.3))
                .frame(width: 200, height: 200)
                .blur(radius: 40)

            Text(isVictory ? "VICTORY" : "DEFEAT")
                .font(.system(size: 64, weight: .black))
                .foregroundColor(isVictory ? NeonTheme.green : NeonTheme.pink)
                .shadow(color: (isVictory ? NeonTheme.green : NeonTheme.pink).opacity(0.9), radius: 20)
                .shadow(color: .black.opacity(0.5), radius: 0, x: 3, y: 3)
        }
    }

    // MARK: VS Section

    private var vsSection: some View {
        HStack(spacing: 16) {
            playerColumn(brain: appState.customization, label: "YOU", bg: NeonTheme.purpleDark)

            ZStack {
                Circle()
                    .fill(Color.white)
                    .frame(width: 48, height: 48)
                    .overlay(Circle().stroke(Color.black, lineWidth: 4))
                    .shadow(color: .black.opacity(0.8), radius: 0, x: 0, y: 4)
                Text("VS")
                    .font(.system(size: 18, weight: .black))
                    .foregroundColor(.black)
            }

            playerColumn(
                brain: { var c = BrainCustomization(); c.skin = "toxic"; c.expression = "focused"; return c }(),
                label: opponent.name.uppercased(),
                bg: NeonTheme.pink
            )
        }
    }

    private func playerColumn(brain: BrainCustomization, label: String, bg: Color) -> some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(bg)
                    .frame(width: 72, height: 72)
                    .overlay(Circle().stroke(Color.black, lineWidth: 4))
                    .shadow(color: .black.opacity(0.8), radius: 0, x: 0, y: 6)
                BrainCharacterView(customization: brain, rotLevel: 25, size: 56, showArms: false, animated: false)
            }
            Text(label)
                .font(.system(size: 12, weight: .black))
                .foregroundColor(.white)
                .shadow(color: .black.opacity(0.5), radius: 0, x: 2, y: 2)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: HP Towers

    private var hpTowers: some View {
        VStack(spacing: 8) {
            Text("TOWER HP")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.white.opacity(0.7))

            HStack(spacing: 16) {
                VStack(spacing: 4) {
                    Text("YOUR TOWER")
                        .font(.system(size: 11, weight: .black))
                        .foregroundColor(NeonTheme.purpleLight)
                    if animateNumbers {
                        AnimatedNumberView(targetValue: yourHP, duration: 1.0,
                                           font: .system(size: 24, weight: .black))
                    } else {
                        Text("0").font(.system(size: 24, weight: .black)).foregroundColor(.white)
                    }
                    Text("/ 1000").font(.system(size: 12)).foregroundColor(.white.opacity(0.5))
                }
                .frame(maxWidth: .infinity)

                VStack(spacing: 4) {
                    Text("OPP TOWER")
                        .font(.system(size: 11, weight: .black))
                        .foregroundColor(NeonTheme.green)
                    if animateNumbers {
                        AnimatedNumberView(targetValue: oppHP, duration: 1.0,
                                           font: .system(size: 24, weight: .black))
                    } else {
                        Text("0").font(.system(size: 24, weight: .black)).foregroundColor(.white)
                    }
                    Text("/ 1000").font(.system(size: 12)).foregroundColor(.white.opacity(0.5))
                }
                .frame(maxWidth: .infinity)
            }

            HStack(spacing: 8) {
                GeometryReader { geo in
                    RoundedRectangle(cornerRadius: 4)
                        .fill(NeonTheme.purpleDark)
                        .frame(width: geo.size.width * CGFloat(yourHP) / 1000)
                        .animation(.easeOut(duration: 1).delay(0.5), value: animateNumbers)
                }
                .frame(height: 12)
                .background(Color.black.opacity(0.6))
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.black, lineWidth: 2))

                GeometryReader { geo in
                    RoundedRectangle(cornerRadius: 4)
                        .fill(NeonTheme.green)
                        .frame(width: geo.size.width * CGFloat(oppHP) / 1000)
                        .animation(.easeOut(duration: 1).delay(0.5), value: animateNumbers)
                }
                .frame(height: 12)
                .background(Color.black.opacity(0.6))
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.black, lineWidth: 2))
            }
        }
        .padding(16)
        .background(Color.black.opacity(0.6))
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.black, lineWidth: 4))
        .shadow(color: .black.opacity(0.8), radius: 0, x: 0, y: 6)
    }

    // MARK: Match Stats

    private var matchStats: some View {
        VStack(spacing: 12) {
            Text("MATCH STATS")
                .font(.system(size: 13, weight: .black))
                .foregroundColor(.white)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                ForEach(stats, id: \.label) { stat in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 6) {
                            Image(systemName: stat.icon)
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white)
                            Text(stat.label)
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(.white.opacity(0.7))
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)
                        }
                        if animateNumbers {
                            AnimatedNumberView(targetValue: stat.value, duration: 1.5,
                                               font: .system(size: 20, weight: .black))
                        } else {
                            Text("0").font(.system(size: 20, weight: .black)).foregroundColor(.white)
                        }
                    }
                    .padding(8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.black.opacity(0.4))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.black, lineWidth: 2))
                }
            }
        }
        .padding(16)
        .background(NeonTheme.purpleDark)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.black, lineWidth: 4))
        .shadow(color: .black.opacity(0.8), radius: 0, x: 0, y: 6)
    }

    // MARK: Timeline

    private var battleTimeline: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("BATTLE TIMELINE")
                .font(.system(size: 13, weight: .black))
                .foregroundColor(.white)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(timelineEvents.indices, id: \.self) { i in
                        let event = timelineEvents[i]
                        VStack(spacing: 4) {
                            ZStack {
                                Circle()
                                    .fill(eventColor(event.type))
                                    .frame(width: 40, height: 40)
                                    .overlay(Circle().stroke(Color.black, lineWidth: 3))
                                    .shadow(color: .black.opacity(0.8), radius: 0, x: 0, y: 3)
                                Image(systemName: eventIcon(event.type))
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(eventIconColor(event.type))
                            }
                            Text(event.time)
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(.white.opacity(0.7))
                        }
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .padding(16)
        .background(Color.black.opacity(0.6))
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.black, lineWidth: 4))
        .shadow(color: .black.opacity(0.8), radius: 0, x: 0, y: 6)
    }

    private func eventColor(_ type: String) -> Color {
        switch type {
        case "damage":       return NeonTheme.pink
        case "quiz-correct": return NeonTheme.green
        case "quiz-wrong":   return NeonTheme.pink
        case "combo":        return NeonTheme.yellow
        case "discovery":    return NeonTheme.purpleDark
        case "boost":        return NeonTheme.cyan
        default:             return .white
        }
    }

    private func eventIcon(_ type: String) -> String {
        switch type {
        case "damage":       return "bolt.fill"
        case "quiz-correct": return "checkmark.circle.fill"
        case "quiz-wrong":   return "xmark.circle.fill"
        case "combo":        return "star.fill"
        case "discovery":    return "diamond.fill"
        case "boost":        return "rectangle.stack.fill"
        default:             return "circle.fill"
        }
    }

    private func eventIconColor(_ type: String) -> Color {
        switch type {
        case "quiz-correct", "combo", "discovery": return .black
        default: return .white
        }
    }

    // MARK: Rewards

    private var rewardsSection: some View {
        VStack(spacing: 12) {
            Text("REWARDS")
                .font(.system(size: 13, weight: .black))
                .foregroundColor(.white)

            // Trophies
            HStack {
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 48, height: 48)
                            .overlay(Circle().stroke(Color.black, lineWidth: 3))
                        TrophyIcon(size: 26, color: NeonTheme.yellow)
                    }
                    Text("TROPHIES")
                        .font(.system(size: 15, weight: .black))
                        .foregroundColor(.black)
                }
                Spacer()
                Text("\(trophyChange > 0 ? "+" : "")\(trophyChange)")
                    .font(.system(size: 36, weight: .black))
                    .foregroundColor(isVictory ? NeonTheme.green : NeonTheme.pink)
                    .shadow(color: .black.opacity(0.3), radius: 0, x: 2, y: 2)
            }
            .padding(16)
            .background(NeonTheme.yellow)
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.black, lineWidth: 4))
            .shadow(color: .black.opacity(0.8), radius: 0, x: 0, y: 6)

            // XP
            VStack(spacing: 8) {
                HStack {
                    Text("XP GAINED")
                        .font(.system(size: 15, weight: .black))
                        .foregroundColor(.black)
                    Spacer()
                    Text("+\(xpGained)")
                        .font(.system(size: 22, weight: .black))
                        .foregroundColor(.white)
                }
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.black.opacity(0.4))
                        LinearGradient(colors: [NeonTheme.green, NeonTheme.yellow], startPoint: .leading, endPoint: .trailing)
                            .frame(width: geo.size.width * xpProgress)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                            .animation(.easeOut(duration: 1.2).delay(0.9), value: xpProgress)
                        Text("LEVEL 12")
                            .font(.system(size: 11, weight: .black))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                    }
                }
                .frame(height: 20)
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.black, lineWidth: 2))
            }
            .padding(16)
            .background(NeonTheme.cyan)
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.black, lineWidth: 4))
            .shadow(color: .black.opacity(0.8), radius: 0, x: 0, y: 6)
        }
    }

    // MARK: MVP Boost

    private var mvpBoostCard: some View {
        HStack(spacing: 12) {
            // Mini card
            VStack(spacing: 0) {
                ZStack {
                    Color.white.frame(height: 44)
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(NeonTheme.pink)
                }
                Text("RAGE").font(.system(size: 8, weight: .black)).foregroundColor(.black)
                    .padding(.vertical, 4).frame(maxWidth: .infinity).background(Color.white)
            }
            .frame(width: 60, height: 62)
            .background(Color(hex: "F5F5DC"))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.black, lineWidth: 3))
            .shadow(color: .black.opacity(0.6), radius: 0, x: 0, y: 3)

            VStack(alignment: .leading, spacing: 4) {
                Text("Rage")
                    .font(.system(size: 13, weight: .black))
                    .foregroundColor(.white)
                HStack(spacing: 16) {
                    HStack(spacing: 4) {
                        Text("Used:")
                            .font(.system(size: 11)).foregroundColor(.white.opacity(0.7))
                        Text("3x")
                            .font(.system(size: 12, weight: .black)).foregroundColor(NeonTheme.yellow)
                    }
                    HStack(spacing: 4) {
                        Text("Damage:")
                            .font(.system(size: 11)).foregroundColor(.white.opacity(0.7))
                        Text("+84")
                            .font(.system(size: 12, weight: .black)).foregroundColor(NeonTheme.pink)
                    }
                }
            }
        }
        .padding(16)
        .background(Color.black.opacity(0.6))
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.black, lineWidth: 4))
        .shadow(color: .black.opacity(0.8), radius: 0, x: 0, y: 6)
    }

    // MARK: Action Buttons

    private var actionButtons: some View {
        VStack(spacing: 12) {
            // Rematch
            Button(action: onDismiss) {
                Text("REMATCH")
                    .font(.system(size: 22, weight: .black))
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .frame(height: 64)
                    .background(NeonTheme.green)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.black, lineWidth: 4))
                    .shadow(color: .black.opacity(0.8), radius: 0, x: 0, y: 6)
                    .shadow(color: NeonTheme.green.opacity(0.6), radius: 12)
            }
            .buttonStyle(.plain)

            HStack(spacing: 12) {
                Button {} label: {
                    Text("VIEW REPLAY")
                        .font(.system(size: 13, weight: .black))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(NeonTheme.cyan)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.black, lineWidth: 4))
                        .shadow(color: .black.opacity(0.8), radius: 0, x: 0, y: 4)
                }
                .buttonStyle(.plain)

                Button(action: onDismiss) {
                    Text("HOME")
                        .font(.system(size: 13, weight: .black))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(Color.white.opacity(0.2))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.black, lineWidth: 4))
                        .shadow(color: .black.opacity(0.8), radius: 0, x: 0, y: 4)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

// MARK: - Confetti

struct ConfettiView: View {
    private let colors: [Color] = [NeonTheme.green, NeonTheme.yellow, NeonTheme.cyan, NeonTheme.pink, NeonTheme.purpleDark]
    @State private var particles: [(id: UUID, x: CGFloat, rotation: Double, color: Color, speed: Double, delay: Double, isCircle: Bool)] = []

    var body: some View {
        GeometryReader { geo in
            ForEach(particles, id: \.id) { p in
                ConfettiParticle(
                    startX: p.x * geo.size.width,
                    color: p.color,
                    endY: geo.size.height + 20,
                    duration: p.speed,
                    delay: p.delay,
                    rotationAmount: p.rotation,
                    isCircle: p.isCircle
                )
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .onAppear {
            particles = (0..<80).map { _ in
                (
                    id: UUID(),
                    x: CGFloat.random(in: 0...1),
                    rotation: Double.random(in: 0...720),
                    color: colors.randomElement()!,
                    speed: Double.random(in: 2...4),
                    delay: Double.random(in: 0...0.5),
                    isCircle: Bool.random()
                )
            }
        }
    }
}

struct ConfettiParticle: View {
    let startX: CGFloat
    let color: Color
    let endY: CGFloat
    let duration: Double
    let delay: Double
    let rotationAmount: Double
    let isCircle: Bool

    @State private var y: CGFloat = -20
    @State private var opacity: Double = 1
    @State private var rotation: Double = 0

    var body: some View {
        Group {
            if isCircle {
                Circle().fill(color).frame(width: 10, height: 10)
            } else {
                Rectangle().fill(color).frame(width: 10, height: 10)
            }
        }
        .opacity(opacity)
        .rotationEffect(.degrees(rotation))
        .position(x: startX, y: y)
        .onAppear {
            withAnimation(.linear(duration: duration).delay(delay)) {
                y = endY
                rotation = rotationAmount
                opacity = 0
            }
        }
    }
}
