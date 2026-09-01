//
//  LaserCycleTimer.swift
//  PlanetEscape
//
//  Created by Hades on 2026/7/31.
//

import Foundation

/// 激光的周期节奏计算：文档 8.4 要求"玩家需要观察周期"。
/// 把节奏计算抽成独立小类型，方便 LaserSweepEmitter 与未来
/// 教学提示 UI（例如显示倒计时环）共用同一套节奏数据，而不必重复实现。
struct LaserCycleTimer {
    var activeDuration: TimeInterval
    var restDuration: TimeInterval

    var totalCycleDuration: TimeInterval { activeDuration + restDuration }

    /// 给定累计时间，返回 (isActive, phaseProgress 0~1, timeUntilNextTransition)。
    func state(at elapsed: TimeInterval) -> (isActive: Bool, phaseProgress: Double, timeUntilTransition: TimeInterval) {
        guard totalCycleDuration > 0 else { return (false, 0, .infinity) }
        let cyclePosition = elapsed.truncatingRemainder(dividingBy: totalCycleDuration)
        if cyclePosition < activeDuration {
            let progress = cyclePosition / activeDuration
            return (true, progress, activeDuration - cyclePosition)
        } else {
            let restPosition = cyclePosition - activeDuration
            let progress = restPosition / restDuration
            return (false, progress, restDuration - restPosition)
        }
    }
}
