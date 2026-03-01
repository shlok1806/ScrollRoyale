import SwiftUI

struct NeonCard<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(NeonTheme.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
    }
}

struct NeonPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .semibold, design: .rounded))
            .foregroundStyle(NeonTheme.textPrimary)
            .frame(maxWidth: .infinity)
            .frame(minHeight: 48)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [NeonTheme.accent, NeonTheme.accentStrong],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Color.white.opacity(0.14), lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
    }
}

struct NeonSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .semibold, design: .rounded))
            .foregroundStyle(NeonTheme.textPrimary)
            .frame(maxWidth: .infinity)
            .frame(minHeight: 48)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(NeonTheme.surfaceStrong)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Color.white.opacity(0.22), lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
    }
}

struct NeonPill: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title.uppercased())
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .tracking(0.4)
                .foregroundStyle(NeonTheme.textSecondary)
            Text(value)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(NeonTheme.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 10)
        .background(
            Capsule(style: .continuous)
                .fill(NeonTheme.surfaceStrong)
        )
    }
}

struct NeonSectionTitle: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(spacing: 6) {
            Text(title)
                .font(.system(size: 32, weight: .black, design: .rounded))
                .foregroundStyle(NeonTheme.textPrimary)
                .multilineTextAlignment(.center)
            Text(subtitle)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(NeonTheme.textSecondary)
                .multilineTextAlignment(.center)
        }
    }
}
