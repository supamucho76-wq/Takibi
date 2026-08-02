import XCTest
@testable import Takibi

final class BurningFuelTests: XCTestCase {
    func testStarterFireContainsThreeSequentialLogsForOneDay() {
        let start = Date(timeIntervalSince1970: 1_000)
        let queue = BurningFuelEngine.starterQueue(at: start)

        XCTAssertEqual(queue.count, 3)
        XCTAssertEqual(
            queue[0].expiresAt.timeIntervalSince(start),
            GameConstants.standardWoodBurnDuration,
            accuracy: 0.001
        )
        XCTAssertEqual(
            queue[2].expiresAt.timeIntervalSince(start),
            GameConstants.standardWoodBurnDuration * 3,
            accuracy: 0.001
        )
    }

    func testExpiredLogsDisappearOneAtATime() {
        let start = Date(timeIntervalSince1970: 1_000)
        let queue = BurningFuelEngine.starterQueue(at: start)
        let afterFirstLog = start.addingTimeInterval(GameConstants.standardWoodBurnDuration + 1)

        XCTAssertEqual(BurningFuelEngine.active(queue, at: afterFirstLog).count, 2)
    }

    func testNewFuelExtendsTheEndOfTheExistingQueue() {
        let start = Date(timeIntervalSince1970: 1_000)
        let queue = BurningFuelEngine.starterQueue(at: start)
        let charcoal = try! XCTUnwrap(WoodCatalog.wood(id: "oak"))
        let updated = BurningFuelEngine.adding(
            charcoal,
            to: queue,
            at: start,
            placement: BurningFuelPlacement(horizontal: 0, vertical: 0, rotationDegrees: 0, scale: 1)
        )

        let addedFuel = try! XCTUnwrap(updated.last)
        XCTAssertEqual(updated.count, 4)
        XCTAssertEqual(addedFuel.woodID, charcoal.id)
        XCTAssertEqual(
            addedFuel.expiresAt.timeIntervalSince(queue.last!.expiresAt),
            charcoal.burnDuration,
            accuracy: 0.001
        )
    }

    func testOneVisibleLogProducesLessVisualHeatThanThree() {
        let start = Date(timeIntervalSince1970: 1_000)
        let threeLogs = BurningFuelEngine.starterQueue(at: start)
        let oneLog = [threeLogs[2]]

        let oneLogHeat = BurningFuelEngine.visualHeat(storedHeat: 60, fuels: oneLog, at: start)
        let threeLogHeat = BurningFuelEngine.visualHeat(storedHeat: 60, fuels: threeLogs, at: start)

        XCTAssertLessThan(oneLogHeat, threeLogHeat)
    }

    func testSelectedFuelSurvivesSaveWithZeroInventory() throws {
        let start = Date(timeIntervalSince1970: 1_000)
        let charcoal = try XCTUnwrap(WoodCatalog.wood(id: "oak"))
        let state = GameState(
            heat: 40,
            heatUpdatedAt: start,
            lastPedometerProcessedAt: start,
            woodInventory: [charcoal.id: 0],
            burningFuels: [],
            totalStepsAllTime: charcoal.unlockSteps,
            firstLaunchedAt: start,
            onboardingCompleted: true,
            unlockedWoodIDs: [WoodCatalog.standard.id, charcoal.id],
            selectedWoodID: charcoal.id
        )

        let restored = try JSONDecoder().decode(GameState.self, from: JSONEncoder().encode(state))
        XCTAssertEqual(restored.selectedWoodID, charcoal.id)
        XCTAssertEqual(restored.woodInventory[charcoal.id], 0)
    }
}
