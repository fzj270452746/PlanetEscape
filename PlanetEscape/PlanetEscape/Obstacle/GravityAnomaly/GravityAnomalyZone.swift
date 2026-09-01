//
//  GravityAnomalyZone.swift
//  PlanetEscape
//
//  Created by Hades on 2026/7/31.
//

import Foundation
import SceneKit
import UIKit

/// 重力异常区（文档 4.1 世界设定："每颗星球都有...重力异常区"）。
/// 进入区域后角色的有效前进速度会被随机放大或减慢（模拟局部重力紊乱），
/// 而不是造成伤害——它是"节奏扰动"型危险，与会直接 GameOver 的火山/黑洞不同，
/// 所以 kind 复用 .movingPlatformMiss 并不合适，这里单独定义一个非致命效果的枚举分支。
final class GravityAnomalyZone: HazardBehavior {
    let hazardID: String
    let kind: HazardKind = .laser
    let rootNode: SCNNode
    let surfaceCoordinate: SphereSurfaceCoordinate

    /// 速度倍率范围：>1 加速通过，<1 放慢（两者都打乱玩家对节奏的预期）。
    var speedMultiplierRange: ClosedRange<Double> = 0.6...1.6
    private(set) var currentMultiplier: Double = 1.0
    private var oscillationPhase: Double = 0
    var oscillationPeriod: TimeInterval = 2.4

    private var dispatcher: CollisionSignalDispatcher?

    init(hazardID: String, coordinate: SphereSurfaceCoordinate, radius: CGFloat = 0.7) {
        self.hazardID = hazardID
        self.surfaceCoordinate = coordinate

        let disc = SCNCylinder(radius: radius, height: 0.02)
        let material = SCNMaterial()
        material.diffuse.contents = UIColor(red: 0.55, green: 0.3, blue: 0.9, alpha: 0.35)
        material.emission.contents = UIColor(red: 0.55, green: 0.3, blue: 0.9, alpha: 0.5)
        material.transparency = 0.6
        disc.materials = [material]

        let node = SCNNode(geometry: disc)
        node.name = "GravityAnomaly_\(hazardID)"
        self.rootNode = node
    }

    func activate(planet: PlanetBody, dispatcher: CollisionSignalDispatcher) {
        planet.attachSurfaceObject(rootNode, at: surfaceCoordinate)
        self.dispatcher = dispatcher
        // 重力异常区不触发失败事件，因此不注册进 hazardLookup，
        // 只在这里保留 dispatcher 引用以便未来扩展（例如轻微震动反馈）。
    }

    func tick(deltaTime: TimeInterval) {
        oscillationPhase += deltaTime
        let normalized = (sin(oscillationPhase / oscillationPeriod * 2 * Double.pi) + 1) / 2
        currentMultiplier = speedMultiplierRange.lowerBound + (speedMultiplierRange.upperBound - speedMultiplierRange.lowerBound) * normalized
        rootNode.opacity = CGFloat(0.3 + 0.2 * normalized)
    }

    func deactivate() {
        dispatcher = nil
    }

    /// 供 ExplorerMotionUnit 查询：角色若在此区域内，应使用的速度倍率；否则返回 1。
    func speedMultiplier(at coordinate: SphereSurfaceCoordinate, planetRadius: Double, effectRadius: Double = 1.5) -> Double {
        let angularDistance = surfaceCoordinate.greatCircleDistance(to: coordinate)
        let arcDistance = angularDistance * planetRadius
        return arcDistance < effectRadius ? currentMultiplier : 1.0
    }
}
