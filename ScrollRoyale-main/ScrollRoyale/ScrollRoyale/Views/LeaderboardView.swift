import SwiftUI

struct LeaderboardView: View {
    @StateObject var viewModel: LeaderboardViewModel

    var body: some View {
        ZStack {
            LinearGradient.neonBackground.ignoresSafeArea()

            VStack(spacing: 16) {
                NeonSectionTitle(title: "Leaderboard", subtitle: "Global rankings from live matches")

                if viewModel.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else if let errorMessage = viewModel.errorMessage {
                    NeonCard {
                        Text("Could not load leaderboard.\n\(errorMessage)")
                            .foregroundStyle(.red)
                            .multilineTextAlignment(.center)
                    }
                } else if viewModel.entries.isEmpty {
                    NeonCard {
                        Text("No ranked matches yet.")
                            .foregroundStyle(NeonTheme.textSecondary)
                    }
                } else {
                    ScrollView {
                        VStack(spacing: 10) {
                            ForEach(Array(viewModel.entries.enumerated()), id: \.element.id) { index, entry in
                                NeonCard {
                                    HStack {
                                        Text("#\(index + 1)")
                                            .font(.headline.weight(.bold))
                                            .foregroundStyle(NeonTheme.textPrimary)
                                            .frame(width: 42, alignment: .leading)
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(entry.displayName)
                                                .font(.headline)
                                                .foregroundStyle(NeonTheme.textPrimary)
                                            Text("Wins \(entry.wins)")
                                                .font(.caption)
                                                .foregroundStyle(NeonTheme.textSecondary)
                                        }
                                        Spacer()
                                        Text("\(Int(entry.averageScore))")
                                            .font(.headline.weight(.semibold))
                                            .foregroundStyle(NeonTheme.textPrimary)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                Spacer()
            }
            .padding(.top, 24)
        }
        .onAppear {
            viewModel.load()
        }
    }
}
