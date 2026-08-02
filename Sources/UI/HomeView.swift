import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var appModel: AppModel
    @StateObject private var woodThrowController = WoodThrowController()
    @State private var settingsPresented = false
    @State private var collectionPresented = false
    @State private var feedbackTrigger = 0
    @State private var emptyInventoryHint = false
    @State private var fireBurstSequence = 0
    @State private var isThrowingWood = false
    @State private var showBurnConfirmation = false
    @State private var burnConfirmationText = "薪を1本くべた"
    @State private var showWoodReward = false
    @State private var rewardedWoodCount = 0
    @State private var showUnlockReward = false
    @State private var preparedWood: WoodType?
    @State private var throwDrag: CGSize = .zero

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { timeline in
            let time = timeline.date.timeIntervalSinceReferenceDate
            let flicker = 0.94 + 0.06 * sin(time * 4.17) + 0.025 * sin(time * 9.73 + 1.4)

            ZStack {
                GeometryReader { proxy in
                    ZStack {
                        background(time: time)
                        environmentLight(flicker: flicker)

                        WoodPileView(
                            heat: appModel.visualHeat,
                            burnSequence: fireBurstSequence,
                            burningFuels: appModel.activeBurningFuels
                        )
                            .frame(width: min(proxy.size.width * 0.66, 310), height: 150)
                            .position(x: proxy.size.width / 2, y: proxy.size.height * 0.71)

                        FireView(
                            heat: appModel.visualHeat,
                            isActive: appModel.isRenderingActive,
                            burnSequence: fireBurstSequence,
                            tint: appModel.selectedFlame.tint
                        )
                        .blendMode(.plusLighter)
                        .allowsHitTesting(false)

                        // Keep the physical log above the flame renderer so the
                        // whole throw, bounce and landing remain readable.
                        WoodPhysicsView(
                            controller: woodThrowController,
                            isActive: appModel.isRenderingActive,
                            onLogLanded: finishBurn
                        )
                        .frame(width: proxy.size.width, height: proxy.size.height)
                        .allowsHitTesting(false)
                    }
                    .frame(width: proxy.size.width, height: proxy.size.height)
                    .clipped()
                }
                .ignoresSafeArea()

                overlay
                    .zIndex(3)

                GeometryReader { proxy in
                    if let wood = preparedWood {
                        throwableWood(wood, in: proxy.size)
                    }
                }
                .ignoresSafeArea()
                .zIndex(4)
                .allowsHitTesting(preparedWood != nil)
            }
        }
        .sheet(isPresented: $settingsPresented) {
            SettingsView()
                .environmentObject(appModel)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $collectionPresented) {
            CollectionView()
                .environmentObject(appModel)
        }
        .sensoryFeedback(.impact(weight: .heavy, intensity: 0.82), trigger: feedbackTrigger)
        .sensoryFeedback(.success, trigger: appModel.woodAwardSequence)
        .onChange(of: appModel.woodAwardSequence) { _, _ in
            rewardedWoodCount = appModel.lastAwardedWoodCount
            withAnimation(.spring(response: 0.36, dampingFraction: 0.70)) {
                showWoodReward = true
            }
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 2_300_000_000)
                withAnimation(.easeOut(duration: 0.24)) {
                    showWoodReward = false
                }
            }
        }
        .onChange(of: appModel.unlockSequence) { _, _ in
            withAnimation(.spring(response: 0.38, dampingFraction: 0.68)) { showUnlockReward = true }
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 3_000_000_000)
                withAnimation(.easeOut(duration: 0.24)) { showUnlockReward = false }
            }
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
            .brightness(theme.brightness)
            .overlay(Color(theme.overlayTint).opacity(0.16))
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

                if showBurnConfirmation {
                    Label(burnConfirmationText, systemImage: "checkmark.circle.fill")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Color.orange.opacity(0.84), in: Capsule())
                        .transition(.scale.combined(with: .opacity))
                }

                if showWoodReward {
                    Label("歩いたごほうび！ 薪+\(rewardedWoodCount)", systemImage: "sparkles")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.black)
                        .padding(.horizontal, 15)
                        .padding(.vertical, 9)
                        .background(Color.orange, in: Capsule())
                        .shadow(color: .orange.opacity(0.45), radius: 14)
                        .transition(.move(edge: .bottom).combined(with: .scale).combined(with: .opacity))
                }

                if showUnlockReward, let reward = appModel.lastUnlockedReward {
                    Label("新発見：\(reward.name)（\(reward.kind.rawValue)）", systemImage: "star.circle.fill")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 15)
                        .padding(.vertical, 9)
                        .background(Color.purple.opacity(0.92), in: Capsule())
                        .shadow(color: .purple.opacity(0.55), radius: 16)
                        .transition(.move(edge: .bottom).combined(with: .scale).combined(with: .opacity))
                }

                walkMission
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
                value: "\(appModel.totalWoodCount)本",
                label: "手持ち・燃焼\(appModel.activeBurningFuelCount)本"
            )

            Spacer(minLength: 8)

            Button {
                collectionPresented = true
            } label: {
                Image(systemName: "sparkles.rectangle.stack.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.orange)
                    .frame(width: 36, height: 40)
                    .background(.white.opacity(0.08), in: Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("コレクション")

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
        let now = Date()
        return VStack(spacing: 6) {
            HStack(spacing: 8) {
                Image(systemName: appModel.visualState.stage.systemImage)
                    .foregroundStyle(appModel.visualState.stage.tint)
                Text("\(appModel.visualState.stage.title)・\(appModel.selectedFlame.name)")
                    .fontWeight(.semibold)
                Spacer(minLength: 8)
                Label("\(appModel.activeBurningFuelCount)本燃焼中", systemImage: "timelapse")
                    .foregroundStyle(.orange.opacity(0.94))
            }

            if let nextFuel = appModel.nextBurningFuel {
                GeometryReader { proxy in
                    ZStack(alignment: .leading) {
                        Capsule().fill(.white.opacity(0.10))
                        Capsule()
                            .fill(LinearGradient(colors: [.red, .orange, .yellow], startPoint: .leading, endPoint: .trailing))
                            .frame(
                                width: max(
                                    4,
                                    proxy.size.width * CGFloat(nextFuel.remainingFraction(at: now))
                                )
                            )
                    }
                }
                .frame(height: 4)

                HStack(spacing: 6) {
                    Text(nextFuelLabel(nextFuel, now: now))
                    Spacer(minLength: 6)
                    Text(queueEndLabel(now: now))
                }
                .font(.system(size: 9, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.68))
                .monospacedDigit()
            } else {
                Text("炉内の燃料は燃え尽きました。歩いて次の火種を作ろう")
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                    .foregroundStyle(.orange.opacity(0.84))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .font(.caption)
        .foregroundStyle(.white)
        .padding(.horizontal, 14)
        .padding(.vertical, 9)
        .frame(maxWidth: 340, minHeight: 58)
        .background(.black.opacity(0.55), in: RoundedRectangle(cornerRadius: 17, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 17, style: .continuous)
                .stroke(.orange.opacity(0.24), lineWidth: 1)
        )
        .contentTransition(.numericText())
    }

    private var walkMission: some View {
        HStack(spacing: 11) {
            ZStack {
                Circle()
                    .fill(Color.orange.opacity(0.16))
                Image(systemName: appModel.totalWoodCount == 0 ? "figure.walk.motion" : "figure.walk")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.orange)
            }
            .frame(width: 36, height: 36)

            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 5) {
                    Text(walkingMissionTitle)
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .lineLimit(1)
                        .minimumScaleFactor(0.78)
                    Spacer(minLength: 4)
                    Text("約\(walkingMinutes)分")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(.orange.opacity(0.90))
                }

                GeometryReader { proxy in
                    ZStack(alignment: .leading) {
                        Capsule().fill(.white.opacity(0.10))
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [.orange, .yellow],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: max(5, proxy.size.width * CGFloat(nextWoodProgress)))
                    }
                }
                .frame(height: 5)

                if let reward = appModel.nextCollectibleReward {
                    HStack(spacing: 4) {
                        Image(systemName: "flag.checkered")
                        Text("次の発見：\(reward.name)")
                        Spacer(minLength: 4)
                        Text("累計 \(reward.unlockSteps.formatted())歩")
                    }
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.66))
                }
            }
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 13)
        .frame(maxWidth: 340, minHeight: 66)
        .background(.black.opacity(emptyInventoryHint ? 0.72 : 0.56), in: RoundedRectangle(cornerRadius: 17, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 17, style: .continuous)
                .stroke(.orange.opacity(emptyInventoryHint ? 0.65 : 0.22), lineWidth: 1)
        )
        .scaleEffect(emptyInventoryHint ? 1.025 : 1)
        .animation(.spring(response: 0.34, dampingFraction: 0.72), value: emptyInventoryHint)
    }

    private var burnButton: some View {
        Button(action: burnWood) {
            HStack(spacing: 12) {
                WoodIconView(wood: appModel.selectedWood)
                    .frame(width: 52, height: 36)

                VStack(alignment: .leading, spacing: 2) {
                    Text(preparedWood == nil ? "\(appModel.selectedWood.name)を持つ" : "薪を上へスワイプ")
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                    Text(appModel.selectedWoodCount > 0 ? "手元に出してから投げます" : "選択モードを保持中・在庫0")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.70))
                }

                Spacer(minLength: 4)

                Text("\(appModel.selectedWoodCount)")
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
                            colors: appModel.selectedWoodCount > 0
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
            .shadow(color: .orange.opacity(appModel.selectedWoodCount > 0 ? 0.30 : 0), radius: 18, y: 7)
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
        MotivationEngine.stepsUntilNextWood(totalSteps: appModel.state.totalStepsAllTime)
    }

    private var nextWoodProgress: Double {
        MotivationEngine.nextWoodProgress(totalSteps: appModel.state.totalStepsAllTime)
    }

    private var walkingMinutes: Int {
        MotivationEngine.estimatedWalkingMinutes(for: stepsUntilNextWood)
    }

    private var walkingMissionTitle: String {
        if appModel.activeBurningFuelCount == 0 {
            return "火を復活させるまで、あと\(stepsUntilNextWood)歩"
        }
        if let end = appModel.fireQueueEndsAt,
           end.timeIntervalSinceNow < 4 * 60 * 60 {
            return "火を絶やさないため、あと\(stepsUntilNextWood)歩"
        }
        return "次の薪まで、あと\(stepsUntilNextWood)歩"
    }

    private func nextFuelLabel(_ fuel: BurningFuel, now: Date) -> String {
        let wood = WoodCatalog.wood(id: fuel.woodID) ?? WoodCatalog.standard
        return "次の\(wood.name)：あと\(compactDuration(fuel.expiresAt.timeIntervalSince(now)))"
    }

    private func queueEndLabel(now: Date) -> String {
        guard let end = appModel.fireQueueEndsAt else { return "火守り 0分" }
        return "火守り \(compactDuration(end.timeIntervalSince(now)))"
    }

    private func compactDuration(_ interval: TimeInterval) -> String {
        let minutes = max(0, Int(interval / 60))
        if minutes < 60 { return "\(max(1, minutes))分" }
        let hours = minutes / 60
        let remainingMinutes = minutes % 60
        if hours < 24 { return remainingMinutes > 0 ? "\(hours)時間\(remainingMinutes)分" : "\(hours)時間" }
        let days = hours / 24
        let remainingHours = hours % 24
        return remainingHours > 0 ? "\(days)日\(remainingHours)時間" : "\(days)日"
    }

    private func burnWood() {
        guard !isThrowingWood else { return }

        if appModel.selectedWoodCount > 0 {
            emptyInventoryHint = false
            isThrowingWood = true
            throwDrag = .zero
            withAnimation(.spring(response: 0.34, dampingFraction: 0.68)) {
                preparedWood = appModel.selectedWood
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

    private func finishBurn() {
        guard isThrowingWood else { return }
        isThrowingWood = false

        guard let burnedWood = appModel.burnSelectedWood() else { return }
        feedbackTrigger += 1
        fireBurstSequence += 1
        burnConfirmationText = "\(burnedWood.name)を投入・燃焼\(appModel.activeBurningFuelCount)本"

        withAnimation(.spring(response: 0.32, dampingFraction: 0.72)) {
            showBurnConfirmation = true
        }
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 1_350_000_000)
            withAnimation(.easeOut(duration: 0.22)) {
                showBurnConfirmation = false
            }
        }
    }

    private func throwableWood(_ wood: WoodType, in size: CGSize) -> some View {
        VStack(spacing: 7) {
            Label("上へスワイプして投げる", systemImage: "hand.draw.fill")
                .font(.caption.weight(.bold))
                .foregroundStyle(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(.black.opacity(0.68), in: Capsule())

            WoodIconView(wood: wood)
                .frame(width: 124, height: 66)
                .padding(8)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color(wood.flameTint).opacity(0.72), lineWidth: 2))
                .shadow(color: Color(wood.flameTint).opacity(0.50), radius: 18)
        }
        .contentShape(Rectangle())
        .position(x: size.width / 2, y: size.height * 0.76)
        .offset(throwDrag)
        .rotationEffect(.degrees(Double(throwDrag.width) * 0.08))
        .scaleEffect(1 + min(0.12, max(0, -throwDrag.height / 900)))
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    throwDrag = value.translation
                }
                .onEnded { value in
                    if value.translation.height < -52 {
                        let releasePoint = CGPoint(
                            x: size.width / 2 + value.translation.width,
                            y: size.height * 0.76 + value.translation.height
                        )
                        let swipe = value.translation
                        withAnimation(.easeOut(duration: 0.10)) {
                            preparedWood = nil
                            throwDrag = .zero
                        }
                        woodThrowController.launchWood(wood, from: releasePoint, swipe: swipe)
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
