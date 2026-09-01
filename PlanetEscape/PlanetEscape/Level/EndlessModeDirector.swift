//
//  EndlessModeDirector.swift
//  PlanetEscape
//
//  Created by Hades on 2026/7/31.
//

import Foundation

/// 无限模式（文档 9.2）：目标是最高距离，障碍/能量/黑洞随机生成，
/// 没有固定的 LevelBlueprint 终点。这里持续按距离里程碑追加新的一批障碍，
/// 并让密度随距离缓慢提升，复用 LevelSceneAssembler 的放置逻辑。
final class EndlessModeDirector {
    private let planet: PlanetBody
    private let hazards: HazardWorldAssembly
    private let collectibles: CollectionSignalHandler
    private let dispatcher: CollisionSignalDispatcher
    private let assembler = LevelSceneAssembler()

    private var nextMilestoneDistance: Double = 30
    private let milestoneStep: Double = 30
    private var batchIndex: Int = 0
    private(set) var bestDistanceThisRun: Double = 0

    init(planet: PlanetBody, hazards: HazardWorldAssembly, collectibles: CollectionSignalHandler, dispatcher: CollisionSignalDispatcher) {
        self.planet = planet
        self.hazards = hazards
        self.collectibles = collectibles
        self.dispatcher = dispatcher
    }

    func handleDistanceUpdate(_ distanceTravelled: Double) {
        bestDistanceThisRun = max(bestDistanceThisRun, distanceTravelled)
        guard distanceTravelled >= nextMilestoneDistance else { return }
        spawnNextBatch()
        nextMilestoneDistance += milestoneStep
    }

    private func spawnNextBatch() {
        batchIndex += 1
        let densityScale = min(1.0 + Double(batchIndex) * 0.08, 3.0)

        let blueprint = LevelBlueprint(
            levelNumber: -1,
            chapter: 0,
            themeIdentifier: "dark",
            planetRadius: planet.radius,
            targetDistance: 0,
            volcanoCount: Int((1.0 * densityScale).rounded()),
            blackHoleCount: Int((0.4 * densityScale).rounded()),
            laserCount: Int((0.6 * densityScale).rounded()),
            movingPlatformCount: Int((0.5 * densityScale).rounded()),
            gravityAnomalyCount: Int((0.3 * densityScale).rounded()),
            iceSlickCount: 0,
            energyPulseCount: 0,
            spikeFieldCount: Int((0.2 * densityScale).rounded()),
            meteorSpawnIntervalSeconds: max(1.5, 5.0 / densityScale),
            collectibleCount: Int((4.0 * densityScale).rounded()),
            explorerForwardSpeed: 0,
            layoutSeed: UInt64(batchIndex) &* 40503 &+ UInt64(Date().timeIntervalSince1970)
        )

        assembler.populate(blueprint: blueprint, planet: planet, hazards: hazards, collectibles: collectibles, dispatcher: dispatcher)
    }

    func reset() {
        nextMilestoneDistance = 30
        batchIndex = 0
        bestDistanceThisRun = 0
        hazards.registry.unregisterAll()
        collectibles.clearAll()
    }
}
