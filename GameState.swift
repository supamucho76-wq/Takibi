import Foundation

struct GameState: Codable, Equatable {
    var heat: Double
    var heatUpdatedAt: Date
    var lastPedometerProcessedAt: Date
    var woodInventory: [String: Int]
    var totalStepsAllTime: Int
    var firstLaunchedAt: Date
    var onboardingCompleted: Bool

    private enum CodingKeys: String, CodingKey {
        case heat
        case heatUpdatedAt
        case lastPedometerProcessedAt
        case woodInventory
        case totalStepsAllTime
        case firstLaunchedAt
        case onboardingCompleted
    }

    init(
        heat: Double,
        heatUpdatedAt: Date,
        lastPedometerProcessedAt: Date,
        woodInventory: [String: Int],
        totalStepsAllTime: Int,
        firstLaunchedAt: Date,
        onboardingCompleted: Bool
    ) {
        self.heat = heat
        self.heatUpdatedAt = heatUpdatedAt
        self.lastPedometerProcessedAt = lastPedometerProcessedAt
        self.woodInventory = woodInventory
        self.totalStepsAllTime = totalStepsAllTime
        self.firstLaunchedAt = firstLaunchedAt
        self.onboardingCompleted = onboardingCompleted
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let fallbackDate = Date()
        heat = try container.decodeIfPresent(Double.self, forKey: .heat) ?? GameConstants.initialHeat
        heatUpdatedAt = try container.decodeIfPresent(Date.self, forKey: .heatUpdatedAt) ?? fallbackDate
        lastPedometerProcessedAt = try container.decodeIfPresent(Date.self, forKey: .lastPedometerProcessedAt) ?? fallbackDate
        woodInventory = try container.decodeIfPresent([String: Int].self, forKey: .woodInventory)
            ?? [WoodCatalog.standard.id: GameConstants.starterWoodCount]
        totalStepsAllTime = try container.decodeIfPresent(Int.self, forKey: .totalStepsAllTime) ?? 0
        firstLaunchedAt = try container.decodeIfPresent(Date.self, forKey: .firstLaunchedAt) ?? fallbackDate
        onboardingCompleted = try container.decodeIfPresent(Bool.self, forKey: .onboardingCompleted) ?? false
    }

    static func initial(at date: Date = Date()) -> GameState {
        GameState(
            heat: GameConstants.initialHeat,
            heatUpdatedAt: date,
            lastPedometerProcessedAt: date,
            woodInventory: [WoodCatalog.standard.id: GameConstants.starterWoodCount],
            totalStepsAllTime: 0,
            firstLaunchedAt: date,
            onboardingCompleted: false
        )
    }

    var standardWoodCount: Int {
        woodInventory[WoodCatalog.standard.id, default: 0]
    }
}
