//
//  QuaternionRotationMath.swift
//  PlanetEscape
//
//  Created by Hades on 2026/7/31.
//

import Foundation
import SceneKit

/// 四元数旋转向量的通用数学工具，独立于 PlanetRotationDriver 的私有实现，
/// 供 OrbitalPathCalculator 把"世界固定路径坐标"投影进星球当前朝向下的本地坐标系
/// （这是修复核心玩法的关键：角色前进方向必须相对世界固定，而不是相对星球本体固定，
/// 否则旋转星球不会改变角色实际穿越的本地危险区域）。
struct QuaternionRotationMath {
    /// 单位四元数的逆等于其共轭。
    static func conjugate(_ q: SCNQuaternion) -> SCNQuaternion {
        SCNQuaternion(-q.x, -q.y, -q.z, q.w)
    }

    static func multiply(_ a: SCNQuaternion, _ b: SCNQuaternion) -> SCNQuaternion {
        let x = a.w * b.x + a.x * b.w + a.y * b.z - a.z * b.y
        let y = a.w * b.y - a.x * b.z + a.y * b.w + a.z * b.x
        let z = a.w * b.z + a.x * b.y - a.y * b.x + a.z * b.w
        let w = a.w * b.w - a.x * b.x - a.y * b.y - a.z * b.z
        return SCNQuaternion(x, y, z, w)
    }

    /// 用四元数旋转公式 v' = q * v * q⁻¹（v 以纯四元数形式代入）旋转一个向量。
    static func rotate(_ v: SCNVector3, by q: SCNQuaternion) -> SCNVector3 {
        let vectorAsQuaternion = SCNQuaternion(v.x, v.y, v.z, 0)
        let rotated = multiply(multiply(q, vectorAsQuaternion), conjugate(q))
        return SCNVector3(rotated.x, rotated.y, rotated.z)
    }
}
