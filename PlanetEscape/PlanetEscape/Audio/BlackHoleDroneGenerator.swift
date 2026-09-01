//
//  BlackHoleDroneGenerator.swift
//  PlanetEscape
//
//  Created by Hades on 2026/7/31.
//

import Foundation
import AVFoundation

/// 黑洞的低频嗡鸣音：角色越靠近黑洞（BlackHoleEscapeAssist 报告的吸引强度越高），
/// 音量越大，营造危险临近感。持续循环播放一段低频正弦波，只调节音量而非重新生成波形。
final class BlackHoleDroneGenerator {
    private let engine: ProceduralAudioEngine
    private let playerNode: AVAudioPlayerNode
    private var subscription: SignalSubscription?

    init(engine: ProceduralAudioEngine) {
        self.engine = engine
        self.playerNode = engine.makePlayerNode()
        playerNode.volume = 0
        subscription = CosmicSignalRelay.current.subscribe { [weak self] event in
            guard case .blackHolePullStrengthChanged(let strength) = event else { return }
            self?.setPullStrength(strength)
        }
    }

    func start() {
        guard let buffer = ToneBufferFactory.sineWave(duration: 3.0, startFrequency: 55, endFrequency: 60, amplitude: 0.3) else { return }
        playerNode.scheduleBuffer(buffer, at: nil, options: .loops, completionHandler: nil)
        playerNode.play()
    }

    func setPullStrength(_ strength: Double) {
        playerNode.volume = Float(min(max(strength, 0), 1)) * 0.6
    }
}
