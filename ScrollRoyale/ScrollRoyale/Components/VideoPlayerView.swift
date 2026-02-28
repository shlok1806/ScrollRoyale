import SwiftUI
import AVKit

/// AVPlayer wrapper for MP4 playback - supports looping and playback control
struct VideoPlayerView: View {
    let url: URL
    var isPlaying: Bool = true
    var playbackTime: Double = 0
    var onPlaybackTimeUpdate: ((Double) -> Void)?

    var body: some View {
        VideoPlayerViewRepresentable(
            url: url,
            isPlaying: isPlaying,
            playbackTime: playbackTime,
            onPlaybackTimeUpdate: onPlaybackTimeUpdate
        )
        .aspectRatio(9/16, contentMode: .fit)
        .clipped()
    }
}

private struct VideoPlayerViewRepresentable: UIViewRepresentable {
    let url: URL
    let isPlaying: Bool
    let playbackTime: Double
    let onPlaybackTimeUpdate: ((Double) -> Void)?

    func makeUIView(context: Context) -> PlayerUIView {
        let view = PlayerUIView()
        view.configure(url: url)
        return view
    }

    func updateUIView(_ uiView: PlayerUIView, context: Context) {
        uiView.setPlaying(isPlaying)
        if abs(uiView.currentTime() - playbackTime) > 0.5 {
            uiView.seek(to: playbackTime)
        }
        uiView.onPlaybackTimeUpdate = onPlaybackTimeUpdate
    }
}

private final class PlayerUIView: UIView {
    private var player: AVPlayer?
    private var playerLayer: AVPlayerLayer?
    private var timeObserver: Any?

    var onPlaybackTimeUpdate: ((Double) -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .black
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        playerLayer?.frame = bounds
    }

    func configure(url: URL) {
        player?.pause()
        let playerItem = AVPlayerItem(url: url)
        let newPlayer = AVPlayer(playerItem: playerItem)
        newPlayer.actionAtItemEnd = .none

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(playerDidFinish),
            name: .AVPlayerItemDidPlayToEndTime,
            object: playerItem
        )

        let layer = AVPlayerLayer(player: newPlayer)
        layer.videoGravity = .resizeAspect
        layer.frame = bounds
        layer.backgroundColor = UIColor.black.cgColor

        playerLayer?.removeFromSuperlayer()
        layer.add(to: self)

        player = newPlayer
        playerLayer = layer

        addTimeObserver()
    }

    private func addTimeObserver() {
        if let observer = timeObserver {
            player?.removeTimeObserver(observer)
            timeObserver = nil
        }
        let interval = CMTime(seconds: 0.1, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        timeObserver = player?.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            self?.onPlaybackTimeUpdate?(time.seconds)
        }
    }

    @objc private func playerDidFinish() {
        player?.seek(to: .zero)
        player?.play()
    }

    func setPlaying(_ playing: Bool) {
        if playing {
            player?.play()
        } else {
            player?.pause()
        }
    }

    func seek(to time: Double) {
        player?.seek(to: CMTime(seconds: time, preferredTimescale: 600))
    }

    func currentTime() -> Double {
        player?.currentTime().seconds ?? 0
    }

    deinit {
        if let observer = timeObserver {
            player?.removeTimeObserver(observer)
        }
        NotificationCenter.default.removeObserver(self)
    }
}

extension CALayer {
    func add(to view: UIView) {
        view.layer.addSublayer(self)
    }
}
