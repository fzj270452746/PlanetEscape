//
//  CollectChimeSynth.swift
//  PlanetEscape
//
//  Created by Hades on 2026/7/31.
//

import Foundation
import AVFoundation

/// 收集能量水晶时的清脆提示音：音高上扬的短促正弦音，
/// 数值越高（Gold > Green > Blue）音调越高，给玩家即时的价值反馈。
final class CollectChimeSynth {
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
        guard case .collectibleGathered(_, let value) = event else { return }
        let baseFrequency: Double
        switch value {
        case 20: baseFrequency = 880
        case 5: baseFrequency = 660
        default: baseFrequency = 520
        }
        guard let buffer = ToneBufferFactory.sineWave(
            duration: 0.22,
            startFrequency: baseFrequency,
            endFrequency: baseFrequency * 1.4,
            amplitude: 0.25
        ) else { return }
        playerNode.scheduleBuffer(buffer, at: nil, options: [], completionHandler: nil)
    }
}
