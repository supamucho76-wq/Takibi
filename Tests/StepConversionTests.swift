import XCTest
@testable import Takibi

final class StepConversionTests: XCTestCase {
    func testCrossingThousandStepBoundaryAwardsWood() {
        let result = StepConversion.convert(newSteps: 2, previousTotal: 999)
        XCTAssertEqual(result.awardedWood, 1)
        XCTAssertEqual(result.newTotalSteps, 1_001)
    }

    func testRemainderCarriesAcrossUpdates() {
        let first = StepConversion.convert(newSteps: 600, previousTotal: 0)
        let second = StepConversion.convert(newSteps: 400, previousTotal: first.newTotalSteps)
        XCTAssertEqual(first.awardedWood, 0)
        XCTAssertEqual(second.awardedWood, 1)
    }

    func testMultipleRewardsCanBeAwardedAtOnce() {
        let result = StepConversion.convert(newSteps: 2_350, previousTotal: 980)
        XCTAssertEqual(result.awardedWood, 3)
        XCTAssertEqual(result.newTotalSteps, 3_330)
    }

    func testNegativeStepsAreIgnored() {
        let result = StepConversion.convert(newSteps: -20, previousTotal: 990)
        XCTAssertEqual(result.acceptedSteps, 0)
        XCTAssertEqual(result.awardedWood, 0)
        XCTAssertEqual(result.newTotalSteps, 990)
    }

    func testPedometerWindowIsLimitedToSevenDays() {
        let now = Date(timeIntervalSince1970: 2_000_000)
        let oldDate = now.addingTimeInterval(-30 * 24 * 60 * 60)
        let start = PedometerWindow.startDate(lastProcessedAt: oldDate, now: now)
        XCTAssertEqual(now.timeIntervalSince(start), GameConstants.pedometerHistoryLimit, accuracy: 0.001)
    }

    func testPedometerWindowRejectsFutureCursor() {
        let now = Date(timeIntervalSince1970: 2_000_000)
        let start = PedometerWindow.startDate(
            lastProcessedAt: now.addingTimeInterval(600),
            now: now
        )
        XCTAssertEqual(start, now)
    }
}
