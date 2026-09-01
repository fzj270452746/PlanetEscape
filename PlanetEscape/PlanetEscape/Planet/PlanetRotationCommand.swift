//
//  PlanetRotationCommand.swift
//  PlanetEscape
//
//  Created by Hades on 2026/7/31.
//

import Foundation
import SceneKit

/// 一次旋转意图的数据结构：绕哪条轴，转多少角度，用多长时间完成。
/// 由 RotationGestureInterpreter 产出，交给 PlanetRotationDriver 执行。
struct PlanetRotationCommand {
    enum Origin {
        case swipe
        case doubleTapBurst
        case longPressCreep
        case programmatic
    }

    /// 旋转轴，世界空间下的单位向量（通常是屏幕竖直方向对应的世界轴）。
    var axis: SCNVector3
    /// 旋转角度，弧度，正值代表右手定则方向。
    var angleRadians: Double
    /// 完成这次旋转所需时间（秒）；0 表示立即施加（例如物理修正）。
    var duration: TimeInterval
    var origin: Origin

    static func swipeRotation(angleRadians: Double, duration: TimeInterval) -> PlanetRotationCommand {
        PlanetRotationCommand(axis: SCNVector3(0, 1, 0), angleRadians: angleRadians, duration: duration, origin: .swipe)
    }
}
