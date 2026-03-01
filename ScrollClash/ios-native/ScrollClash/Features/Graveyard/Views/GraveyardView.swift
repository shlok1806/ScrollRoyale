import SwiftUI

struct GraveyardView: View {
    @State private var activeScene: GraveyardScene = .healthy
    @State private var selectedDay: GraveyardDay? = nil

    enum GraveyardScene { case healthy, graveyard }

    private let data = MockData.graveyardData
    private var healthyDays: [GraveyardDay] { data.filter { $0.rot < 50 } }
    private var graveyardDays: [GraveyardDay] { data.filter { $0.rot >= 50 } }

    var body: some View {
        ZStack {
            StripedBackground().ignoresSafeArea()
                .overlay(Color.black.opacity(0.4).ignoresSafeArea())

            VStack(spacing: 0) {
                Color.clear.frame(height: 12)

                // Title
                Text("BRAIN HISTORY")
                    .font(.system(size: 28, weight: .black))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.5), radius: 0, x: 4, y: 4)
                    .padding(.bottom, 12)

                // Scene toggle
                sceneToggle
                    .padding(.horizontal, 20)
                    .padding(.bottom, 12)

                // Stats banner
                statsBanner
                    .padding(.horizontal, 20)
                    .padding(.bottom, 0)

                // Scene
                ZStack {
                    if activeScene == .healthy {
                        HealthyForestSceneView(days: healthyDays, onSelectDay: { selectedDay = $0 })
                            .transition(.opacity)
                    } else {
                        GraveyardSceneView(days: graveyardDays, onSelectDay: { selectedDay = $0 })
                            .transition(.opacity)
                    }
                }
                .animation(.easeInOut(duration: 0.3), value: activeScene)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .sheet(item: $selectedDay) { day in
            DailyReportModal(day: day, onClose: { selectedDay = nil })
                .presentationDetents([.medium])
        }
    }

    // MARK: Scene Toggle

    private var sceneToggle: some View {
        HStack(spacing: 8) {
            toggleBtn(.healthy,    icon: "tree.fill",  label: "HEALTHY",    active: NeonTheme.green, activeText: .black)
            toggleBtn(.graveyard,  icon: "moon.fill",   label: "GRAVEYARD",  active: NeonTheme.pink,  activeText: .white)
        }
        .padding(4)
        .background(Color.black.opacity(0.4))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.black, lineWidth: 3))
    }

    @ViewBuilder
    private func toggleBtn(_ scene: GraveyardScene, icon: String, label: String, active: Color, activeText: Color) -> some View {
        let selected = activeScene == scene
        Button { withAnimation { activeScene = scene } } label: {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .bold))
                Text(label)
                    .font(.system(size: 13, weight: .black))
            }
            .foregroundColor(selected ? activeText : .white)
            .frame(maxWidth: .infinity)
            .frame(height: 40)
            .background(selected ? active : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.black, lineWidth: selected ? 2 : 0))
            .shadow(color: selected ? .black.opacity(0.6) : .clear, radius: 0, x: 0, y: 3)
        }
        .buttonStyle(.plain)
    }

    // MARK: Stats Banner

    private var statsBanner: some View {
        HStack {
            Spacer()
            VStack(spacing: 4) {
                FlameIcon(size: 18, color: NeonTheme.green)
                Text("4")
                    .font(.system(size: 28, weight: .black))
                    .foregroundColor(NeonTheme.green)
                    .shadow(color: .black.opacity(0.5), radius: 0, x: 2, y: 2)
                Text("STREAK")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.white)
            }
            Spacer()
            Rectangle()
                .fill(Color.white.opacity(0.2))
                .frame(width: 1, height: 50)
            Spacer()
            VStack(spacing: 4) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(NeonTheme.pink)
                Text("75%")
                    .font(.system(size: 28, weight: .black))
                    .foregroundColor(NeonTheme.pink)
                    .shadow(color: .black.opacity(0.5), radius: 0, x: 2, y: 2)
                Text("WORST")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.white)
            }
            Spacer()
        }
        .padding(12)
        .background(NeonTheme.purpleDark)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.black, lineWidth: 4))
        .shadow(color: .black.opacity(0.8), radius: 0, x: 0, y: 6)
    }
}

// MARK: - Healthy Forest Scene

struct HealthyForestSceneView: View {
    let days: [GraveyardDay]
    let onSelectDay: (GraveyardDay) -> Void

    var body: some View {
        ZStack {
            // Sky
            LinearGradient(
                colors: [Color(hex: "4CC9F0").opacity(0.3), Color(hex: "2A6B7F").opacity(0.5)],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()

            // Tree silhouettes
            Canvas { context, size in
                // Back trees (dark)
                let backPath = createTreeSilhouette(width: size.width, height: size.height * 0.7, offset: size.height * 0.3)
                context.fill(backPath, with: .color(Color(hex: "2A1A4A").opacity(0.6)))

                // Front trees (green)
                let frontPath = createTreeSilhouette(width: size.width, height: size.height * 0.55, offset: size.height * 0.45, phase: .pi / 8)
                context.fill(frontPath, with: .color(NeonTheme.green.opacity(0.8)))

                // Ground
                var ground = Path()
                ground.addRect(CGRect(x: 0, y: size.height * 0.82, width: size.width, height: size.height * 0.18))
                context.fill(ground, with: .color(Color(hex: "1A6B3A")))
            }
            .ignoresSafeArea()

            // Brain cards on stumps
            VStack {
                Spacer()
                HStack(spacing: 0) {
                    ForEach(days) { day in
                        HealthyBrainCardView(day: day, onTap: { onSelectDay(day) })
                            .frame(maxWidth: .infinity)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 100)
            }
        }
    }
}

private func createTreeSilhouette(width: CGFloat, height: CGFloat, offset: CGFloat, phase: CGFloat = 0) -> Path {
    var path = Path()
    let peaks = 8
    path.move(to: CGPoint(x: 0, y: offset))
    for i in 0...peaks {
        let x = width * CGFloat(i) / CGFloat(peaks)
        let y = offset - (sin(CGFloat(i) * .pi / 2 + phase) * 0.5 + 0.5) * (height - offset) * 0.6 - (height - offset) * 0.2
        path.addLine(to: CGPoint(x: x, y: y))
    }
    path.addLine(to: CGPoint(x: width, y: height))
    path.addLine(to: CGPoint(x: 0, y: height))
    path.closeSubpath()
    return path
}

struct HealthyBrainCardView: View {
    let day: GraveyardDay
    let onTap: () -> Void

    @State private var floatOffset: CGFloat = 0

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 2) {
                // Brain on stump
                ZStack(alignment: .bottom) {
                    // Stump
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color(hex: "8B5A3C"))
                        .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.black, lineWidth: 2))
                        .frame(width: 44, height: 28)

                    // Brain
                    BrainCharacterView(rotLevel: day.rot, size: 44, showArms: false, animated: false)
                        .offset(y: floatOffset - 26)
                }
                .frame(height: 70)

                // Date label
                Text(day.date)
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(.white.opacity(0.9))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(Color.black.opacity(0.4))
                    .clipShape(Capsule())
                    .overlay(Capsule().stroke(NeonTheme.green, lineWidth: 1))

                // Rot badge
                Text("\(day.rot)%")
                    .font(.system(size: 9, weight: .black))
                    .foregroundColor(.black)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 2)
                    .background(NeonTheme.green)
                    .clipShape(Capsule())
                    .overlay(Capsule().stroke(Color.black, lineWidth: 1.5))
            }
        }
        .buttonStyle(.plain)
        .onAppear {
            withAnimation(.easeInOut(duration: 2.5 + Double.random(in: 0...1)).repeatForever(autoreverses: true)) {
                floatOffset = -4
            }
        }
    }
}

// MARK: - Graveyard Scene

struct GraveyardSceneView: View {
    let days: [GraveyardDay]
    let onSelectDay: (GraveyardDay) -> Void

    @State private var starOpacity: [Double] = Array(repeating: 0.3, count: 12)
    @State private var moonOffset: CGFloat = 0
    @State private var fogOffset: CGFloat = 0

    var body: some View {
        ZStack {
            // Night sky
            LinearGradient(
                colors: [Color(hex: "1a0040").opacity(0.9), Color(hex: "0a0015").opacity(0.95)],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()

            // Stars
            ForEach(0..<12, id: \.self) { i in
                Circle()
                    .fill(Color.white)
                    .frame(width: 3, height: 3)
                    .opacity(starOpacity[i])
                    .position(x: CGFloat.random(in: 20...340), y: CGFloat.random(in: 40...200))
                    .onAppear {
                        withAnimation(
                            .easeInOut(duration: Double.random(in: 2...4))
                            .repeatForever(autoreverses: true)
                            .delay(Double.random(in: 0...2))
                        ) {
                            starOpacity[i] = 1
                        }
                    }
            }

            // Moon
            Circle()
                .fill(Color(hex: "FFE8B6"))
                .overlay(Circle().stroke(Color(hex: "FFD98C"), lineWidth: 4))
                .frame(width: 72, height: 72)
                .shadow(color: Color(hex: "FFE8B6").opacity(0.5), radius: 20)
                .offset(x: 120, y: -100 + moonOffset)
                .onAppear {
                    withAnimation(.easeInOut(duration: 10).repeatForever(autoreverses: true)) {
                        moonOffset = -10
                    }
                }

            // Rocky cliffs canvas
            Canvas { context, size in
                var back = Path()
                back.move(to: CGPoint(x: 0, y: size.height * 0.5))
                back.addLine(to: CGPoint(x: size.width * 0.2, y: size.height * 0.2))
                back.addLine(to: CGPoint(x: size.width * 0.4, y: size.height * 0.45))
                back.addLine(to: CGPoint(x: size.width * 0.6, y: size.height * 0.15))
                back.addLine(to: CGPoint(x: size.width * 0.8, y: size.height * 0.4))
                back.addLine(to: CGPoint(x: size.width, y: size.height * 0.25))
                back.addLine(to: CGPoint(x: size.width, y: size.height))
                back.addLine(to: CGPoint(x: 0, y: size.height))
                back.closeSubpath()
                context.fill(back, with: .color(Color(hex: "3A2A5A").opacity(0.8)))
            }
            .ignoresSafeArea()

            // Fog
            LinearGradient(
                colors: [Color(hex: "9D4EDD").opacity(0.2), Color.clear],
                startPoint: .bottom, endPoint: .top
            )
            .frame(height: 100)
            .offset(x: fogOffset)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
            .ignoresSafeArea()
            .onAppear {
                withAnimation(.linear(duration: 20).repeatForever(autoreverses: true)) {
                    fogOffset = 30
                }
            }

            // Gravestones
            VStack {
                Spacer()
                HStack(spacing: 0) {
                    ForEach(days) { day in
                        GravestoneCardView(day: day, onTap: { onSelectDay(day) })
                            .frame(maxWidth: .infinity)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 100)
            }
        }
    }
}

struct GravestoneCardView: View {
    let day: GraveyardDay
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 2) {
                // Gravestone shape
                ZStack {
                    VStack(spacing: 0) {
                        // Rounded top stone
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(hex: "8B7A9A"))
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.black, lineWidth: 2.5))
                            .frame(width: 52, height: 60)

                        // Base slab
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color(hex: "6A5A7A"))
                            .overlay(RoundedRectangle(cornerRadius: 2).stroke(Color.black, lineWidth: 2))
                            .frame(width: 56, height: 8)
                    }

                    // Brain on stone
                    BrainCharacterView(rotLevel: day.rot, size: 38, showArms: false, animated: false)
                        .offset(y: -18)

                    // R.I.P.
                    Text("R.I.P.")
                        .font(.system(size: 9, weight: .black))
                        .foregroundColor(.black)
                        .offset(y: 12)

                    // Rot %
                    Text("\(day.rot)%")
                        .font(.system(size: 12, weight: .black))
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.8), radius: 1)
                        .offset(y: 24)
                }
                .frame(height: 75)

                // Date
                Text(day.date)
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(.white.opacity(0.9))
                    .padding(.horizontal, 5)
                    .padding(.vertical, 2)
                    .background(Color.black.opacity(0.4))
                    .clipShape(Capsule())
                    .overlay(Capsule().stroke(NeonTheme.pink, lineWidth: 1))
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Daily Report Modal

struct DailyReportModal: View {
    let day: GraveyardDay
    let onClose: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.5).ignoresSafeArea()

            VStack(spacing: 0) {
                // Handle
                Capsule()
                    .fill(Color.white.opacity(0.3))
                    .frame(width: 36, height: 4)
                    .padding(.top, 8)
                    .padding(.bottom, 16)

                VStack(spacing: 16) {
                    // Header
                    VStack(spacing: 8) {
                        Image(systemName: "chart.bar.fill")
                            .font(.system(size: 36))
                            .foregroundColor(NeonTheme.cyan)

                        Text("DAILY REPORT")
                            .font(.system(size: 20, weight: .black))
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.5), radius: 0, x: 2, y: 2)

                        Text(day.date)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white.opacity(0.8))
                    }

                    // Rot display
                    VStack(spacing: 4) {
                        Text("ROT LEVEL")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.white)
                        Text("\(day.rot)%")
                            .font(.system(size: 36, weight: .black))
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.5), radius: 0, x: 2, y: 2)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(NeonTheme.pink)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.black, lineWidth: 3))
                    .shadow(color: .black.opacity(0.6), radius: 0, x: 0, y: 4)

                    // Stats
                    VStack(spacing: 8) {
                        statRow(icon: "waveform.path.ecg", iconColor: NeonTheme.cyan,
                                label: "Stability", value: "\(day.stability)%")
                        statRow(icon: "burst.fill", iconColor: NeonTheme.pink,
                                label: "Rage Flicks", value: "\(day.flicks)")
                        statRow(icon: "flame.fill", iconColor: NeonTheme.yellow,
                                label: "Streak", value: "\(day.streak) days")
                        statRow(icon: "clock.fill", iconColor: NeonTheme.purpleMid,
                                label: "Time", value: "2h 34m")
                    }

                    // Badge (if healthy)
                    if day.rot < 50 {
                        HStack(spacing: 12) {
                            TrophyIcon(size: 28, color: .black)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("BADGE EARNED")
                                    .font(.system(size: 10, weight: .black))
                                    .foregroundColor(.black)
                                Text("Stability Master")
                                    .font(.system(size: 13, weight: .black))
                                    .foregroundColor(.black)
                            }
                        }
                        .padding(12)
                        .frame(maxWidth: .infinity)
                        .background(NeonTheme.yellow)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.black, lineWidth: 3))
                        .shadow(color: .black.opacity(0.6), radius: 0, x: 0, y: 4)
                    }

                    // Close button
                    Button(action: onClose) {
                        Text("CLOSE")
                            .font(.system(size: 16, weight: .black))
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .background(NeonTheme.green)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.black, lineWidth: 3))
                            .shadow(color: .black.opacity(0.8), radius: 0, x: 0, y: 4)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
            }
            .background(NeonTheme.purpleDark)
            .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 28, style: .continuous).stroke(Color.black, lineWidth: 4))
            .shadow(color: .black.opacity(0.8), radius: 0, x: 0, y: 8)
            .padding(.horizontal, 20)
        }
    }

    private func statRow(icon: String, iconColor: Color, label: String, value: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(iconColor)
            Text(label)
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.white)
            Spacer()
            Text(value)
                .font(.system(size: 16, weight: .black))
                .foregroundColor(iconColor)
                .shadow(color: .black.opacity(0.5), radius: 0, x: 1, y: 1)
        }
        .padding(10)
        .background(Color.black.opacity(0.3))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.black, lineWidth: 2))
    }
}
