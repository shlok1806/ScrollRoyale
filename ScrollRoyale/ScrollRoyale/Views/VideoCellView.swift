import SwiftUI

struct VideoCellView: View {
    let item: ContentItem
    let isActive: Bool
    let playbackTime: Double
    var onPlaybackTimeUpdate: ((Double) -> Void)?

    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()

            VideoPlayerView(
                url: item.videoURL,
                isPlaying: isActive,
                playbackTime: playbackTime,
                onPlaybackTimeUpdate: onPlaybackTimeUpdate
            )
            .frame(maxWidth: .infinity)
        }
        .frame(height: UIScreen.main.bounds.height)
    }
}

#Preview {
    VideoCellView(
        item: ContentItem(
            id: "1",
            videoURL: URL(string: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4")!,
            duration: 60,
            order: 1
        ),
        isActive: true,
        playbackTime: 0
    )
}
