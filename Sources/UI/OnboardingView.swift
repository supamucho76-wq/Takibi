import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject private var appModel: AppModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var page = 0
    @State private var woodOffset: CGSize = .zero
    @State private var fireIgnited = false

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.012, green: 0.022, blue: 0.032), .black],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            RadialGradient(
                colors: [Color.orange.opacity(fireIgnited ? 0.24 : 0.04), .clear],
                center: UnitPoint(x: 0.5, y: 0.48),
                startRadius: 12,
                endRadius: fireIgnited ? 280 : 120
            )
            .ignoresSafeArea()
            .animation(reduceMotion ? .linear(duration: 0.01) : .easeOut(duration: 0.8), value: fireIgnited)

            VStack(spacing: 18) {
                Spacer(minLength: 32)

                EmberMark(intensity: fireIgnited ? 1 : 0.20)
                    .frame(width: 180, height: 190)
                    .accessibilityHidden(true)

                content
                    .frame(maxWidth: 360)
                    .padding(.horizontal, 26)

                Spacer(minLength: 20)

                if page != 2 {
                    primaryButton
                        .padding(.horizontal, 26)
                        .padding(.bottom, 20)
                }
            }
        }
        .foregroundStyle(.white)
    }

    @ViewBuilder
    private var content: some View {
        switch page {
        case 0:
            VStack(spacing: 12) {
                Text("この火は、あなたの一歩で\n燃え続けます")
                    .font(.system(size: 27, weight: .bold, design: .rounded))
                    .multilineTextAlignment(.center)
                Text("座りっぱなしを少し中断すると、暗い森に光と生命が戻ります。")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.68))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
        case 1:
            VStack(spacing: 12) {
                Image(systemName: "figure.walk.motion")
                    .font(.system(size: 30))
                    .foregroundStyle(.orange)
                Text("歩いた力を火へ届ける")
                    .font(.title2.bold())
                Text("歩数はこのiPhoneの中だけで処理されます。許可できない場合も、疑似歩数で体験できます。")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.68))
                    .multilineTextAlignment(.center)
            }
        case 2:
            VStack(spacing: 14) {
                Text("最初の薪を、火にくべてください")
                    .font(.title3.bold())
                Text("薪を上の焚き火へドラッグ")
                    .font(.caption)
                    .foregroundStyle(.orange)

                WoodIconView(wood: WoodCatalog.standard)
                    .frame(width: 128, height: 68)
                    .padding(10)
                    .background(.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 20).stroke(.orange.opacity(0.55), lineWidth: 2))
                    .offset(woodOffset)
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { woodOffset = $0.translation }
                            .onEnded { value in
                                if value.translation.height < -70 {
                                    igniteFirstWood()
                                } else {
                                    withAnimation(.spring(response: 0.32, dampingFraction: 0.64)) {
                                        woodOffset = .zero
                                    }
                                }
                            }
                    )
                    .accessibilityLabel("最初の薪")
                    .accessibilityHint("上にドラッグして焚き火に投入します")

                Button("タップして火にくべる") { igniteFirstWood() }
                    .font(.caption.weight(.semibold))
                    .frame(minWidth: 180, minHeight: 44)
                    .foregroundStyle(.white.opacity(0.78))
            }
        default:
            VStack(spacing: 12) {
                Label("火が息を吹き返しました", systemImage: "flame.fill")
                    .font(.title2.bold())
                    .foregroundStyle(.yellow)
                Text("まずは300歩。\n火に風を届けに行きましょう。")
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .multilineTextAlignment(.center)
                Text("100歩ごとに小さなごほうびが届きます")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.62))
            }
        }
    }

    private var primaryButton: some View {
        Button {
            switch page {
            case 0:
                withAnimation { page = 1 }
            case 1:
                Task {
                    await appModel.requestMotionPermission()
                    withAnimation { page = 2 }
                }
            default:
                appModel.completeOnboarding()
            }
        } label: {
            Text(buttonTitle)
                .font(.headline)
                .frame(maxWidth: .infinity, minHeight: 54)
                .background(Color.orange.opacity(0.92), in: Capsule())
                .foregroundStyle(.black)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var buttonTitle: String {
        switch page {
        case 0: "火を守りはじめる"
        case 1: "歩数連携を許可する"
        default: "300歩の旅をはじめる"
        }
    }

    private func igniteFirstWood() {
        guard !fireIgnited else { return }
        woodOffset = .zero
        fireIgnited = appModel.igniteOnboardingFire()
        withAnimation(reduceMotion ? .linear(duration: 0.01) : .spring(response: 0.50, dampingFraction: 0.62)) {
            page = 3
        }
    }
}

private struct EmberMark: View {
    let intensity: Double

    var body: some View {
        let scale = CGFloat(intensity)
        ZStack {
            Circle()
                .fill(Color.orange.opacity(0.08 + intensity * 0.14))
                .blur(radius: 28)
            Circle()
                .fill(Color.red.opacity(0.14 + intensity * 0.22))
                .frame(width: 92 + scale * 30, height: 38 + scale * 20)
                .blur(radius: 14)
                .offset(y: 48)
            Image(systemName: "flame.fill")
                .font(.system(size: 48 + scale * 46, weight: .ultraLight))
                .foregroundStyle(
                    LinearGradient(
                        colors: intensity > 0.5 ? [.white, .yellow, .orange, .red] : [.orange, .red.opacity(0.55)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .shadow(color: .orange.opacity(0.20 + intensity * 0.55), radius: 12 + scale * 18)
        }
        .animation(.easeOut(duration: 0.7), value: intensity)
    }
}
