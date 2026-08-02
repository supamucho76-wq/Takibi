import Foundation

struct FlameStyle: Identifiable, Equatable {
    let id: String
    let name: String
    let rarity: Rarity
    let tint: FlameTint
    let unlockSteps: Int
}

enum FlameCatalog {
    static let natural = FlameStyle(id: "natural", name: "原初の炎", rarity: .common, tint: .natural, unlockSteps: 0)

    static let all: [FlameStyle] = [
        natural,
        FlameStyle(id: "amber", name: "琥珀火", rarity: .uncommon, tint: FlameTint(red: 1.0, green: 0.66, blue: 0.15), unlockSteps: 1_000),
        FlameStyle(id: "blue", name: "蒼炎", rarity: .rare, tint: FlameTint(red: 0.22, green: 0.58, blue: 1.0), unlockSteps: 3_000),
        FlameStyle(id: "emerald", name: "翠炎", rarity: .rare, tint: FlameTint(red: 0.20, green: 1.0, blue: 0.46), unlockSteps: 5_500),
        FlameStyle(id: "violet", name: "紫幻火", rarity: .rare, tint: FlameTint(red: 0.68, green: 0.24, blue: 1.0), unlockSteps: 8_000),
        FlameStyle(id: "sakura", name: "桜花火", rarity: .epic, tint: FlameTint(red: 1.0, green: 0.30, blue: 0.62), unlockSteps: 11_000),
        FlameStyle(id: "ice", name: "氷晶火", rarity: .epic, tint: FlameTint(red: 0.46, green: 0.92, blue: 1.0), unlockSteps: 15_000),
        FlameStyle(id: "gold", name: "黄金火", rarity: .epic, tint: FlameTint(red: 1.0, green: 0.84, blue: 0.20), unlockSteps: 20_000),
        FlameStyle(id: "aurora", name: "極光炎", rarity: .legendary, tint: FlameTint(red: 0.24, green: 1.0, blue: 0.78), unlockSteps: 27_000),
        FlameStyle(id: "starlight", name: "星天火", rarity: .legendary, tint: FlameTint(red: 0.72, green: 0.76, blue: 1.0), unlockSteps: 35_000)
    ]

    static func style(id: String) -> FlameStyle? { all.first { $0.id == id } }
    static func unlockedIDs(at steps: Int) -> Set<String> { Set(all.filter { steps >= $0.unlockSteps }.map(\.id)) }
}

struct BackgroundTheme: Identifiable, Equatable {
    let id: String
    let name: String
    let rarity: Rarity
    let imageName: String
    let hueDegrees: Double
    let saturation: Double
    let brightness: Double
    let overlayTint: FlameTint
    let unlockSteps: Int
}

enum BackgroundCatalog {
    static let quietForest = BackgroundTheme(id: "quiet", name: "静かな森", rarity: .common, imageName: "CampBackground", hueDegrees: 0, saturation: 1, brightness: 0, overlayTint: FlameTint(red: 0.01, green: 0.03, blue: 0.08), unlockSteps: 0)

    static let all: [BackgroundTheme] = [
        quietForest,
        BackgroundTheme(id: "moon", name: "月影の森", rarity: .uncommon, imageName: "CampBackground", hueDegrees: -18, saturation: 0.78, brightness: 0.03, overlayTint: FlameTint(red: 0.05, green: 0.12, blue: 0.26), unlockSteps: 1_500),
        BackgroundTheme(id: "mist", name: "霧深き森", rarity: .uncommon, imageName: "CampBackground", hueDegrees: 12, saturation: 0.48, brightness: 0.10, overlayTint: FlameTint(red: 0.35, green: 0.42, blue: 0.48), unlockSteps: 3_500),
        BackgroundTheme(id: "bluehour", name: "蒼刻の森", rarity: .rare, imageName: "CampBackground", hueDegrees: -42, saturation: 1.18, brightness: 0.02, overlayTint: FlameTint(red: 0.02, green: 0.16, blue: 0.34), unlockSteps: 6_000),
        BackgroundTheme(id: "deep", name: "古樹の深淵", rarity: .rare, imageName: "CampBackground", hueDegrees: 24, saturation: 0.82, brightness: -0.08, overlayTint: FlameTint(red: 0.02, green: 0.14, blue: 0.07), unlockSteps: 9_000),
        BackgroundTheme(id: "frost", name: "白霜の夜", rarity: .rare, imageName: "CampBackground", hueDegrees: -70, saturation: 0.36, brightness: 0.16, overlayTint: FlameTint(red: 0.28, green: 0.46, blue: 0.62), unlockSteps: 13_000),
        BackgroundTheme(id: "ember", name: "残照の谷", rarity: .epic, imageName: "CampBackground", hueDegrees: 34, saturation: 1.34, brightness: 0.04, overlayTint: FlameTint(red: 0.36, green: 0.06, blue: 0.01), unlockSteps: 18_000),
        BackgroundTheme(id: "sakura", name: "桜霞の森", rarity: .epic, imageName: "CampBackground", hueDegrees: 82, saturation: 0.82, brightness: 0.08, overlayTint: FlameTint(red: 0.30, green: 0.05, blue: 0.16), unlockSteps: 24_000),
        BackgroundTheme(id: "aurora", name: "極光の聖域", rarity: .legendary, imageName: "AuroraBackground", hueDegrees: 0, saturation: 1.08, brightness: 0, overlayTint: FlameTint(red: 0.02, green: 0.20, blue: 0.18), unlockSteps: 30_000),
        BackgroundTheme(id: "cosmos", name: "星界の森", rarity: .legendary, imageName: "AuroraBackground", hueDegrees: 56, saturation: 1.36, brightness: -0.02, overlayTint: FlameTint(red: 0.14, green: 0.02, blue: 0.28), unlockSteps: 40_000)
    ]

    static func theme(id: String) -> BackgroundTheme? { all.first { $0.id == id } }
    static func unlockedIDs(at steps: Int) -> Set<String> { Set(all.filter { steps >= $0.unlockSteps }.map(\.id)) }
}

enum CollectibleKind: String, Equatable {
    case wood = "薪"
    case flame = "炎"
    case background = "背景"
}

struct CollectibleReward: Identifiable, Equatable {
    let id: String
    let name: String
    let kind: CollectibleKind
    let rarity: Rarity
    let unlockSteps: Int
}

enum ProgressionCatalog {
    static var allRewards: [CollectibleReward] {
        let woods = WoodCatalog.all.dropFirst().map { CollectibleReward(id: "wood:\($0.id)", name: $0.name, kind: .wood, rarity: $0.rarity, unlockSteps: $0.unlockSteps) }
        let flames = FlameCatalog.all.dropFirst().map { CollectibleReward(id: "flame:\($0.id)", name: $0.name, kind: .flame, rarity: $0.rarity, unlockSteps: $0.unlockSteps) }
        let backgrounds = BackgroundCatalog.all.dropFirst().map { CollectibleReward(id: "background:\($0.id)", name: $0.name, kind: .background, rarity: $0.rarity, unlockSteps: $0.unlockSteps) }
        return (woods + flames + backgrounds).sorted { lhs, rhs in
            lhs.unlockSteps == rhs.unlockSteps ? lhs.name < rhs.name : lhs.unlockSteps < rhs.unlockSteps
        }
    }

    static func nextReward(after steps: Int) -> CollectibleReward? {
        allRewards.first { $0.unlockSteps > steps }
    }

    static func newlyUnlocked(from oldSteps: Int, to newSteps: Int) -> [CollectibleReward] {
        guard newSteps > oldSteps else { return [] }
        return allRewards.filter { $0.unlockSteps > oldSteps && $0.unlockSteps <= newSteps }
    }
}
