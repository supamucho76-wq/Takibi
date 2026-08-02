import SwiftUI

struct CollectionView: View {
    @EnvironmentObject private var appModel: AppModel
    @Environment(\.dismiss) private var dismiss
    @State private var section: CollectionSection = .wood

    private enum CollectionSection: String, CaseIterable, Identifiable {
        case wood = "薪"
        case flame = "炎"
        case background = "背景"
        var id: String { rawValue }
    }

    private let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]

    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                Picker("コレクション", selection: $section) {
                    ForEach(CollectionSection.allCases) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                HStack {
                    Text("累計 \(appModel.state.totalStepsAllTime.formatted())歩")
                    Spacer()
                    Text(unlockSummary)
                }
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 18)

                ScrollView {
                    LazyVGrid(columns: columns, spacing: 12) {
                        switch section {
                        case .wood:
                            ForEach(WoodCatalog.all) { woodCard($0) }
                        case .flame:
                            ForEach(FlameCatalog.all) { flameCard($0) }
                        case .background:
                            ForEach(BackgroundCatalog.all) { backgroundCard($0) }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 30)
                }
            }
            .navigationTitle("火守りコレクション")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("閉じる") { dismiss() } } }
        }
    }

    private var unlockSummary: String {
        switch section {
        case .wood: "解放 \(appModel.state.unlockedWoodIDs.count)/10"
        case .flame: "解放 \(appModel.state.unlockedFlameIDs.count)/10"
        case .background: "解放 \(appModel.state.unlockedBackgroundIDs.count)/10"
        }
    }

    private func woodCard(_ wood: WoodType) -> some View {
        let unlocked = appModel.state.unlockedWoodIDs.contains(wood.id)
        let selected = appModel.state.selectedWoodID == wood.id
        let count = appModel.state.woodInventory[wood.id, default: 0]
        return Button { appModel.selectWood(wood) } label: {
            collectibleShell(name: wood.name, rarity: wood.rarity, unlocked: unlocked, selected: selected, unlockSteps: wood.unlockSteps) {
                WoodIconView(wood: wood)
                    .rotationEffect(.degrees(-9))
                    .padding(.horizontal, 10)
                    .overlay(alignment: .bottomTrailing) {
                        if unlocked { Text("×\(count)").font(.caption.bold()).padding(5).background(.black.opacity(0.62), in: Capsule()) }
                    }
            }
        }
        .buttonStyle(.plain)
        .disabled(!unlocked)
    }

    private func flameCard(_ flame: FlameStyle) -> some View {
        let unlocked = appModel.state.unlockedFlameIDs.contains(flame.id)
        let selected = appModel.state.selectedFlameID == flame.id
        return Button { appModel.selectFlame(flame) } label: {
            collectibleShell(name: flame.name, rarity: flame.rarity, unlocked: unlocked, selected: selected, unlockSteps: flame.unlockSteps) {
                ZStack {
                    Circle().fill(Color(flame.tint).opacity(0.22)).blur(radius: 7)
                    Image(systemName: "flame.fill")
                        .font(.system(size: 48, weight: .medium))
                        .foregroundStyle(Color(flame.tint))
                        .shadow(color: Color(flame.tint), radius: 12)
                }
            }
        }
        .buttonStyle(.plain)
        .disabled(!unlocked)
    }

    private func backgroundCard(_ theme: BackgroundTheme) -> some View {
        let unlocked = appModel.state.unlockedBackgroundIDs.contains(theme.id)
        let selected = appModel.state.selectedBackgroundID == theme.id
        return Button { appModel.selectBackground(theme) } label: {
            collectibleShell(name: theme.name, rarity: theme.rarity, unlocked: unlocked, selected: selected, unlockSteps: theme.unlockSteps) {
                Image(theme.imageName)
                    .resizable()
                    .scaledToFill()
                    .hueRotation(.degrees(theme.hueDegrees))
                    .saturation(theme.saturation)
                    .brightness(theme.brightness)
                    .overlay(Color(theme.overlayTint).opacity(0.18))
                    .clipped()
            }
        }
        .buttonStyle(.plain)
        .disabled(!unlocked)
    }

    private func collectibleShell<Preview: View>(
        name: String,
        rarity: Rarity,
        unlocked: Bool,
        selected: Bool,
        unlockSteps: Int,
        @ViewBuilder preview: () -> Preview
    ) -> some View {
        VStack(spacing: 7) {
            ZStack {
                RoundedRectangle(cornerRadius: 15).fill(Color.black.opacity(0.48))
                preview()
                    .opacity(unlocked ? 1 : 0.20)
                if !unlocked {
                    VStack(spacing: 3) {
                        Image(systemName: "lock.fill")
                        Text("累計 \(unlockSteps.formatted())歩")
                            .font(.caption2.bold())
                    }
                    .foregroundStyle(.white)
                }
            }
            .frame(height: 104)

            Text(name).font(.caption.weight(.bold)).lineLimit(1)
            Text(selected ? "選択中 ✓" : rarity.title)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(selected ? Color.orange : rarity.color)
        }
        .padding(8)
        .background(Color(uiColor: .secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(selected ? Color.orange : rarity.color.opacity(unlocked ? 0.38 : 0.12), lineWidth: selected ? 2 : 1))
    }
}

extension Color {
    init(_ tint: FlameTint) {
        self.init(red: tint.red, green: tint.green, blue: tint.blue)
    }
}

private extension Rarity {
    var color: Color {
        switch self {
        case .common: .secondary
        case .uncommon: .green
        case .rare: .blue
        case .epic: .purple
        case .legendary: .orange
        }
    }
}
