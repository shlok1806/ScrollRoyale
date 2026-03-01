import SwiftUI

// MARK: - Trophy Icon

struct TrophyIcon: View {
    var size: CGFloat = 24
    var color: Color = NeonTheme.yellow

    var body: some View {
        Image(systemName: "trophy.fill")
            .font(.system(size: size, weight: .bold))
            .foregroundColor(color)
    }
}

// MARK: - Flame Icon

struct FlameIcon: View {
    var size: CGFloat = 24
    var color: Color = NeonTheme.orange

    var body: some View {
        Image(systemName: "flame.fill")
            .font(.system(size: size, weight: .bold))
            .foregroundColor(color)
    }
}

// MARK: - Crown Icon

struct CrownIcon: View {
    var size: CGFloat = 24
    var color: Color = NeonTheme.yellow

    var body: some View {
        Image(systemName: "crown.fill")
            .font(.system(size: size, weight: .bold))
            .foregroundColor(color)
    }
}

// MARK: - Swords Icon

struct SwordsIcon: View {
    var size: CGFloat = 24
    var color: Color = NeonTheme.green

    var body: some View {
        Image(systemName: "bolt.fill")
            .font(.system(size: size, weight: .bold))
            .foregroundColor(color)
    }
}

// MARK: - Home Icon

struct HomeIcon: View {
    var size: CGFloat = 24
    var color: Color = .white

    var body: some View {
        Image(systemName: "house.fill")
            .font(.system(size: size, weight: .bold))
            .foregroundColor(color)
    }
}

// MARK: - Ghost Icon

struct GhostIcon: View {
    var size: CGFloat = 24
    var color: Color = .white

    var body: some View {
        Image(systemName: "figure.wave")
            .font(.system(size: size, weight: .bold))
            .foregroundColor(color)
    }
}

// MARK: - User Icon

struct UserIcon: View {
    var size: CGFloat = 24
    var color: Color = .white

    var body: some View {
        Image(systemName: "person.fill")
            .font(.system(size: size, weight: .bold))
            .foregroundColor(color)
    }
}

// MARK: - Target Icon

struct TargetIcon: View {
    var size: CGFloat = 24
    var color: Color = .white

    var body: some View {
        Image(systemName: "target")
            .font(.system(size: size, weight: .bold))
            .foregroundColor(color)
    }
}

// MARK: - Zap Icon

struct ZapIcon: View {
    var size: CGFloat = 24
    var color: Color = NeonTheme.yellow

    var body: some View {
        Image(systemName: "bolt.fill")
            .font(.system(size: size, weight: .bold))
            .foregroundColor(color)
    }
}

// MARK: - Star Icon

struct StarIcon: View {
    var size: CGFloat = 24
    var color: Color = NeonTheme.yellow

    var body: some View {
        Image(systemName: "star.fill")
            .font(.system(size: size, weight: .bold))
            .foregroundColor(color)
    }
}

// MARK: - Settings Icon

struct SettingsIcon: View {
    var size: CGFloat = 24
    var color: Color = .white

    var body: some View {
        Image(systemName: "gearshape.fill")
            .font(.system(size: size, weight: .bold))
            .foregroundColor(color)
    }
}

// MARK: - Activity Icon

struct ActivityIcon: View {
    var size: CGFloat = 24
    var color: Color = NeonTheme.cyan

    var body: some View {
        Image(systemName: "waveform.path.ecg")
            .font(.system(size: size, weight: .bold))
            .foregroundColor(color)
    }
}

// MARK: - Globe Icon

struct GlobeIcon: View {
    var size: CGFloat = 24
    var color: Color = .white

    var body: some View {
        Image(systemName: "globe")
            .font(.system(size: size, weight: .bold))
            .foregroundColor(color)
    }
}

// MARK: - UserGroup Icon

struct UserGroupIcon: View {
    var size: CGFloat = 24
    var color: Color = .white

    var body: some View {
        Image(systemName: "person.3.fill")
            .font(.system(size: size, weight: .bold))
            .foregroundColor(color)
    }
}

// MARK: - Close Icon

struct CloseIcon: View {
    var size: CGFloat = 24
    var color: Color = .white

    var body: some View {
        Image(systemName: "xmark")
            .font(.system(size: size, weight: .black))
            .foregroundColor(color)
    }
}

// MARK: - Shield Icon

struct ShieldIcon: View {
    var size: CGFloat = 24
    var color: Color = NeonTheme.cyan

    var body: some View {
        Image(systemName: "shield.fill")
            .font(.system(size: size, weight: .bold))
            .foregroundColor(color)
    }
}

// MARK: - Boost Icon (generic by type)

struct BoostTypeIcon: View {
    let iconType: String
    var size: CGFloat = 24
    var color: Color = NeonTheme.yellow

    var body: some View {
        Image(systemName: systemImageName)
            .font(.system(size: size, weight: .bold))
            .foregroundColor(color)
    }

    private var systemImageName: String {
        switch iconType {
        case "anchor":  return "anchor.fill"
        case "zen":     return "brain.head.profile"
        case "blast":   return "burst.fill"
        case "clock":   return "clock.arrow.circlepath"
        case "shield":  return "shield.fill"
        case "eye":     return "eye.fill"
        case "chain":   return "link"
        case "reset":   return "arrow.counterclockwise"
        case "energy":  return "bolt.fill"
        case "freeze":  return "snowflake"
        case "mirror":  return "arrow.left.and.right"
        case "fire":    return "flame.fill"
        case "pulse":   return "waveform.path.ecg"
        case "fortress": return "house.fill"
        default:        return "sparkles"
        }
    }
}

// MARK: - Skull Icon
// skull.fill is not in the iOS 16 SF Symbols set; using moon.fill as graveyard-scene stand-in.

struct SkullIcon: View {
    var size: CGFloat = 24
    var color: Color = .white

    var body: some View {
        Image(systemName: "moon.fill")
            .font(.system(size: size, weight: .bold))
            .foregroundColor(color)
    }
}

// MARK: - Tree Icon (for graveyard healthy scene)

struct TreeIcon: View {
    var size: CGFloat = 24
    var color: Color = NeonTheme.green

    var body: some View {
        Image(systemName: "tree.fill")
            .font(.system(size: size, weight: .bold))
            .foregroundColor(color)
    }
}

// MARK: - Lock Icon

struct LockIcon: View {
    var size: CGFloat = 24
    var color: Color = .black

    var body: some View {
        Image(systemName: "lock.fill")
            .font(.system(size: size, weight: .bold))
            .foregroundColor(color)
    }
}

// MARK: - Award Badge Icon

struct AwardBadgeIcon: View {
    var size: CGFloat = 24
    var color: Color = NeonTheme.yellow

    var body: some View {
        Image(systemName: "medal.fill")
            .font(.system(size: size, weight: .bold))
            .foregroundColor(color)
    }
}

// MARK: - Palette Icon

struct PaletteIcon: View {
    var size: CGFloat = 24
    var color: Color = NeonTheme.pink

    var body: some View {
        Image(systemName: "paintpalette.fill")
            .font(.system(size: size, weight: .bold))
            .foregroundColor(color)
    }
}
