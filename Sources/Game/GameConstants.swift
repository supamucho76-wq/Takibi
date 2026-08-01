import Foundation

enum GameConstants {
    static let minimumHeat = 8.0
    static let maximumHeat = 100.0
    static let initialHeat = 42.0
    static let standardWoodHeat = 12.0
    static let heatHalfLife: TimeInterval = 12 * 60 * 60
    static let stepsPerWood = 100
    static let pedometerHistoryLimit: TimeInterval = 7 * 24 * 60 * 60
    static let starterWoodCount = 3
}

