import Foundation

enum Rarity: String, Codable, CaseIterable {
    case common
    case uncommon
    case rare
    case legendary
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
}

enum WoodCatalog {
    static let standard = WoodType(
        id: "cedar",
        name: "杉の薪",
        rarity: .common,
        heatValue: GameConstants.standardWoodHeat,
        flameTint: .natural,
        burnDuration: GameConstants.heatHalfLife
    )

    static let all: [WoodType] = [standard]

    static func wood(id: String) -> WoodType? {
        all.first { $0.id == id }
    }
}

