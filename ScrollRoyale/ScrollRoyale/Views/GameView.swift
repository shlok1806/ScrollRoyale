import SwiftUI

struct GameView: View {
    @ObservedObject var viewModel: GameViewModel
    let onExit: () -> Void

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ArcadeGameplayBackground()
                    .ignoresSafeArea()

                VStack(spacing: 8) {
                    HStack(alignment: .top) {
                        ForfeitButton(action: onExit)
                        Spacer()
                        HStack(spacing: 6) {
                            ArcadeBadge(title: "MATCH", value: viewModel.matchCode)
                            ArcadeBadge(title: "STATUS", value: viewModel.matchStatusLabel)
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.top, max(8, geometry.safeAreaInsets.top + 4))

                    HStack(alignment: .center) {
                        PlayerBadge(name: "YOU", accent: Color(red: 0.48, green: 0.17, blue: 0.75))
                        Spacer()
                        TimerRing(progress: viewModel.timerProgress, remaining: viewModel.remainingSeconds)
                        Spacer()
                        PlayerBadge(name: "RIVAL", accent: Color(red: 1.0, green: 0.0, blue: 0.43))
                    }
                    .padding(.horizontal, 18)

                    Spacer(minLength: 0)

                    mainVideoFocus
                        .frame(height: min(max(geometry.size.height * 0.66, 410), 640))
                        .padding(.horizontal, 10)

                    ArcadeHUDPanel {
                        HStack(alignment: .center) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("LIVE SCORE")
                                    .font(.system(size: 9, weight: .black, design: .rounded))
                                    .foregroundStyle(.white.opacity(0.75))
                                Text("\(Int(viewModel.localScore))")
                                    .font(.system(size: 22, weight: .black, design: .rounded))
                                    .foregroundStyle(Color(red: 0.22, green: 1.0, blue: 0.08))
                            }
                            Spacer()
                            HStack(spacing: 6) {
                                SmallChip(text: "VIDEO \(viewModel.currentVideoIndex + 1)", fill: Color(red: 1.0, green: 0.84, blue: 0.04))
                                SmallChip(text: "TIME \(viewModel.remainingSeconds)s", fill: Color(red: 0.3, green: 0.79, blue: 0.94))
                            }
                        }
                    }
                    .padding(.horizontal, 12)

                    Spacer(minLength: 0)
                        .frame(height: 8)
                }
            }
        }
        .onAppear {
            viewModel.startSync()
        }
        .onDisappear {
            viewModel.stopSync()
        }
    }

    @ViewBuilder
    private var mainVideoFocus: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 22)
                .fill(Color.black.opacity(0.7))
                .overlay(
                    RoundedRectangle(cornerRadius: 22)
                        .stroke(Color.black, lineWidth: 3)
                )
                .shadow(color: .black.opacity(0.85), radius: 0, x: 0, y: 6)

            if viewModel.contentItems.isEmpty && !viewModel.isLoading {
                VStack(spacing: 8) {
                    Text("NO VIDEOS READY")
                        .font(.system(size: 18, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                    Text(viewModel.feedStatusMessage ?? "Try again in a moment.")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.82))
                }
                .multilineTextAlignment(.center)
            } else if viewModel.contentItems.isEmpty {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
            } else {
                VideoFeedView(
                    items: viewModel.contentItems,
                    scrollOffset: $viewModel.scrollOffset,
                    currentIndex: $viewModel.currentVideoIndex,
                    playbackTime: $viewModel.videoPlaybackTime,
                    onScroll: { offset, index, time in
                        viewModel.handleScroll(offset: offset, videoIndex: index, playbackTime: time)
                    }
                )
                .clipShape(RoundedRectangle(cornerRadius: 18))
                .padding(4)
            }
        }
    }
}

private struct ArcadeGameplayBackground: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.09, green: 0.04, blue: 0.16),
                    Color(red: 0.03, green: 0.02, blue: 0.06)
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            GeometryReader { geometry in
                Path { path in
                    let spacing: CGFloat = 24
                    let width = geometry.size.width
                    let height = geometry.size.height
                    var x: CGFloat = -height
                    while x < width + height {
                        path.move(to: CGPoint(x: x, y: 0))
                        path.addLine(to: CGPoint(x: x + height, y: height))
                        x += spacing
                    }
                }
                .stroke(Color.white.opacity(0.06), lineWidth: 2)
            }
        }
    }
}

private struct ArcadeHUDPanel<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.black.opacity(0.62))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.black, lineWidth: 3)
                )
                .shadow(color: .black.opacity(0.85), radius: 0, x: 0, y: 4)

            content
            .padding(10)
        }
    }
}

private struct ArcadeBadge: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.system(size: 8, weight: .black, design: .rounded))
                .foregroundStyle(.white.opacity(0.72))
            Text(value)
                .font(.system(size: 10, weight: .black, design: .rounded))
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(Color.black.opacity(0.5))
        )
        .overlay(Capsule().stroke(Color.black, lineWidth: 2))
    }
}

private struct ForfeitButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(red: 1.0, green: 0.0, blue: 0.43))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.black, lineWidth: 2.5)
                    )
                    .shadow(color: .black.opacity(0.8), radius: 0, x: 0, y: 3)
                Text("FORFEIT")
                    .font(.system(size: 11, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
            }
            .frame(width: 82, height: 34)
        }
        .buttonStyle(.plain)
    }
}

private struct SmallChip: View {
    let text: String
    let fill: Color

    var body: some View {
        Text(text)
            .font(.system(size: 9, weight: .black, design: .rounded))
            .foregroundStyle(.black)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Capsule().fill(fill))
            .overlay(Capsule().stroke(Color.black, lineWidth: 2))
    }
}

private struct PlayerBadge: View {
    let name: String
    let accent: Color

    var body: some View {
        VStack(spacing: 6) {
            Circle()
                .fill(accent)
                .frame(width: 40, height: 40)
                .overlay(Circle().stroke(Color.black, lineWidth: 3))
                .shadow(color: .black.opacity(0.85), radius: 0, x: 0, y: 4)
                .overlay(
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 16, weight: .black))
                        .foregroundStyle(.white)
                )
            Text(name)
                .font(.system(size: 9, weight: .black, design: .rounded))
                .foregroundStyle(.white)
        }
    }
}

private struct TimerRing: View {
    let progress: Double
    let remaining: Int

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.18), lineWidth: 5)

            Circle()
                .trim(from: 0, to: max(0, min(1, 1.0 - progress)))
                .stroke(Color(red: 0.22, green: 1.0, blue: 0.08), style: StrokeStyle(lineWidth: 5, lineCap: .round))
                .rotationEffect(.degrees(-90))

            Text("\(remaining)")
                .font(.system(size: 21, weight: .black, design: .rounded))
                .foregroundStyle(.white)
        }
        .frame(width: 62, height: 62)
        .padding(4)
        .background(
            Circle()
                .fill(Color.black.opacity(0.5))
        )
        .overlay(Circle().stroke(Color.black, lineWidth: 3))
    }
}
