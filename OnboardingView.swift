import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject private var appModel: AppModel

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.015, green: 0.025, blue: 0.035), .black],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 28) {
                Spacer()

                EmberMark()
                    .frame(width: 150, height: 150)

                VStack(spacing: 12) {
                    Text("歩いて、火を育てる")
                        .font(.system(size: 28, weight: .light, design: .rounded))
                    Text("歩数に応じて薪が集まります。\n火は弱くなっても、決して消えません。")
                        .font(.system(size: 15, weight: .light))
                        .foregroundStyle(.white.opacity(0.64))
                        .multilineTextAlignment(.center)
                        .lineSpacing(6)
                }

                Spacer()

                VStack(spacing: 14) {
                    Label("歩数は端末内だけで処理されます", systemImage: "figure.walk")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.52))

                    Button {
                        appModel.completeOnboarding()
                    } label: {
                        Text("焚き火をはじめる")
                            .font(.system(size: 17, weight: .medium))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(.white.opacity(0.11), in: Capsule())
                            .overlay(Capsule().stroke(.orange.opacity(0.32), lineWidth: 0.8))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 28)
                .padding(.bottom, 22)
            }
        }
    }
}

private struct EmberMark: View {
    var body: some View {
        ZStack {
            Circle()
                .fill(Color.orange.opacity(0.06))
                .blur(radius: 24)
            Circle()
                .fill(Color.red.opacity(0.18))
                .frame(width: 78, height: 34)
                .blur(radius: 13)
                .offset(y: 38)
            Image(systemName: "flame.fill")
                .font(.system(size: 72, weight: .ultraLight))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.white, .yellow, .orange, .red.opacity(0.7)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .shadow(color: .orange.opacity(0.55), radius: 22)
        }
    }
}

