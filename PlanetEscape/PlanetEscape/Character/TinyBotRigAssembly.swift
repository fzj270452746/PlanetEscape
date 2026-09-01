//
//  TinyBotRigAssembly.swift
//  PlanetEscape
//
//  Created by Hades on 2026/7/31.
//

import Foundation
import SceneKit

/// 把 TinyBotRig 的几何体、CharacterSurfaceAnchor、ExplorerMotionUnit、
/// TinyBotAnimationDriver、TinyBotBalanceComponent 组装成一个整体，
/// 挂载到 ComponentHost 上。这一装配步骤单独成文件，
/// 避免 WorldRuntime 里堆砌大段初始化代码（万能 Manager 的雏形）。
final class TinyBotRigAssembly {
    let rootNode: SCNNode
    let host = ComponentHost()
    let motionUnit: ExplorerMotionUnit
    let animationDriver: TinyBotAnimationDriver
    let balanceComponent: TinyBotBalanceComponent
    let surfaceAnchor: CharacterSurfaceAnchor
    let energyReserve: EnergyReserveComponent

    init(planet: PlanetBody, startingCoordinate: SphereSurfaceCoordinate) {
        let node = TinyBotRig.buildRootNode()
        let scale: Float = Float(planet.radius) * 0.06
        node.scale = SCNVector3(scale, scale, scale)
        self.rootNode = node

        let anchor = CharacterSurfaceAnchor(node: node, planet: planet, initialCoordinate: startingCoordinate)
        self.surfaceAnchor = anchor

        let motion = ExplorerMotionUnit(anchor: anchor, planet: planet)
        self.motionUnit = motion

        let animation = TinyBotAnimationDriver(rigRoot: node)
        self.animationDriver = animation

        let balance = TinyBotBalanceComponent(motionUnit: motion, animationDriver: animation)
        self.balanceComponent = balance

        let energy = EnergyReserveComponent()
        self.energyReserve = energy

        host.install(anchor)
        host.install(motion)
        host.install(animation)
        host.install(balance)
        host.install(energy)

        planet.attachSurfaceObject(node, at: startingCoordinate)
    }

    func advance(deltaTime: TimeInterval) {
        host.advanceAll(deltaTime: deltaTime)
    }
}
