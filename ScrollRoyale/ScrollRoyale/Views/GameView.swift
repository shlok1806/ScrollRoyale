import SwiftUI

struct GameView: View {
    @ObservedObject var viewModel: GameViewModel
    let onExit: () -> Void

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if viewModel.contentItems.isEmpty && !viewModel.isLoading {
                Text("No content available")
                    .foregroundStyle(.white)
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
            }

            VStack {
                HStack {
                    Button {
                        onExit()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.white.opacity(0.8))
                    }
                    .padding()

                    Spacer()

                    Text("vs")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.6))

                    Spacer()

                    Text("Score \(Int(viewModel.localScore))")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.6))
                        .padding()
                }
                .padding(.top, 8)

                Spacer()
            }
        }
        .ignoresSafeArea()
        .onAppear {
            viewModel.startSync()
        }
        .onDisappear {
            viewModel.stopSync()
        }
    }
}
