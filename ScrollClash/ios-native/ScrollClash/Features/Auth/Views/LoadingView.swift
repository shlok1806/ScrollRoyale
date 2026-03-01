import SwiftUI
import Combine

struct LoadingView: View {
    let onComplete: () -> Void

    @EnvironmentObject private var appState: AppState
    @State private var progress: Double = 0
    @State private var tipIndex: Int = 0
    @State private var appeared = false
    @State private var ring1Rotation: Double = 0
    @State private var ring2Rotation: Double = 0
    @State private var ring3Rotation: Double = 0

    private let tips = MockData.loadingTips
    private let timer = Timer.publish(every: 0.03, on: .main, in: .common).autoconnect()
    private let tipTimer = Timer.publish(every: 2.0, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            StripedBackground()
                .ignoresSafeArea()
                .overlay(
                    LinearGradient(
                        colors: [
                            Color(hex: "1a0a2e").opacity(0.9),
                            Color(hex: "0f0520").opacity(0.8),
                            Color(hex: "050509").opacity(0.9)
                        ],
                        startPoint: .top, endPoint: .bottom
                    )
                    .ignoresSafeArea()
                )

            // Animated rings
            ZStack {
                Circle()
                    .stroke(Color(hex: "7B2CBF").opacity(0.2), lineWidth: 4)
                    .frame(width: 256, height: 256)
                    .rotationEffect(.degrees(ring1Rotation))

                Circle()
                    .stroke(NeonTheme.green.opacity(0.2), lineWidth: 4)
                    .frame(width: 320, height: 320)
                    .rotationEffect(.degrees(-ring2Rotation))

                Circle()
                    .stroke(NeonTheme.cyan.opacity(0.2), lineWidth: 4)
                    .frame(width: 384, height: 384)
                    .rotationEffect(.degrees(ring3Rotation))
            }
            .onAppear {
                withAnimation(.linear(duration: 8).repeatForever(autoreverses: false)) { ring1Rotation = 360 }
                withAnimation(.linear(duration: 6).repeatForever(autoreverses: false)) { ring2Rotation = 360 }
                withAnimation(.linear(duration: 10).repeatForever(autoreverses: false)) { ring3Rotation = 360 }
            }

            // Center brain
            BrainCharacterView(
                customization: appState.customization,
                rotLevel: 35,
                size: 140,
                showArms: true
            )
            .shadow(color: Color(hex: "7B2CBF").opacity(0.8), radius: 20)

            // Bottom: progress + tips
            VStack(spacing: 16) {
                Spacer()

                VStack(spacing: 4) {
                    Text("LOADING...")
                        .font(.system(size: 22, weight: .black))
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.5), radius: 0, x: 2, y: 2)

                    Text("Preparing your arena")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.white.opacity(0.7))
                }
                .opacity(appeared ? 1 : 0)
                .animation(.easeOut.delay(0.4), value: appeared)

                // Progress Bar
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.black.opacity(0.6))
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.black, lineWidth: 4))
                        .frame(height: 32)
                        .shadow(color: .black.opacity(0.8), radius: 0, x: 0, y: 4)

                    GeometryReader { geo in
                        RoundedRectangle(cornerRadius: 14)
                            .fill(
                                LinearGradient(
                                    colors: [Color(hex: "7B2CBF"), NeonTheme.cyan, NeonTheme.green],
                                    startPoint: .leading, endPoint: .trailing
                                )
                            )
                            .frame(width: geo.size.width * (progress / 100), height: geo.size.height)
                            .animation(.linear(duration: 0.03), value: progress)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .padding(4)

                    Text("\(Int(progress))%")
                        .font(.system(size: 13, weight: .black))
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.8), radius: 2)
                }
                .frame(height: 32)
                .opacity(appeared ? 1 : 0)
                .animation(.easeOut.delay(0.5), value: appeared)

                Text(tips[tipIndex])
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white.opacity(0.5))
                    .multilineTextAlignment(.center)
                    .opacity(appeared ? 1 : 0)
                    .animation(.easeOut.delay(0.7), value: appeared)
                    .animation(.easeInOut(duration: 0.3), value: tipIndex)
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 80)
        }
        .onAppear { appeared = true }
        .onReceive(timer) { _ in
            if progress < 100 {
                progress = min(100, progress + 1.5)
            }
        }
        .onReceive(tipTimer) { _ in
            tipIndex = (tipIndex + 1) % tips.count
        }
        .task {
            try? await Task.sleep(for: .seconds(3))
            onComplete()
        }
    }
}
