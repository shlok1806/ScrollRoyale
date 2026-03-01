import SwiftUI

struct ProgressRingView: View {
    let progress: Double   // 0–100
    let size: CGFloat
    let strokeWidth: CGFloat
    var color: Color = NeonTheme.pink

    private var normalizedProgress: Double { min(max(progress / 100, 0), 1) }

    private var ringColor: Color {
        if progress < 35 { return NeonTheme.green }
        if progress < 60 { return NeonTheme.cyan }
        return NeonTheme.pink
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.1), lineWidth: strokeWidth)

            Circle()
                .trim(from: 0, to: normalizedProgress)
                .stroke(
                    ringColor,
                    style: StrokeStyle(lineWidth: strokeWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .shadow(color: ringColor.opacity(0.6), radius: 6)
        }
        .frame(width: size, height: size)
        .animation(.easeInOut(duration: 0.6), value: progress)
    }
}
