//
//  VolcanoEmissionController.swift
//  PlanetEscape
//
//  Created by Hades on 2026/7/31.
//

import Foundation
import SceneKit
import UIKit

/// 火山障碍（文档 8.1）：周期性喷发岩浆/烟雾/火焰粒子，接触即 GameOver。
/// 喷发周期与静止期交替，玩家需要观察节奏来判断何时安全通过。
final class VolcanoEmissionController: HazardBehavior {
    let hazardID: String
    let kind: HazardKind = .volcano
    let rootNode: SCNNode
    let surfaceCoordinate: SphereSurfaceCoordinate

    /// 喷发周期参数：静止 idleDuration 秒后喷发 eruptDuration 秒，循环。
    var idleDuration: TimeInterval = 2.2
    var eruptDuration: TimeInterval = 0.9
    private var phaseTimer: TimeInterval = 0
    private var isErupting = false

    private let lavaParticles: SCNParticleSystem
    private let smokeParticles: SCNParticleSystem
    private let fireParticles: SCNParticleSystem
    private var dispatcher: CollisionSignalDispatcher?

    /// 共享的粒子预算限制器（文档第 21 节性能优化），多个火山实例共用同一个实例，
    /// 由 HazardWorldAssembly 注入，避免多个火山同时喷发时粒子数量失控拖垮帧率。
    weak var particleBudget: ParticleBudgetLimiter?

    init(hazardID: String, coordinate: SphereSurfaceCoordinate, coneRadius: CGFloat = 0.5, coneHeight: CGFloat = 0.7) {
        self.hazardID = hazardID
        self.surfaceCoordinate = coordinate

        let cone = SCNCone(topRadius: 0, bottomRadius: coneRadius, height: coneHeight)
        let material = SCNMaterial()
        material.diffuse.contents = UIColor(red: 0.25, green: 0.12, blue: 0.08, alpha: 1)
        material.roughness.contents = 0.9
        cone.materials = [material]

        let node = SCNNode(geometry: cone)
        node.name = "Volcano_\(hazardID)"
        self.rootNode = node

        self.lavaParticles = VolcanoEmissionController.makeLavaParticles()
        self.smokeParticles = VolcanoEmissionController.makeSmokeParticles()
        self.fireParticles = VolcanoEmissionController.makeFireParticles()
    }

    func activate(planet: PlanetBody, dispatcher: CollisionSignalDispatcher) {
        planet.attachSurfaceObject(rootNode, at: surfaceCoordinate)
        self.dispatcher = dispatcher
        dispatcher.registerHazardNode(name: rootNode.name ?? "", hazardID: hazardID, kind: kind)

        let shape = SCNPhysicsShape(geometry: SCNCone(topRadius: 0, bottomRadius: 0.5, height: 0.7), options: nil)
        SurfacePhysicsCoordinator.installStaticHazardBody(on: rootNode, shape: shape)

        rootNode.addParticleSystem(smokeParticles)
    }

    func tick(deltaTime: TimeInterval) {
        phaseTimer += deltaTime
        if isErupting {
            if phaseTimer >= eruptDuration {
                isErupting = false
                phaseTimer = 0
                if let budget = particleBudget {
                    budget.releaseActivation(system: lavaParticles, on: rootNode)
                    budget.releaseActivation(system: fireParticles, on: rootNode)
                } else {
                    rootNode.removeParticleSystem(lavaParticles)
                    rootNode.removeParticleSystem(fireParticles)
                }
            }
        } else {
            if phaseTimer >= idleDuration {
                isErupting = true
                phaseTimer = 0
                if let budget = particleBudget {
                    _ = budget.requestActivation(system: lavaParticles, on: rootNode)
                    _ = budget.requestActivation(system: fireParticles, on: rootNode)
                } else {
                    rootNode.addParticleSystem(lavaParticles)
                    rootNode.addParticleSystem(fireParticles)
                }
            }
        }
    }

    func deactivate() {
        dispatcher?.unregisterHazardNode(name: rootNode.name ?? "")
    }

    private static func makeLavaParticles() -> SCNParticleSystem {
        let system = SCNParticleSystem()
        system.particleColor = UIColor(red: 1.0, green: 0.35, blue: 0.05, alpha: 1)
        system.birthRate = 40
        system.particleLifeSpan = 1.0
        system.particleVelocity = 2.0
        system.particleSize = 0.06
        system.emitterShape = SCNCone(topRadius: 0, bottomRadius: 0.1, height: 0.1)
        system.spreadingAngle = 25
        system.acceleration = SCNVector3(0, -1.5, 0)
        return system
    }

    private static func makeSmokeParticles() -> SCNParticleSystem {
        let system = SCNParticleSystem()
        system.particleColor = UIColor(white: 0.4, alpha: 0.6)
        system.birthRate = 6
        system.particleLifeSpan = 3.0
        system.particleVelocity = 0.6
        system.particleSize = 0.2
        system.particleSizeVariation = 0.1
        return system
    }

    private static func makeFireParticles() -> SCNParticleSystem {
        let system = SCNParticleSystem()
        system.particleColor = UIColor(red: 1.0, green: 0.7, blue: 0.1, alpha: 1)
        system.birthRate = 25
        system.particleLifeSpan = 0.6
        system.particleVelocity = 1.4
        system.particleSize = 0.08
        system.blendMode = .additive
        return system
    }
}
