import SwiftUI

struct WoodPileView: View {
    let heat: Double
    let burnSequence: Int
    let burningFuels: [BurningFuel]

    @State private var arrivalGlow: Double = 0

    private var visuals: FireVisualState {
        FireVisualState(heat: heat)
    }

    private var visibleFuels: [BurningFuel] {
        Array(burningFuels.suffix(8))
    }

    private var overflowCount: Int {
        max(0, burningFuels.count - visibleFuels.count)
    }

    var body: some View {
        ZStack {
            Ellipse()
                .fill(Color.black.opacity(0.74))
                .frame(width: 238, height: 48)
                .blur(radius: 12)
                .offset(y: 34)

            emberBed

            ForEach(visibleFuels) { fuel in
                fuelView(fuel)
                    .transition(
                        .asymmetric(
                            insertion: .scale(scale: 1.22)
                                .combined(with: .move(edge: .top))
                                .combined(with: .opacity),
                            removal: .scale(scale: 0.62).combined(with: .opacity)
                        )
                    )
            }

            if overflowCount > 0 {
                Text("+\(overflowCount)")
                    .font(.caption2.bold())
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.black.opacity(0.68), in: Capsule())
                    .offset(x: 92, y: -31)
            }

            Circle()
                .fill(.orange.opacity(arrivalGlow * 0.36))
                .frame(width: 176, height: 84)
                .blur(radius: 25)
                .blendMode(.plusLighter)
        }
        .animation(.spring(response: 0.48, dampingFraction: 0.76), value: burningFuels)
        .onChange(of: burnSequence) { _, _ in
            arrivalGlow = 1
            withAnimation(.easeOut(duration: 0.78)) {
                arrivalGlow = 0
            }
        }
    }

    private var emberBed: some View {
        ZStack {
            Ellipse()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.orange.opacity(0.32 * visuals.brightness),
                            Color.red.opacity(0.18 * visuals.brightness),
                            .black.opacity(0.72),
                        ],
                        center: .center,
                        startRadius: 2,
                        endRadius: 74
                    )
                )
                .frame(width: 168, height: 42)
                .blur(radius: 4)

            ForEach(0 ..< 6, id: \.self) { index in
                Circle()
                    .fill(index.isMultiple(of: 2) ? Color.red.opacity(0.58) : Color.orange.opacity(0.62))
                    .frame(width: 8 + CGFloat(index % 3) * 3)
                    .offset(
                        x: CGFloat(index - 3) * 19,
                        y: CGFloat((index * 7) % 13) - 6
                    )
                    .blur(radius: 1.5)
            }
        }
        .offset(y: 24)
    }

    private func fuelView(_ fuel: BurningFuel) -> some View {
        let wood = WoodCatalog.wood(id: fuel.woodID) ?? WoodCatalog.standard
        let remaining = fuel.remainingFraction(at: Date())
        return WoodIconView(wood: wood)
            .frame(
                width: 174 * fuel.placement.scale,
                height: 80 * fuel.placement.scale
            )
            .rotationEffect(.degrees(fuel.placement.rotationDegrees))
            .offset(
                x: fuel.placement.horizontal * 108,
                y: fuel.placement.vertical * 64
            )
            .brightness(-0.34 + visuals.environmentLight * 0.13 - (1 - remaining) * 0.10)
            .saturation(0.58 + remaining * 0.36 + visuals.environmentLight * 0.18)
            .opacity(0.72 + remaining * 0.28)
            .shadow(
                color: Color(wood.flameTint).opacity(0.12 + visuals.environmentLight * 0.10),
                radius: 7
            )
            .id(fuel.id)
    }
}
