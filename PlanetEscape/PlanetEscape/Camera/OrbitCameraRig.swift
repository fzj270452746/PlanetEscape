//
//  OrbitCameraRig.swift
//  PlanetEscape
//
//  Created by Hades on 2026/7/31.
//

import Foundation
import SceneKit

/// 近距离跟随摄像机（文档 1.2：视角=3D固定摄像机，玩家不直接操控摄像机）。
/// 摄像机节点不是星球的子节点，只是紧贴在角色身后上方的固定偏移处，
/// 每帧朝角色前方看去——这与"玩家操控的是星球，不是角色"并不矛盾：
/// 摄像机跟的是角色的世界位置，而角色的世界位置本身完全由星球旋转决定
/// （它沿一条世界固定的大圆前进，星球转动只改变它途经的本地危险物分布）。
/// 早期实现让摄像机退到能框住整个星球的远距离，导致角色/障碍物只占屏幕
/// 一两个像素；现在改为贴近角色的追逐视角，与星球实际半径无关，
/// 保证角色和周围地形始终占据画面足够大的比例。
final class OrbitCameraRig {
    let node: SCNNode
    private let camera: SCNCamera

    /// 相对角色的跟随偏移，单位与星球半径无关：沿角色前进反方向后退，
    /// 沿表面法线方向抬高，构成"背后上方看向角色前方"的经典追逐视角。
    var backOffset: Double = 0.9
    var upOffset: Double = 0.5
    var lookAheadOffset: Double = 0.45
    /// 跟随缓动系数：越大跟随越快。
    var followLerpSpeed: Double = 4.5

    private var desiredPosition: SCNVector3?
    private var desiredLookTarget = SCNVector3(0, 0, 0)
    private var desiredUp = SCNVector3(0, 1, 0)

    init() {
        let cam = SCNCamera()
        cam.fieldOfView = 62
        cam.zNear = 0.02
        cam.zFar = 60
        self.camera = cam

        let node = SCNNode()
        node.camera = cam
        node.position = SCNVector3(0, 2, 4)
        self.node = node
    }

    /// 每帧调用：给出角色当前所在的"世界固定路径坐标"、星球半径，以及角色当前
    /// 实际的前进方向向量。用 worldPathCoordinate 而不是 node.worldPosition 读取，
    /// 是因为角色的世界位置恒等于 worldPathCoordinate.cartesian(radius)（核心玩法
    /// 保证了这一点与星球当前朝向无关），不必等节点变换更新。
    ///
    /// forward 必须是调用方（ExplorerMotionUnit）用平行移动逐帧维护的持久化方向，
    /// 不能在这里用 worldCoordinate.forwardTangent() 重新反推——那个只依赖经纬度的
    /// 向量场在南北极附近必然发生方向跳变（拓扑上不可避免），会导致摄像机在角色
    /// 经过极点的几帧内发生剧烈的朝向翻转，正是"几秒后视角错误"最终在画面上的表现。
    func follow(worldCoordinate: SphereSurfaceCoordinate, forward: SCNVector3, planetRadius: Double) {
        let characterPosition = worldCoordinate.cartesian(radius: planetRadius)
        let normal = worldCoordinate.normal()

        let back = Float(backOffset)
        let up = Float(upOffset)
        let ahead = Float(lookAheadOffset)

        let posX = characterPosition.x - forward.x * back + normal.x * up
        let posY = characterPosition.y - forward.y * back + normal.y * up
        let posZ = characterPosition.z - forward.z * back + normal.z * up
        desiredPosition = SCNVector3(posX, posY, posZ)

        let lookX = characterPosition.x + forward.x * ahead
        let lookY = characterPosition.y + forward.y * ahead
        let lookZ = characterPosition.z + forward.z * ahead
        desiredLookTarget = SCNVector3(lookX, lookY, lookZ)

        desiredUp = normal
    }

    func advance(deltaTime: TimeInterval) {
        guard deltaTime > 0, let desired = desiredPosition else { return }
        let t = Float(min(followLerpSpeed * deltaTime, 1.0))
        let newX = node.position.x + (desired.x - node.position.x) * t
        let newY = node.position.y + (desired.y - node.position.y) * t
        let newZ = node.position.z + (desired.z - node.position.z) * t
        node.position = SCNVector3(newX, newY, newZ)
        // 用当前表面法线作为摄像机的 up 提示，保证画面中的"下"始终对应
        // 角色脚下的球面方向，这是小星球视觉风格的关键，不能用默认世界 up。
        node.look(at: desiredLookTarget, up: desiredUp, localFront: SCNVector3(0, 0, -1))
    }
}
