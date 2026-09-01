//
//  SpikeFieldCluster.swift
//  PlanetEscape
//
//  Created by Hades on 2026/7/31.
//

import Foundation
import SceneKit
import UIKit

/// 静态尖刺群（Galaxy Escape 章节特有的地表危险）：不移动、不周期开关，
/// 一旦接触立即判定为危险接触。与其他障碍相比它最简单——
/// 存在的意义是给最终章节提供"纯粹依靠观察路线来避开"的危险类型，
/// 与依赖节奏判断的火山/激光形成体验区分。
final class SpikeFieldCluster: HazardBehavior {
    let hazardID: String
    let kind: HazardKind = .volcano
    let rootNode: SCNNode
    let surfaceCoordinate: SphereSurfaceCoordinate

    private var dispatcher: CollisionSignalDispatcher?

    init(hazardID: String, coordinate: SphereSurfaceCoordinate, spikeCount: Int = 5) {
        self.hazardID = hazardID
        self.surfaceCoordinate = coordinate

        let cluster = SCNNode()
        cluster.name = "SpikeField_\(hazardID)"
        self.rootNode = cluster

        for i in 0..<spikeCount {
            let spike = SpikeFieldCluster.makeSpike(seed: i)
            cluster.addChildNode(spike)
        }
    }

    func activate(planet: PlanetBody, dispatcher: CollisionSignalDispatcher) {
        planet.attachSurfaceObject(rootNode, at: surfaceCoordinate)
        self.dispatcher = dispatcher
        dispatcher.registerHazardNode(name: rootNode.name ?? "", hazardID: hazardID, kind: kind)

        let shape = SCNPhysicsShape(geometry: SCNSphere(radius: 0.4), options: nil)
        SurfacePhysicsCoordinator.installStaticHazardBody(on: rootNode, shape: shape)
    }

    func deactivate() {
        dispatcher?.unregisterHazardNode(name: rootNode.name ?? "")
    }

    private static func makeSpike(seed: Int) -> SCNNode {
        let cone = SCNCone(topRadius: 0, bottomRadius: 0.04, height: 0.22)
        let material = SCNMaterial()
        material.diffuse.contents = UIColor(red: 0.5, green: 0.1, blue: 0.15, alpha: 1)
        material.roughness.contents = 0.5
        material.metalness.contents = 0.3
        cone.materials = [material]

        let node = SCNNode(geometry: cone)
        node.name = "Spike_\(seed)"
        let angle = Double(seed) * (2 * Double.pi / 5)
        let radius: Float = 0.2
        node.position = SCNVector3(cos(Float(angle)) * radius, 0.11, sin(Float(angle)) * radius)
        return node
    }
}
