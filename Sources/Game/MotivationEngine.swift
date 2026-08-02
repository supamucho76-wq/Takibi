import Foundation

enum MotivationEngine {
    static let livelyFlameThreshold = 20.0
    static let comfortableWalkingCadence = 100.0

    static func stepsUntilNextWood(
        totalSteps: Int,
        rate: Int = GameConstants.stepsPerWood
    ) -> Int {
        guard rate > 0 else { return 0 }
        let safeSteps = max(0, totalSteps)
        let remainder = safeSteps % rate
        return remainder == 0 ? rate : rate - remainder
    }

    static func nextWoodProgress(
        totalSteps: Int,
        rate: Int = GameConstants.stepsPerWood
    ) -> Double {
        guard rate > 0 else { return 0 }
        let remainder = max(0, totalSteps) % rate
        return Double(remainder) / Double(rate)
    }

    static func estimatedWalkingMinutes(for steps: Int) -> Int {
        max(1, Int(ceil(Double(max(0, steps)) / comfortableWalkingCadence)))
    }

    static func hoursUntilFlameWeakens(
        heat: Double,
        threshold: Double = livelyFlameThreshold,
        halfLife: TimeInterval = GameConstants.heatHalfLife
    ) -> Double {
        guard heat > threshold, threshold > 0, halfLife > 0 else { return 0 }
        let seconds = halfLife * log2(heat / threshold)
        return max(0, seconds / 3_600)
    }
}
