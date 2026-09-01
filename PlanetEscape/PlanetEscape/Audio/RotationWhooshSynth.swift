//
//  RotationWhooshSynth.swift
//  PlanetEscape
//
//  Created by Hades on 2026/7/31.
//

import Foundation
import AVFoundation

/// 星球旋转时的“呼呼”音效：一段短促的下滑正弦音，
/// 每次收到旋转指令时触发一次，音高随旋转幅度略微变化。
final class RotationWhooshSynth {
    private let engine: ProceduralAudioEngine
    private let playerNode: AVAudioPlayerNode
    private var subscription: SignalSubscription?

    init(engine: ProceduralAudioEngine) {
        self.engine = engine
        self.playerNode = engine.makePlayerNode()
        subscription = CosmicSignalRelay.current.subscribe { [weak self] event in
            self?.handle(event)
        }
        playerNode.play()
    }

    private func handle(_ event: GameEvent) {
        guard case .rotationRequested(let command) = event else { return }
        let magnitude = min(abs(command.angleRadians), Double.pi)
        let startFrequency = 320 + magnitude * 60
        guard let buffer = ToneBufferFactory.sineWave(
            duration: 0.18,
            startFrequency: startFrequency,
            endFrequency: startFrequency * 0.6,
            amplitude: 0.18
        ) else { return }
        playerNode.scheduleBuffer(buffer, at: nil, options: [], completionHandler: nil)
    }
}
