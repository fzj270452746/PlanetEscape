//
//  ImpactShakeEffect.swift
//  PlanetEscape
//
//  Created by Hades on 2026/7/31.
//

import Foundation
import SceneKit

/// 碰撞/失衡时的摄像机抖动反馈，订阅 GameEvent.cameraShakeRequested，
/// 对 OrbitCameraRig 节点施加短暂的随机位移衰减，增强打击感。
final class ImpactShakeEffect {
    private weak var cameraNode: SCNNode?
    private var subscription: SignalSubscription?

    private var shakeTimeRemaining: TimeInterval = 0
    private var shakeMagnitude: Float = 0
    private var basePosition: SCNVector3?

    init(cameraNode: SCNNode) {
        self.cameraNode = cameraNode
        subscription = CosmicSignalRelay.current.subscribe { [weak self] event in
            self?.handle(event)
        }
    }

    private func handle(_ event: GameEvent) {
        guard case .cameraShakeRequested(let intensity) = event else { return }
        shakeMagnitude = intensity
        shakeTimeRemaining = 0.35
    }

    func advance(deltaTime: TimeInterval) {
        guard let node = cameraNode, shakeTimeRemaining > 0 else { return }
        if basePosition == nil { basePosition = node.position }
        shakeTimeRemaining -= deltaTime

        let decay = Float(max(shakeTimeRemaining, 0) / 0.35)
        let offsetX = Float.random(in: -1...1) * shakeMagnitude * decay * 0.05
        let offsetY = Float.random(in: -1...1) * shakeMagnitude * decay * 0.05

        if let base = basePosition {
            node.position = SCNVector3(base.x + offsetX, base.y + offsetY, base.z)
        }

        if shakeTimeRemaining <= 0, let base = basePosition {
            node.position = base
            basePosition = nil
        }
    }
}
