//
//  CharacterSurfaceAnchor.swift
//  PlanetEscape
//
//  Created by Hades on 2026/7/31.
//

import Foundation
import SceneKit

/// 把角色节点绑定到星球表面坐标系：既是 SurfaceComponent（供 HazardRegistry 等按经纬度比较），
/// 也负责把 SphereSurfaceCoordinate 的变化实时写回 SCNNode 的 position/orientation。
final class CharacterSurfaceAnchor: SurfaceComponent, UpdatableComponent {
    private weak var node: SCNNode?
    private let planet: PlanetBody

    var surfaceCoordinate: SphereSurfaceCoordinate {
        didSet { syncTransform() }
    }
    let surfaceFootprint: Double

    /// 角色本地空间下的前进方向，由 ExplorerMotionUnit 每帧通过
    /// planet.projectWorldDirectionToLocal(worldForwardDirection) 写入，而不是
    /// 在这里用 surfaceCoordinate.forwardTangent() 重新反推——那样在角色经过
    /// 本地极点时会因为方向场本身的不连续而瞬间转向，见 OrbitalPathCalculator
    /// 的详细说明。初始值仅用于角色生成瞬间（此时 advance 还未被调用过一次）。
    var forwardDirection: SCNVector3 {
        didSet { syncTransform() }
    }

    /// 落地抬升高度（局部坐标沿法线方向的微小偏移），避免脚部与球体表面产生 z-fighting。
    var groundClearance: Double = 0.02

    init(node: SCNNode, planet: PlanetBody, initialCoordinate: SphereSurfaceCoordinate, footprint: Double = 0.05) {
        self.node = node
        self.planet = planet
        self.surfaceCoordinate = initialCoordinate
        self.forwardDirection = initialCoordinate.forwardTangent()
        self.surfaceFootprint = footprint
        syncTransform()
    }

    func advance(deltaTime: TimeInterval) {
        // 位置/朝向的推进由 ExplorerMotionUnit 负责写 surfaceCoordinate/forwardDirection，
        // 这里只保证每帧都把最新状态同步到渲染节点，职责单一。
        syncTransform()
    }

    private func syncTransform() {
        guard let node = node else { return }
        let basePosition = planet.pathCalculator.localPosition(for: surfaceCoordinate)
        let normal = surfaceCoordinate.normal()
        let clearance = Float(groundClearance)
        node.position = SCNVector3(
            basePosition.x + normal.x * clearance,
            basePosition.y + normal.y * clearance,
            basePosition.z + normal.z * clearance
        )
        node.orientation = planet.pathCalculator.localOrientation(for: surfaceCoordinate, forward: forwardDirection)
    }
}
