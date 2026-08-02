import Foundation

struct StepRewardResult: Equatable {
    let smallRewardCount: Int
    let fireSparkCount: Int
}

enum StepRewardEngine {
    static let smallRewardInterval = 100
    static let sparksPerReward = 5

    static func evaluate(from oldTotal: Int, to newTotal: Int) -> StepRewardResult {
        let safeOld = max(0, oldTotal)
        let safeNew = max(safeOld, newTotal)
        let rewards = max(0, safeNew / smallRewardInterval - safeOld / smallRewardInterval)
        return StepRewardResult(
            smallRewardCount: rewards,
            fireSparkCount: rewards * sparksPerReward
        )
    }

    static func nextTarget(
        totalSteps: Int,
        woodInterval: Int = GameConstants.stepsPerWood
    ) -> StepRewardTarget {
        let safeSteps = max(0, totalSteps)
        let nextSmall = nextBoundary(after: safeSteps, interval: smallRewardInterval)
        let nextWood = nextBoundary(after: safeSteps, interval: woodInterval)
        let isWood = nextWood <= nextSmall
        let boundary = isWood ? nextWood : nextSmall
        let previousBoundary = isWood ? boundary - woodInterval : boundary - smallRewardInterval
        let interval = max(1, boundary - previousBoundary)
        let progress = min(max(Double(safeSteps - previousBoundary) / Double(interval), 0), 1)
        return StepRewardTarget(
            kind: isWood ? .wood : .fireSparks,
            boundary: boundary,
            remainingSteps: max(0, boundary - safeSteps),
            progress: progress
        )
    }

    private static func nextBoundary(after steps: Int, interval: Int) -> Int {
        guard interval > 0 else { return steps }
        return (steps / interval + 1) * interval
    }
}
