//
//  CelebrationBurstEffect.swift
//  PlanetEscape
//
//  Created by Hades on 2026/7/31.
//

import Foundation
import SceneKit
import UIKit

/// 通关庆祝的一次性粒子爆发效果，配合 TinyBotAnimationState.celebrating 播放。
/// 与 TrailRibbonEffect 分开：拖尾是持续挂载的，庆祝爆发是一次性触发后自动消亡的，
/// 生命周期语义不同不合并成同一个类型。
final class CelebrationBurstEffect {
    static func spawn(at node: SCNNode) {
        let system = SCNParticleSystem()
        system.particleColor = UIColor(red: 1.0, green: 0.9, blue: 0.4, alpha: 1)
        system.birthRate = 0
        system.emissionDuration = 0.1
        system.loops = false
        system.particleLifeSpan = 1.2
        system.particleVelocity = 1.5
        system.particleVelocityVariation = 0.8
        system.spreadingAngle = 180
        system.particleSize = 0.06
        system.blendMode = .additive
        system.birthRate = 120

        node.addParticleSystem(system)

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) {
            node.removeParticleSystem(system)
        }
    }
}
