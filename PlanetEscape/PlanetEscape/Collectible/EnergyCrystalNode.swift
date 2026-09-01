//
//  EnergyCrystalNode.swift
//  PlanetEscape
//
//  Created by Hades on 2026/7/31.
//

import Foundation
import SceneKit

/// 单个能量水晶收集品：程序化几何体（八面体近似用双锥体拼出），
/// 挂载到星球表面坐标，靠近角色时被 CollisionSignalDispatcher 判定拾取。
final class EnergyCrystalNode {
    let collectibleID: String
    let tier: CollectibleValueTier
    let surfaceCoordinate: SphereSurfaceCoordinate
    let rootNode: SCNNode

    private(set) var isCollected = false
    private var spinPhase: Double = 0

    init(collectibleID: String, tier: CollectibleValueTier, coordinate: SphereSurfaceCoordinate) {
        self.collectibleID = collectibleID
        self.tier = tier
        self.surfaceCoordinate = coordinate

        let geometry = SCNPyramid(width: 0.12, height: 0.16, length: 0.12)
        let material = SCNMaterial()
        material.diffuse.contents = tier.displayColor
        material.emission.contents = tier.displayColor
        material.lightingModel = .physicallyBased
        material.metalness.contents = 0.2
        material.roughness.contents = 0.15
        geometry.materials = [material]

        let node = SCNNode(geometry: geometry)
        node.name = "Crystal_\(collectibleID)"
        self.rootNode = node
    }

    func activate(planet: PlanetBody, dispatcher: CollisionSignalDispatcher) {
        planet.attachSurfaceObject(rootNode, at: surfaceCoordinate)
        dispatcher.registerCollectibleNode(name: rootNode.name ?? "", collectibleID: collectibleID, value: tier.pointValue)
        SurfacePhysicsCoordinator.installCollectibleBody(on: rootNode, radius: 0.14)
    }

    func tick(deltaTime: TimeInterval) {
        guard !isCollected else { return }
        spinPhase += deltaTime
        rootNode.eulerAngles.y = Float(spinPhase * 1.6)
        rootNode.position.y += Float(sin(spinPhase * 2) * 0.0006)
    }

    func markCollected() {
        isCollected = true
        rootNode.removeFromParentNode()
    }
}
