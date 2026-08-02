import XCTest
@testable import Takibi

final class ProgressionCatalogTests: XCTestCase {
    func testEachCollectionContainsTenItems() {
        XCTAssertEqual(WoodCatalog.all.count, 10)
        XCTAssertEqual(FlameCatalog.all.count, 10)
        XCTAssertEqual(BackgroundCatalog.all.count, 10)
    }

    func testCrossingMilestonesReturnsEveryNewReward() {
        let rewards = ProgressionCatalog.newlyUnlocked(from: 900, to: 2_100)
        XCTAssertEqual(Set(rewards.map(\.name)), Set(["琥珀火", "月影の森", "樫炭"]))
    }

    func testNextRewardPointsBeyondCurrentProgress() {
        let reward = ProgressionCatalog.nextReward(after: 1_500)
        XCTAssertEqual(reward?.name, "樫炭")
        XCTAssertEqual(reward?.unlockSteps, 2_000)
    }

    func testEveryFuelHasADifferentPhysicalSilhouette() {
        XCTAssertEqual(Set(WoodCatalog.all.map(\.visualKind)).count, 10)
    }
}
