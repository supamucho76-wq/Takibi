import XCTest
@testable import Takibi

final class StepRewardEngineTests: XCTestCase {
    func testCrossingSmallRewardBoundaryAwardsFireSparks() {
        let result = StepRewardEngine.evaluate(from: 90, to: 110)

        XCTAssertEqual(result.smallRewardCount, 1)
        XCTAssertEqual(result.fireSparkCount, 5)
    }

    func testMultipleSmallRewardsCanArriveTogether() {
        let result = StepRewardEngine.evaluate(from: 40, to: 360)

        XCTAssertEqual(result.smallRewardCount, 3)
        XCTAssertEqual(result.fireSparkCount, 15)
    }

    func testBackwardStepCountDoesNotAwardAnything() {
        let result = StepRewardEngine.evaluate(from: 250, to: 120)

        XCTAssertEqual(result.smallRewardCount, 0)
        XCTAssertEqual(result.fireSparkCount, 0)
    }

    func testWoodIsShownWhenNextBoundaryMatchesSmallReward() {
        let target = StepRewardEngine.nextTarget(totalSteps: 450, woodInterval: 500)

        XCTAssertEqual(target.kind, .wood)
        XCTAssertEqual(target.remainingSteps, 50)
        XCTAssertEqual(target.progress, 0.9, accuracy: 0.0001)
    }
}
