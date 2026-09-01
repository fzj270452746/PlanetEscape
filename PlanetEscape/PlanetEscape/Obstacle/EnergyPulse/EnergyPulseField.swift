//
//  EnergyPulseField.swift
//  PlanetEscape
//
//  Created by Hades on 2026/7/31.
//

import Foundation
import SceneKit
import UIKit

/// Cyber Planet 章节特有的危险（文档 10.1 Cyber Planet 元素：能量管）。
/// 沿一条纬线布置的能量管周期性放电，放电瞬间形成一次性冲击而非持续危险，
/// 与 LaserSweepEmitter（持续旋转的光束）在体验上形成区分：这是"定点周期打击"而不是"扫射"。
final class EnergyPulseField: HazardBehavior {
    let hazardID: String
    let kind: HazardKind = .laser
    let rootNode: SCNNode
    let surfaceCoordinate: SphereSurfaceCoordinate

    var chargeDuration: TimeInterval = 1.6
    var dischargeDuration: TimeInterval = 0.3
    private var phaseTimer: TimeInterval = 0
    private var isDischarging = false
    private var dispatcher: CollisionSignalDispatcher?

    private let coreNode: SCNNode

    init(hazardID: String, coordinate: SphereSurfaceCoordinate, coreRadius: CGFloat = 0.12) {
        self.hazardID = hazardID
        self.surfaceCoordinate = coordinate

        let pivot = SCNNode()
        pivot.name = "EnergyPulse_\(hazardID)"
        self.rootNode = pivot

        let core = SCNSphere(radius: coreRadius)
        let material = SCNMaterial()
        material.diffuse.contents = UIColor(red: 0.1, green: 0.85, blue: 0.9, alpha: 1)
        material.emission.contents = UIColor(red: 0.1, green: 0.85, blue: 0.9, alpha: 1)
        core.materials = [material]
        let coreNode = SCNNode(geometry: core)
        self.coreNode = coreNode
        pivot.addChildNode(coreNode)
    }

    func activate(planet: PlanetBody, dispatcher: CollisionSignalDispatcher) {
        planet.attachSurfaceObject(rootNode, at: surfaceCoordinate)
        self.dispatcher = dispatcher
        dispatcher.registerHazardNode(name: rootNode.name ?? "", hazardID: hazardID, kind: kind)

        let shape = SCNPhysicsShape(geometry: SCNSphere(radius: 0.35), options: nil)
        SurfacePhysicsCoordinator.installStaticHazardBody(on: coreNode, shape: shape)
        coreNode.physicsBody?.categoryBitMask = 0
        coreNode.physicsBody?.contactTestBitMask = 0
    }

    func tick(deltaTime: TimeInterval) {
        phaseTimer += deltaTime
        if isDischarging {
            let progress = phaseTimer / dischargeDuration
            let scale = 1.0 + Float(progress) * 2.0
            coreNode.scale = SCNVector3(scale, scale, scale)
            if phaseTimer >= dischargeDuration {
                isDischarging = false
                phaseTimer = 0
                coreNode.scale = SCNVector3(1, 1, 1)
                coreNode.physicsBody?.categoryBitMask = 0
                coreNode.physicsBody?.contactTestBitMask = 0
            }
        } else {
            if phaseTimer >= chargeDuration {
                isDischarging = true
                phaseTimer = 0
                coreNode.physicsBody?.categoryBitMask = SurfacePhysicsCoordinator.Category.hazard
                coreNode.physicsBody?.contactTestBitMask = SurfacePhysicsCoordinator.Category.explorer
            }
        }
    }

    func deactivate() {
        dispatcher?.unregisterHazardNode(name: rootNode.name ?? "")
    }
}
