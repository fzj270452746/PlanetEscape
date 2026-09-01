//
//  BlackHoleGravityWell.swift
//  PlanetEscape
//
//  Created by Hades on 2026/7/31.
//

import Foundation
import SceneKit
import UIKit

/// 黑洞障碍（文档 8.2）：用 SCNPhysicsField.radialGravityField 制造吸引力场，
/// 玩家需要快速旋转星球来改变角色轨迹，避免被吸入。
/// 由于角色位置由 SphereSurfaceCoordinate 驱动而非纯物理模拟，
/// 这里额外提供 pullStrength(at:) 供 ExplorerMotionUnit/CharacterFallGuard
/// 主动查询"角色当前是否处于黑洞影响范围"，物理场本身只用于视觉/粒子层面的其他物体。
final class BlackHoleGravityWell: HazardBehavior {
    let hazardID: String
    let kind: HazardKind = .blackHole
    let rootNode: SCNNode
    let surfaceCoordinate: SphereSurfaceCoordinate

    /// 影响半径（文档给出 3~8）。
    var effectRadius: Double
    /// 最大吸引强度，用于计算角色被拉向黑洞中心的等效位移。
    var maxPullStrength: Double

    private var dispatcher: CollisionSignalDispatcher?
    private var rotationPhase: Double = 0

    init(hazardID: String, coordinate: SphereSurfaceCoordinate, effectRadius: Double = 5.0, maxPullStrength: Double = 1.6) {
        self.hazardID = hazardID
        self.surfaceCoordinate = coordinate
        self.effectRadius = effectRadius
        self.maxPullStrength = maxPullStrength

        let sphere = SCNSphere(radius: 0.35)
        let material = SCNMaterial()
        material.diffuse.contents = UIColor.black
        material.emission.contents = UIColor(red: 0.3, green: 0.05, blue: 0.4, alpha: 1)
        sphere.materials = [material]
        let node = SCNNode(geometry: sphere)
        node.name = "BlackHole_\(hazardID)"
        self.rootNode = node
    }

    func activate(planet: PlanetBody, dispatcher: CollisionSignalDispatcher) {
        planet.attachSurfaceObject(rootNode, at: surfaceCoordinate)
        self.dispatcher = dispatcher
        dispatcher.registerHazardNode(name: rootNode.name ?? "", hazardID: hazardID, kind: kind)

        let field = SCNPhysicsField.radialGravity()
        field.strength = CGFloat(maxPullStrength * 40)
        field.falloffExponent = 2
        field.minimumDistance = 0.4
        field.categoryBitMask = SurfacePhysicsCoordinator.Category.meteor | SurfacePhysicsCoordinator.Category.explorer
        rootNode.physicsField = field

        rootNode.addParticleSystem(BlackHoleGravityWell.makeAccretionParticles())
    }

    func tick(deltaTime: TimeInterval) {
        rotationPhase += deltaTime
        rootNode.eulerAngles.y = Float(rotationPhase)
    }

    func deactivate() {
        dispatcher?.unregisterHazardNode(name: rootNode.name ?? "")
    }

    /// 给定角色的表面坐标，返回 0~1 的归一化吸引强度，供角色速度/摄像机抖动等参考。
    func pullStrength(at coordinate: SphereSurfaceCoordinate, planetRadius: Double) -> Double {
        let angularDistance = surfaceCoordinate.greatCircleDistance(to: coordinate)
        let arcDistance = angularDistance * planetRadius
        guard arcDistance < effectRadius else { return 0 }
        let normalized = 1 - (arcDistance / effectRadius)
        return max(0, min(1, normalized)) * maxPullStrength
    }

    private static func makeAccretionParticles() -> SCNParticleSystem {
        let system = SCNParticleSystem()
        system.particleColor = UIColor(red: 0.6, green: 0.2, blue: 0.9, alpha: 0.8)
        system.birthRate = 30
        system.particleLifeSpan = 1.2
        system.particleVelocity = 0.8
        system.particleSize = 0.03
        system.blendMode = .additive
        system.emitterShape = SCNSphere(radius: 0.8)
        return system
    }
}
