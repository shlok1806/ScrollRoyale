import SwiftUI
import UIKit

struct LobbyView: View {
    @ObservedObject var viewModel: LobbyViewModel
    let onMatchFound: (Match) -> Void

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.1, green: 0.05, blue: 0.2),
                    Color(red: 0.05, green: 0.02, blue: 0.15)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 32) {
                Text("Scroll Royale")
                    .font(.system(size: 42, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                Text("1v1 Competitive Doomscrolling")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.white.opacity(0.7))

                Spacer()

                if viewModel.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.5)
                    Text(viewModel.statusMessage.isEmpty ? "Loading..." : viewModel.statusMessage)
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.8))
                } else if let error = viewModel.errorMessage {
                    Text(error)
                        .font(.subheadline)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                        .padding()
                } else {
                    lobbyContent
                        .padding(.horizontal, 40)
                }

                Spacer()
            }
            .padding(.top, 60)
        }
        .onChange(of: viewModel.currentMatch) { match in
            if let match, match.status == .inProgress {
                onMatchFound(match)
            }
        }
        .onChange(of: viewModel.joinCodeInput) { newValue in
            let normalized = newValue
                .uppercased()
                .filter { character in
                    character.unicodeScalars.allSatisfy {
                        CharacterSet.alphanumerics.contains($0)
                    }
                }
            let trimmed = String(normalized.prefix(6))
            if trimmed != newValue {
                viewModel.joinCodeInput = trimmed
            }
        }
    }

    @ViewBuilder
    private var lobbyContent: some View {
        switch viewModel.mode {
        case .idle:
            idleContent
        case .hosting:
            hostingContent
        case .joining:
            joiningContent
        }
    }

    private var idleContent: some View {
        VStack(spacing: 16) {
            Picker("Match Length", selection: $viewModel.selectedDuration) {
                ForEach(MatchDuration.allCases) { duration in
                    Text(duration.label).tag(duration)
                }
            }
            .pickerStyle(.segmented)
            .padding(.bottom, 4)

            Button {
                viewModel.createMatch()
            } label: {
                Text("Create Match")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(red: 0.6, green: 0.2, blue: 1.0))
                    )
            }
            .disabled(viewModel.isLoading)

            Button {
                viewModel.beginJoinFlow()
            } label: {
                Text("Join with Code")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.5), lineWidth: 2)
                    )
            }
            .disabled(viewModel.isLoading)
        }
    }

    private var hostingContent: some View {
        VStack(spacing: 18) {
            Text("Share this match code")
                .font(.headline)
                .foregroundStyle(.white.opacity(0.9))

            Text(viewModel.hostedMatchCode.isEmpty ? "------" : viewModel.hostedMatchCode)
                .font(.system(size: 34, weight: .bold, design: .monospaced))
                .kerning(3)
                .foregroundStyle(.white)
                .padding(.vertical, 18)
                .frame(maxWidth: .infinity)
                .background(Color.white.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 14))

            if !viewModel.statusMessage.isEmpty {
                Text(viewModel.statusMessage)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.75))
                    .multilineTextAlignment(.center)
            }

            HStack(spacing: 12) {
                Button {
                    UIPasteboard.general.string = viewModel.hostedMatchCode
                } label: {
                    Text("Copy Code")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.white.opacity(0.2))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }

                Button {
                    viewModel.cancelHostedMatch()
                } label: {
                    Text("Cancel")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.red.opacity(0.4))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
        }
    }

    private var joiningContent: some View {
        VStack(spacing: 16) {
            Text("Enter match code")
                .font(.headline)
                .foregroundStyle(.white.opacity(0.9))

            TextField("A7K2P9", text: $viewModel.joinCodeInput)
                .textInputAutocapitalization(.characters)
                .autocorrectionDisabled(true)
                .font(.system(size: 28, weight: .bold, design: .monospaced))
                .multilineTextAlignment(.center)
                .padding(.vertical, 14)
                .padding(.horizontal, 12)
                .background(Color.white.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 12))

            Button {
                viewModel.joinMatchWithCode()
            } label: {
                Text("Join Match")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(red: 0.6, green: 0.2, blue: 1.0))
                    )
            }
            .disabled(viewModel.joinCodeInput.count != 6 || viewModel.isLoading)

            Button {
                viewModel.backToIdle()
            } label: {
                Text("Back")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.5), lineWidth: 2)
                    )
            }
        }
    }
}
