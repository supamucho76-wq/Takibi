import AVFoundation
import Combine
import Foundation

@MainActor
final class FireAudioService: ObservableObject {
    private let engine = AVAudioEngine()
    private let player = AVAudioPlayerNode()
    private let sampleRate: Float = 44_100
    private let format = AVAudioFormat(standardFormatWithSampleRate: 44_100, channels: 2)!
    private var isPrepared = false

    init() {
        engine.attach(player)
        engine.connect(player, to: engine.mainMixerNode, format: format)
        try? AVAudioSession.sharedInstance().setCategory(.ambient, options: [.mixWithOthers])
    }

    func start(stage: FireStage) {
        prepareIfNeeded()
        player.volume = stage.ambienceVolume
        try? AVAudioSession.sharedInstance().setActive(true)
        if !engine.isRunning { try? engine.start() }
        if !player.isPlaying { player.play() }
    }

    func update(stage: FireStage) {
        player.volume = stage.ambienceVolume
    }

    func stop() {
        player.pause()
        engine.pause()
    }

    private func prepareIfNeeded() {
        guard !isPrepared, let buffer = makeCrackleBuffer() else { return }
        isPrepared = true
        player.scheduleBuffer(buffer, at: nil, options: [.loops])
    }

    private func makeCrackleBuffer() -> AVAudioPCMBuffer? {
        let frameCount = AVAudioFrameCount(Int(sampleRate) * 8)
        guard
            let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount),
            let channels = buffer.floatChannelData
        else { return nil }

        buffer.frameLength = frameCount
        var seed: UInt32 = 0x4B_55_42_45
        var warmLeft: Float = 0
        var warmRight: Float = 0
        var airLeft: Float = 0
        var airRight: Float = 0
        var previousAirLeft: Float = 0
        var previousAirRight: Float = 0
        var popEnvelope: Float = 0
        var popPan: Float = 0.5
        var popPhase: Float = 0
        var popFrequency: Float = 1_350
        var framesUntilPop = Int(sampleRate * 0.16)

        for frame in 0 ..< Int(frameCount) {
            let rawLeft = randomSample(seed: &seed)
            let rawRight = randomSample(seed: &seed)

            warmLeft += (rawLeft - warmLeft) * 0.0028
            warmRight += (rawRight - warmRight) * 0.0028
            airLeft += (rawLeft - airLeft) * 0.075
            airRight += (rawRight - airRight) * 0.075
            let dryAirLeft = airLeft - previousAirLeft
            let dryAirRight = airRight - previousAirRight
            previousAirLeft = airLeft
            previousAirRight = airRight

            framesUntilPop -= 1
            if framesUntilPop <= 0 {
                let strength = 0.28 + (randomSample(seed: &seed) + 1) * 0.20
                popEnvelope = strength
                popPan = 0.18 + (randomSample(seed: &seed) + 1) * 0.32
                popFrequency = 900 + (randomSample(seed: &seed) + 1) * 720
                popPhase = 0
                let gap = 0.10 + (randomSample(seed: &seed) + 1) * 0.26
                framesUntilPop = max(1, Int(sampleRate * gap))
            }

            popPhase += 2 * .pi * popFrequency / sampleRate
            let woodyKnock = sin(popPhase) * popEnvelope
            let crack = randomSample(seed: &seed) * popEnvelope * 0.72 + woodyKnock * 0.28
            popEnvelope *= 0.99908

            let slowBreath = 0.86 + 0.14 * sin(Float(frame) / sampleRate * 2 * .pi * 0.23)
            let bedLeft = warmLeft * 0.42 + dryAirLeft * 0.36 + rawLeft * 0.016
            let bedRight = warmRight * 0.42 + dryAirRight * 0.36 + rawRight * 0.016
            channels[0][frame] = softClip(bedLeft * slowBreath + crack * (1 - popPan) * 0.40)
            channels[1][frame] = softClip(bedRight * slowBreath + crack * popPan * 0.40)
        }
        return buffer
    }

    private func randomSample(seed: inout UInt32) -> Float {
        seed = 1_664_525 &* seed &+ 1_013_904_223
        return Float(seed & 0xFFFF) / Float(0x7FFF) - 1
    }

    private func softClip(_ sample: Float) -> Float {
        sample / (1 + abs(sample))
    }
}
