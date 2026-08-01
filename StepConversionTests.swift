import XCTest
@testable import Takibi

final class StepConversionTests: XCTestCase {
    func testCrossingHundredStepBoundaryAwardsWood() {
        let result = StepConversion.convert(newSteps: 2, previousTotal: 99)
        XCTAssertEqual(result.awardedWood, 1)
        XCTAssertEqual(result.newTotalSteps, 101)
    }

    func testRemainderCarriesAcrossUpdates() {
        let first = StepConversion.convert(newSteps: 60, previousTotal: 0)
        let second = StepConversion.convert(newSteps: 40, previousTotal: first.newTotalSteps)
        XCTAssertEqual(first.awardedWood, 0)
        XCTAssertEqual(second.awardedWood, 1)
    }

    func testMultipleRewardsCanBeAwardedAtOnce() {
        let result = StepConversion.convert(newSteps: 350, previousTotal: 80)
        XCTAssertEqual(result.awardedWood, 4)
        XCTAssertEqual(result.newTotalSteps, 430)
    }

    func testNegativeStepsAreIgnored() {
        let result = StepConversion.convert(newSteps: -20, previousTotal: 90)
        XCTAssertEqual(result.acceptedSteps, 0)
        XCTAssertEqual(result.awardedWood, 0)
        XCTAssertEqual(result.newTotalSteps, 90)
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
