//
//  TrailRibbonEffect.swift
//  PlanetEscape
//
//  Created by Hades on 2026/7/31.
//

import Foundation
import SceneKit
import UIKit

/// 角色身后的拖尾特效（文档第 12 节解锁项之一：新拖尾效果）。
/// 用 SCNParticleSystem 的 trail 发射方式实现，不同解锁款式只是换粒子颜色/形状参数，
/// 所以这里做成一个可配置样式的结构体而不是为每种拖尾写一个子类。
struct TrailStyle {
    let color: UIColor
    let particleSize: CGFloat
    let birthRate: CGFloat

    static let spark = TrailStyle(color: UIColor(red: 1.0, green: 0.85, blue: 0.3, alpha: 0.9), particleSize: 0.04, birthRate: 40)
    static let comet = TrailStyle(color: UIColor(red: 0.4, green: 0.8, blue: 1.0, alpha: 0.9), particleSize: 0.06, birthRate: 70)
}

final class TrailRibbonEffect {
    private let particleSystem: SCNParticleSystem
    private weak var attachedNode: SCNNode?

    init(style: TrailStyle) {
        let system = SCNParticleSystem()
        system.particleColor = style.color
        system.particleSize = style.particleSize
        system.birthRate = style.birthRate
        system.particleLifeSpan = 0.6
        system.particleVelocity = 0.05
        system.blendMode = .additive
        system.emitterShape = SCNSphere(radius: 0.02)
        self.particleSystem = system
    }

    func attach(to node: SCNNode) {
        node.addParticleSystem(particleSystem)
        attachedNode = node
    }

    func detach() {
        attachedNode?.removeParticleSystem(particleSystem)
        attachedNode = nil
    }

    func setEnabled(_ enabled: Bool) {
        particleSystem.birthRate = enabled ? particleSystem.birthRate : 0
    }
}
