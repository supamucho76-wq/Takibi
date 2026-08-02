import Foundation

enum Rarity: String, Codable, CaseIterable {
    case common
    case uncommon
    case rare
    case epic
    case legendary

    var title: String {
        switch self {
        case .common: "通常"
        case .uncommon: "上質"
        case .rare: "レア"
        case .epic: "極上"
        case .legendary: "伝説"
        }
    }
}

struct FlameTint: Codable, Equatable {
    let red: Double
    let green: Double
    let blue: Double

    static let natural = FlameTint(red: 1.0, green: 0.48, blue: 0.12)
}

struct WoodType: Codable, Identifiable, Equatable {
    let id: String
    let name: String
    let rarity: Rarity
    let heatValue: Double
    let flameTint: FlameTint
    let burnDuration: Double
    let unlockSteps: Int
    let barkTint: FlameTint
    let weight: Double
}

enum WoodCatalog {
    static let standard = WoodType(
        id: "cedar",
        name: "杉の薪",
        rarity: .common,
        heatValue: GameConstants.standardWoodHeat,
        flameTint: .natural,
        burnDuration: GameConstants.heatHalfLife,
        unlockSteps: 0,
        barkTint: FlameTint(red: 0.56, green: 0.26, blue: 0.09),
        weight: 1.0
    )

    static let all: [WoodType] = [
        standard,
        WoodType(id: "oak", name: "樫の薪", rarity: .uncommon, heatValue: 15, flameTint: .natural, burnDuration: GameConstants.heatHalfLife * 1.12, unlockSteps: 2_000, barkTint: FlameTint(red: 0.40, green: 0.21, blue: 0.08), weight: 1.22),
        WoodType(id: "birch", name: "白樺の薪", rarity: .uncommon, heatValue: 14, flameTint: FlameTint(red: 1.0, green: 0.66, blue: 0.24), burnDuration: GameConstants.heatHalfLife, unlockSteps: 4_000, barkTint: FlameTint(red: 0.88, green: 0.82, blue: 0.68), weight: 0.86),
        WoodType(id: "cherry", name: "桜の薪", rarity: .rare, heatValue: 17, flameTint: FlameTint(red: 1.0, green: 0.35, blue: 0.42), burnDuration: GameConstants.heatHalfLife * 1.18, unlockSteps: 6_500, barkTint: FlameTint(red: 0.52, green: 0.20, blue: 0.18), weight: 0.96),
        WoodType(id: "maple", name: "楓の薪", rarity: .rare, heatValue: 18, flameTint: FlameTint(red: 1.0, green: 0.22, blue: 0.05), burnDuration: GameConstants.heatHalfLife * 1.22, unlockSteps: 9_000, barkTint: FlameTint(red: 0.68, green: 0.18, blue: 0.05), weight: 1.02),
        WoodType(id: "walnut", name: "胡桃の薪", rarity: .rare, heatValue: 19, flameTint: FlameTint(red: 0.82, green: 0.38, blue: 0.10), burnDuration: GameConstants.heatHalfLife * 1.30, unlockSteps: 12_000, barkTint: FlameTint(red: 0.26, green: 0.12, blue: 0.06), weight: 1.15),
        WoodType(id: "olive", name: "聖樹の薪", rarity: .epic, heatValue: 21, flameTint: FlameTint(red: 0.42, green: 1.0, blue: 0.35), burnDuration: GameConstants.heatHalfLife * 1.36, unlockSteps: 16_000, barkTint: FlameTint(red: 0.36, green: 0.42, blue: 0.12), weight: 1.04),
        WoodType(id: "ironwood", name: "鉄木の薪", rarity: .epic, heatValue: 23, flameTint: FlameTint(red: 0.28, green: 0.62, blue: 1.0), burnDuration: GameConstants.heatHalfLife * 1.48, unlockSteps: 21_000, barkTint: FlameTint(red: 0.16, green: 0.21, blue: 0.25), weight: 1.48),
        WoodType(id: "dragonwood", name: "竜鱗の薪", rarity: .legendary, heatValue: 27, flameTint: FlameTint(red: 0.72, green: 0.22, blue: 1.0), burnDuration: GameConstants.heatHalfLife * 1.62, unlockSteps: 28_000, barkTint: FlameTint(red: 0.34, green: 0.06, blue: 0.12), weight: 1.30),
        WoodType(id: "starwood", name: "星屑の薪", rarity: .legendary, heatValue: 32, flameTint: FlameTint(red: 0.55, green: 0.92, blue: 1.0), burnDuration: GameConstants.heatHalfLife * 1.85, unlockSteps: 36_000, barkTint: FlameTint(red: 0.16, green: 0.22, blue: 0.48), weight: 0.78)
    ]

    static func wood(id: String) -> WoodType? {
        all.first { $0.id == id }
    }

    static func unlockedIDs(at steps: Int) -> Set<String> {
        Set(all.filter { steps >= $0.unlockSteps }.map(\.id))
    }
}

