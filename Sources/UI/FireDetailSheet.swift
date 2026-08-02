import SwiftUI

struct FireDetailSheet: View {
    @EnvironmentObject private var appModel: AppModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section("現在の火") {
                    LabeledContent("状態", value: "Level \(appModel.fireStatus.stage.level)・\(appModel.fireStatus.stage.title)")
                    LabeledContent("残り燃焼時間", value: durationText(appModel.fireStatus.remainingDuration))
                    LabeledContent("焚き火に入っている薪", value: "\(appModel.activeBurningFuelCount)本")
                }

                Section("手持ちと進捗") {
                    LabeledContent("所持している薪", value: "\(appModel.totalWoodCount)本")
                    LabeledContent("選択中の薪", value: appModel.selectedWood.name)
                    LabeledContent("集めた火の粉", value: "\(appModel.state.stepProgress.fireSparkCount)")
                    LabeledContent(
                        "次の\(appModel.nextStepRewardTarget.kind.title)",
                        value: "あと\(appModel.nextStepRewardTarget.remainingSteps)歩"
                    )
                }

                if let nextFuel = appModel.nextBurningFuel {
                    Section("次に燃え尽きる薪") {
                        LabeledContent(
                            WoodCatalog.wood(id: nextFuel.woodID)?.name ?? "薪",
                            value: durationText(nextFuel.expiresAt.timeIntervalSinceNow)
                        )
                    }
                }
            }
            .navigationTitle("焚き火の詳細")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("閉じる") { dismiss() }
                }
            }
        }
    }

    private func durationText(_ duration: TimeInterval) -> String {
        let totalMinutes = max(0, Int(duration / 60))
        return "\(totalMinutes / 60)時間\(totalMinutes % 60)分"
    }
}
