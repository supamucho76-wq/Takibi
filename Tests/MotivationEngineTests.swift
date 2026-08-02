import XCTest
@testable import Takibi

final class MotivationEngineTests: XCTestCase {
    func testNextWoodMissionUsesCurrentThousandStepBlock() {
        XCTAssertEqual(MotivationEngine.stepsUntilNextWood(totalSteps: 209), 791)
        XCTAssertEqual(MotivationEngine.nextWoodProgress(totalSteps: 209), 0.209, accuracy: 0.0001)
    }

    func testExactBoundaryStartsTheNextMission() {
        XCTAssertEqual(MotivationEngine.stepsUntilNextWood(totalSteps: 1_000), 1_000)
        XCTAssertEqual(MotivationEngine.nextWoodProgress(totalSteps: 1_000), 0, accuracy: 0.0001)
    }

    func testWalkingEstimateNeverShowsZeroMinutes() {
        XCTAssertEqual(MotivationEngine.estimatedWalkingMinutes(for: 0), 1)
        XCTAssertEqual(MotivationEngine.estimatedWalkingMinutes(for: 91), 1)
        XCTAssertEqual(MotivationEngine.estimatedWalkingMinutes(for: 101), 2)
    }

    func testFlameLifetimeUsesHeatHalfLife() {
        XCTAssertEqual(MotivationEngine.hoursUntilFlameWeakens(heat: 80), 24, accuracy: 0.0001)
        XCTAssertEqual(MotivationEngine.hoursUntilFlameWeakens(heat: 20), 0, accuracy: 0.0001)
    }
}
