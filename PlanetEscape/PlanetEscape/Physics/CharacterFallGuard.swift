//
//  CharacterFallGuard.swift
//  PlanetEscape
//
//  Created by Hades on 2026/7/31.
//

import Foundation

/// 监控角色是否被黑洞拉离球面太远（掉出可玩范围），
/// 超出阈值即判定为"跌落"并广播失败事件。
/// 与 TinyBotBalanceComponent 分离：balance 处理"碰撞失衡"，
/// 这里专门处理"脱离星球表面"这一类失败，职责不同不合并。
final class CharacterFallGuard: UpdatableComponent {
    private let anchor: CharacterSurfaceAnchor
    private let planet: PlanetBody

    /// 允许的最大法向偏移（相对星球半径的比例），超过视为掉出。
    var maxNormalOffsetRatio: Double = 1.6
    private var currentOffsetDistance: Double = 0
    private(set) var hasTriggeredFailure = false

    init(anchor: CharacterSurfaceAnchor, planet: PlanetBody) {
        self.anchor = anchor
        self.planet = planet
    }

    /// 供黑洞等外部系统报告当前角色离球心的实际距离（局部空间下）。
    func reportRadialDistance(_ distance: Double) {
        currentOffsetDistance = distance
    }

    func advance(deltaTime: TimeInterval) {
        guard !hasTriggeredFailure else { return }
        let threshold = planet.radius * maxNormalOffsetRatio
        if currentOffsetDistance > threshold {
            hasTriggeredFailure = true
            CosmicSignalRelay.current.publish(.explorerFellOff)
            CosmicSignalRelay.current.publish(.explorerStumbled(reason: .blackHoleConsumed))
        }
    }

    func reset() {
        hasTriggeredFailure = false
        currentOffsetDistance = 0
    }
}
