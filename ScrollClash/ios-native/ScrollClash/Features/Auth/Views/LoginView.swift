import SwiftUI

struct LoginView: View {
    let onLogin: () -> Void

    @State private var appeared = false

    var body: some View {
        ZStack {
            StripedBackground()
                .ignoresSafeArea()
                .overlay(
                    LinearGradient(
                        colors: [
                            Color(hex: "1a0a2e").opacity(0.8),
                            Color(hex: "0f0520").opacity(0.6),
                            Color(hex: "050509").opacity(0.8)
                        ],
                        startPoint: .top, endPoint: .bottom
                    )
                    .ignoresSafeArea()
                )

            // Floating brain characters
            FloatingBrainsLayer()

            VStack(spacing: 0) {
                Spacer()

                // Title
                VStack(spacing: 8) {
                    Text("BRAINROT")
                        .font(.system(size: 60, weight: .black))
                        .foregroundColor(NeonTheme.green)
                        .neonShadow(NeonTheme.green, radius: 20, x: 4, y: 4)
                        .scaleEffect(appeared ? 1 : 0.8)
                        .opacity(appeared ? 1 : 0)

                    Text("ARENA")
                        .font(.system(size: 40, weight: .black))
                        .foregroundColor(Color(hex: "7B2CBF"))
                        .neonShadow(Color(hex: "7B2CBF"), radius: 15, x: 3, y: 3)
                        .scaleEffect(appeared ? 1 : 0.8)
                        .opacity(appeared ? 1 : 0)

                    Text("Battle. Customize. Dominate.")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white.opacity(0.7))
                        .opacity(appeared ? 1 : 0)
                }
                .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.1), value: appeared)
                .padding(.bottom, 48)

                // Login Card
                VStack(spacing: 0) {
                    VStack(spacing: 8) {
                        Text("GET STARTED")
                            .font(.system(size: 20, weight: .black))
                            .foregroundColor(.white)
                        Text("Sign in to start your journey")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.white.opacity(0.6))
                    }
                    .padding(.bottom, 24)

                    // Google Sign-In Button
                    Button(action: onLogin) {
                        HStack(spacing: 12) {
                            GoogleLogoView(size: 24)
                            Text("Continue with Google")
                                .font(.system(size: 18, weight: .black))
                                .foregroundColor(.black)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.black, lineWidth: 4))
                        .shadow(color: .black.opacity(0.8), radius: 0, x: 0, y: 6)
                    }
                    .buttonStyle(.plain)
                }
                .padding(32)
                .background(Color.black.opacity(0.6))
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.black, lineWidth: 4))
                .shadow(color: .black.opacity(0.8), radius: 0, x: 0, y: 8)
                .padding(.horizontal, 24)
                .offset(y: appeared ? 0 : 50)
                .opacity(appeared ? 1 : 0)
                .animation(.easeOut(duration: 0.4).delay(0.2), value: appeared)
                .padding(.bottom, 24)

                // Footer
                Text("By continuing, you agree to our Terms & Privacy Policy")
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.5))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
                    .opacity(appeared ? 1 : 0)
                    .animation(.easeOut.delay(0.4), value: appeared)

                Spacer()
            }
        }
        .onAppear { appeared = true }
    }
}

// MARK: - Floating Brains Background

private struct FloatingBrainsLayer: View {
    let brains: [(skin: String, expression: String, rot: Int, x: CGFloat, y: CGFloat, duration: Double, delay: Double)] = [
        ("default", "happy",    20, -120, -200,  4.0, 0.0),
        ("toxic",   "focused",  60,  100, -120,  5.0, 0.5),
        ("retro",   "smirk",    40,  -60,  120,  4.5, 1.0),
    ]

    @State private var offsets: [CGSize] = Array(repeating: .zero, count: 3)

    var body: some View {
        ZStack {
            ForEach(brains.indices, id: \.self) { i in
                let b = brains[i]
                BrainCharacterView(
                    customization: { var c = BrainCustomization(); c.skin = b.skin; c.expression = b.expression; return c }(),
                    rotLevel: b.rot,
                    size: 80,
                    showArms: false,
                    animated: false
                )
                .offset(x: b.x, y: b.y + offsets[i].height)
                .onAppear {
                    withAnimation(
                        .easeInOut(duration: b.duration).repeatForever(autoreverses: true)
                        .delay(b.delay)
                    ) {
                        offsets[i] = CGSize(width: 0, height: -20)
                    }
                }
            }
        }
    }
}

// MARK: - Google Logo

private struct GoogleLogoView: View {
    let size: CGFloat
    var body: some View {
        ZStack {
            Circle()
                .fill(Color.white)
                .frame(width: size, height: size)
            Text("G")
                .font(.system(size: size * 0.65, weight: .bold))
                .foregroundColor(Color(hex: "4285F4"))
        }
    }
}
