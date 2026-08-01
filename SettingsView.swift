import SwiftUI
import UIKit

struct SettingsView: View {
    @EnvironmentObject private var appModel: AppModel
    @Environment(\.dismiss) private var dismiss
    @State private var resetConfirmation = false

    var body: some View {
        NavigationStack {
            List {
                Section("権限") {
                    LabeledContent("モーションと運動", value: appModel.motionPermission.rawValue)
                    LabeledContent("通知", value: "未使用（フェーズ1）")
                    if appModel.motionPermission == .denied {
                        Button("設定アプリを開く") { openSystemSettings() }
                    } else {
                        Button("歩数を再確認") { appModel.refreshPedometer() }
                    }
                }

                Section("このアプリについて") {
                    LabeledContent("プライバシーポリシー", value: "公開時に設定")
                    LabeledContent("データ保存", value: "このiPhone内のみ")
                    LabeledContent("バージョン", value: "0.1.0")
                }

                #if DEBUG
                Section("開発") {
                    Button("状態をリセット", role: .destructive) {
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

    private func openSystemSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }
}
