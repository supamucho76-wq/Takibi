import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var appModel: AppModel
    @State private var settingsPresented = false
    @State private var feedbackTrigger = 0
    @State private var emptyInventoryHint = false
    @State private var burnSequence = 0
    @State private var isThrowingWood = false
    @State private var showBurnConfirmation = false

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { timeline in
            let time = timeline.date.timeIntervalSinceReferenceDate
            let flicker = 0.94 + 0.06 * sin(time * 4.17) + 0.025 * sin(time * 9.73 + 1.4)

            ZStack {
                GeometryReader { proxy in
                    ZStack {
                        background(time: time)
                        environmentLight(flicker: flicker)

                        WoodPileView(heat: appModel.state.heat, burnSequence: burnSequence)
                            .frame(width: min(proxy.size.width * 0.66, 310), height: 150)
                            .position(x: proxy.size.width / 2, y: proxy.size.height * 0.71)

                        WoodPhysicsView(
                            burnSequence: burnSequence,
                            isActive: appModel.isRenderingActive
                        )
                        .allowsHitTesting(false)

                        FireView(
                            heat: appModel.state.heat,
                            isActive: appModel.isRenderingActive,
                            burnSequence: burnSequence
                        )
                        .blendMode(.plusLighter)
                        .allowsHitTesting(false)
                    }
                    .frame(width: proxy.size.width, height: proxy.size.height)
                    .clipped()
                }
                .ignoresSafeArea()

                overlay
                    .zIndex(3)
            }
        }
        .sheet(isPresented: $settingsPresented) {
            SettingsView()
                .environmentObject(appModel)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .sensoryFeedback(.impact(weight: .heavy, intensity: 0.82), trigger: feedbackTrigger)
    }

    private func background(time: TimeInterval) -> some View {
        Image("CampBackground")
            .resizable()
            .scaledToFill()
            .scaleEffect(1.025)
            .offset(y: sin(time * 0.075) * 4)
            .overlay(Color.black.opacity(0.25))
            .ignoresSafeArea()
    }

    private func environmentLight(flicker: Double) -> some View {
        RadialGradient(
            colors: [
                Color(red: 1.0, green: 0.30, blue: 0.035)
                    .opacity(0.25 * appModel.visualState.environmentLight * flicker),
                Color(red: 0.72, green: 0.10, blue: 0.01)
                    .opacity(0.08 * appModel.visualState.environmentLight),
                .clear
            ],
            center: UnitPoint(x: 0.5, y: 0.70),
            startRadius: 8,
            endRadius: 300
        )
        .blendMode(.plusLighter)
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }

    private var overlay: some View {
        VStack(spacing: 0) {
            topHUD

            Spacer(minLength: 12)

            VStack(spacing: 10) {
                if let message = appModel.pedometerMessage {
                    Text(message)
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.66))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                        .transition(.opacity)
                }

                if emptyInventoryHint {
                    Label("歩くと100歩ごとに薪が増えます", systemImage: "figure.walk")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.orange.opacity(0.92))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(.black.opacity(0.58), in: Capsule())
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }

                if showBurnConfirmation {
                    Label("薪を1本くべた", systemImage: "checkmark.circle.fill")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Color.orange.opacity(0.84), in: Capsule())
                        .transition(.scale.combined(with: .opacity))
                }

                fireStatus
                burnButton
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    private var topHUD: some View {
        HStack(spacing: 0) {
            hudMetric(
                icon: "figure.walk",
                value: appModel.todaySteps.formatted(),
                label: "あと\(stepsUntilNextWood)歩"
            )

            Rectangle()
                .fill(.white.opacity(0.12))
                .frame(width: 1, height: 30)
                .padding(.horizontal, 8)

            hudMetric(
                icon: "square.stack.3d.up.fill",
                value: "\(appModel.standardWoodCount)本",
                label: "薪"
            )

            Spacer(minLength: 8)

            Button {
                settingsPresented = true
            } label: {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.90))
                    .frame(width: 40, height: 40)
                    .background(.white.opacity(0.08), in: Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("設定")
        }
        .padding(.leading, 12)
        .padding(.trailing, 6)
        .padding(.vertical, 6)
        .frame(maxWidth: 340)
        .background(.ultraThinMaterial.opacity(0.90), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(.white.opacity(0.13), lineWidth: 1)
        )
    }

    private var fireStatus: some View {
        HStack(spacing: 8) {
            Image(systemName: appModel.visualState.stage.systemImage)
                .foregroundStyle(appModel.visualState.stage.tint)
            Text(appModel.visualState.stage.title)
                .fontWeight(.semibold)
            Spacer(minLength: 10)
            Text("火力 \(Int(appModel.state.heat.rounded()))%")
                .monospacedDigit()
                .foregroundStyle(.white.opacity(0.68))
        }
        .font(.caption)
        .foregroundStyle(.white)
        .padding(.horizontal, 14)
        .frame(maxWidth: 290, minHeight: 38)
        .background(.black.opacity(0.52), in: Capsule())
        .overlay(Capsule().stroke(.orange.opacity(0.20), lineWidth: 1))
        .contentTransition(.numericText())
    }

    private var burnButton: some View {
        Button(action: burnWood) {
            HStack(spacing: 12) {
                Image("WoodLog")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 52, height: 36)
                    .rotationEffect(.degrees(-8))

                VStack(alignment: .leading, spacing: 2) {
                    Text("薪をくべる")
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                    Text(appModel.standardWoodCount > 0 ? "炎に薪を1本入れる" : "薪がありません")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.70))
                }

                Spacer(minLength: 4)

                Text("\(appModel.standardWoodCount)")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .frame(width: 34, height: 34)
                    .background(.black.opacity(0.26), in: Circle())
                    .contentTransition(.numericText())
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 16)
            .frame(maxWidth: 340, minHeight: 66)
            .background {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: appModel.standardWoodCount > 0
                                ? [Color.orange.opacity(0.90), Color.red.opacity(0.78)]
                                : [Color.gray.opacity(0.46), Color.black.opacity(0.62)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(.white.opacity(0.18), lineWidth: 1)
            )
            .shadow(color: .orange.opacity(appModel.standardWoodCount > 0 ? 0.30 : 0), radius: 18, y: 7)
        }
        .buttonStyle(BurnButtonStyle())
        .disabled(isThrowingWood)
        .accessibilityHint("所持している薪を1本使って火を強くします")
    }

    private func hudMetric(icon: String, value: String, label: String) -> some View {
        HStack(spacing: 7) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.orange)
                .frame(width: 22)

            VStack(alignment: .leading, spacing: 1) {
                Text(value)
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .contentTransition(.numericText())
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
                Text(label)
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.58))
                    .lineLimit(1)
            }
        }
        .foregroundStyle(.white)
        .frame(minWidth: 88, alignment: .leading)
    }

    private var stepsUntilNextWood: Int {
        let remainder = appModel.state.totalStepsAllTime % GameConstants.stepsPerWood
        return remainder == 0 ? GameConstants.stepsPerWood : GameConstants.stepsPerWood - remainder
    }

    private func burnWood() {
        guard !isThrowingWood else { return }

        if appModel.burnStandardWood() {
            feedbackTrigger += 1
            burnSequence += 1
            emptyInventoryHint = false
            isThrowingWood = true

            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 680_000_000)
                withAnimation(.spring(response: 0.32, dampingFraction: 0.72)) {
                    showBurnConfirmation = true
                }
                try? await Task.sleep(nanoseconds: 420_000_000)
                isThrowingWood = false
                try? await Task.sleep(nanoseconds: 1_100_000_000)
                withAnimation(.easeOut(duration: 0.22)) {
                    showBurnConfirmation = false
                }
            }
        } else {
            withAnimation(.spring(response: 0.34, dampingFraction: 0.76)) {
                emptyInventoryHint = true
            }
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 2_000_000_000)
                withAnimation(.easeOut(duration: 0.24)) {
                    emptyInventoryHint = false
                }
            }
        }
    }
}

private struct BurnButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .brightness(configuration.isPressed ? 0.08 : 0)
            .animation(.spring(response: 0.22, dampingFraction: 0.70), value: configuration.isPressed)
    }
}
