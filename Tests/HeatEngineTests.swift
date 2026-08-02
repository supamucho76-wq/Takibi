import XCTest
@testable import Takibi

final class HeatEngineTests: XCTestCase {
    func testHeatHalvesAfterTwelveHours() {
        let start = Date(timeIntervalSince1970: 1_000)
        let result = HeatEngine.decayedHeat(
            from: 80,
            updatedAt: start,
            now: start.addingTimeInterval(12 * 60 * 60)
        )
        XCTAssertEqual(result, 40, accuracy: 0.0001)
    }

    func testHeatNeverFallsBelowEmberFloor() {
        let start = Date(timeIntervalSince1970: 1_000)
        let result = HeatEngine.decayedHeat(
            from: 100,
            updatedAt: start,
            now: start.addingTimeInterval(365 * 24 * 60 * 60)
        )
        XCTAssertEqual(result, GameConstants.minimumHeat)
    }

    func testAddingWoodCapsHeatAtMaximum() {
        XCTAssertEqual(HeatEngine.adding(12, to: 95), 100)
    }

    func testClockMovingBackwardDoesNotChangeHeat() {
        let now = Date(timeIntervalSince1970: 1_000)
        XCTAssertEqual(
            HeatEngine.decayedHeat(from: 50, updatedAt: now, now: now.addingTimeInterval(-100)),
            50
        )
    }

    func testVisualStagesChangeAcrossHeatRanges() {
        XCTAssertEqual(FireVisualState(heat: 8).stage, .fading)
        XCTAssertEqual(FireVisualState(heat: 30).stage, .small)
        XCTAssertEqual(FireVisualState(heat: 55).stage, .steady)
        XCTAssertEqual(FireVisualState(heat: 78).stage, .bonfire)
        XCTAssertEqual(FireVisualState(heat: 95).stage, .festival)
    }
}

