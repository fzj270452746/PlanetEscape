//
//  MeteorObject.swift
//  PlanetEscape
//
//  Created by Hades on 2026/7/31.
//

import Foundation
import SceneKit
import UIKit

/// 单个陨石实例（文档 8.3）：从星球上方随机高度落向表面，
/// 使用真实的 SCNPhysicsBody 动力学下落，落地或超时后由 MeteorSpawner 回收。
final class MeteorObject: HazardBehavior {
    let hazardID: String
    let kind: HazardKind = .meteor
    let rootNode: SCNNode
    /// 陨石落点的表面坐标（预测的着陆点，供 EscapeRouteAnalyzer 提前分析危险区域）。
    let surfaceCoordinate: SphereSurfaceCoordinate

    private(set) var hasLanded = false
    private var lifetime: TimeInterval = 0
    var maxLifetime: TimeInterval = 6.0
    private var dispatcher: CollisionSignalDispatcher?

    init(hazardID: String, targetCoordinate: SphereSurfaceCoordinate, radius: CGFloat = 0.18) {
        self.hazardID = hazardID
        self.surfaceCoordinate = targetCoordinate

        let sphere = SCNSphere(radius: radius)
        let material = SCNMaterial()
        material.diffuse.contents = UIColor(red: 0.35, green: 0.3, blue: 0.28, alpha: 1)
        material.roughness.contents = 0.95
        sphere.materials = [material]
        let node = SCNNode(geometry: sphere)
        node.name = "Meteor_\(hazardID)"
        self.rootNode = node
    }

    /// 由 MeteorSpawner 在挂载前设置初始局部位置（星球上方一定高度处）与下落速度方向。
    func configureInitialLocalPosition(_ position: SCNVector3) {
        rootNode.position = position
    }

    func activate(planet: PlanetBody, dispatcher: CollisionSignalDispatcher) {
        planet.rootNode.addChildNode(rootNode)
        self.dispatcher = dispatcher
        dispatcher.registerHazardNode(name: rootNode.name ?? "", hazardID: hazardID, kind: kind)
        SurfacePhysicsCoordinator.installDynamicMeteorBody(on: rootNode, radius: 0.18, mass: 0.4)

        // 施加一个朝向球心的初始冲量，让陨石看起来是"坠向"星球而不是自由飘浮。
        let towardCenter = rootNode.position.negated().normalizedSafely()
        let impulseScale: Float = 1.2
        rootNode.physicsBody?.applyForce(
            SCNVector3(towardCenter.x * impulseScale, towardCenter.y * impulseScale, towardCenter.z * impulseScale),
            asImpulse: true
        )

        rootNode.addParticleSystem(MeteorObject.makeTrailParticles())
    }

    func tick(deltaTime: TimeInterval) {
        lifetime += deltaTime
        if lifetime >= maxLifetime {
            hasLanded = true
        }
    }

    func deactivate() {
        dispatcher?.unregisterHazardNode(name: rootNode.name ?? "")
    }

    func markLanded() {
        hasLanded = true
    }

    private static func makeTrailParticles() -> SCNParticleSystem {
        let system = SCNParticleSystem()
        system.particleColor = UIColor(red: 1.0, green: 0.5, blue: 0.15, alpha: 0.9)
        system.birthRate = 50
        system.particleLifeSpan = 0.4
        system.particleVelocity = 0.2
        system.particleSize = 0.05
        system.blendMode = .additive
        return system
    }
}
