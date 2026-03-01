import SwiftUI

enum MockData {

    static let leaderboardData: [LeaderboardPlayer] = [
        .init(rank: 1,  name: "NeonKing",     score: 10240, badge: "Legend",   rotLevel: 15),
        .init(rank: 2,  name: "PixelWiz",     score: 9875,  badge: "Master",   rotLevel: 18),
        .init(rank: 3,  name: "CyberNinja",   score: 9120,  badge: "Expert",   rotLevel: 22),
        .init(rank: 4,  name: "QuantumGamer", score: 8450,  badge: "Pro",      rotLevel: 25),
        .init(rank: 5,  name: "NeonDreamer",  score: 7980,  badge: "Pro",      rotLevel: 28),
        .init(rank: 6,  name: "DataSurfer",   score: 7640,  badge: "Advanced", rotLevel: 32),
        .init(rank: 7,  name: "CodeMaster",   score: 7320,  badge: "Advanced", rotLevel: 35),
        .init(rank: 8,  name: "FlowState",    score: 6890,  badge: "Advanced", rotLevel: 38),
        .init(rank: 9,  name: "BrainBoss",    score: 6540,  badge: "Skilled",  rotLevel: 42),
        .init(rank: 10, name: "ScrollLord",   score: 6210,  badge: "Skilled",  rotLevel: 45),
    ]

    static let graveyardData: [GraveyardDay] = [
        .init(date: "Today",     rot: 28, streak: 4, flicks: 12, stability: 92),
        .init(date: "Yesterday", rot: 32, streak: 3, flicks: 18, stability: 88),
        .init(date: "Feb 26",    rot: 35, streak: 2, flicks: 10, stability: 94),
        .init(date: "Feb 25",    rot: 58, streak: 1, flicks: 22, stability: 85),
        .init(date: "Feb 24",    rot: 62, streak: 0, flicks: 15, stability: 90),
        .init(date: "Feb 23",    rot: 75, streak: 0, flicks: 28, stability: 78),
    ]

    static let boosts: [Boost] = [
        .init(id: "anchor",     name: "ANCHOR",       category: .control,  rarity: .common,
              focusCost: 2, cooldown: 15,
              description: "Force watch current content for 5 seconds. Builds stability.",
              flavorText: "Sometimes you just need to stay.",
              effect: "+15% stability, prevents skip", owned: true,  equipped: true,  iconType: "anchor"),
        .init(id: "deep-focus", name: "DEEP FOCUS",   category: .control,  rarity: .rare,
              focusCost: 3, cooldown: 20,
              description: "Enter zen mode. Immune to rot gain for 10 seconds.",
              flavorText: "The mind finds its center.",
              effect: "Rot immunity, +20% stability",  owned: true,  equipped: true,  iconType: "zen"),
        .init(id: "brain-blast",name: "BRAIN BLAST",  category: .damage,   rarity: .epic,
              focusCost: 4, cooldown: 25,
              description: "Instant -15% rot. High risk, high reward.",
              flavorText: "Clear the fog, restore the signal.",
              effect: "-15% rot instantly",             owned: true,  equipped: true,  iconType: "blast"),
        .init(id: "time-warp",  name: "TIME WARP",    category: .utility,  rarity: .legendary,
              focusCost: 5, cooldown: 40,
              description: "Rewind 30 seconds. Second chance at choices.",
              flavorText: "Undo the damage of mindless scrolling.",
              effect: "Rewind 30s, restore previous state", owned: true, equipped: true, iconType: "clock"),
        .init(id: "shield",     name: "MIND SHIELD",  category: .defense,  rarity: .common,
              focusCost: 2, cooldown: 18,
              description: "Block next rot spike. One-time protection.",
              flavorText: "Armor for the attention span.",
              effect: "Block next +rot event",          owned: true,  equipped: false, iconType: "shield"),
        .init(id: "insight",    name: "INSIGHT BURST",category: .utility,  rarity: .rare,
              focusCost: 3, cooldown: 30,
              description: "Reveal rot predictions for next minute.",
              flavorText: "See the path ahead.",
              effect: "Show future rot changes",        owned: true,  equipped: false, iconType: "eye"),
        .init(id: "combo-chain",name: "COMBO CHAIN",  category: .damage,   rarity: .epic,
              focusCost: 4, cooldown: 35,
              description: "Each correct answer chains for bonus -rot.",
              flavorText: "Keep the momentum going.",
              effect: "Chain multiplier: 2x, 3x, 5x",  owned: true,  equipped: false, iconType: "chain"),
        .init(id: "reset",      name: "NEURAL RESET", category: .control,  rarity: .legendary,
              focusCost: 6, cooldown: 60,
              description: "Set rot to 25%. Ultimate recovery.",
              flavorText: "Factory reset for the mind.",
              effect: "Set rot = 25%",                  owned: false, equipped: false, iconType: "reset"),
        .init(id: "focus-surge",name: "FOCUS SURGE",  category: .utility,  rarity: .rare,
              focusCost: 2, cooldown: 12,
              description: "Gain +3 focus instantly.",
              flavorText: "Tap into reserve energy.",
              effect: "+3 focus",                       owned: true,  equipped: false, iconType: "energy"),
        .init(id: "freeze",     name: "FREEZE FRAME", category: .control,  rarity: .epic,
              focusCost: 4, cooldown: 28,
              description: "Pause rot decay/growth for 15 seconds.",
              flavorText: "Hold the moment.",
              effect: "Pause all rot changes",          owned: false, equipped: false, iconType: "freeze"),
        .init(id: "reflect",    name: "REFLECT",      category: .defense,  rarity: .rare,
              focusCost: 3, cooldown: 22,
              description: "Mirror opponent rot spike back at them.",
              flavorText: "No u.",
              effect: "Reflect enemy attack",           owned: true,  equipped: false, iconType: "mirror"),
        .init(id: "overdrive",  name: "OVERDRIVE",    category: .damage,   rarity: .legendary,
              focusCost: 5, cooldown: 45,
              description: "Double all rot reduction for 10 seconds.",
              flavorText: "Maximum efficiency mode.",
              effect: "2x rot reduction",               owned: false, equipped: false, iconType: "fire"),
        .init(id: "clarity",    name: "CLARITY PULSE",category: .utility,  rarity: .common,
              focusCost: 2, cooldown: 10,
              description: "Small -5% rot, quick cooldown.",
              flavorText: "Breathe and reset.",
              effect: "-5% rot",                        owned: true,  equipped: false, iconType: "pulse"),
        .init(id: "fortress",   name: "FORTRESS",     category: .defense,  rarity: .epic,
              focusCost: 4, cooldown: 35,
              description: "Halve all incoming rot for 20 seconds.",
              flavorText: "Unbreakable defense.",
              effect: "50% rot damage reduction",       owned: false, equipped: false, iconType: "fortress"),
    ]

    static let currentUser = UserProfile(
        username: "BrainMaster",
        level: 12,
        rank: 12,
        trophies: 1204,
        winRate: 68,
        totalDuels: 127,
        bestStreak: 12,
        bestStability: 98,
        avgRot: 39,
        rankTitle: "ALGORITHM OVERLORD"
    )

    static let defaultOpponent = DuelOpponent(
        name: "SkibidiSlayer99",
        rank: 217,
        rotLevel: 65,
        wins: 42
    )

    static let badges: [PlayerBadge] = [
        .init(name: "First Win",  color: Color(hex: "FFD60A")),
        .init(name: "7 Day",      color: Color(hex: "FF6B35")),
        .init(name: "Speed",      color: Color(hex: "4CC9F0")),
        .init(name: "Top 10",     color: Color(hex: "39FF14")),
        .init(name: "Precision",  color: Color(hex: "F72585")),
        .init(name: "Flawless",   color: Color(hex: "9D4EDD")),
        .init(name: "Rising",     color: Color(hex: "FFD60A")),
        .init(name: "Master",     color: Color(hex: "7B2CBF")),
    ]

    static let brainSkins: [BrainSkin] = [
        .init(name: "Classic", color: Color(hex: "FFB3D1"), owned: true),
        .init(name: "Cyber",   color: Color(hex: "4CC9F0"), owned: true),
        .init(name: "Cosmic",  color: Color(hex: "9D4EDD"), owned: true),
        .init(name: "Inferno", color: Color(hex: "FF6B35"), owned: false),
        .init(name: "Diamond", color: Color(hex: "4895EF"), owned: false),
        .init(name: "Rainbow", color: Color(hex: "FFD60A"), owned: false),
    ]

    static let weeklyRotData: [Int] = [45, 38, 42, 35, 40, 37, 37]

    static let loadingTips: [String] = [
        "Boost your combo to deal massive damage!",
        "Complete quizzes correctly to gain focus faster!",
        "Discovery payouts give instant focus boosts!",
        "Save boosts for critical moments!",
        "Chain videos together for combo multipliers!",
        "Higher rot = stronger attacks but worse defense!",
    ]
}
