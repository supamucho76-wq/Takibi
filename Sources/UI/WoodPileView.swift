import SwiftUI

struct WoodPileView: View {
    let heat: Double
    let burnSequence: Int
    let wood: WoodType

    @State private var arrivalGlow: Double = 0

    private var visuals: FireVisualState { FireVisualState(heat: heat) }

    var body: some View {
        ZStack {
            Ellipse()
                .fill(Color.black.opacity(0.72))
                .frame(width: 230, height: 46)
                .blur(radius: 12)
                .offset(y: 34)

            // The base pile stays stable. Newly burned logs now remain as real
            // SpriteKit bodies instead of appearing here automatically.
            ForEach(0..<3, id: \.self) { index in
                WoodIconView(wood: wood)
                    .frame(width: 184 - CGFloat(index % 3) * 9)
                    .rotationEffect(angle(for: index))
                    .offset(offset(for: index))
                    .brightness(-0.30 + visuals.environmentLight * 0.12)
                    .saturation(0.72 + visuals.environmentLight * 0.30)
                    .shadow(color: .orange.opacity(0.13 * visuals.environmentLight), radius: 7)
            }

            Circle()
                .fill(.orange.opacity(arrivalGlow * 0.34))
                .frame(width: 170, height: 80)
                .blur(radius: 24)
                .blendMode(.plusLighter)
        }
        .onChange(of: burnSequence) { _, _ in
            arrivalGlow = 1
            withAnimation(.easeOut(duration: 0.72)) {
                arrivalGlow = 0
            }
        }
    }

    private func angle(for index: Int) -> Angle {
        let angles: [Double] = [-16, 17, -5, 28, -30, 7]
        return .degrees(angles[index % angles.count])
    }

    private func offset(for index: Int) -> CGSize {
        let offsets: [CGSize] = [
            CGSize(width: -12, height: 15),
            CGSize(width: 12, height: 10),
            CGSize(width: 0, height: -2),
            CGSize(width: 5, height: -14),
            CGSize(width: -8, height: -24),
            CGSize(width: 3, height: -34)
        ]
        return offsets[index % offsets.count]
    }
}

