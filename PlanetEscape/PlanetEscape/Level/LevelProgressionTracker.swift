//
//  LevelProgressionTracker.swift
//  PlanetEscape
//
//  Created by Hades on 2026/7/31.
//

import Foundation

/// 追踪单次关卡游玩过程中的统计数据（用时、失败次数、旋转次数），
/// 并在关卡开始/结束时通过 CosmicSignalRelay 广播事件。
/// 与 UserProgressStore（Save 模块，Phase 4）分开：这里只管"当前这次游玩"的即时统计，
/// 持久化解锁状态是另一层职责。
final class LevelProgressionTracker {
    private(set) var currentLevelNumber: Int?
    private var startTime: TimeInterval = 0
    private var elapsedAccumulator: TimeInterval = 0
    private(set) var failureCount = 0
    private(set) var rotationCount = 0

    private var subscription: SignalSubscription?

    init() {
        subscription = CosmicSignalRelay.current.subscribe { [weak self] event in
            self?.handle(event)
        }
    }

    func beginLevel(_ levelNumber: Int) {
        currentLevelNumber = levelNumber
        elapsedAccumulator = 0
        failureCount = 0
        rotationCount = 0
        CosmicSignalRelay.current.publish(.levelStarted(levelID: levelNumber))
    }

    func advance(deltaTime: TimeInterval) {
        guard currentLevelNumber != nil else { return }
        elapsedAccumulator += deltaTime
    }

    func completeLevel() {
        guard let level = currentLevelNumber else { return }
        CosmicSignalRelay.current.publish(.levelCompleted(levelID: level, elapsedSeconds: elapsedAccumulator, rotationsUsed: rotationCount))
        currentLevelNumber = nil
    }

    func failLevel(reason: StumbleReason) {
        guard let level = currentLevelNumber else { return }
        CosmicSignalRelay.current.publish(.levelFailed(levelID: level, reason: reason))
        currentLevelNumber = nil
    }

    private func handle(_ event: GameEvent) {
        switch event {
        case .rotationRequested:
            rotationCount += 1
        case .explorerStumbled:
            failureCount += 1
        default:
            break
        }
    }

    var elapsedSeconds: TimeInterval { elapsedAccumulator }
}
