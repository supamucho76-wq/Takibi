import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var appModel: AppModel
    @State private var settingsPresented = false
    @State private var feedbackTrigger = 0
    @State private var emptyInventoryHint = false

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { timeline in
            let time = timeline.date.timeIntervalSinceReferenceDate
            let flicker = 0.94 + 0.06 * sin(time * 4.17) + 0.025 * sin(time * 9.73 + 1.4)
            GeometryReader { proxy in
                ZStack {
                    background(time: time)
                    environmentLight(flicker: flicker)
                    WoodPileView(heat: appModel.state.heat)
                        .frame(width: min(proxy.size.width * 0.62, 310), height: 150)
                        .position(x: proxy.size.width / 2, y: proxy.size.height * 0.73)

                    FireView(heat: appModel.state.heat, isActive: appModel.isRenderingActive)
                        .blendMode(.plusLighter)
                        .allowsHitTesting(false)
                        .ignoresSafeArea()

                    overlay
                }
                .frame(width: proxy.size.width, height: proxy.size.height)
                .clipped()
            }
        }
        .ignoresSafeArea()
        .sheet(isPresented: $settingsPresented) {
            SettingsView()
                .environmentObject(appModel)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .sensoryFeedback(.impact(weight: .heavy, intensity: 0.72), trigger: feedbackTrigger)
    }

    private func background(time: TimeInterval) -> some View {
        Image("CampBackground")
            .resizable()
            .scaledToFill()
            .scaleEffect(1.025)
            .offset(y: sin(time * 0.075) * 4)
            .overlay(Color.black.opacity(0.20))
            .ignoresSafeArea()
    }

    private func environmentLight(flicker: Double) -> some View {
        RadialGradient(
            colors: [
                Color(red: 1.0, green: 0.30, blue: 0.035).opacity(0.28 * appModel.visualState.environmentLight * flicker),
                Color(red: 0.72, green: 0.10, blue: 0.01).opacity(0.09 * appModel.visualState.environmentLight),
                .clear
            ],
            center: UnitPoint(x: 0.5, y: 0.73),
            startRadius: 8,
            endRadius: 320
        )
        .blendMode(.plusLighter)
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }

    private var overlay: some View {
        VStack {
            HStack(alignment: .top) {
                metric(value: appModel.todaySteps.formatted(), label: "今日の歩数")
                Spacer()
                metric(value: appModel.standardWoodCount.formatted(), label: "薪")
            }
            .padding(.horizontal, 24)
            .padding(.top, 14)

            Spacer()

            if let message = appModel.pedometerMessage {
                Text(message)
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.56))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .transition(.opacity)
            }

            if emptyInventoryHint {
                Text("歩くと薪が集まります")
                    .font(.caption)
                    .foregroundStyle(.orange.opacity(0.78))
                    .transition(.opacity)
            }

            HStack(alignment: .bottom) {
                Color.clear.frame(width: 44, height: 44)
                Spacer()
                burnButton
                Spacer()
                Button {
                    settingsPresented = true
                } label: {
                    Image(systemName: "gearshape")
                        .font(.system(size: 16, weight: .light))
                        .foregroundStyle(.white.opacity(0.55))
                        .frame(width: 44, height: 44)
                        .background(.black.opacity(0.18), in: Circle())
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 18)
        }
        .safeAreaPadding(.top)
        .safeAreaPadding(.bottom)
    }

    private var burnButton: some View {
        Button {
            if appModel.burnStandardWood() {
                feedbackTrigger += 1
                emptyInventoryHint = false
            } else {
                withAnimation { emptyInventoryHint = true }
                Task {
                    try? await Task.sleep(nanoseconds: 2_000_000_000)
                    withAnimation { emptyInventoryHint = false }
                }
            }
        } label: {
            VStack(spacing: 5) {
                Image(systemName: "flame")
                    .font(.system(size: 19, weight: .light))
                Text("くべる")
                    .font(.system(size: 14, weight: .regular))
            }
            .foregroundStyle(.white.opacity(appModel.standardWoodCount > 0 ? 0.9 : 0.38))
            .frame(width: 88, height: 64)
            .background(.ultraThinMaterial.opacity(0.66), in: Capsule())
            .overlay(Capsule().stroke(.orange.opacity(0.22), lineWidth: 0.7))
        }
        .buttonStyle(.plain)
    }

    private func metric(value: String, label: String) -> some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(value)
                .font(.system(size: 19, weight: .light, design: .rounded))
                .monospacedDigit()
            Text(label)
                .font(.system(size: 10, weight: .light))
                .textCase(.uppercase)
                .tracking(1.2)
                .foregroundStyle(.white.opacity(0.46))
        }
        .foregroundStyle(.white.opacity(0.80))
        .shadow(color: .black.opacity(0.75), radius: 8)
    }
}

