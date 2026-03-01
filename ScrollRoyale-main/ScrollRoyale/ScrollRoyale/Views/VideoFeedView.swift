import SwiftUI

/// One reel at a time, vertical paging (Instagram Reels / YouTube Shorts style).
/// No continuous list — swipe up/down to go to next/previous reel.
struct VideoFeedView: View {
    let items: [ContentItem]
    @Binding var scrollOffset: Double
    @Binding var currentIndex: Int
    @Binding var playbackTime: Double
    let onScroll: (Double, Int, Double) -> Void

    var body: some View {
        GeometryReader { geometry in
            let w = geometry.size.width
            let h = geometry.size.height

            TabView(selection: Binding(
                get: { currentIndex },
                set: { newIndex in
                    guard newIndex != currentIndex, newIndex >= 0, newIndex < items.count else { return }
                    currentIndex = newIndex
                    playbackTime = 0
                    scrollOffset = Double(newIndex) * h
                    onScroll(scrollOffset, currentIndex, playbackTime)
                }
            )) {
                ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                    VideoCellView(
                        item: item,
                        index: index,
                        totalCount: items.count,
                        cellHeight: h,
                        isActive: index == currentIndex,
                        playbackTime: index == currentIndex ? playbackTime : 0,
                        onPlaybackTimeUpdate: index == currentIndex ? { time in
                            playbackTime = time
                            onScroll(scrollOffset, currentIndex, time)
                        } : nil
                    )
                    .frame(width: w, height: h)
                    .rotationEffect(.degrees(-90))
                    .frame(width: h, height: w)
                    .tag(index)
                }
            }
            .frame(width: h, height: w)
            .rotationEffect(.degrees(90))
            .tabViewStyle(.page(indexDisplayMode: .never))
        }
    }
}
