import SwiftUI

struct ProfileView: View {
    @StateObject var viewModel: ProfileViewModel

    var body: some View {
        ZStack {
            LinearGradient.neonBackground.ignoresSafeArea()

            VStack(spacing: 18) {
                NeonSectionTitle(title: "Profile", subtitle: "Account summary from live data")

                if viewModel.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else if let errorMessage = viewModel.errorMessage {
                    NeonCard {
                        Text("Could not load profile.\n\(errorMessage)")
                            .foregroundStyle(.red)
                            .multilineTextAlignment(.center)
                    }
                } else if let profile = viewModel.profile {
                    NeonCard {
                        VStack(alignment: .leading, spacing: 14) {
                            Text(profile.displayName)
                                .font(.title2.weight(.bold))
                                .foregroundStyle(NeonTheme.textPrimary)
                            Text("User ID: \(profile.userId)")
                                .font(.caption)
                                .foregroundStyle(NeonTheme.textSecondary)
                            HStack(spacing: 12) {
                                NeonPill(title: "Matches", value: "\(profile.matchesPlayed)")
                                NeonPill(title: "Wins", value: "\(profile.wins)")
                                NeonPill(title: "Best", value: "\(Int(profile.bestScore))")
                            }
                        }
                    }
                } else {
                    NeonCard {
                        Text("Profile is not available yet.")
                            .foregroundStyle(NeonTheme.textSecondary)
                    }
                }

                Spacer()
            }
            .padding(.horizontal)
            .padding(.top, 24)
        }
        .onAppear {
            viewModel.load()
        }
    }
}
