import SwiftUI

struct BoostInventoryView: View {
    let onDismiss: () -> Void

    enum FilterTab: String, CaseIterable {
        case all, equipped, control, damage, utility, defense
        var label: String { rawValue.uppercased() }
    }

    @State private var activeTab: FilterTab = .all
    @State private var selectedBoost: Boost? = nil
    @State private var boosts = MockData.boosts

    private var equippedBoosts: [Boost] { boosts.filter { $0.equipped } }
    private var filteredBoosts: [Boost] {
        switch activeTab {
        case .all:      return boosts
        case .equipped: return boosts.filter { $0.equipped }
        case .control:  return boosts.filter { $0.category == .control }
        case .damage:   return boosts.filter { $0.category == .damage }
        case .utility:  return boosts.filter { $0.category == .utility }
        case .defense:  return boosts.filter { $0.category == .defense }
        }
    }

    var body: some View {
        ZStack {
            StripedBackground().ignoresSafeArea()
                .overlay(Color.black.opacity(0.2).ignoresSafeArea())

            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: onDismiss) {
                        ZStack {
                            Circle()
                                .fill(NeonTheme.purpleDark)
                                .frame(width: 40, height: 40)
                                .overlay(Circle().stroke(Color.black, lineWidth: 3))
                                .shadow(color: .black.opacity(0.8), radius: 0, x: 0, y: 3)
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
                    .buttonStyle(.plain)

                    Spacer()

                    Text("BOOST DECK")
                        .font(.system(size: 22, weight: .black))
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.5), radius: 0, x: 3, y: 3)

                    Spacer()
                    Color.clear.frame(width: 40)
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 12)

                // Active deck preview
                activeDeckPanel
                    .padding(.horizontal, 20)
                    .padding(.bottom, 12)

                // Filter tabs
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(FilterTab.allCases, id: \.self) { tab in
                            Button { withAnimation { activeTab = tab } } label: {
                                Text(tab.label)
                                    .font(.system(size: 11, weight: .black))
                                    .foregroundColor(activeTab == tab ? .black : .white)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 8)
                                    .background(activeTab == tab ? NeonTheme.green : Color(hex: "5A5A7A"))
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.black, lineWidth: 3))
                                    .shadow(color: .black.opacity(0.8), radius: 0, x: 0, y: 3)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.bottom, 12)

                // Boost grid
                ScrollView(showsIndicators: false) {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        ForEach(filteredBoosts) { boost in
                            BoostCardView(boost: boost)
                                .onTapGesture { selectedBoost = boost }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 100)
                }
            }
        }
        .sheet(item: $selectedBoost) { boost in
            BoostDetailSheet(boost: boost, onDismiss: { selectedBoost = nil }, onEquipToggle: {
                if let idx = boosts.firstIndex(where: { $0.id == boost.id }) {
                    boosts[idx].equipped.toggle()
                }
                selectedBoost = nil
            })
            .presentationDetents([.large])
        }
    }

    // MARK: Active Deck Panel

    private var activeDeckPanel: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("ACTIVE DECK")
                    .font(.system(size: 13, weight: .black))
                    .foregroundColor(.white)
                Spacer()
                Text("\(equippedBoosts.count)/4")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.white.opacity(0.7))
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(equippedBoosts) { boost in
                        BoostCardView(boost: boost, size: .small)
                            .onTapGesture { selectedBoost = boost }
                    }

                    ForEach(0..<max(0, 4 - equippedBoosts.count), id: \.self) { _ in
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.3), style: StrokeStyle(lineWidth: 3, dash: [6]))
                            .frame(width: 80, height: 112)
                            .overlay(
                                Image(systemName: "plus")
                                    .font(.system(size: 28, weight: .bold))
                                    .foregroundColor(.white.opacity(0.3))
                            )
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .padding(12)
        .background(NeonTheme.purpleDark)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.black, lineWidth: 4))
        .shadow(color: .black.opacity(0.8), radius: 0, x: 0, y: 6)
    }
}

// MARK: - Boost Card View

enum BoostCardSize { case normal, small, large }

struct BoostCardView: View {
    let boost: Boost
    var size: BoostCardSize = .normal

    private var width: CGFloat {
        switch size {
        case .small:  return 80
        case .normal: return .infinity
        case .large:  return 160
        }
    }

    private var aspectRatio: CGFloat { 2.0 / 3.0 }

    var body: some View {
        ZStack {
            // Rarity glow
            RoundedRectangle(cornerRadius: cardRadius)
                .fill(boost.rarity.glowColor)
                .blur(radius: 8)
                .padding(-2)

            VStack(spacing: 0) {
                // Top colored header
                ZStack(alignment: .topTrailing) {
                    boost.rarity.color
                        .frame(height: headerHeight)

                    // Category badge
                    Text(boost.category.displayName)
                        .font(.system(size: 7, weight: .black))
                        .foregroundColor(.white)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 2)
                        .background(Color.black.opacity(0.5))
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                        .padding(4)
                }

                // Icon area
                ZStack {
                    Color.white

                    BoostTypeIcon(
                        iconType: boost.iconType,
                        size: iconSize,
                        color: boost.rarity.color
                    )

                    // Focus cost
                    VStack {
                        Spacer()
                        HStack {
                            HStack(spacing: 2) {
                                Circle()
                                    .fill(NeonTheme.cyan)
                                    .frame(width: 6, height: 6)
                                Text("\(boost.focusCost)")
                                    .font(.system(size: 8, weight: .black))
                                    .foregroundColor(.black)
                            }
                            .padding(.horizontal, 4)
                            .padding(.vertical, 2)
                            .background(NeonTheme.cyan)
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                            .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color.black, lineWidth: 1.5))

                            Spacer()

                            HStack(spacing: 2) {
                                Image(systemName: "clock")
                                    .font(.system(size: 7))
                                    .foregroundColor(.black.opacity(0.6))
                                Text("\(boost.cooldown)s")
                                    .font(.system(size: 8, weight: .bold))
                                    .foregroundColor(.black.opacity(0.6))
                            }
                        }
                        .padding(.horizontal, 4)
                        .padding(.bottom, 4)
                    }
                }
                .frame(height: iconAreaHeight)

                // Name + rarity
                VStack(spacing: 2) {
                    Text(boost.name)
                        .font(.system(size: nameSize, weight: .black))
                        .foregroundColor(.black)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)

                    Text(boost.rarity.rawValue.uppercased())
                        .font(.system(size: raritySize, weight: .bold))
                        .foregroundColor(boost.rarity.color)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 4)
                .background(Color(hex: "F5F5DC"))

                // Equipped badge
                if boost.equipped {
                    Text("EQUIPPED")
                        .font(.system(size: 7, weight: .black))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 3)
                        .background(NeonTheme.green)
                }

                // Locked overlay bottom
                if !boost.owned {
                    HStack(spacing: 4) {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 9))
                        Text("LOCKED")
                            .font(.system(size: 9, weight: .black))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 3)
                    .background(Color.black.opacity(0.6))
                }
            }
            .background(Color(hex: "F5F5DC"))
            .clipShape(RoundedRectangle(cornerRadius: cardRadius))
            .overlay(
                RoundedRectangle(cornerRadius: cardRadius)
                    .stroke(Color.black, lineWidth: size == .large ? 6 : (size == .normal ? 4 : 3))
            )
            .shadow(color: .black.opacity(0.8), radius: 0, x: 0, y: size == .normal ? 5 : 3)
            .opacity(boost.owned ? 1 : 0.7)
        }
        .frame(width: size == .small ? 80 : (size == .large ? 160 : nil))
    }

    private var cardRadius: CGFloat {
        switch size {
        case .small: return 14
        case .normal: return 18
        case .large: return 22
        }
    }

    private var headerHeight: CGFloat {
        switch size {
        case .small: return 8
        case .normal: return 10
        case .large: return 14
        }
    }

    private var iconAreaHeight: CGFloat {
        switch size {
        case .small: return 50
        case .normal: return 90
        case .large: return 120
        }
    }

    private var iconSize: CGFloat {
        switch size {
        case .small: return 24
        case .normal: return 40
        case .large: return 52
        }
    }

    private var nameSize: CGFloat {
        switch size {
        case .small: return 8
        case .normal: return 11
        case .large: return 14
        }
    }

    private var raritySize: CGFloat {
        switch size {
        case .small: return 7
        case .normal: return 9
        case .large: return 11
        }
    }
}

// MARK: - Boost Detail Sheet

struct BoostDetailSheet: View {
    let boost: Boost
    let onDismiss: () -> Void
    let onEquipToggle: () -> Void

    var body: some View {
        ZStack {
            Color(hex: "F5F5DC").ignoresSafeArea()

            VStack(spacing: 16) {
                // Handle
                Capsule()
                    .fill(Color.black.opacity(0.3))
                    .frame(width: 36, height: 4)
                    .padding(.top, 8)

                // Large card
                BoostCardView(boost: boost, size: .large)
                    .frame(width: 160)

                // Details
                VStack(spacing: 12) {
                    detailBox(title: "EFFECT", content: boost.effect)
                    detailBox(title: "DESCRIPTION", content: boost.description)

                    // Flavor text
                    Text("\"\(boost.flavorText)\"")
                        .font(.system(size: 13, weight: .bold))
                        .italic()
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding(12)
                        .frame(maxWidth: .infinity)
                        .background(NeonTheme.purpleDark)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.black, lineWidth: 3))
                        .shadow(color: .black.opacity(0.6), radius: 0, x: 0, y: 4)

                    // Action
                    if boost.owned {
                        Button(action: onEquipToggle) {
                            Text(boost.equipped ? "UNEQUIP" : "EQUIP")
                                .font(.system(size: 16, weight: .black))
                                .foregroundColor(boost.equipped ? .white : .black)
                                .frame(maxWidth: .infinity)
                                .frame(height: 48)
                                .background(boost.equipped ? NeonTheme.pink : NeonTheme.green)
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.black, lineWidth: 3))
                                .shadow(color: .black.opacity(0.8), radius: 0, x: 0, y: 4)
                        }
                        .buttonStyle(.plain)
                    } else {
                        Button {} label: {
                            HStack {
                                TrophyIcon(size: 18, color: NeonTheme.yellow)
                                Text("UNLOCK (500 🏆)")
                                    .font(.system(size: 15, weight: .black))
                                    .foregroundColor(.black)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                            .background(NeonTheme.yellow)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.black, lineWidth: 3))
                            .shadow(color: .black.opacity(0.8), radius: 0, x: 0, y: 4)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
        }
    }

    private func detailBox(title: String, content: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 11, weight: .black))
                .foregroundColor(.black)
            Text(content)
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.black)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.black, lineWidth: 3))
        .shadow(color: .black.opacity(0.6), radius: 0, x: 0, y: 3)
    }
}
