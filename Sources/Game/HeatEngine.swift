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
    let smokeDensity: Double
    let companionOpacity: Double
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
        sparkDensity = 0.05 + 0.95 * Self.smoothstep(0.10, 0.92, t)
        smokeDensity = min(max(0.82 - t * 0.68, 0.10), 0.78)
        companionOpacity = Self.smoothstep(0.66, 0.94, t)
        visibleLogCount = min(6, max(1, 1 + Int((t * 5.5).rounded(.down))))

        switch t {
        case ..<0.18: stage = .fading
        case ..<0.38: stage = .small
        case ..<0.68: stage = .steady
        case ..<0.90: stage = .bonfire
        default: stage = .festival
        }
    }

    private static func smoothstep(_ edge0: Double, _ edge1: Double, _ value: Double) -> Double {
        let x = min(max((value - edge0) / (edge1 - edge0), 0), 1)
        return x * x * (3 - 2 * x)
    }
}

enum FireStage: Int, Codable, CaseIterable, Equatable {
    case fading = 1
    case small
    case steady
    case bonfire
    case festival

    var level: Int { rawValue }

    var title: String {
        switch self {
        case .fading: "消えかけ"
        case .small: "小さな火"
        case .steady: "安定した火"
        case .bonfire: "大きな焚き火"
        case .festival: "祝祭の炎"
        }
    }

    var message: String {
        switch self {
        case .fading: "火が弱まっています"
        case .small: "小さな火が息づいています"
        case .steady: "今夜の火は安定しています"
        case .bonfire: "森の奥まで光が届いています"
        case .festival: "森が祝祭の光に包まれています"
        }
    }

    var systemImage: String {
        switch self {
        case .fading: "circle.dotted.circle.fill"
        case .small: "flame"
        case .steady: "flame.fill"
        case .bonfire: "flame.circle.fill"
        case .festival: "sparkles"
        }
    }

    var tint: Color {
        switch self {
        case .fading: .red
        case .small: .orange
        case .steady: .yellow
        case .bonfire: Color(red: 1.0, green: 0.92, blue: 0.62)
        case .festival: Color(red: 1.0, green: 0.72, blue: 0.95)
        }
    }

    var ambienceVolume: Float {
        switch self {
        case .fading: 0.14
        case .small: 0.22
        case .steady: 0.30
        case .bonfire: 0.38
        case .festival: 0.46
        }
    }
}
