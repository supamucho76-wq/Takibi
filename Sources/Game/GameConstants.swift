import Foundation

enum GameConstants {
    static let minimumHeat = 8.0
    static let maximumHeat = 100.0
    static let initialHeat = 42.0
    static let standardWoodHeat = 12.0
    static let heatHalfLife: TimeInterval = 12 * 60 * 60
    // A standard log visibly lasts one third of a day. Three logs therefore
    // make a full-day fire, and each disappearance has a clear meaning.
    static let standardWoodBurnDuration: TimeInterval = 8 * 60 * 60
    // Five minutes of walking should feel like an intentional trip, not a few
    // laps around the desk. Rare collectibles provide the shorter milestones.
    static let stepsPerWood = 1_000
    static let pedometerHistoryLimit: TimeInterval = 7 * 24 * 60 * 60
    static let starterWoodCount = 3
}

