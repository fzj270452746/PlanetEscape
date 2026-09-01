//
//  SphereSurfaceCoordinate.swift
//  PlanetEscape
//
//  Created by Hades on 2026/7/31.
//

import Foundation
import SceneKit

/// 用经纬度表达星球局部坐标系中某一点在球面上的位置。
/// longitude ∈ [0, 2π)，环绕赤道方向；latitude ∈ [-π/2, π/2]，从南极到北极。
/// 这是文档第 19 节要求的 "Sphere Surface Path Algorithm" 的数据基础：
/// 角色/障碍/收集品都用这一坐标定位，而不是直接摆放笛卡尔坐标，
/// 这样旋转星球本体节点时，所有表面对象天然“随球体旋转”，无需逐个重新计算。
struct SphereSurfaceCoordinate: Equatable {
    var longitude: Double
    var latitude: Double

    static let zero = SphereSurfaceCoordinate(longitude: 0, latitude: 0)

    /// 归一化到标准区间，避免累加运动后数值无限增长导致精度问题。
    func normalized() -> SphereSurfaceCoordinate {
        var lon = longitude.truncatingRemainder(dividingBy: 2 * Double.pi)
        if lon < 0 { lon += 2 * Double.pi }
        let clampedLat = min(max(latitude, -Double.pi / 2 + 1e-4), Double.pi / 2 - 1e-4)
        return SphereSurfaceCoordinate(longitude: lon, latitude: clampedLat)
    }

    /// 转换为星球局部空间的笛卡尔坐标（半径为 radius）。
    /// 采用标准球坐标系：y 轴为极轴（北极为 +y），x/z 平面为赤道面。
    func cartesian(radius: Double) -> SCNVector3 {
        let cosLat = cos(latitude)
        let x = radius * cosLat * cos(longitude)
        let y = radius * sin(latitude)
        let z = radius * cosLat * sin(longitude)
        return SCNVector3(x, y, z)
    }

    /// 该点处的球面法线（指向球心外侧），单位向量。
    func normal() -> SCNVector3 {
        let cosLat = cos(latitude)
        return SCNVector3(cosLat * cos(longitude), sin(latitude), cosLat * sin(longitude))
    }

    /// 沿纬度增大方向（角色默认前进方向）的单位切向量。
    /// 对纬度求导：d/dlat (cosLat*cosLon, sinLat, cosLat*sinLon) = (-sinLat*cosLon, cosLat, -sinLat*sinLon)
    func forwardTangent() -> SCNVector3 {
        let sinLat = sin(latitude)
        let cosLat = cos(latitude)
        let raw = SCNVector3(-sinLat * cos(longitude), cosLat, -sinLat * sin(longitude))
        return raw.normalizedSafely()
    }

    /// 由笛卡尔坐标反算经纬度（假定点位于以给定半径为参数的球面上，或至少方向正确）。
    static func from(cartesian point: SCNVector3) -> SphereSurfaceCoordinate {
        let length = sqrt(Double(point.x * point.x + point.y * point.y + point.z * point.z))
        guard length > 1e-9 else { return .zero }
        let lat = asin(min(max(Double(point.y) / length, -1), 1))
        var lon = atan2(Double(point.z), Double(point.x))
        if lon < 0 { lon += 2 * Double.pi }
        return SphereSurfaceCoordinate(longitude: lon, latitude: lat)
    }

    /// 两点间的大圆角距离（弧度），用于判断障碍/收集品是否临近角色。
    func greatCircleDistance(to other: SphereSurfaceCoordinate) -> Double {
        let selfNormal = normal()
        let otherNormal = other.normal()
        let dot = Double(selfNormal.x * otherNormal.x + selfNormal.y * otherNormal.y + selfNormal.z * otherNormal.z)
        return acos(min(max(dot, -1), 1))
    }
}

extension SCNVector3 {
    func normalizedSafely() -> SCNVector3 {
        let length = sqrt(x * x + y * y + z * z)
        guard length > 1e-6 else { return SCNVector3(0, 1, 0) }
        return SCNVector3(x / length, y / length, z / length)
    }
}
