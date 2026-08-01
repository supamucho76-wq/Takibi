import Combine
import Foundation
import SwiftUI

@MainActor
final class AppModel: ObservableObject {
    @Published private(set) var state = GameState.initial()
    @Published private(set) var todaySteps = 0
    @Published private(set) var motionPermission: MotionPermissionState = .notDetermined
    @Published private(set) var pedometerMessage: String?
    @Published private(set) var isReady = false
    @Published private(set) var isRenderingActive = true

    private let store: GameStateStore
    private let pedometer: PedometerService
    private var saveTask: Task<Void, Never>?
    private var reconcileTask: Task<Void, Never>?
    private var maintenanceTask: Task<Void, Never>?
    private var liveCommittedSteps = 0
    private var todayBaselineSteps = 0

    init(
        store: GameStateStore = GameStateStore(),
        pedometer: PedometerService = PedometerService()
    ) {
        self.store = store
        self.pedometer = pedometer
        Task { await load() }
    }

    var visualState: FireVisualState {
        FireVisualState(heat: state.heat)
    }

    var standardWoodCount: Int {
        state.standardWoodCount
    }

    func completeOnboarding() {
        state.onboardingCompleted = true
        scheduleSave()
        activatePedometer()
    }

    @discardableResult
    func burnStandardWood(now: Date = Date()) -> Bool {
        applyDecay(now: now)
        let wood = WoodCatalog.standard
        let count = state.woodInventory[wood.id, default: 0]
        guard count > 0 else { return false }

        state.woodInventory[wood.id] = count - 1
        state.heat = HeatEngine.adding(wood.heatValue, to: state.heat)
        state.heatUpdatedAt = now
        scheduleSave()
        return true
    }

    func handleScenePhase(_ phase: ScenePhase) {
        switch phase {
        case .active:
            isRenderingActive = true
            applyDecay()
            startMaintenance()
            if state.onboardingCompleted { activatePedometer() }
        case .inactive:
            break
        case .background:
            isRenderingActive = false
            pedometer.stopUpdates()
            reconcileTask?.cancel()
            maintenanceTask?.cancel()
            Task { await flush() }
        @unknown default:
            break
        }
    }

    func refreshPedometer() {
        activatePedometer()
    }

    #if DEBUG
    func resetAllData() {
        saveTask?.cancel()
        reconcileTask?.cancel()
        pedometer.stopUpdates()
        Task {
            try? await store.reset()
            state = .initial()
            todaySteps = 0
            todayBaselineSteps = 0
            liveCommittedSteps = 0
            pedometerMessage = nil
            motionPermission = pedometer.permissionState
        }
    }
    #endif

    private func load() async {
        state = await store.load()
        motionPermission = pedometer.permissionState
        isReady = true
        startMaintenance()
        if state.onboardingCompleted {
            activatePedometer()
        }
    }

    private func applyDecay(now: Date = Date()) {
        state.heat = HeatEngine.decayedHeat(
            from: state.heat,
            updatedAt: state.heatUpdatedAt,
            now: now
        )
        state.heatUpdatedAt = now
        scheduleSave()
    }

    private func startMaintenance() {
        maintenanceTask?.cancel()
        maintenanceTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 60_000_000_000)
                guard !Task.isCancelled, let self else { return }
                self.applyDecay()
            }
        }
    }

    private func activatePedometer() {
        reconcileTask?.cancel()
        pedometer.stopUpdates()
        motionPermission = pedometer.permissionState

        guard pedometer.isAvailable else {
            motionPermission = .unavailable
            pedometerMessage = "この端末では歩数を取得できません。焚き火は引き続き眺められます。"
            return
        }

        reconcileTask = Task { [weak self] in
            guard let self else { return }
            let now = Date()
            let queryStart = PedometerWindow.startDate(
                lastProcessedAt: self.state.lastPedometerProcessedAt,
                now: now
            )

            do {
                if now.timeIntervalSince(queryStart) > 0.5 {
                    let missed = try await self.pedometer.query(from: queryStart, to: now)
                    guard !Task.isCancelled else { return }
                    self.applySteps(missed.steps, processedAt: missed.endDate)
                } else {
                    self.state.lastPedometerProcessedAt = now
                }

                let startOfDay = Calendar.current.startOfDay(for: now)
                let today = try await self.pedometer.query(from: startOfDay, to: now)
                guard !Task.isCancelled else { return }
                self.todayBaselineSteps = max(0, today.steps)
                self.todaySteps = self.todayBaselineSteps
                self.motionPermission = self.pedometer.permissionState
                self.pedometerMessage = nil
                self.startLiveUpdates(from: now)
            } catch {
                guard !Task.isCancelled else { return }
                self.motionPermission = self.pedometer.permissionState
                self.pedometerMessage = self.message(for: error)
            }
        }
    }

    private func startLiveUpdates(from date: Date) {
        liveCommittedSteps = 0
        pedometer.startUpdates(from: date) { [weak self] result in
            Task { @MainActor in
                guard let self else { return }
                switch result {
                case .success(let sample):
                    let cumulative = max(0, sample.steps)
                    let delta = max(0, cumulative - self.liveCommittedSteps)
                    self.liveCommittedSteps = max(self.liveCommittedSteps, cumulative)
                    self.todaySteps = self.todayBaselineSteps + cumulative
                    self.applySteps(delta, processedAt: sample.endDate)
                    self.motionPermission = self.pedometer.permissionState
                    self.pedometerMessage = nil
                case .failure(let error):
                    self.motionPermission = self.pedometer.permissionState
                    self.pedometerMessage = self.message(for: error)
                }
            }
        }
    }

    private func applySteps(_ steps: Int, processedAt: Date) {
        let result = StepConversion.convert(
            newSteps: steps,
            previousTotal: state.totalStepsAllTime
        )
        state.totalStepsAllTime = result.newTotalSteps
        if result.awardedWood > 0 {
            state.woodInventory[WoodCatalog.standard.id, default: 0] += result.awardedWood
        }
        state.lastPedometerProcessedAt = max(state.lastPedometerProcessedAt, processedAt)
        scheduleSave()
    }

    private func scheduleSave() {
        guard isReady else { return }
        saveTask?.cancel()
        let snapshot = state
        saveTask = Task { [store] in
            try? await Task.sleep(nanoseconds: 350_000_000)
            guard !Task.isCancelled else { return }
            try? await store.save(snapshot)
        }
    }

    private func flush() async {
        saveTask?.cancel()
        try? await store.save(state)
    }

    private func message(for error: Error) -> String {
        if pedometer.permissionState == .denied {
            return "モーションの利用が許可されていません。設定アプリから後で変更できます。"
        }
        return error.localizedDescription
    }
}
