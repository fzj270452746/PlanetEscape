//
//  CollectionSignalHandler.swift
//  PlanetEscape
//
//  Created by Hades on 2026/7/31.
//

import Foundation
import SceneKit

/// 持有当前关卡内所有 EnergyCrystalNode，订阅拾取事件并更新累计能量值。
/// 与 HazardRegistry 结构对称（注册表 + 事件订阅），但收集品的"命中效果"
/// 是加分而非伤害，所以拆成独立类型而不是塞进 HazardRegistry。
final class CollectionSignalHandler {
    private var crystals: [EnergyCrystalNode] = []
    private var subscription: SignalSubscription?

    private(set) var totalEnergyCollected = 0

    init() {
        subscription = CosmicSignalRelay.current.subscribe { [weak self] event in
            self?.handle(event)
        }
    }

    func register(_ crystal: EnergyCrystalNode, planet: PlanetBody, dispatcher: CollisionSignalDispatcher) {
        crystal.activate(planet: planet, dispatcher: dispatcher)
        crystals.append(crystal)
    }

    func tick(deltaTime: TimeInterval) {
        for crystal in crystals where !crystal.isCollected {
            crystal.tick(deltaTime: deltaTime)
        }
    }

    func clearAll() {
        for crystal in crystals {
            crystal.rootNode.removeFromParentNode()
        }
        crystals.removeAll()
        totalEnergyCollected = 0
    }

    private func handle(_ event: GameEvent) {
        guard case .collectibleGathered(let id, let value) = event else { return }
        guard let crystal = crystals.first(where: { $0.collectibleID == id && !$0.isCollected }) else { return }
        crystal.markCollected()
        totalEnergyCollected += value
    }
}
