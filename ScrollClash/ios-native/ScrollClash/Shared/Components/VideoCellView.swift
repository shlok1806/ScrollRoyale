import SwiftUI

struct VideoCellView: View {
    let item: ContentItem
    let index: Int
    let totalCount: Int
    let cellHeight: CGFloat
    let isActive: Bool
    let playbackTime: Double
    var onPlaybackTimeUpdate: ((Double) -> Void)?

    @State private var cellScale: CGFloat = 0.92
    @State private var cellOpacity: Double = 0.6
    @State private var hintPulse = false

    private var watchProgress: Double {
        guard item.duration > 0 else { return 0 }
        return min(1, max(0, playbackTime / item.duration))
    }

    // Clamp dots to max 10; show a collapsed "..." dot if feed is longer
    private var dotCount: Int { min(totalCount, 10) }
    private var activeDot: Int { min(index, dotCount - 1) }

    var body: some View {
        ZStack {
            // Full-screen video
            VideoPlayerView(
                url: item.videoURL,
                isPlaying: isActive,
                playbackTime: playbackTime,
                onPlaybackTimeUpdate: onPlaybackTimeUpdate
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            // Top vignette — extra strong so the game HUD stays readable
            VStack {
                LinearGradient(
                    colors: [Color.black.opacity(0.72), Color.black.opacity(0.3), .clear],
                    startPoint: .top, endPoint: .bottom
                )
                .frame(height: 180)
                Spacer()
                // Bottom vignette — space for boost deck / HUD
                LinearGradient(
                    colors: [.clear, Color.black.opacity(0.35), Color.black.opacity(0.72)],
                    startPoint: .top, endPoint: .bottom
                )
                .frame(height: 120)
            }
            .ignoresSafeArea()

            // Right edge — vertical page-dot indicator (Reels-style)
            HStack {
                Spacer()
                VStack(spacing: 5) {
                    ForEach(0..<dotCount, id: \.self) { i in
                        let active = (i == activeDot)
                        Capsule()
                            .fill(active ? NeonTheme.green : Color.white.opacity(0.35))
                            .frame(width: active ? 4 : 3, height: active ? 18 : 8)
                            .shadow(color: active ? NeonTheme.green.opacity(0.8) : .clear, radius: 4)
                            .animation(.easeInOut(duration: 0.2), value: activeDot)
                    }
                }
                .padding(.trailing, 10)
                .padding(.top, 96)
            }

            // Bottom — playback progress bar + swipe hint
            VStack {
                Spacer()
                VStack(spacing: 10) {
                    // Swipe-up chevron hint — visible on first (active) page only
                    if isActive && index < totalCount - 1 {
                        Image(systemName: "chevron.compact.up")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundColor(.white.opacity(0.75))
                            .scaleEffect(hintPulse ? 1.18 : 1.0)
                            .animation(
                                .easeInOut(duration: 0.7).repeatForever(autoreverses: true),
                                value: hintPulse
                            )
                            .onAppear { hintPulse = true }
                            .transition(.opacity)
                    }

                    // Thin playback progress bar
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(Color.white.opacity(0.2))
                                .frame(height: 3)
                            Capsule()
                                .fill(Color.white)
                                .frame(width: geo.size.width * watchProgress, height: 3)
                                .animation(.linear(duration: 0.1), value: watchProgress)
                        }
                    }
                    .frame(height: 3)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 8)
                }
            }
        }
        .frame(height: cellHeight)
        .scaleEffect(cellScale)
        .opacity(cellOpacity)
        .clipped()
        .onAppear {
            // Cells that are already active on first appear should be full-size immediately
            if isActive {
                cellScale = 1.0
                cellOpacity = 1.0
            }
        }
        .onChange(of: isActive) { active in
            if active {
                withAnimation(.interactiveSpring(response: 0.28, dampingFraction: 0.8)) {
                    cellScale = 1.0
                    cellOpacity = 1.0
                }
                hintPulse = true
            } else {
                withAnimation(.easeOut(duration: 0.15)) {
                    cellScale = 0.92
                    cellOpacity = 0.6
                }
                hintPulse = false
            }
        }
    }
}
