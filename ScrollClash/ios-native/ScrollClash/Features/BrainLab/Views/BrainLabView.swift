import SwiftUI

struct BrainLabView: View {
    @EnvironmentObject private var appState: AppState
    let onDismiss: () -> Void

    enum Category: String, CaseIterable {
        case hats, glasses, expressions, skins, effects, accessories

        var label: String {
            switch self {
            case .hats:         return "HATS"
            case .glasses:      return "GLASSES"
            case .expressions:  return "FACE"
            case .skins:        return "SKINS"
            case .effects:      return "EFFECTS"
            case .accessories:  return "ITEMS"
            }
        }
    }

    private let items: [Category: [(id: String, name: String)]] = [
        .hats:         [("none","None"),("crown","Crown"),("beanie","Beanie"),("wizard","Wizard Hat"),("headset","Headset"),("tophat","Top Hat"),("helmet","Helmet")],
        .glasses:      [("none","None"),("sunglasses","Sunglasses"),("pixel","Pixel Shades"),("nerd","Nerd Glasses"),("visor","Visor")],
        .expressions:  [("happy","Happy"),("determined","Determined"),("sleepy","Sleepy"),("angry","Angry"),("hypnotized","Hypnotized"),("confident","Confident")],
        .skins:        [("classic","Classic Pink"),("toxic","Toxic Green"),("purple","Royal Purple"),("cyber","Neon Cyber"),("lava","Lava Cracked"),("frozen","Frozen"),("chrome","Chrome")],
        .effects:      [("none","None"),("purple-aura","Purple Aura"),("green-flame","Green Flame"),("electric","Electric"),("particles","Particles"),("glitch","Glitch")],
        .accessories:  [("none","None"),("spoon","Spoon"),("lighter","Lighter"),("sword","Sword"),("shield","Shield")],
    ]

    @State private var activeCategory: Category = .hats
    @State private var draft = BrainCustomization()

    var body: some View {
        ZStack {
            StripedBackground().ignoresSafeArea()
                .overlay(Color.black.opacity(0.3).ignoresSafeArea())

            VStack(spacing: 0) {
                // Header
                HStack(spacing: 10) {
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

                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(NeonTheme.yellow)
                            .frame(width: 40, height: 40)
                            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.black, lineWidth: 3))
                            .shadow(color: .black.opacity(0.8), radius: 0, x: 0, y: 3)
                        Image(systemName: "brain.head.profile")
                            .font(.system(size: 18))
                            .foregroundColor(.black)
                    }

                    VStack(alignment: .leading, spacing: 0) {
                        Text("BRAIN LAB")
                            .font(.system(size: 22, weight: .black))
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.5), radius: 0, x: 3, y: 3)
                        Text("Customize your brain")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.white.opacity(0.8))
                    }

                    Spacer()

                    Text("1,204")
                        .font(.system(size: 13, weight: .black))
                        .foregroundColor(.black)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(NeonTheme.yellow)
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(Color.black, lineWidth: 3))
                        .shadow(color: .black.opacity(0.8), radius: 0, x: 0, y: 3)
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 12)

                // Brain Preview
                ZStack {
                    // Background
                    LinearGradient(
                        colors: [NeonTheme.purpleDark, NeonTheme.purpleMid],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    )
                    .overlay(
                        Canvas { context, size in
                            for i in stride(from: 0, to: max(size.width, size.height), by: 20) {
                                var path = Path()
                                path.move(to: CGPoint(x: i, y: 0))
                                path.addLine(to: CGPoint(x: 0, y: i))
                                context.stroke(path, with: .color(Color.white.opacity(0.05)), lineWidth: 1)
                            }
                        }
                    )

                    BrainCharacterView(
                        customization: draft,
                        rotLevel: 20,
                        size: 130,
                        showArms: true
                    )
                    .shadow(color: NeonTheme.purpleLight.opacity(0.4), radius: 20)
                }
                .frame(height: 200)
                .clipShape(RoundedRectangle(cornerRadius: 24))
                .overlay(RoundedRectangle(cornerRadius: 24).stroke(Color.black, lineWidth: 4))
                .shadow(color: .black.opacity(0.8), radius: 0, x: 0, y: 8)
                .padding(.horizontal, 20)
                .padding(.bottom, 12)

                // Category tabs
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(Category.allCases, id: \.self) { cat in
                            Button {
                                withAnimation(.easeInOut(duration: 0.15)) { activeCategory = cat }
                            } label: {
                                Text(cat.label)
                                    .font(.system(size: 12, weight: .black))
                                    .foregroundColor(activeCategory == cat ? .black : .white)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(activeCategory == cat ? NeonTheme.green : NeonTheme.purpleDark)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.black, lineWidth: 3))
                                    .shadow(color: .black.opacity(0.8), radius: 0, x: 0, y: activeCategory == cat ? 4 : 3)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.bottom, 12)

                // Items grid
                ScrollView(showsIndicators: false) {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                        ForEach(items[activeCategory] ?? [], id: \.id) { item in
                            ItemCardView(
                                item: item,
                                category: activeCategory,
                                isSelected: currentSelection == item.id,
                                draft: draft,
                                onSelect: { select(item.id) }
                            )
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 120)
                }

                Spacer(minLength: 0)
            }

            // Save button — pinned to bottom
            VStack {
                Spacer()
                VStack {
                    Button {
                        appState.updateCustomization(draft)
                        onDismiss()
                    } label: {
                        ZStack {
                            RoundedRectangle(cornerRadius: 14)
                                .fill(NeonTheme.green)
                                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.black, lineWidth: 4))
                                .shadow(color: .black.opacity(0.8), radius: 0, x: 0, y: 6)
                            Text("SAVE & EQUIP")
                                .font(.system(size: 18, weight: .black))
                                .foregroundColor(.black)
                        }
                        .frame(height: 56)
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 20)
                }
                .padding(.vertical, 12)
                .background(
                    LinearGradient(
                        colors: [Color(hex: "1a0040"), Color.clear],
                        startPoint: .bottom, endPoint: .top
                    )
                )
            }
        }
        .onAppear { draft = appState.customization }
    }

    private var currentSelection: String {
        switch activeCategory {
        case .hats:         return draft.hat
        case .glasses:      return draft.glasses
        case .expressions:  return draft.expression
        case .skins:        return draft.skin
        case .effects:      return draft.effect
        case .accessories:  return draft.accessory
        }
    }

    private func select(_ id: String) {
        switch activeCategory {
        case .hats:         draft.hat = id
        case .glasses:      draft.glasses = id
        case .expressions:  draft.expression = id
        case .skins:        draft.skin = id
        case .effects:      draft.effect = id
        case .accessories:  draft.accessory = id
        }
    }
}

// MARK: - Item Card View

struct ItemCardView: View {
    let item: (id: String, name: String)
    let category: BrainLabView.Category
    let isSelected: Bool
    let draft: BrainCustomization
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            ZStack {
                if isSelected {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(NeonTheme.green.opacity(0.3))
                        .blur(radius: 8)
                        .padding(-4)
                }

                VStack(spacing: 6) {
                    // Preview
                    ZStack {
                        Color.clear.frame(height: 48)
                        itemPreview
                    }

                    Text(item.name.uppercased())
                        .font(.system(size: 9, weight: .black))
                        .foregroundColor(isSelected ? .black : .white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)

                    Text(isSelected ? "EQUIPPED" : "TAP TO USE")
                        .font(.system(size: 7, weight: .black))
                        .foregroundColor(isSelected ? .black.opacity(0.7) : .white.opacity(0.6))
                }
                .padding(10)
                .background(isSelected ? NeonTheme.green : NeonTheme.purpleMid)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.black, lineWidth: 3))
                .shadow(color: .black.opacity(0.8), radius: 0, x: 0, y: 4)
            }
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var itemPreview: some View {
        if item.id == "none" {
            Text("—").font(.system(size: 22)).foregroundColor(.white)
        } else {
            switch category {
            case .skins:
                Circle()
                    .fill(skinColor(for: item.id))
                    .frame(width: 28, height: 28)
                    .overlay(Circle().stroke(Color.black, lineWidth: 2))
            case .expressions:
                BrainCharacterView(
                    customization: { var c = BrainCustomization(); c.expression = item.id; return c }(),
                    rotLevel: 20, size: 40, showArms: false, animated: false
                )
            case .effects:
                Text(effectEmoji(item.id))
                    .font(.system(size: 28))
            case .accessories:
                Text(accessoryEmoji(item.id))
                    .font(.system(size: 28))
            case .hats:
                HatOverlayView(hatId: item.id, size: 52)
            case .glasses:
                // Mini glasses representation
                Image(systemName: "eyeglasses")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
            }
        }
    }

    private func effectEmoji(_ id: String) -> String {
        switch id {
        case "purple-aura": return "💜"
        case "green-flame": return "🔥"
        case "electric":    return "⚡"
        case "particles":   return "✨"
        case "glitch":      return "📺"
        default: return "❓"
        }
    }

    private func accessoryEmoji(_ id: String) -> String {
        switch id {
        case "spoon":   return "🥄"
        case "lighter": return "🔥"
        case "sword":   return "⚔️"
        case "shield":  return "🛡️"
        default: return "❓"
        }
    }
}
