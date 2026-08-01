import Foundation
import SwiftUI

enum HeatEngine {
    static func decayedHeat(
        from heat: Double,
        updatedAt: Date,
        now: Date,
        halfLife: TimeInterval = GameConstants.heatHalfLife
    ) -> Double {
        let safeHeat = min(max(heat, GameConstants.minimumHeat), GameConstants.maximumHeat)
        let elapsed = max(0, now.timeIntervalSince(updatedAt))
        guard elapsed > 0, halfLife > 0 else { return safeHeat }

        let decayed = safeHeat * pow(0.5, elapsed / halfLife)
        return max(GameConstants.minimumHeat, decayed)
    }

    static func adding(_ amount: Double, to heat: Double) -> Double {
        min(GameConstants.maximumHeat, max(GameConstants.minimumHeat, heat) + max(0, amount))
    }

    static func normalized(_ heat: Double) -> Double {
        min(max(heat, 0), GameConstants.maximumHeat) / GameConstants.maximumHeat
    }
}

struct FireVisualState: Equatable {
    let normalizedHeat: Double
    let flameHeight: Double
    let flameWidth: Double
    let brightness: Double
    let environmentLight: Double
    let sparkDensity: Double
    let visibleLogCount: Int
    let stage: FireStage

    init(heat: Double) {
        let t = HeatEngine.normalized(heat)
        let alive = Self.smoothstep(0.08, 0.30, t)
        normalizedHeat = t
        flameHeight = 0.12 + 0.96 * pow(t, 0.72) * alive
        flameWidth = 0.18 + 0.72 * pow(t, 0.86)
        brightness = 0.20 + 0.80 * pow(t, 0.55)
        environmentLight = 0.08 + 0.92 * pow(t, 1.25)
        sparkDensity = Self.smoothstep(0.12, 0.95, t)
        visibleLogCount = min(6, max(1, 1 + Int((t * 5.5).rounded(.down))))
        switch t {
        case ..<0.20: stage = .embers
        case ..<0.46: stage = .small
        case ..<0.74: stage = .steady
        default: stage = .roaring
        }
    }

    private static func smoothstep(_ edge0: Double, _ edge1: Double, _ value: Double) -> Double {
        let x = min(max((value - edge0) / (edge1 - edge0), 0), 1)
        return x * x * (3 - 2 * x)
    }
}

enum FireStage: Equatable {
    case embers
    case small
    case steady
    case roaring

    var title: String {
        switch self {
        case .embers: "熾火"
        case .small: "小さな炎"
        case .steady: "よく燃えている"
        case .roaring: "大きな炎"
        }
    }

    var systemImage: String {
        switch self {
        case .embers: "circle.dotted.circle.fill"
        case .small: "flame"
        case .steady: "flame.fill"
        case .roaring: "flame.circle.fill"
        }
    }

    var tint: Color {
        switch self {
        case .embers: .red
        case .small: .orange
        case .steady: .yellow
        case .roaring: Color(red: 1.0, green: 0.92, blue: 0.62)
        }
    }
}

