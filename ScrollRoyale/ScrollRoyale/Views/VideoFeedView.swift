import SwiftUI

struct VideoFeedView: View {
    let items: [ContentItem]
    @Binding var scrollOffset: Double
    @Binding var currentIndex: Int
    @Binding var playbackTime: Double
    let onScroll: (Double, Int, Double) -> Void

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                        VideoCellView(
                            item: item,
                            isActive: index == currentIndex,
                            playbackTime: index == currentIndex ? playbackTime : 0,
                            onPlaybackTimeUpdate: index == currentIndex ? { time in
                                playbackTime = time
                                onScroll(scrollOffset, currentIndex, time)
                            } : nil
                        )
                        .id(index)
                    }
                }
                .background(
                    GeometryReader { geo in
                        Color.clear
                            .preference(
                                key: ScrollOffsetPreferenceKey.self,
                                value: geo.frame(in: .named("scroll")).minY
                            )
                    }
                )
            }
            .coordinateSpace(name: "scroll")
            .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
                let offset = -value
                scrollOffset = max(0, offset)
                let newIndex = Int(offset / UIScreen.main.bounds.height)
                if newIndex >= 0 && newIndex < items.count && newIndex != currentIndex {
                    currentIndex = newIndex
                }
                onScroll(scrollOffset, currentIndex, playbackTime)
            }
        }
    }
}

private struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}
