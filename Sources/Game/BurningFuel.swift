import Foundation

struct BurningFuelPlacement: Codable, Equatable {
    let horizontal: Double
    let vertical: Double
    let rotationDegrees: Double
    let scale: Double

    static func random() -> BurningFuelPlacement {
        BurningFuelPlacement(
            horizontal: Double.random(in: -0.34 ... 0.34),
            vertical: Double.random(in: -0.20 ... 0.20),
            rotationDegrees: Double.random(in: -34 ... 34),
            scale: Double.random(in: 0.88 ... 1.06)
        )
    }
}

struct BurningFuel: Codable, Equatable, Identifiable {
    let id: UUID
    let woodID: String
    let ignitedAt: Date
    let expiresAt: Date
    let placement: BurningFuelPlacement

    init(
        id: UUID = UUID(),
        woodID: String,
        ignitedAt: Date,
        expiresAt: Date,
        placement: BurningFuelPlacement
    ) {
        self.id = id
        self.woodID = woodID
        self.ignitedAt = ignitedAt
        self.expiresAt = expiresAt
        self.placement = placement
    }

    func remainingFraction(at date: Date) -> Double {
        let duration = expiresAt.timeIntervalSince(ignitedAt)
        guard duration > 0 else { return 0 }
        return min(max(expiresAt.timeIntervalSince(date) / duration, 0), 1)
    }
}

enum BurningFuelEngine {
    static func active(_ fuels: [BurningFuel], at date: Date) -> [BurningFuel] {
        fuels
            .filter { $0.expiresAt > date }
            .sorted { $0.expiresAt < $1.expiresAt }
    }

    static func adding(
        _ wood: WoodType,
        to fuels: [BurningFuel],
        at date: Date,
        placement: BurningFuelPlacement = .random()
    ) -> [BurningFuel] {
        var queue = active(fuels, at: date)
        let queueEnd = queue.map(\.expiresAt).max() ?? date
        let expiresAt = queueEnd.addingTimeInterval(wood.burnDuration)
        queue.append(
            BurningFuel(
                woodID: wood.id,
                ignitedAt: date,
                expiresAt: expiresAt,
                placement: placement
            )
        )
        return queue
    }

    static func starterQueue(at date: Date) -> [BurningFuel] {
        let placements = [
            BurningFuelPlacement(horizontal: -0.18, vertical: 0.10, rotationDegrees: -19, scale: 0.96),
            BurningFuelPlacement(horizontal: 0.20, vertical: 0.04, rotationDegrees: 18, scale: 0.93),
            BurningFuelPlacement(horizontal: 0.01, vertical: -0.16, rotationDegrees: -4, scale: 1.02),
        ]
        let duration = WoodCatalog.standard.burnDuration
        return placements.enumerated().map { index, placement in
            BurningFuel(
                woodID: WoodCatalog.standard.id,
                ignitedAt: date,
                expiresAt: date.addingTimeInterval(duration * Double(index + 1)),
                placement: placement
            )
        }
    }

    static func migratedQueue(heat: Double, at date: Date) -> [BurningFuel] {
        guard heat > GameConstants.minimumHeat * 1.15 else { return [] }
        return starterQueue(at: date)
    }

    static func visualHeat(
        storedHeat: Double,
        fuels: [BurningFuel],
        at date: Date
    ) -> Double {
        let count = active(fuels, at: date).count
        guard count > 0 else {
            return min(storedHeat, GameConstants.minimumHeat + 4)
        }
        let countMultiplier = min(1.18, 0.62 + Double(count) * 0.13)
        let visibleFuelFloor = min(
            GameConstants.maximumHeat,
            12 + Double(count) * 16
        )
        return min(
            GameConstants.maximumHeat,
            max(visibleFuelFloor, storedHeat * countMultiplier)
        )
    }
}
