import SwiftUI

/// Full-screen paged video feed (Instagram Reels / TikTok style).
///
/// Each video occupies the full screen. A swipe snaps to the adjacent page.
/// Playback of the incoming page is intentionally delayed by ~1 second after
/// the swipe settles so fast consecutive swipes don't start/stop videos mid-animation.
struct VideoFeedView: View {
    let items: [ContentItem]
    @Binding var scrollOffset: Double
    @Binding var currentIndex: Int
    @Binding var playbackTime: Double
    let onScroll: (Double, Int, Double) -> Void

    // activeIndex tracks which page is *playing* — lags behind currentIndex by 1 s.
    @State private var activeIndex: Int = 0
    // Raw finger drag translation while a gesture is in flight.
    @State private var dragOffset: CGFloat = 0
    // Cancellable activation task so rapid swipes don't stack timers.
    @State private var pendingActivation: Task<Void, Never>?

    var body: some View {
        GeometryReader { geo in
            let pageH = geo.size.height

            ZStack {
                Color.black.ignoresSafeArea()

                ForEach(visibleIndices, id: \.self) { index in
                    VideoCellView(
                        item: items[index],
                        index: index,
                        totalCount: items.count,
                        cellHeight: pageH,
                        isActive: index == activeIndex,
                        playbackTime: index == activeIndex ? playbackTime : 0,
                        onPlaybackTimeUpdate: index == activeIndex ? { time in
                            playbackTime = time
                            onScroll(Double(currentIndex) * pageH, currentIndex, time)
                        } : nil
                    )
                    .frame(width: geo.size.width, height: pageH)
                    // Position each page at its slot relative to the current page.
                    .offset(y: CGFloat(index - currentIndex) * pageH + dragOffset)
                }
            }
            .frame(width: geo.size.width, height: pageH)
            .clipped()
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 12, coordinateSpace: .local)
                    .onChanged { value in
                        // Only track predominantly vertical drags.
                        guard abs(value.translation.height) > abs(value.translation.width) else { return }
                        dragOffset = value.translation.height
                    }
                    .onEnded { value in
                        let translation  = value.translation.height
                        let velocity     = value.predictedEndTranslation.height
                        let snapThresh   = pageH * 0.22           // 22 % of screen
                        let velThresh: CGFloat = 420              // px predicted

                        var target = currentIndex
                        if (translation < -snapThresh || velocity < -velThresh),
                           currentIndex < items.count - 1 {
                            target = currentIndex + 1
                        } else if (translation > snapThresh || velocity > velThresh),
                                  currentIndex > 0 {
                            target = currentIndex - 1
                        }

                        // Animate both state mutations together so the cells slide
                        // smoothly from their current drag position to the new resting place.
                        withAnimation(.interactiveSpring(response: 0.28, dampingFraction: 0.88)) {
                            currentIndex = target
                            dragOffset   = 0
                        }

                        let newOffset = Double(target) * Double(pageH)
                        scrollOffset  = newOffset
                        onScroll(newOffset, target, playbackTime)
                        scheduleActivation(to: target)
                    }
            )
            .onAppear {
                activeIndex = max(0, min(currentIndex, max(0, items.count - 1)))
            }
        }
    }

    // Only keep prev / current / next in memory — avoids loading all AVPlayers at once.
    private var visibleIndices: [Int] {
        guard !items.isEmpty else { return [] }
        let lo = max(0, currentIndex - 1)
        let hi = min(items.count - 1, currentIndex + 1)
        return Array(lo...hi)
    }

    /// Delay activating (playing) the new page by ~1 s so rapid swipes don't
    /// start and stop multiple AVPlayers in quick succession.
    private func scheduleActivation(to index: Int) {
        pendingActivation?.cancel()
        guard index != activeIndex else { return }
        pendingActivation = Task {
            try? await Task.sleep(for: .milliseconds(950))
            guard !Task.isCancelled else { return }
            await MainActor.run { activeIndex = index }
        }
    }
}
