import Foundation

enum GameConstants {
    static let minimumHeat = 8.0
    static let maximumHeat = 100.0
    static let initialHeat = 42.0
    static let standardWoodHeat = 12.0
    static let heatHalfLife: TimeInterval = 12 * 60 * 60
    // Five minutes of walking should feel like an intentional trip, not a few
    // laps around the desk. Rare collectibles provide the shorter milestones.
    static let stepsPerWood = 500
    static let pedometerHistoryLimit: TimeInterval = 7 * 24 * 60 * 60
    static let starterWoodCount = 3
}

