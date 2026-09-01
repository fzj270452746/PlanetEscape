//
//  HazardBehavior.swift
//  PlanetEscape
//
//  Created by Hades on 2026/7/31.
//

import Foundation
import SceneKit

/// 所有障碍类型（火山/黑洞/陨石/激光/移动平台）实现的统一协议。
/// Protocol-Oriented：HazardRegistry 只认识这个协议，
/// 不知道也不关心具体是哪一种障碍，避免出现"万能 EnemyManager"式的分支判断。
protocol HazardBehavior: AnyObject {
    var hazardID: String { get }
    var kind: HazardKind { get }
    var rootNode: SCNNode { get }
    var surfaceCoordinate: SphereSurfaceCoordinate { get }

    /// 挂载到星球后调用一次，用于安装物理体、粒子系统等。
    func activate(planet: PlanetBody, dispatcher: CollisionSignalDispatcher)
    /// 每帧调用，驱动周期性行为（喷发、旋转、下落等）。
    func tick(deltaTime: TimeInterval)
    /// 从场景移除前调用，做清理。
    func deactivate()
}

/// 提供默认空实现，具体障碍类型只需覆写需要的部分。
extension HazardBehavior {
    func tick(deltaTime: TimeInterval) {}
    func deactivate() {}
}
