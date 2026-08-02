import SwiftUI

struct WalkSessionSheet: View {
    @EnvironmentObject private var appModel: AppModel
    @Environment(\.dismiss) private var dismiss
    @State private var baselineSteps = 0
    @State private var startedAt = Date()

    private var gainedSteps: Int { max(0, appModel.todaySteps - baselineSteps) }
    private var progress: Double { min(Double(gainedSteps) / 300, 1) }

    var body: some View {
        NavigationStack {
            TimelineView(.periodic(from: .now, by: 1)) { context in
                VStack(spacing: 24) {
                    Spacer()
                    Image(systemName: progress >= 1 ? "flame.fill" : "figure.walk.motion")
                        .font(.system(size: 54, weight: .semibold))
                        .foregroundStyle(progress >= 1 ? .yellow : .orange)

                    Text(progress >= 1 ? "火に風が届きました" : "3分間の火起こし散歩")
                        .font(.title2.bold())

                    Text("\(gainedSteps) / 300歩")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .monospacedDigit()

                    ProgressView(value: progress)
                        .tint(.orange)
                        .scaleEffect(y: 2)
                        .padding(.horizontal, 36)

                    Text(elapsedText(context.date.timeIntervalSince(startedAt)))
                        .font(.headline.monospacedDigit())
                        .foregroundStyle(.secondary)

                    Text("室内での歩行も数えられます。安全な場所で少しだけ座りっぱなしを中断しましょう。")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 28)

                    Spacer()

                    Button(progress >= 1 ? "焚き火へ戻る" : "終了して戻る") { dismiss() }
                        .font(.headline)
                        .frame(maxWidth: .infinity, minHeight: 52)
                        .background(Color.orange, in: Capsule())
                        .foregroundStyle(.black)
                        .padding(.horizontal, 24)
                        .contentShape(Rectangle())
                }
                .padding(.bottom, 20)
            }
            .navigationTitle("火起こし散歩")
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear {
            baselineSteps = appModel.todaySteps
            startedAt = Date()
            appModel.refreshPedometer()
        }
    }

    private func elapsedText(_ duration: TimeInterval) -> String {
        let seconds = max(0, Int(duration))
        return String(format: "%02d:%02d", seconds / 60, seconds % 60)
    }
}
