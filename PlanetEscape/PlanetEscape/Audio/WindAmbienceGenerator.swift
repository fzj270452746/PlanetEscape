//
//  WindAmbienceGenerator.swift
//  PlanetEscape
//
//  Created by Hades on 2026/7/31.
//

import Foundation
import AVFoundation

/// 持续循环播放的风声环境音，用滤波白噪声生成，音量随角色前进速度轻微起伏。
final class WindAmbienceGenerator {
    private let engine: ProceduralAudioEngine
    private let playerNode: AVAudioPlayerNode
    private var loopBuffer: AVAudioPCMBuffer?

    init(engine: ProceduralAudioEngine) {
        self.engine = engine
        self.playerNode = engine.makePlayerNode()
    }

    func start() {
        guard let buffer = ToneBufferFactory.filteredNoise(duration: 2.5, amplitude: 0.08) else { return }
        loopBuffer = buffer
        playerNode.scheduleBuffer(buffer, at: nil, options: .loops, completionHandler: nil)
        playerNode.play()
    }

    func stop() {
        playerNode.stop()
    }

    func setIntensity(_ intensity: Float) {
        playerNode.volume = min(max(intensity, 0), 1)
    }
}
