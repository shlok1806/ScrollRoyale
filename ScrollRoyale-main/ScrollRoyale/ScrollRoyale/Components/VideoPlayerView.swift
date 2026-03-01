import SwiftUI
import AVKit
import AVFoundation
import os

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
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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
        view.onPlaybackTimeUpdate = onPlaybackTimeUpdate
        view.setPlaying(isPlaying)
        return view
    }

    func updateUIView(_ uiView: PlayerUIView, context: Context) {
        if uiView.currentURL != url {
            uiView.configure(url: url)
        }

        uiView.onPlaybackTimeUpdate = onPlaybackTimeUpdate
        uiView.setPlaying(isPlaying)

        if playbackTime > 0.2 {
            let delta = abs(uiView.currentTime() - playbackTime)
            if delta > 0.8 {
                uiView.seek(to: playbackTime)
            }
        }
    }
}

private final class PlayerUIView: UIView {
    private static let logger = Logger(subsystem: "com.scrollroyale.app", category: "VideoPlayer")

    private var player: AVPlayer?
    private var playerLayer: AVPlayerLayer?
    private var timeObserver: Any?
    private var shouldPlayWhenReady = false

    private var itemStatusObservation: NSKeyValueObservation?
    private var timeControlObservation: NSKeyValueObservation?

    var onPlaybackTimeUpdate: ((Double) -> Void)?
    private(set) var currentURL: URL?

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

    override func didMoveToWindow() {
        super.didMoveToWindow()
        if window != nil {
            attemptAutoplayIfReady()
        } else {
            player?.pause()
        }
    }

    func configure(url: URL) {
        currentURL = url

        shouldPlayWhenReady = false
        itemStatusObservation = nil
        timeControlObservation = nil

        if let observer = timeObserver {
            player?.removeTimeObserver(observer)
            timeObserver = nil
        }

        player?.pause()
        NotificationCenter.default.removeObserver(self)

        let item = AVPlayerItem(url: url)
        item.preferredForwardBufferDuration = 1

        let newPlayer = AVPlayer(playerItem: item)
        newPlayer.actionAtItemEnd = .none
        newPlayer.automaticallyWaitsToMinimizeStalling = false

        let layer = AVPlayerLayer(player: newPlayer)
        layer.videoGravity = .resizeAspect
        layer.frame = bounds
        layer.backgroundColor = UIColor.black.cgColor

        playerLayer?.removeFromSuperlayer()
        self.layer.addSublayer(layer)

        player = newPlayer
        playerLayer = layer

        setupAudioSession()
        addTimeObserver()
        addObservers(for: item, player: newPlayer)
    }

    private func setupAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default)
            try session.setActive(true)
        } catch {
            Self.logger.error("Audio session error \(String(describing: error), privacy: .public)")
        }
    }

    private func addTimeObserver() {
        guard let player else { return }
        let interval = CMTime(seconds: 0.1, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        timeObserver = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            self?.onPlaybackTimeUpdate?(time.seconds)
        }
    }

    private func addObservers(for item: AVPlayerItem, player: AVPlayer) {
        itemStatusObservation = item.observe(\.status, options: [.initial, .new]) { [weak self] item, _ in
            guard let self else { return }
            switch item.status {
            case .readyToPlay:
                self.attemptAutoplayIfReady()
            case .failed:
                let message = item.error?.localizedDescription ?? "unknown item error"
                Self.logger.error("Item failed \(message, privacy: .public)")
            default:
                break
            }
        }

        timeControlObservation = player.observe(\.timeControlStatus, options: [.initial, .new]) { _, _ in
        }

        NotificationCenter.default.addObserver(self, selector: #selector(playerDidFinish), name: .AVPlayerItemDidPlayToEndTime, object: item)
        NotificationCenter.default.addObserver(self, selector: #selector(playerDidFailToPlayToEnd(_:)), name: .AVPlayerItemFailedToPlayToEndTime, object: item)
    }

    private func attemptAutoplayIfReady() {
        guard window != nil else { return }
        guard bounds.width > 0, bounds.height > 0 else { return }
        guard shouldPlayWhenReady else { return }
        guard let item = player?.currentItem, item.status == .readyToPlay else { return }
        player?.playImmediately(atRate: 1.0)
    }

    @objc private func playerDidFinish() {
        player?.seek(to: .zero)
        attemptAutoplayIfReady()
    }

    @objc private func playerDidFailToPlayToEnd(_ notification: Notification) {
        let error = notification.userInfo?[AVPlayerItemFailedToPlayToEndTimeErrorKey] as? NSError
        let message = error?.localizedDescription ?? "unknown avplayer error"
        Self.logger.error("Playback failed \(message, privacy: .public)")
    }

    func setPlaying(_ playing: Bool) {
        shouldPlayWhenReady = playing
        if playing {
            attemptAutoplayIfReady()
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
