//
//  HapticFeedbackDispatcher.swift
//  PlanetEscape
//
//  Created by Hades on 2026/7/31.
//

import Foundation
import UIKit

/// 订阅碰撞/收集/失衡事件并触发对应的 UIKit 震动反馈，
/// 受 GameSettingsStore.hapticFeedbackEnabled 控制。单独成类而不是
/// 散落在各个事件处理点调用 UIImpactFeedbackGenerator，保持触感反馈策略集中管理。
final class HapticFeedbackDispatcher {
    private let settingsStore: GameSettingsStore
    private var subscription: SignalSubscription?

    private let lightGenerator = UIImpactFeedbackGenerator(style: .light)
    private let heavyGenerator = UIImpactFeedbackGenerator(style: .heavy)
    private let successGenerator = UINotificationFeedbackGenerator()

    init(settingsStore: GameSettingsStore) {
        self.settingsStore = settingsStore
        subscription = CosmicSignalRelay.current.subscribe { [weak self] event in
            self?.handle(event)
        }
    }

    private func handle(_ event: GameEvent) {
        guard settingsStore.snapshot.hapticFeedbackEnabled else { return }
        switch event {
        case .hazardContact:
            heavyGenerator.impactOccurred()
        case .collectibleGathered:
            lightGenerator.impactOccurred()
        case .levelCompleted:
            successGenerator.notificationOccurred(.success)
        case .levelFailed, .explorerFellOff:
            successGenerator.notificationOccurred(.error)
        default:
            break
        }
    }
}
