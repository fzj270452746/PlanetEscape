//
//  EnergyReserveComponent.swift
//  PlanetEscape
//
//  Created by Hades on 2026/7/31.
//

import Foundation

/// 角色的能量储备（HUD 顶部 Energy%，文档第 13 节）：随时间缓慢消耗，
/// 拾取 Energy Crystal 时回补。耗尽时广播 energyDepleted / explorerStumbled(.energyExhausted)，
/// 是 Adventure 模式除碰撞/黑洞之外的第三种失败途径。
final class EnergyReserveComponent: UpdatableComponent {
    private(set) var currentEnergy: Double
    let maxEnergy: Double
    /// 每秒自然消耗量，关卡越难可以设更高值（由 LevelBlueprint 驱动）。
    var drainPerSecond: Double

    private var subscription: SignalSubscription?
    private(set) var isDepleted = false

    init(maxEnergy: Double = 100, drainPerSecond: Double = 1.6) {
        self.maxEnergy = maxEnergy
        self.currentEnergy = maxEnergy
        self.drainPerSecond = drainPerSecond
        subscription = CosmicSignalRelay.current.subscribe { [weak self] event in
            self?.handle(event)
        }
    }

    func advance(deltaTime: TimeInterval) {
        guard !isDepleted else { return }
        currentEnergy = max(0, currentEnergy - drainPerSecond * deltaTime)
        if currentEnergy <= 0 {
            isDepleted = true
            CosmicSignalRelay.current.publish(.energyDepleted)
            CosmicSignalRelay.current.publish(.explorerStumbled(reason: .energyExhausted))
        }
    }

    func reset() {
        currentEnergy = maxEnergy
        isDepleted = false
    }

    private func handle(_ event: GameEvent) {
        guard case .collectibleGathered(_, let value) = event else { return }
        currentEnergy = min(maxEnergy, currentEnergy + Double(value) * 1.5)
    }
}
