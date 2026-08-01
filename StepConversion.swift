import Foundation

struct StepConversionResult: Equatable {
    let acceptedSteps: Int
    let awardedWood: Int
    let newTotalSteps: Int
}

enum StepConversion {
    static func convert(
        newSteps: Int,
        previousTotal: Int,
        rate: Int = GameConstants.stepsPerWood
    ) -> StepConversionResult {
        let accepted = max(0, newSteps)
        let safePrevious = max(0, previousTotal)
        guard rate > 0 else {
            return StepConversionResult(
                acceptedSteps: accepted,
                awardedWood: 0,
                newTotalSteps: safePrevious + accepted
            )
        }

        let newTotal = safePrevious + accepted
        let awarded = (newTotal / rate) - (safePrevious / rate)
        return StepConversionResult(
            acceptedSteps: accepted,
            awardedWood: max(0, awarded),
            newTotalSteps: newTotal
        )
    }
}

enum PedometerWindow {
    static func startDate(lastProcessedAt: Date, now: Date) -> Date {
        let historyFloor = now.addingTimeInterval(-GameConstants.pedometerHistoryLimit)
        return min(now, max(lastProcessedAt, historyFloor))
    }
}
