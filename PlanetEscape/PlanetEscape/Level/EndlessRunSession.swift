//
//  EndlessRunSession.swift
//  PlanetEscape
//
//  Created by Hades on 2026/7/31.
//

import Foundation

/// 把 EndlessModeDirector 接到实际游玩状态：清空场上内容、重置角色能量/前进速度，
/// 每帧把角色的 totalDistanceTravelled report 给 director 触发新一批障碍生成，
/// 结束时把最高距离写回 UserProgressStore。这是 EndlessModeDirector（纯生成逻辑）
/// 与游玩会话状态（开始/结束/统计）之间的桥接层，职责与 AdventureLevelDirector 对称。
final class EndlessRunSession {
    private let director: EndlessModeDirector
    private let progressStore: UserProgressStore
    private weak var motionUnit: ExplorerMotionUnit?

    private(set) var isActive = false
    private var subscription: SignalSubscription?
    var onRunEnded: ((Double) -> Void)?

    init(director: EndlessModeDirector, progressStore: UserProgressStore) {
        self.director = director
        self.progressStore = progressStore
        subscription = CosmicSignalRelay.current.subscribe { [weak self] event in
            self?.handle(event)
        }
    }

    func start(motionUnit: ExplorerMotionUnit) {
        director.reset()
        self.motionUnit = motionUnit
        isActive = true
    }

    func stop() {
        guard isActive else { return }
        isActive = false
        let finalDistance = director.bestDistanceThisRun
        progressStore.recordEndlessRun(distance: finalDistance)
        director.reset()
        onRunEnded?(finalDistance)
    }

    private func handle(_ event: GameEvent) {
        guard isActive else { return }
        switch event {
        case .explorerAdvanced(_, _, let distanceTravelled):
            director.handleDistanceUpdate(distanceTravelled)
        case .explorerStumbled, .explorerFellOff:
            stop()
        default:
            break
        }
    }

    var currentDistance: Double { director.bestDistanceThisRun }
}
