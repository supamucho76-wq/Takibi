import SwiftUI
import UIKit

struct HomeView: View {
    @EnvironmentObject private var appModel: AppModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @StateObject private var woodThrowController = WoodThrowController()
    @StateObject private var fireAudio = FireAudioService()

    @State private var settingsPresented = false
    @State private var collectionPresented = false
    @State private var fireDetailPresented = false
    @State private var walkPresented = false
    @State private var feedbackTrigger = 0
    @State private var fireBurstSequence = 0
    @State private var isThrowingWood = false
    @State private var preparedWood: WoodType?
    @State private var throwDrag: CGSize = .zero
    @State private var resultMessage: String?

    var body: some View {
        TimelineView(.animation(minimumInterval: reduceMotion ? 1 : 1.0 / 30.0)) { timeline in
            let time = reduceMotion ? 0 : timeline.date.timeIntervalSinceReferenceDate
            let flicker = reduceMotion ? 1 : 0.95 + 0.05 * sin(time * 4.1)

            GeometryReader { proxy in
                ZStack {
                    background(time: time)
                    environmentLight(flicker: flicker)
                    smokeLayer(time: time)
                    companionLayer

                    WoodPileView(
                        heat: appModel.visualHeat,
                        burnSequence: fireBurstSequence,
                        burningFuels: appModel.activeBurningFuels
                    )
                    .frame(width: min(proxy.size.width * 0.68, 310), height: 150)
                    .position(x: proxy.size.width / 2, y: proxy.size.height * 0.66)

                    FireView(
                        heat: appModel.visualHeat,
                        isActive: appModel.isRenderingActive,
                        burnSequence: fireBurstSequence,
                        tint: appModel.selectedFlame.tint
                    )
                    .blendMode(.plusLighter)
                    .allowsHitTesting(false)

                    WoodPhysicsView(
                        controller: woodThrowController,
                        isActive: appModel.isRenderingActive,
                        onLogLanded: finishBurn
                    )
                    .allowsHitTesting(false)

                    fireInteractionArea(in: proxy.size)

                    VStack(spacing: 0) {
                        topHUD
                        stageBadge
                            .padding(.top, 10)
                        Spacer(minLength: 0)
                        bottomControls
                    }
                    .padding(.horizontal, 12)
                    .padding(.top, 8)
                    .padding(.bottom, 8)

                    if let wood = preparedWood {
                        throwableWood(wood, in: proxy.size)
                    }

                    if let receipt = appModel.stepRewardReceipt {
                        StepRewardOverlay(receipt: receipt) {
                            withAnimation(.easeOut(duration: 0.20)) {
                                appModel.dismissStepRewardReceipt()
                            }
                        }
                        .transition(.opacity)
                        .zIndex(20)
                    }
                }
                .frame(width: proxy.size.width, height: proxy.size.height)
                .clipped()
            }
        }
        .sheet(isPresented: $settingsPresented) {
            SettingsView().environmentObject(appModel)
        }
        .sheet(isPresented: $collectionPresented) {
            CollectionView().environmentObject(appModel)
        }
        .sheet(isPresented: $fireDetailPresented) {
            FireDetailSheet()
                .environmentObject(appModel)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $walkPresented) {
            WalkSessionSheet()
                .environmentObject(appModel)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .sensoryFeedback(.impact(weight: .medium, intensity: 0.75), trigger: feedbackTrigger)
        .sensoryFeedback(.success, trigger: appModel.stepRewardSequence)
        .onAppear { fireAudio.start(stage: appModel.visualState.stage) }
        .onDisappear { fireAudio.stop() }
        .onChange(of: appModel.visualState.stage) { _, stage in
            fireAudio.update(stage: stage)
        }
    }

    private func background(time: TimeInterval) -> some View {
        let theme = appModel.selectedBackground
        return Image(theme.imageName)
            .resizable()
            .scaledToFill()
            .scaleEffect(1.025)
            .offset(y: sin(time * 0.075) * 4)
            .hueRotation(.degrees(theme.hueDegrees))
            .saturation(theme.saturation)
            .brightness(theme.brightness + appModel.visualState.environmentLight * 0.035)
            .overlay(Color(theme.overlayTint).opacity(0.14))
            .overlay(Color.black.opacity(0.34 - appModel.visualState.environmentLight * 0.12))
            .ignoresSafeArea()
    }

    private func environmentLight(flicker: Double) -> some View {
        RadialGradient(
            colors: [
                Color(red: 1, green: 0.30, blue: 0.035)
                    .opacity(0.25 * appModel.visualState.environmentLight * flicker),
                Color(red: 0.72, green: 0.10, blue: 0.01)
                    .opacity(0.08 * appModel.visualState.environmentLight),
                .clear,
            ],
            center: UnitPoint(x: 0.5, y: 0.64),
            startRadius: 8,
            endRadius: 330
        )
        .blendMode(.plusLighter)
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }

    private func smokeLayer(time: TimeInterval) -> some View {
        ZStack {
            ForEach(0 ..< 5, id: \.self) { index in
                Capsule()
                    .fill(Color.white.opacity(0.07 * appModel.visualState.smokeDensity))
                    .frame(width: 34 + CGFloat(index * 7), height: 110 + CGFloat(index * 13))
                    .blur(radius: 18)
                    .offset(
                        x: CGFloat(sin(time * 0.28 + Double(index))) * 30 + CGFloat(index - 2) * 11,
                        y: CGFloat(index * -38) - 40
                    )
            }
        }
        .position(x: UIScreen.main.bounds.width / 2, y: UIScreen.main.bounds.height * 0.49)
        .allowsHitTesting(false)
    }

    private var companionLayer: some View {
        HStack {
            Image(systemName: "hare.fill")
                .offset(y: 48)
            Spacer()
            Image(systemName: "bird.fill")
                .offset(y: -28)
        }
        .font(.system(size: 25))
        .foregroundStyle(.black.opacity(0.78))
        .padding(.horizontal, 34)
        .opacity(appModel.visualState.companionOpacity)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private var topHUD: some View {
        HStack(spacing: 8) {
            hudMetric(icon: "figure.walk", value: appModel.todaySteps.formatted(), label: "今日の歩数")

            Rectangle()
                .fill(.white.opacity(0.12))
                .frame(width: 1, height: 30)

            hudMetric(
                icon: appModel.nextStepRewardTarget.kind.systemImage,
                value: "あと\(appModel.nextStepRewardTarget.remainingSteps)歩",
                label: "次の\(appModel.nextStepRewardTarget.kind.title)"
            )

            Spacer(minLength: 2)

            roundButton(systemImage: "sparkles.rectangle.stack.fill", label: "コレクション") {
                collectionPresented = true
            }
            roundButton(systemImage: "gearshape.fill", label: "設定") {
                settingsPresented = true
            }
        }
        .padding(.leading, 12)
        .padding(.trailing, 6)
        .padding(.vertical, 7)
        .frame(maxWidth: 370)
        .background(.ultraThinMaterial.opacity(0.92), in: RoundedRectangle(cornerRadius: 19, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 19).stroke(.white.opacity(0.13), lineWidth: 1))
    }

    private var stageBadge: some View {
        Label(
            "Level \(appModel.visualState.stage.level)  \(appModel.visualState.stage.title)",
            systemImage: appModel.visualState.stage.systemImage
        )
        .font(.caption.weight(.bold))
        .foregroundStyle(appModel.visualState.stage.tint)
        .padding(.horizontal, 12)
        .frame(minHeight: 32)
        .background(.black.opacity(0.48), in: Capsule())
        .accessibilityLabel("火の状態、レベル\(appModel.visualState.stage.level)、\(appModel.visualState.stage.title)")
    }

    private var bottomControls: some View {
        VStack(spacing: 9) {
            if let resultMessage {
                Label(resultMessage, systemImage: "sparkles")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.yellow)
                    .padding(.horizontal, 12)
                    .frame(minHeight: 32)
                    .background(.black.opacity(0.66), in: Capsule())
                    .transition(.scale.combined(with: .opacity))
            }

            Button { fireDetailPresented = true } label: {
                VStack(spacing: 7) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(appModel.fireStatus.message)
                                .font(.subheadline.bold())
                                .lineLimit(1)
                                .minimumScaleFactor(0.78)
                            Text("火はあと\(durationText(appModel.fireStatus.remainingDuration))燃えます")
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.72))
                                .lineLimit(1)
                                .minimumScaleFactor(0.78)
                        }
                        Spacer(minLength: 8)
                        Image(systemName: "chevron.up.circle.fill")
                            .foregroundStyle(.white.opacity(0.58))
                    }

                    HStack(spacing: 8) {
                        Image(systemName: appModel.nextStepRewardTarget.kind.systemImage)
                            .foregroundStyle(.orange)
                        Text("次の\(appModel.nextStepRewardTarget.kind.title)まであと\(appModel.nextStepRewardTarget.remainingSteps)歩")
                            .font(.caption.weight(.semibold))
                            .lineLimit(1)
                            .minimumScaleFactor(0.78)
                        Spacer()
                    }

                    ProgressView(value: appModel.nextStepRewardTarget.progress)
                        .tint(.orange)
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 15)
                .padding(.vertical, 11)
                .frame(maxWidth: 370, minHeight: 92)
                .background(.black.opacity(0.58), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 20).stroke(.orange.opacity(0.25), lineWidth: 1))
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityHint("所持している薪や燃焼中の薪の詳細を表示します")

            HStack(spacing: 9) {
                Button { walkPresented = true } label: {
                    Label("散歩を開始", systemImage: "figure.walk.motion")
                        .font(.subheadline.bold())
                        .lineLimit(1)
                        .minimumScaleFactor(0.78)
                        .frame(maxWidth: .infinity, minHeight: 58)
                        .background(.black.opacity(0.62), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: 18).stroke(.white.opacity(0.18), lineWidth: 1))
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                Button(action: prepareWood) {
                    HStack(spacing: 9) {
                        WoodIconView(wood: appModel.selectedWood)
                            .frame(width: 42, height: 30)
                        VStack(alignment: .leading, spacing: 1) {
                            Text("火にくべる")
                                .font(.subheadline.bold())
                                .lineLimit(1)
                                .minimumScaleFactor(0.78)
                            Text("所持 \(appModel.selectedWoodCount)本")
                                .font(.caption2)
                                .foregroundStyle(.white.opacity(0.72))
                                .lineLimit(1)
                        }
                    }
                    .frame(maxWidth: .infinity, minHeight: 58)
                    .background(
                        appModel.selectedWoodCount > 0 ? Color.orange.opacity(0.88) : Color.gray.opacity(0.48),
                        in: RoundedRectangle(cornerRadius: 18, style: .continuous)
                    )
                    .foregroundStyle(.white)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .disabled(isThrowingWood)
                .accessibilityLabel("\(appModel.selectedWood.name)を火にくべる。所持\(appModel.selectedWoodCount)本")
            }
            .frame(maxWidth: 370)
            .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func fireInteractionArea(in size: CGSize) -> some View {
        Color.clear
            .frame(width: min(size.width * 0.72, 330), height: size.height * 0.42)
            .contentShape(Rectangle())
            .position(x: size.width / 2, y: size.height * 0.52)
            .onTapGesture {
                feedbackTrigger += 1
                fireBurstSequence += 1
            }
            .onLongPressGesture(minimumDuration: 0.55) {
                prepareWood()
            }
            .gesture(
                DragGesture(minimumDistance: 24)
                    .onEnded { value in
                        guard value.translation.height < -45 else { return }
                        feedbackTrigger += 1
                        fireBurstSequence += 1
                        showResult("風が火に届きました")
                    }
            )
            .accessibilityLabel("焚き火")
            .accessibilityHint("タップで火の粉、上へスワイプで風、長押しで薪を準備します")
            .accessibilityAddTraits(.isButton)
    }

    private func hudMetric(icon: String, value: String, label: String) -> some View {
        HStack(spacing: 7) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.orange)
                .frame(width: 20)
            VStack(alignment: .leading, spacing: 1) {
                Text(value)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.70)
                Text(label)
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.60))
                    .lineLimit(1)
            }
        }
        .foregroundStyle(.white)
        .frame(minWidth: 76, alignment: .leading)
    }

    private func roundButton(systemImage: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 15, weight: .semibold))
                .frame(width: 44, height: 44)
                .background(.white.opacity(0.08), in: Circle())
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .foregroundStyle(label == "コレクション" ? .orange : .white.opacity(0.90))
        .accessibilityLabel(label)
    }

    private func prepareWood() {
        guard !isThrowingWood else { return }
        guard appModel.selectedWoodCount > 0 else {
            showResult("\(appModel.selectedWood.name)の在庫がありません")
            return
        }
        isThrowingWood = true
        throwDrag = .zero
        withAnimation(.spring(response: 0.34, dampingFraction: 0.68)) {
            preparedWood = appModel.selectedWood
        }
    }

    private func finishBurn() {
        guard isThrowingWood else { return }
        isThrowingWood = false
        guard let burnedWood = appModel.burnSelectedWood() else { return }
        feedbackTrigger += 1
        fireBurstSequence += 1
        showResult("\(burnedWood.name)：燃焼時間 +\(durationText(burnedWood.burnDuration))")
    }

    private func showResult(_ text: String) {
        withAnimation(.spring(response: 0.30, dampingFraction: 0.72)) { resultMessage = text }
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 1_800_000_000)
            withAnimation(.easeOut(duration: 0.20)) {
                if resultMessage == text { resultMessage = nil }
            }
        }
    }

    private func throwableWood(_ wood: WoodType, in size: CGSize) -> some View {
        VStack(spacing: 7) {
            Label("焚き火へドラッグ", systemImage: "hand.draw.fill")
                .font(.caption.weight(.bold))
                .foregroundStyle(.white)
                .padding(.horizontal, 12)
                .frame(minHeight: 32)
                .background(.black.opacity(0.68), in: Capsule())

            WoodIconView(wood: wood)
                .frame(width: 124, height: 66)
                .padding(8)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color(wood.flameTint).opacity(0.72), lineWidth: 2))
                .shadow(color: Color(wood.flameTint).opacity(0.50), radius: 18)
        }
        .contentShape(Rectangle())
        .position(x: size.width / 2, y: size.height * 0.78)
        .offset(throwDrag)
        .rotationEffect(.degrees(Double(throwDrag.width) * 0.08))
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { throwDrag = $0.translation }
                .onEnded { value in
                    if value.translation.height < -52 {
                        let releasePoint = CGPoint(
                            x: size.width / 2 + value.translation.width,
                            y: size.height * 0.78 + value.translation.height
                        )
                        withAnimation(.easeOut(duration: 0.10)) {
                            preparedWood = nil
                            throwDrag = .zero
                        }
                        woodThrowController.launchWood(wood, from: releasePoint, swipe: value.translation)
                        Task { @MainActor in
                            try? await Task.sleep(nanoseconds: 3_200_000_000)
                            if isThrowingWood { isThrowingWood = false }
                        }
                    } else {
                        withAnimation(.spring(response: 0.30, dampingFraction: 0.62)) {
                            throwDrag = .zero
                        }
                    }
                }
        )
        .transition(.scale(scale: 0.70).combined(with: .opacity))
        .zIndex(10)
        .accessibilityLabel("\(wood.name)。焚き火へ上にドラッグして投入")
    }

    private func durationText(_ interval: TimeInterval) -> String {
        let minutes = max(0, Int(interval / 60))
        guard minutes > 0 else { return "0分" }
        if minutes < 60 { return "\(minutes)分" }
        let hours = minutes / 60
        let remainingMinutes = minutes % 60
        if hours < 24 { return remainingMinutes > 0 ? "\(hours)時間\(remainingMinutes)分" : "\(hours)時間" }
        let days = hours / 24
        let remainingHours = hours % 24
        return remainingHours > 0 ? "\(days)日\(remainingHours)時間" : "\(days)日"
    }
}
