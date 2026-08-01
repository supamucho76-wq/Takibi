import MetalKit
import SwiftUI

struct FireView: UIViewRepresentable {
    let heat: Double
    let isActive: Bool

    final class Coordinator {
        var renderer: FireRenderer?
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> MTKView {
        guard let device = MTLCreateSystemDefaultDevice() else {
            return MTKView(frame: .zero)
        }

        let view = MTKView(frame: .zero, device: device)
        view.colorPixelFormat = .bgra8Unorm
        view.clearColor = MTLClearColorMake(0, 0, 0, 0)
        view.isOpaque = false
        view.backgroundColor = .clear
        view.layer.isOpaque = false
        view.framebufferOnly = true
        view.enableSetNeedsDisplay = false
        view.isPaused = !isActive
        view.preferredFramesPerSecond = ProcessInfo.processInfo.isLowPowerModeEnabled ? 30 : 60

        let renderer = FireRenderer(view: view)
        renderer.heat = Float(heat)
        renderer.isActive = isActive
        context.coordinator.renderer = renderer
        view.delegate = renderer
        return view
    }

    func updateUIView(_ view: MTKView, context: Context) {
        context.coordinator.renderer?.heat = Float(heat)
        context.coordinator.renderer?.isActive = isActive
        view.preferredFramesPerSecond = ProcessInfo.processInfo.isLowPowerModeEnabled ? 30 : 60
        view.isPaused = !isActive
    }

    static func dismantleUIView(_ view: MTKView, coordinator: Coordinator) {
        coordinator.renderer?.isActive = false
        view.isPaused = true
        view.delegate = nil
    }
}

