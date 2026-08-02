import Foundation

struct StepProgress: Codable, Equatable {
    var fireSparkCount: Int
    var totalSmallRewards: Int

    static let empty = StepProgress(fireSparkCount: 0, totalSmallRewards: 0)
}

enum RewardKind: String, Codable, Equatable {
    case fireSparks
    case wood
    case collectible
}

struct Reward: Identifiable, Equatable {
    let id: UUID
    let kind: RewardKind
    let title: String
    let amount: Int

    init(id: UUID = UUID(), kind: RewardKind, title: String, amount: Int) {
        self.id = id
        self.kind = kind
        self.title = title
        self.amount = amount
    }
}

struct StepRewardReceipt: Identifiable, Equatable {
    let id: UUID
    let addedSteps: Int
    let rewards: [Reward]

    init(id: UUID = UUID(), addedSteps: Int, rewards: [Reward]) {
        self.id = id
        self.addedSteps = addedSteps
        self.rewards = rewards
    }
}

enum StepRewardTargetKind: Equatable {
    case fireSparks
    case wood

    var title: String {
        switch self {
        case .fireSparks: "火の粉"
        case .wood: "新しい薪"
        }
    }

    var systemImage: String {
        switch self {
        case .fireSparks: "sparkles"
        case .wood: "square.stack.3d.up.fill"
        }
    }
}

struct StepRewardTarget: Equatable {
    let kind: StepRewardTargetKind
    let boundary: Int
    let remainingSteps: Int
    let progress: Double
}

struct FireStatus: Equatable {
    let stage: FireStage
    let message: String
    let burningFuelCount: Int
    let remainingDuration: TimeInterval
    let nextFuelExpiresAt: Date?

    var hasFuel: Bool { burningFuelCount > 0 }
}
