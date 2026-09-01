//
//  IceSlickPatch.swift
//  PlanetEscape
//
//  Created by Hades on 2026/7/31.
//

import Foundation
import SceneKit
import UIKit

/// 冰面滑行区：Ice Planet 章节特有的地表危险（文档 10.1 Ice Planet 元素：冰面）。
/// 不直接造成 GameOver，而是打乱玩家对旋转手势的预期——角色进入区域后，
/// 旋转指令的响应会被放大（打滑），迫使玩家用更小幅度的滑动来微调路线。
/// 效果实现方式类似 GravityAnomalyZone（非致命型危险），但作用对象是旋转输入而非前进速度，
/// 所以单独建模，不与 GravityAnomalyZone 合并。
final class IceSlickPatch: HazardBehavior {
    let hazardID: String
    let kind: HazardKind = .laser
    let rootNode: SCNNode
    let surfaceCoordinate: SphereSurfaceCoordinate

    /// 区域内旋转灵敏度放大系数（>1 代表打滑，手势会转出比预期更大的角度）。
    var slipAmplification: Double = 1.8
    var effectRadius: Double = 1.2

    private var dispatcher: CollisionSignalDispatcher?
    private var shimmerPhase: Double = 0

    init(hazardID: String, coordinate: SphereSurfaceCoordinate, patchRadius: CGFloat = 0.9) {
        self.hazardID = hazardID
        self.surfaceCoordinate = coordinate

        let disc = SCNCylinder(radius: patchRadius, height: 0.015)
        let material = SCNMaterial()
        material.diffuse.contents = UIColor(red: 0.75, green: 0.92, blue: 1.0, alpha: 0.55)
        material.roughness.contents = 0.05
        material.metalness.contents = 0.3
        disc.materials = [material]

        let node = SCNNode(geometry: disc)
        node.name = "IceSlick_\(hazardID)"
        self.rootNode = node
    }

    func activate(planet: PlanetBody, dispatcher: CollisionSignalDispatcher) {
        planet.attachSurfaceObject(rootNode, at: surfaceCoordinate)
        self.dispatcher = dispatcher
    }

    func tick(deltaTime: TimeInterval) {
        shimmerPhase += deltaTime
        rootNode.opacity = CGFloat(0.45 + 0.15 * sin(shimmerPhase * 2))
    }

    func deactivate() {
        dispatcher = nil
    }

    /// 供 RotationGestureInterpreter/PlanetRotationDriver 查询角色是否在滑行区内，
    /// 返回旋转灵敏度放大系数；不在区域内时返回 1（无影响）。
    func sensitivityMultiplier(at coordinate: SphereSurfaceCoordinate, planetRadius: Double) -> Double {
        let angularDistance = surfaceCoordinate.greatCircleDistance(to: coordinate)
        let arcDistance = angularDistance * planetRadius
        return arcDistance < effectRadius ? slipAmplification : 1.0
    }
}
