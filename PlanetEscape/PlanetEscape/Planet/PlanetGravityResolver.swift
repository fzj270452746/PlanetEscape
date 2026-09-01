//
//  PlanetGravityResolver.swift
//  PlanetEscape
//
//  Created by Hades on 2026/7/31.
//

import Foundation
import SceneKit

/// 统一计算星球表面任意点的"重力方向"（局部空间下指向球心的单位向量），
/// 供角色朝向对齐、粒子特效发射方向、掉落物运动方向复用，
/// 避免每个子系统各自重复实现"指向球心"的向量计算。
struct PlanetGravityResolver {
    let planetRadius: Double

    /// 局部坐标系下，给定表面坐标处的重力方向（指向球心，即法线的反方向）。
    func gravityDirection(at coordinate: SphereSurfaceCoordinate) -> SCNVector3 {
        let normal = coordinate.normal()
        return SCNVector3(-normal.x, -normal.y, -normal.z)
    }

    /// 给定局部空间任意一点（不一定正好贴在球面上），返回其重力方向。
    /// 用于陨石/掉落物尚未落地前的运动计算。
    func gravityDirection(atLocalPoint point: SCNVector3) -> SCNVector3 {
        point.normalizedSafely().negated()
    }

    /// 重力加速度大小（弧度制下的等效标量，用于陨石下落速度积分）。
    /// 星球半径越大，视觉上重力应稍强一些，保持坠落手感一致。
    func gravityMagnitude() -> Double {
        max(4.0, planetRadius * 0.6)
    }
}

extension SCNVector3 {
    func negated() -> SCNVector3 {
        SCNVector3(-x, -y, -z)
    }
}
