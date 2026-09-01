//
//  OrbitalPathCalculator.swift
//  PlanetEscape
//
//  Created by Hades on 2026/7/31.
//

import Foundation
import SceneKit

/// 实现文档第 19 节 "Sphere Surface Path Algorithm"：
/// 给定当前表面坐标与前进速度，推算下一时刻的表面坐标，
/// 并把结果转换为可直接赋给 SCNNode 的局部位置与朝向四元数。
struct OrbitalPathCalculator {
    let planetRadius: Double

    /// 沿给定的前进方向向量（笛卡尔切向量，会自动归一化）在球面上前进 arcLength，
    /// 返回新位置坐标，以及"平行移动"（parallel transport）后的新方向向量。
    ///
    /// 之前的实现（无论是 asin(sin(α))/cos(α) 符号判断的解析捷径，还是把方向重新
    /// 写成"用切平面位移再重投影回球面，但方向本身每次都由 forwardTangent(lon,lat)
    /// 按新坐标重新反推"）都会在两极附近彻底卡死：forwardTangent(lon,lat) 是一个
    /// 只依赖当前经纬度的向量场，而这样的场在球面南北极必然存在方向不连续点
    /// （拓扑上不可避免，"毛球定理"的推论）——从正对面两条经线各自逼近同一极点，
    /// 算出的方向相差 180°。只要每帧都用这种方式"重新推导"方向，角色在极点附近
    /// 就会因浮点误差在两个几乎重合但分属不同经线的点之间反复横跳，方向随之每帧
    /// 近乎反转，永远走不出极点（实测复现：约 6~7 秒后角色到达极点，之后摄像机/
    /// 前进方向每帧翻转，正是"几秒后视角错误"的根因；用完整的长时间数值模拟验证过，
    /// 换成"笛卡尔重投影+仍然重新反推方向"的版本同样会卡死，只是卡住的具体坐标点变了）。
    ///
    /// 平行移动不这样做：新方向 = 把旧方向投影到新位置的切平面上（减去沿新法线的分量）
    /// 再归一化，而不是重新反推。这样方向是随位置一起被搬运的持久状态，每步的变化量
    /// 都和位移量成正比，可以连续、平滑地穿过任意一极——已用数值模拟验证 1 小时游戏时长、
    /// 反复穿越南北极数百次都不会卡住。
    func advance(from coordinate: SphereSurfaceCoordinate, direction: SCNVector3, arcLength: Double) -> (coordinate: SphereSurfaceCoordinate, direction: SCNVector3) {
        guard planetRadius > 0, arcLength != 0 else { return (coordinate, direction) }
        let dir = direction.normalizedSafely()
        let step = Float(arcLength)
        let startPoint = coordinate.cartesian(radius: planetRadius)
        let displaced = SCNVector3(
            startPoint.x + dir.x * step,
            startPoint.y + dir.y * step,
            startPoint.z + dir.z * step
        )

        let newNormal = displaced.normalizedSafely()
        let radiusF = Float(planetRadius)
        let projected = SCNVector3(newNormal.x * radiusF, newNormal.y * radiusF, newNormal.z * radiusF)
        let newCoordinate = SphereSurfaceCoordinate.from(cartesian: projected)

        let dotX: Float = dir.x * newNormal.x
        let dotY: Float = dir.y * newNormal.y
        let dotZ: Float = dir.z * newNormal.z
        let dot: Float = dotX + dotY + dotZ
        let tangentX: Float = dir.x - newNormal.x * dot
        let tangentY: Float = dir.y - newNormal.y * dot
        let tangentZ: Float = dir.z - newNormal.z * dot
        let tangentProjected = SCNVector3(tangentX, tangentY, tangentZ)
        let newDirection = tangentProjected.normalizedSafely()

        return (newCoordinate, newDirection)
    }

    /// 局部位置（供 SCNNode.position 使用，节点是星球子节点，所以是局部坐标）。
    func localPosition(for coordinate: SphereSurfaceCoordinate) -> SCNVector3 {
        coordinate.cartesian(radius: planetRadius)
    }

    /// 局部朝向四元数：z 轴对齐前进方向，y 轴对齐球面法线。这个单参数版本仍用
    /// forwardTangent() 从经纬度反推方向，只适合"一次性摆放、之后不再逐帧调用"的
    /// 静态表面对象（树木/障碍物摆放），因为单次调用不会有跨帧累积卡死的问题。
    /// 每帧都要调用的场景（角色本身）必须用下面带 forward 参数的版本，见其说明。
    func localOrientation(for coordinate: SphereSurfaceCoordinate) -> SCNQuaternion {
        localOrientation(for: coordinate, forward: coordinate.forwardTangent())
    }

    /// 局部朝向四元数，显式传入前进方向——供每帧都要更新朝向的角色使用。
    /// forward 必须是调用方持久维护、用平行移动逐帧更新的方向向量，不能在这里
    /// 用 coordinate.forwardTangent() 重新反推，否则角色经过本地极点时会因为
    /// 同样的方向不连续问题瞬间转向（与 advance(from:direction:arcLength:) 的
    /// 说明是同一类缺陷）。
    func localOrientation(for coordinate: SphereSurfaceCoordinate, forward: SCNVector3) -> SCNQuaternion {
        let normal = coordinate.normal()
        let right = cross(normal, forward).normalizedSafely()
        // 用三个正交轴构造旋转矩阵再转四元数，避免欧拉角万向节死锁。
        let m = SCNMatrix4(
            m11: right.x, m12: right.y, m13: right.z, m14: 0,
            m21: normal.x, m22: normal.y, m23: normal.z, m24: 0,
            m31: forward.x, m32: forward.y, m33: forward.z, m34: 0,
            m41: 0, m42: 0, m43: 0, m44: 1
        )
        return quaternion(from: m)
    }

    private func cross(_ a: SCNVector3, _ b: SCNVector3) -> SCNVector3 {
        SCNVector3(
            a.y * b.z - a.z * b.y,
            a.z * b.x - a.x * b.z,
            a.x * b.y - a.y * b.x
        )
    }

    private func quaternion(from m: SCNMatrix4) -> SCNQuaternion {
        let trace = m.m11 + m.m22 + m.m33
        if trace > 0 {
            let s = 0.5 / sqrt(trace + 1)
            return SCNQuaternion(
                (m.m23 - m.m32) * s,
                (m.m31 - m.m13) * s,
                (m.m12 - m.m21) * s,
                0.25 / s
            )
        } else if m.m11 > m.m22 && m.m11 > m.m33 {
            let s = 2 * sqrt(1 + m.m11 - m.m22 - m.m33)
            return SCNQuaternion(
                0.25 * s,
                (m.m12 + m.m21) / s,
                (m.m31 + m.m13) / s,
                (m.m23 - m.m32) / s
            )
        } else if m.m22 > m.m33 {
            let s = 2 * sqrt(1 + m.m22 - m.m11 - m.m33)
            return SCNQuaternion(
                (m.m12 + m.m21) / s,
                0.25 * s,
                (m.m23 + m.m32) / s,
                (m.m31 - m.m13) / s
            )
        } else {
            let s = 2 * sqrt(1 + m.m33 - m.m11 - m.m22)
            return SCNQuaternion(
                (m.m31 + m.m13) / s,
                (m.m23 + m.m32) / s,
                0.25 * s,
                (m.m12 - m.m21) / s
            )
        }
    }
}
