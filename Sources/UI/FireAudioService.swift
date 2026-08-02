import AVFoundation
import Combine
import Foundation

@MainActor
final class FireAudioService: ObservableObject {
    private let engine = AVAudioEngine()
    private let player = AVAudioPlayerNode()
    private let format = AVAudioFormat(standardFormatWithSampleRate: 44_100, channels: 1)!
    private var isPrepared = false

    init() {
        engine.attach(player)
        engine.connect(player, to: engine.mainMixerNode, format: format)
        try? AVAudioSession.sharedInstance().setCategory(.ambient, options: [.mixWithOthers])
    }

    func start(stage: FireStage) {
        prepareIfNeeded()
        player.volume = stage.ambienceVolume
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
        let frameCount = AVAudioFrameCount(44_100 * 2)
        guard
            let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount),
            let samples = buffer.floatChannelData?[0]
        else { return nil }

        buffer.frameLength = frameCount
        var seed: UInt32 = 0x4B_55_42_45
        var popEnvelope: Float = 0
        for frame in 0 ..< Int(frameCount) {
            seed = 1_664_525 &* seed &+ 1_013_904_223
            let noise = Float(seed & 0xFFFF) / Float(0xFFFF) * 2 - 1
            if seed.isMultiple(of: 2_137) { popEnvelope = Float.random(in: 0.25 ... 0.62) }
            popEnvelope *= 0.986
            let slow = sin(Float(frame) / 44_100 * 2 * .pi * 52) * 0.018
            samples[frame] = noise * (0.020 + popEnvelope * 0.12) + slow
        }
        return buffer
    }
}
