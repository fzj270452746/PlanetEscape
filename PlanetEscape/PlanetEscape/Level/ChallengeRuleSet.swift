//
//  ChallengeRuleSet.swift
//  PlanetEscape
//
//  Created by Hades on 2026/7/31.
//

import Foundation

/// 挑战模式规则组合（文档 9.3）：30 秒内逃脱 / 禁止碰撞 / 只允许旋转 5 次等。
/// 用一个可组合的规则集合而不是为每种挑战写一个专用类，
/// 符合 Protocol-Oriented 精神——规则是数据 + 校验函数，不是继承层级。
struct ChallengeRuleSet {
    var timeLimitSeconds: TimeInterval?
    var forbidsAnyCollision: Bool = false
    var maxRotationCount: Int?

    static let speedRun = ChallengeRuleSet(timeLimitSeconds: 30, forbidsAnyCollision: false, maxRotationCount: nil)
    static let noHitRun = ChallengeRuleSet(timeLimitSeconds: nil, forbidsAnyCollision: true, maxRotationCount: nil)
    static let limitedRotation = ChallengeRuleSet(timeLimitSeconds: nil, forbidsAnyCollision: false, maxRotationCount: 5)

    enum ViolationReason {
        case timeExpired
        case collisionOccurred
        case rotationLimitExceeded
    }

    /// 根据当前进度快照，判断规则是否已被违反。
    func checkViolation(elapsedSeconds: TimeInterval, collisionCount: Int, rotationCount: Int) -> ViolationReason? {
        if let limit = timeLimitSeconds, elapsedSeconds >= limit {
            return .timeExpired
        }
        if forbidsAnyCollision, collisionCount > 0 {
            return .collisionOccurred
        }
        if let maxRotations = maxRotationCount, rotationCount > maxRotations {
            return .rotationLimitExceeded
        }
        return nil
    }
}

/// 监听 LevelProgressionTracker 广播的事件，实时校验 ChallengeRuleSet，
/// 一旦违反立即触发失败事件。
final class ChallengeModeMonitor {
    private let ruleSet: ChallengeRuleSet
    private var elapsed: TimeInterval = 0
    private var collisionCount = 0
    private var rotationCount = 0
    private var hasEnded = false

    private var subscription: SignalSubscription?

    init(ruleSet: ChallengeRuleSet) {
        self.ruleSet = ruleSet
        subscription = CosmicSignalRelay.current.subscribe { [weak self] event in
            self?.handle(event)
        }
    }

    func advance(deltaTime: TimeInterval) {
        guard !hasEnded else { return }
        elapsed += deltaTime
        if let violation = ruleSet.checkViolation(elapsedSeconds: elapsed, collisionCount: collisionCount, rotationCount: rotationCount) {
            hasEnded = true
            let reason: StumbleReason = violation == .timeExpired ? .timeExpired : .hazardCollision
            CosmicSignalRelay.current.publish(.explorerStumbled(reason: reason))
        }
    }

    private func handle(_ event: GameEvent) {
        switch event {
        case .hazardContact:
            collisionCount += 1
        case .rotationRequested:
            rotationCount += 1
        default:
            break
        }
    }
}
