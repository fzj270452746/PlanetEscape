//
//  TinyBotBalanceComponent.swift
//  PlanetEscape
//
//  Created by Hades on 2026/7/31.
//

import Foundation

/// 角色的“失衡”反馈组件（文档 5.1 Hit 动作）：碰撞后进入短暂失衡状态，
/// 期间前进暂停、播放 Hit 动画，超时后恢复 Running；若在失衡期再次被打击可触发 GameOver。
/// 订阅 CosmicSignalRelay 的 hazardContact 事件，不需要 HazardRegistry 直接引用它。
final class TinyBotBalanceComponent: UpdatableComponent {
    private let motionUnit: ExplorerMotionUnit
    private let animationDriver: TinyBotAnimationDriver

    private(set) var isStumbling = false
    private var stumbleTimer: TimeInterval = 0
    var stumbleRecoveryDuration: TimeInterval = 0.6
    var maxStumblesBeforeFailure = 1

    private(set) var stumbleCount = 0
    private var subscription: SignalSubscription?

    init(motionUnit: ExplorerMotionUnit, animationDriver: TinyBotAnimationDriver) {
        self.motionUnit = motionUnit
        self.animationDriver = animationDriver
        subscription = CosmicSignalRelay.current.subscribe { [weak self] event in
            self?.handle(event)
        }
    }

    private func handle(_ event: GameEvent) {
        switch event {
        case .hazardContact(_, let kind):
            triggerStumble(kind: kind)
        default:
            break
        }
    }

    private func triggerStumble(kind: HazardKind) {
        guard !isStumbling else {
            stumbleCount += 1
            if stumbleCount >= maxStumblesBeforeFailure {
                CosmicSignalRelay.current.publish(.explorerStumbled(reason: .hazardCollision))
            }
            return
        }
        isStumbling = true
        stumbleTimer = 0
        stumbleCount += 1
        motionUnit.pause()
        animationDriver.transition(to: .hit)
        CosmicSignalRelay.current.publish(.cameraShakeRequested(intensity: kind == .volcano ? 1.0 : 0.6))
    }

    func advance(deltaTime: TimeInterval) {
        guard isStumbling else { return }
        stumbleTimer += deltaTime
        if stumbleTimer >= stumbleRecoveryDuration {
            isStumbling = false
            motionUnit.resume()
            animationDriver.transition(to: .running)
        }
    }
}
