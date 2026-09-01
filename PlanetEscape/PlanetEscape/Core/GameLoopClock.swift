//
//  GameLoopClock.swift
//  PlanetEscape
//
//  Created by Hades on 2026/7/31.
//

import Foundation

/// 帮 WorldRuntime 计算帧间 deltaTime，并对异常大的时间跨度（如后台恢复）做钳制，
/// 避免物理/动画在一次 tick 里跳过过多距离。
final class GameLoopClock {
    private(set) var lastTimestamp: TimeInterval?
    private(set) var elapsedSinceStart: TimeInterval = 0
    private let maxDelta: TimeInterval

    init(maxDelta: TimeInterval = 1.0 / 20.0) {
        self.maxDelta = maxDelta
    }

    /// 传入 SCNSceneRendererDelegate 回调的 currentTime，返回钳制后的 deltaTime。
    func tick(currentTime: TimeInterval) -> TimeInterval {
        defer { lastTimestamp = currentTime }
        guard let previous = lastTimestamp else { return 0 }
        let rawDelta = currentTime - previous
        let clamped = min(max(rawDelta, 0), maxDelta)
        elapsedSinceStart += clamped
        return clamped
    }

    func reset() {
        lastTimestamp = nil
        elapsedSinceStart = 0
    }
}
