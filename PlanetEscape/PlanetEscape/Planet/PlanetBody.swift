//
//  PlanetBody.swift
//  PlanetEscape
//
//  Created by Hades on 2026/7/31.
//

import Foundation
import SceneKit

/// 星球本体的运行时封装：持有根节点、半径、以及供其他子系统复用的坐标/重力计算器。
/// 角色、障碍、收集品都作为 rootNode 的子节点挂载，这样施加到 rootNode 上的
/// 旋转会天然带动所有表面对象一起转，这就是"玩家操控星球而非角色"的核心实现基础。
final class PlanetBody {
    let rootNode: SCNNode
    let radius: Double
    let pathCalculator: OrbitalPathCalculator
    let gravityResolver: PlanetGravityResolver

    /// 挂载表面对象用的容器节点，方便与地形装饰节点区分层级，便于按类型批量清理。
    let surfaceObjectsNode: SCNNode

    init(radius: Double, blueprint: PlanetGenerator.Blueprint? = nil) {
        self.radius = radius
        self.pathCalculator = OrbitalPathCalculator(planetRadius: radius)
        self.gravityResolver = PlanetGravityResolver(planetRadius: radius)

        let generator = PlanetGenerator()
        let usedBlueprint = blueprint ?? PlanetGenerator.Blueprint.defaultBlueprint(radius: radius)
        self.rootNode = generator.buildPlanetNode(blueprint: usedBlueprint)

        let container = SCNNode()
        container.name = "SurfaceObjects"
        self.surfaceObjectsNode = container
        rootNode.addChildNode(container)
    }

    /// 把一个表面对象节点放置到指定经纬度，并对齐朝向。
    func place(node: SCNNode, at coordinate: SphereSurfaceCoordinate) {
        node.position = pathCalculator.localPosition(for: coordinate)
        node.orientation = pathCalculator.localOrientation(for: coordinate)
    }

    /// 把一个"世界固定坐标系"下的经纬度投影成星球当前朝向下的本地经纬度。
    /// 这是核心玩法的关键：角色沿世界固定方向前进（worldCoordinate 只随时间推进，
    /// 与星球朝向无关），但它在星球表面实际穿越的位置（localCoordinate）
    /// 会随 rootNode.orientation 变化——玩家旋转星球，等价于把同一条世界路径
    /// 映射到不同的本地危险物分布上，这正是"转星球以改变角色实际路线"的实现原理。
    func projectWorldToLocal(_ worldCoordinate: SphereSurfaceCoordinate) -> SphereSurfaceCoordinate {
        let worldCartesian = worldCoordinate.cartesian(radius: radius)
        let inverseOrientation = QuaternionRotationMath.conjugate(rootNode.orientation)
        let localCartesian = QuaternionRotationMath.rotate(worldCartesian, by: inverseOrientation)
        return SphereSurfaceCoordinate.from(cartesian: localCartesian)
    }

    /// 把一个"世界固定参考系"下的方向向量（例如 ExplorerMotionUnit 用平行移动
    /// 维护的前进方向）同样旋转进星球当前朝向下的本地空间，与 projectWorldToLocal
    /// 对坐标点做的事情完全对应——方向向量只需要旋转分量，不涉及位置，
    /// 所以用同一个 rootNode.orientation 的逆旋转即可，不能重新对本地坐标反推方向
    /// （那样会在本地极点附近重新引入方向不连续问题）。
    func projectWorldDirectionToLocal(_ worldDirection: SCNVector3) -> SCNVector3 {
        let inverseOrientation = QuaternionRotationMath.conjugate(rootNode.orientation)
        return QuaternionRotationMath.rotate(worldDirection, by: inverseOrientation)
    }

    func attachSurfaceObject(_ node: SCNNode, at coordinate: SphereSurfaceCoordinate) {
        place(node: node, at: coordinate)
        surfaceObjectsNode.addChildNode(node)
    }
}
