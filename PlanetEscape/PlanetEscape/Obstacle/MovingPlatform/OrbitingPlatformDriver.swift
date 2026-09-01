//
//  OrbitingPlatformDriver.swift
//  PlanetEscape
//
//  Created by Hades on 2026/7/31.
//

import Foundation
import SceneKit
import UIKit

/// 移动平台（文档 8.5）：沿固定纬线绕星球旋转的平台，
/// 角色需要"时间判断"来赶上或躲开。这里不做成障碍物直接碰撞失败，
/// 而是作为一段可站立的安全区——若角色所在经度长时间与平台经度不重合，
/// 则视为"错过平台"，由 kind = .movingPlatformMiss 的事件通知上层判定失败或减速。
final class OrbitingPlatformDriver: HazardBehavior {
    let hazardID: String
    let kind: HazardKind = .movingPlatformMiss
    let rootNode: SCNNode
    var surfaceCoordinate: SphereSurfaceCoordinate

    /// 绕星球公转周期（秒）。
    var orbitPeriod: TimeInterval
    private let orbitLatitude: Double
    private var elapsed: TimeInterval = 0
    private var dispatcher: CollisionSignalDispatcher?

    init(hazardID: String, orbitLatitude: Double, startingLongitude: Double, orbitPeriod: TimeInterval = 6.0, platformSize: CGFloat = 0.5) {
        self.hazardID = hazardID
        self.orbitLatitude = orbitLatitude
        self.orbitPeriod = orbitPeriod
        self.surfaceCoordinate = SphereSurfaceCoordinate(longitude: startingLongitude, latitude: orbitLatitude)

        let box = SCNBox(width: platformSize, height: 0.08, length: platformSize, chamferRadius: 0.02)
        let material = SCNMaterial()
        material.diffuse.contents = UIColor(red: 0.5, green: 0.55, blue: 0.6, alpha: 1)
        material.metalness.contents = 0.6
        material.roughness.contents = 0.4
        box.materials = [material]
        let node = SCNNode(geometry: box)
        node.name = "Platform_\(hazardID)"
        self.rootNode = node
    }

    func activate(planet: PlanetBody, dispatcher: CollisionSignalDispatcher) {
        planet.attachSurfaceObject(rootNode, at: surfaceCoordinate)
        self.dispatcher = dispatcher
        // 平台是安全落脚点，站上去不应该触发 hazardContact —— 因此不向 dispatcher
        // 注册为碰撞危险节点。真正的危险是"错过平台掉落"，由 PlatformMissDetector
        // 通过 isAligned() 逐帧判定，而不是靠物理接触事件。

        let shape = SCNPhysicsShape(geometry: SCNBox(width: 0.5, height: 0.08, length: 0.5, chamferRadius: 0.02), options: nil)
        let body = SCNPhysicsBody(type: .static, shape: shape)
        body.categoryBitMask = SurfacePhysicsCoordinator.Category.platform
        body.contactTestBitMask = 0
        body.collisionBitMask = 0
        rootNode.physicsBody = body
    }

    func tick(deltaTime: TimeInterval) {
        elapsed += deltaTime
        let angularSpeed = (2 * Double.pi) / orbitPeriod
        let newLongitude = surfaceCoordinate.longitude + angularSpeed * deltaTime
        surfaceCoordinate = SphereSurfaceCoordinate(longitude: newLongitude, latitude: orbitLatitude).normalized()
        // 位置更新交由外部（HazardRegistry 持有 planet 引用）在下一次渲染前统一 place，
        // 这里只更新逻辑坐标，避免每个 Hazard 类型各自重复"写回 SCNNode"的代码。
    }

    func deactivate() {
        dispatcher?.unregisterHazardNode(name: rootNode.name ?? "")
    }

    /// 供 HazardRegistry 在 tick 后统一同步渲染位置。
    func syncTransform(planet: PlanetBody) {
        planet.place(node: rootNode, at: surfaceCoordinate)
    }

    /// 判断角色是否与本平台"同步"（经度足够接近，可以视为站在平台上）。
    func isAligned(with characterCoordinate: SphereSurfaceCoordinate, toleranceRadians: Double = 0.15) -> Bool {
        surfaceCoordinate.greatCircleDistance(to: characterCoordinate) < toleranceRadians
    }
}
