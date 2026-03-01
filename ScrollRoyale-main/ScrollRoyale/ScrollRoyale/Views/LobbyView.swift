import SwiftUI
import UIKit

struct LobbyView: View {
    @ObservedObject var viewModel: LobbyViewModel
    let onMatchFound: (Match) -> Void

    var body: some View {
        ZStack {
            ArcadeBackground()
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    VStack(spacing: 8) {
                        Text("TODAY'S BATTLE")
                            .font(.system(size: 32, weight: .black, design: .rounded))
                            .foregroundStyle(.white)

                        Text("1v1 COMPETITIVE DOOMSCROLLING")
                            .font(.system(size: 13, weight: .black, design: .rounded))
                            .foregroundStyle(.white.opacity(0.86))
                            .tracking(0.6)
                    }
                    .padding(.top, 6)

                    if viewModel.isLoading {
                        VStack(spacing: 10) {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(1.25)
                            Text(viewModel.statusMessage.isEmpty ? "PREPARING MATCH..." : viewModel.statusMessage.uppercased())
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                                .foregroundStyle(.white.opacity(0.85))
                                .multilineTextAlignment(.center)
                        }
                        .padding(.vertical, 24)
                    } else if let error = viewModel.errorMessage {
                        ArcadePanel(fill: Color(red: 0.96, green: 0.24, blue: 0.45)) {
                            Text(error)
                                .font(.system(size: 14, weight: .black, design: .rounded))
                                .foregroundStyle(.white)
                                .multilineTextAlignment(.center)
                        }
                    } else {
                        lobbyContent
                    }
                }
                .frame(maxWidth: 460)
                .padding(.horizontal, 20)
                .padding(.top, 54)
                .padding(.bottom, 28)
            }
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
        ArcadePanel(fill: Color(red: 0.48, green: 0.17, blue: 0.75)) {
            VStack(spacing: 14) {
                Text("READY FOR BATTLE?")
                    .font(.system(size: 22, weight: .black, design: .rounded))
                    .foregroundStyle(.white)

                Picker("Match Length", selection: $viewModel.selectedDuration) {
                    ForEach(MatchDuration.allCases) { duration in
                        Text(duration.label).tag(duration)
                    }
                }
                .pickerStyle(.segmented)

                Button {
                    viewModel.createMatch()
                } label: {
                    Text("CREATE MATCH")
                }
                .buttonStyle(ArcadePrimaryButtonStyle(color: Color(red: 0.22, green: 1.0, blue: 0.08), textColor: .black))

                Button {
                    viewModel.beginJoinFlow()
                } label: {
                    Text("JOIN WITH CODE")
                }
                .buttonStyle(ArcadePrimaryButtonStyle(color: Color(red: 0.3, green: 0.79, blue: 0.94), textColor: .black))
            }
        }
        .disabled(viewModel.isLoading)
    }

    private var hostingContent: some View {
        ArcadePanel(fill: Color(red: 0.48, green: 0.17, blue: 0.75)) {
            VStack(spacing: 18) {
                Text("SHARE THIS MATCH CODE")
                    .font(.system(size: 16, weight: .black, design: .rounded))
                    .foregroundStyle(.white)

                Text(viewModel.hostedMatchCode.isEmpty ? "------" : viewModel.hostedMatchCode)
                    .font(.system(size: 34, weight: .bold, design: .monospaced))
                    .kerning(3)
                    .foregroundStyle(.white)
                    .padding(.vertical, 18)
                    .frame(maxWidth: .infinity)
                    .background(Color(red: 1.0, green: 0.0, blue: 0.43))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color.black, lineWidth: 3)
                    )

                if !viewModel.statusMessage.isEmpty {
                    Text(viewModel.statusMessage)
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.84))
                        .multilineTextAlignment(.center)
                }

                HStack(spacing: 12) {
                    Button {
                        UIPasteboard.general.string = viewModel.hostedMatchCode
                    } label: {
                        Text("COPY CODE")
                    }
                    .buttonStyle(ArcadePrimaryButtonStyle(color: Color(red: 0.3, green: 0.79, blue: 0.94), textColor: .black))

                    Button {
                        viewModel.cancelHostedMatch()
                    } label: {
                        Text("CANCEL")
                    }
                    .buttonStyle(ArcadePrimaryButtonStyle(color: Color(red: 0.96, green: 0.24, blue: 0.45), textColor: .white))
                }
                .frame(maxWidth: .infinity)
            }
        }
    }

    private var joiningContent: some View {
        ArcadePanel(fill: Color(red: 0.48, green: 0.17, blue: 0.75)) {
            VStack(spacing: 16) {
                Text("ENTER A 6-CHARACTER CODE")
                    .font(.system(size: 18, weight: .black, design: .rounded))
                    .foregroundStyle(.white)

                TextField("A7K2P9", text: $viewModel.joinCodeInput)
                    .textInputAutocapitalization(.characters)
                    .autocorrectionDisabled(true)
                    .font(.system(size: 28, weight: .bold, design: .monospaced))
                    .multilineTextAlignment(.center)
                    .padding(.vertical, 14)
                    .padding(.horizontal, 12)
                    .background(Color(red: 0.99, green: 0.84, blue: 0.04))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.black, lineWidth: 3)
                    )
                    .foregroundStyle(.black)

                Button {
                    viewModel.joinMatchWithCode()
                } label: {
                    Text("JOIN MATCH")
                }
                .buttonStyle(ArcadePrimaryButtonStyle(color: Color(red: 0.22, green: 1.0, blue: 0.08), textColor: .black))
                .disabled(viewModel.joinCodeInput.count != 6 || viewModel.isLoading)

                Button {
                    viewModel.backToIdle()
                } label: {
                    Text("BACK")
                }
                .buttonStyle(ArcadePrimaryButtonStyle(color: Color(red: 0.3, green: 0.79, blue: 0.94), textColor: .black))
            }
        }
    }
}

private struct ArcadeBackground: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.05, green: 0.04, blue: 0.09),
                    Color(red: 0.02, green: 0.02, blue: 0.05)
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            GeometryReader { geometry in
                Path { path in
                    let spacing: CGFloat = 26
                    let width = geometry.size.width
                    let height = geometry.size.height
                    var x: CGFloat = -height
                    while x < width + height {
                        path.move(to: CGPoint(x: x, y: 0))
                        path.addLine(to: CGPoint(x: x + height, y: height))
                        x += spacing
                    }
                }
                .stroke(Color.white.opacity(0.06), lineWidth: 2)
            }

            LinearGradient(
                colors: [Color.black.opacity(0.08), Color.black.opacity(0.36)],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }
}

private struct ArcadePanel<Content: View>: View {
    let fill: Color
    let content: Content

    init(fill: Color, @ViewBuilder content: () -> Content) {
        self.fill = fill
        self.content = content()
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(fill)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.black, lineWidth: 4)
                )
                .shadow(color: Color.black.opacity(0.85), radius: 0, x: 0, y: 7)

            content
                .padding(16)
        }
    }
}

private struct ArcadePrimaryButtonStyle: ButtonStyle {
    let color: Color
    let textColor: Color

    func makeBody(configuration: Configuration) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(color)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.black, lineWidth: 3)
                )
                .shadow(color: Color.black.opacity(0.85), radius: 0, x: 0, y: 5)

            configuration.label
                .font(.system(size: 17, weight: .black, design: .rounded))
                .foregroundStyle(textColor)
                .tracking(0.5)
                .frame(maxWidth: .infinity)
                .frame(minHeight: 52)
        }
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .offset(y: configuration.isPressed ? 1 : 0)
    }
}
