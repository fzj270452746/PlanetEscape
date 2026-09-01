//
//  ParticleBudgetLimiter.swift
//  PlanetEscape
//
//  Created by Hades on 2026/7/31.
//

import Foundation
import SceneKit

/// 文档第 21 节性能目标（iPhone 11+ 60FPS，粒子限制）：
/// 统一限制同时激活的粒子系统数量，超出预算时优先关闭距离摄像机最远、
/// 或最早激活的粒子系统，避免多个火山同时喷发导致的粒子风暴拖垮帧率。
final class ParticleBudgetLimiter {
    struct TrackedSystem {
        let node: SCNNode
        let system: SCNParticleSystem
        let activatedAt: TimeInterval
    }

    var maxActiveSystems: Int = 12
    private var tracked: [TrackedSystem] = []
    private var clockValue: TimeInterval = 0

    func requestActivation(system: SCNParticleSystem, on node: SCNNode) -> Bool {
        clockValue += 1
        if tracked.count >= maxActiveSystems {
            evictOldest()
        }
        guard tracked.count < maxActiveSystems else { return false }
        node.addParticleSystem(system)
        tracked.append(TrackedSystem(node: node, system: system, activatedAt: clockValue))
        return true
    }

    func releaseActivation(system: SCNParticleSystem, on node: SCNNode) {
        node.removeParticleSystem(system)
        tracked.removeAll { $0.system === system && $0.node === node }
    }

    private func evictOldest() {
        guard let oldest = tracked.min(by: { $0.activatedAt < $1.activatedAt }) else { return }
        releaseActivation(system: oldest.system, on: oldest.node)
    }

    var currentActiveCount: Int { tracked.count }
}
