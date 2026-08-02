import Foundation

struct GameState: Codable, Equatable {
    var heat: Double
    var heatUpdatedAt: Date
    var lastPedometerProcessedAt: Date
    var woodInventory: [String: Int]
    var burningFuels: [BurningFuel]
    var stepProgress: StepProgress
    var totalStepsAllTime: Int
    var firstLaunchedAt: Date
    var onboardingCompleted: Bool
    var unlockedWoodIDs: Set<String>
    var unlockedFlameIDs: Set<String>
    var unlockedBackgroundIDs: Set<String>
    var selectedWoodID: String
    var selectedFlameID: String
    var selectedBackgroundID: String

    private enum CodingKeys: String, CodingKey {
        case heat
        case heatUpdatedAt
        case lastPedometerProcessedAt
        case woodInventory
        case burningFuels
        case stepProgress
        case totalStepsAllTime
        case firstLaunchedAt
        case onboardingCompleted
        case unlockedWoodIDs
        case unlockedFlameIDs
        case unlockedBackgroundIDs
        case selectedWoodID
        case selectedFlameID
        case selectedBackgroundID
    }

    init(
        heat: Double,
        heatUpdatedAt: Date,
        lastPedometerProcessedAt: Date,
        woodInventory: [String: Int],
        burningFuels: [BurningFuel] = [],
        stepProgress: StepProgress = .empty,
        totalStepsAllTime: Int,
        firstLaunchedAt: Date,
        onboardingCompleted: Bool,
        unlockedWoodIDs: Set<String> = [WoodCatalog.standard.id],
        unlockedFlameIDs: Set<String> = [FlameCatalog.natural.id],
        unlockedBackgroundIDs: Set<String> = [BackgroundCatalog.quietForest.id],
        selectedWoodID: String = WoodCatalog.standard.id,
        selectedFlameID: String = FlameCatalog.natural.id,
        selectedBackgroundID: String = BackgroundCatalog.quietForest.id
    ) {
        self.heat = heat
        self.heatUpdatedAt = heatUpdatedAt
        self.lastPedometerProcessedAt = lastPedometerProcessedAt
        self.woodInventory = woodInventory
        self.burningFuels = burningFuels
        self.stepProgress = stepProgress
        self.totalStepsAllTime = totalStepsAllTime
        self.firstLaunchedAt = firstLaunchedAt
        self.onboardingCompleted = onboardingCompleted
        self.unlockedWoodIDs = unlockedWoodIDs
        self.unlockedFlameIDs = unlockedFlameIDs
        self.unlockedBackgroundIDs = unlockedBackgroundIDs
        self.selectedWoodID = selectedWoodID
        self.selectedFlameID = selectedFlameID
        self.selectedBackgroundID = selectedBackgroundID
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let fallbackDate = Date()
        heat = try container.decodeIfPresent(Double.self, forKey: .heat) ?? GameConstants.initialHeat
        heatUpdatedAt = try container.decodeIfPresent(Date.self, forKey: .heatUpdatedAt) ?? fallbackDate
        lastPedometerProcessedAt = try container.decodeIfPresent(Date.self, forKey: .lastPedometerProcessedAt) ?? fallbackDate
        woodInventory = try container.decodeIfPresent([String: Int].self, forKey: .woodInventory)
            ?? [WoodCatalog.standard.id: GameConstants.starterWoodCount]
        burningFuels = try container.decodeIfPresent([BurningFuel].self, forKey: .burningFuels)
            ?? BurningFuelEngine.migratedQueue(heat: heat, at: heatUpdatedAt)
        stepProgress = try container.decodeIfPresent(StepProgress.self, forKey: .stepProgress) ?? .empty
        totalStepsAllTime = try container.decodeIfPresent(Int.self, forKey: .totalStepsAllTime) ?? 0
        firstLaunchedAt = try container.decodeIfPresent(Date.self, forKey: .firstLaunchedAt) ?? fallbackDate
        onboardingCompleted = try container.decodeIfPresent(Bool.self, forKey: .onboardingCompleted) ?? false
        unlockedWoodIDs = try container.decodeIfPresent(Set<String>.self, forKey: .unlockedWoodIDs) ?? WoodCatalog.unlockedIDs(at: totalStepsAllTime)
        unlockedFlameIDs = try container.decodeIfPresent(Set<String>.self, forKey: .unlockedFlameIDs) ?? FlameCatalog.unlockedIDs(at: totalStepsAllTime)
        unlockedBackgroundIDs = try container.decodeIfPresent(Set<String>.self, forKey: .unlockedBackgroundIDs) ?? BackgroundCatalog.unlockedIDs(at: totalStepsAllTime)
        unlockedWoodIDs.insert(WoodCatalog.standard.id)
        unlockedFlameIDs.insert(FlameCatalog.natural.id)
        unlockedBackgroundIDs.insert(BackgroundCatalog.quietForest.id)
        selectedWoodID = try container.decodeIfPresent(String.self, forKey: .selectedWoodID) ?? WoodCatalog.standard.id
        selectedFlameID = try container.decodeIfPresent(String.self, forKey: .selectedFlameID) ?? FlameCatalog.natural.id
        selectedBackgroundID = try container.decodeIfPresent(String.self, forKey: .selectedBackgroundID) ?? BackgroundCatalog.quietForest.id
    }

    static func initial(at date: Date = Date()) -> GameState {
        GameState(
            heat: GameConstants.initialHeat,
            heatUpdatedAt: date,
            lastPedometerProcessedAt: date,
            woodInventory: [WoodCatalog.standard.id: GameConstants.starterWoodCount],
            burningFuels: BurningFuelEngine.starterQueue(at: date),
            totalStepsAllTime: 0,
            firstLaunchedAt: date,
            onboardingCompleted: false
        )
    }

    var standardWoodCount: Int {
        woodInventory[WoodCatalog.standard.id, default: 0]
    }
}
