//
//  BlackHoleEscapeAssist.swift
//  PlanetEscape
//
//  Created by Hades on 2026/7/31.
//

import Foundation

/// 文档 8.2 要求："玩家需要快速旋转星球来改变轨迹"。
/// 这个组件在每帧检测角色是否处于任一黑洞的影响范围内，
/// 若是，则临时降低 ExplorerMotionUnit 的有效前进速度感知（视觉上的挣扎感），
/// 并通过事件提示 UI 显示"危险"指示，鼓励玩家旋转逃脱。
/// 真正的"逃脱"结果由角色新的表面坐标是否离开影响半径自然决定，
/// 这里不做强制修正角色路径，保持"玩家操控的是星球，不是角色"的原则。
final class BlackHoleEscapeAssist: UpdatableComponent {
    private let anchor: CharacterSurfaceAnchor
    private let fallGuard: CharacterFallGuard
    private let planet: PlanetBody
    private var blackHoles: [BlackHoleGravityWell] = []

    private(set) var isCurrentlyBeingPulled = false
    private var accumulatedExposure: TimeInterval = 0
    /// 持续暴露在最大吸引力下超过此时长即触发"吸入"失败。
    var consumeThreshold: TimeInterval = 1.8

    init(anchor: CharacterSurfaceAnchor, fallGuard: CharacterFallGuard, planet: PlanetBody) {
        self.anchor = anchor
        self.fallGuard = fallGuard
        self.planet = planet
    }

    func trackBlackHoles(_ holes: [BlackHoleGravityWell]) {
        blackHoles = holes
    }

    func advance(deltaTime: TimeInterval) {
        guard !blackHoles.isEmpty else { return }
        let strongestPull = blackHoles
            .map { $0.pullStrength(at: anchor.surfaceCoordinate, planetRadius: planet.radius) }
            .max() ?? 0

        isCurrentlyBeingPulled = strongestPull > 0.05
        CosmicSignalRelay.current.publish(.blackHolePullStrengthChanged(strength: min(strongestPull, 1.0)))
        guard isCurrentlyBeingPulled else {
            accumulatedExposure = 0
            return
        }

        accumulatedExposure += deltaTime * strongestPull
        fallGuard.reportRadialDistance(planet.radius * (1 + strongestPull * 0.4))

        if accumulatedExposure >= consumeThreshold {
            CosmicSignalRelay.current.publish(.explorerStumbled(reason: .blackHoleConsumed))
        }
    }
}
