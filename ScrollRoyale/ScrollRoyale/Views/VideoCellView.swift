import SwiftUI

struct VideoCellView: View {
    let item: ContentItem
    let index: Int
    let totalCount: Int
    let cellHeight: CGFloat
    let isActive: Bool
    let playbackTime: Double
    var onPlaybackTimeUpdate: ((Double) -> Void)?

    var body: some View {
        ZStack {
            VideoPlayerView(
                url: item.videoURL,
                isPlaying: isActive,
                playbackTime: playbackTime,
                onPlaybackTimeUpdate: onPlaybackTimeUpdate
            )
            .frame(maxWidth: .infinity)
            .overlay(
                LinearGradient(
                    colors: [Color.black.opacity(0.42), .clear, Color.black.opacity(0.42)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )

            VStack {
                HStack {
                    Text("VIDEO \(index + 1) / \(totalCount)")
                        .font(.system(size: 10, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 9)
                        .padding(.vertical, 5)
                        .background(Color.black.opacity(0.46))
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(Color.black, lineWidth: 2))
                    Spacer()
                }
                .padding(.top, 96)
                .padding(.horizontal, 14)
                Spacer()
                if isActive {
                    Text("SWIPE TO NEXT CLIP")
                        .font(.system(size: 10, weight: .black, design: .rounded))
                        .foregroundStyle(.white.opacity(0.86))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.black.opacity(0.44))
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(Color.black, lineWidth: 2))
                        .padding(.bottom, 134)
                }
            }
        }
        .frame(height: cellHeight)
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
        index: 0,
        totalCount: 3,
        cellHeight: 600,
        isActive: true,
        playbackTime: 0
    )
}
