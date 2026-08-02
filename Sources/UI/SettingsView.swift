import SwiftUI
import UIKit

struct SettingsView: View {
    @EnvironmentObject private var appModel: AppModel
    @Environment(\.dismiss) private var dismiss
    @State private var resetConfirmation = false

    var body: some View {
        NavigationStack {
            List {
                Section("歩数連携") {
                    LabeledContent("モーションと運動", value: appModel.motionPermission.rawValue)
                    if appModel.motionPermission == .denied {
                        Button("設定アプリを開く") { openSystemSettings() }
                    } else {
                        Button("歩数を再確認") { appModel.refreshPedometer() }
                    }
                }

                #if DEBUG
                simulatedStepsSection
                #else
                if appModel.motionPermission == .unavailable {
                    simulatedStepsSection
                }
                #endif

                Section("表示と演出") {
                    LabeledContent("動きを減らす", value: "iPhoneの設定に連動")
                    LabeledContent("低電力モード", value: "自動で演出を軽減")
                    Text("設定アプリの『アクセシビリティ > 動作』でReduce Motionを変更できます。")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section("このアプリについて") {
                    LabeledContent("歩数データ", value: "このiPhone内のみ")
                    LabeledContent("バージョン", value: "0.1.0")
                }

                #if DEBUG
                Section("開発") {
                    Button("保存データをリセット", role: .destructive) {
                        resetConfirmation = true
                    }
                }
                #endif
            }
            .navigationTitle("設定")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("閉じる") { dismiss() }
                }
            }
            .confirmationDialog("保存データをリセットしますか？", isPresented: $resetConfirmation) {
                #if DEBUG
                Button("リセット", role: .destructive) {
                    appModel.resetAllData()
                    dismiss()
                }
                #endif
            }
        }
    }

    private var simulatedStepsSection: some View {
        Section("シミュレータ用の疑似歩数") {
            Text("歩数取得が使えない環境でも報酬演出を確認できます。")
                .font(.caption)
                .foregroundStyle(.secondary)
            Button("+100歩") { appModel.addSimulatedSteps(100) }
            Button("+500歩") { appModel.addSimulatedSteps(500) }
            Button("+1,250歩") { appModel.addSimulatedSteps(1_250) }
        }
    }

    private func openSystemSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }
}
