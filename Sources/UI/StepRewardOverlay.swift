import SwiftUI

struct StepRewardOverlay: View {
    let receipt: StepRewardReceipt
    let onDismiss: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var particlesArrived = false
    @State private var cardVisible = false

    var body: some View {
        ZStack {
            Color.black.opacity(0.72)
                .ignoresSafeArea()

            ForEach(0 ..< 18, id: \.self) { index in
                Circle()
                    .fill(index.isMultiple(of: 3) ? Color.yellow : Color.orange)
                    .frame(width: 5 + CGFloat(index % 4), height: 5 + CGFloat(index % 4))
                    .shadow(color: .orange, radius: 6)
                    .offset(
                        x: particlesArrived ? 0 : CGFloat((index * 37) % 180 - 90),
                        y: particlesArrived ? 120 : CGFloat((index * 53) % 240 - 210)
                    )
                    .opacity(particlesArrived ? 0.12 : 0.92)
                    .animation(
                        reduceMotion ? .linear(duration: 0.01) : .easeIn(duration: 0.85).delay(Double(index) * 0.018),
                        value: particlesArrived
                    )
            }

            VStack(spacing: 18) {
                Image(systemName: "figure.walk.motion")
                    .font(.system(size: 38, weight: .semibold))
                    .foregroundStyle(.orange)

                Text("\(receipt.addedSteps.formatted())歩の力が、\n焚き火に届きました")
                    .font(.system(size: 23, weight: .bold, design: .rounded))
                    .multilineTextAlignment(.center)

                if receipt.rewards.isEmpty {
                    Text("次の報酬へ力がたまりました")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.72))
                } else {
                    VStack(spacing: 8) {
                        ForEach(receipt.rewards) { reward in
                            Label(
                                "\(reward.title) +\(reward.amount)",
                                systemImage: reward.kind == .wood ? "square.stack.3d.up.fill" : "sparkles"
                            )
                            .font(.headline)
                            .foregroundStyle(reward.kind == .wood ? .orange : .yellow)
                        }
                    }
                    .padding(.horizontal, 22)
                    .padding(.vertical, 14)
                    .background(.white.opacity(0.09), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                }

                Button("火を見に行く", action: onDismiss)
                    .font(.headline)
                    .frame(maxWidth: .infinity, minHeight: 50)
                    .background(Color.orange, in: Capsule())
                    .foregroundStyle(.black)
                    .contentShape(Rectangle())

                Button("スキップ", action: onDismiss)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.60))
                    .frame(minWidth: 88, minHeight: 44)
            }
            .padding(28)
            .frame(maxWidth: 360)
            .foregroundStyle(.white)
            .scaleEffect(cardVisible ? 1 : 0.94)
            .opacity(cardVisible ? 1 : 0)
        }
        .accessibilityElement(children: .contain)
        .onAppear {
            withAnimation(.spring(response: 0.42, dampingFraction: 0.78)) { cardVisible = true }
            particlesArrived = true
        }
    }
}
