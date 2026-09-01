//
//  AdventureLevelDirector.swift
//  PlanetEscape
//
//  Created by Hades on 2026/7/31.
//

import Foundation

/// Adventure Mode（文档 9.1）的关卡驱动器：持有 LevelGenerator/LevelSceneAssembler/
/// LevelProgressionTracker/DifficultyEvaluator/CollectionSignalHandler，
/// 负责"加载第 N 关到当前 WorldRuntime"这一件事。WorldRuntime 只需要
/// 持有一个 AdventureLevelDirector 引用并转发 deltaTime，不需要认识
/// Level 模块内部的具体类型，保持模块边界清晰。
final class AdventureLevelDirector {
    private let generator = LevelGenerator()
    private let assembler = LevelSceneAssembler()
    private let routeAnalyzer = EscapeRouteAnalyzer()
    let progressionTracker = LevelProgressionTracker()
    let difficultyEvaluator = DifficultyEvaluator()
    let collectibles = CollectionSignalHandler()
    let lodController = LODController()

    private weak var planet: PlanetBody?
    private weak var hazards: HazardWorldAssembly?
    private var subscription: SignalSubscription?

    private(set) var currentBlueprint: LevelBlueprint?

    init(planet: PlanetBody, hazards: HazardWorldAssembly) {
        self.planet = planet
        self.hazards = hazards
        subscription = CosmicSignalRelay.current.subscribe { [weak self] event in
            self?.handle(event)
        }
    }

    /// 加载指定关卡：清空上一关的障碍/收集品，按蓝图重新填充。
    /// 生成后用 EscapeRouteAnalyzer 自检可达性，若发现某段纬线被完全封锁
    /// （程序化生成的极端情况），用不同的 layoutSeed 重新生成，最多重试几次，
    /// 避免真的把无解关卡摆给玩家。
    @discardableResult
    func loadLevel(_ levelNumber: Int) -> LevelBlueprint? {
        guard let planet = planet, let hazards = hazards else { return nil }
        guard let baseBlueprint = generator.generateBlueprint(forLevel: levelNumber) else { return nil }

        var blueprint = difficultyEvaluator.applyDensity(to: baseBlueprint)
        var attempt = 0
        let maxAttempts = 4

        while attempt < maxAttempts {
            let report = routeAnalyzer.analyze(
                hazardCoordinates: AdventureLevelDirector.estimatedHazardCoordinates(for: blueprint),
                startLatitude: -Double.pi / 2.2,
                travelSpanRadians: Double.pi * 0.9
            )
            if report.isTraversable { break }
            attempt += 1
            blueprint.layoutSeed = blueprint.layoutSeed &+ UInt64(attempt) &* 999331
        }

        hazards.registry.unregisterAll()
        collectibles.clearAll()
        lodController.clear()

        assembler.populate(
            blueprint: blueprint,
            planet: planet,
            hazards: hazards,
            collectibles: collectibles,
            dispatcher: hazards.dispatcher,
            lod: lodController
        )

        currentBlueprint = blueprint
        progressionTracker.beginLevel(levelNumber)

        if let explorer = WorldRuntime.current?.explorer {
            explorer.motionUnit.resume()
            explorer.animationDriver.transition(to: .running)
        }

        return blueprint
    }

    /// 离开 Adventure/Challenge 玩法、进入 Endless 或回主页时必须调用：
    /// currentBlueprint 之前只在 loadLevel/completeCurrentLevel/失败事件里被赋值或清空，
    /// startEndlessRun 从不调用 loadLevel，如果不在这里显式清空，上一局关卡残留的
    /// targetDistance 会在 Endless 模式下继续被 advance() 里的距离判断使用，
    /// 一旦（残留的）totalDistanceTravelled 达标就会误触发 completeCurrentLevel()——
    /// 表现为角色被永久暂停并卡在 celebrating 转圈动画。这里只清空追踪状态，
    /// 不触发 completeCurrentLevel 的庆祝/计分副作用，因为这不是一次真正的关卡完成。
    func exitToFreeMode() {
        currentBlueprint = nil
    }

    func advance(deltaTime: TimeInterval) {
        progressionTracker.advance(deltaTime: deltaTime)
        collectibles.tick(deltaTime: deltaTime)

        guard let blueprint = currentBlueprint else { return }
        if let explorer = WorldRuntime.current?.explorer,
           explorer.motionUnit.totalDistanceTravelled >= blueprint.targetDistance {
            completeCurrentLevel()
        }
    }

    private func completeCurrentLevel() {
        guard currentBlueprint != nil else { return }
        progressionTracker.completeLevel()
        difficultyEvaluator.recordAttempt(
            completionTime: progressionTracker.elapsedSeconds,
            failures: progressionTracker.failureCount,
            rotations: progressionTracker.rotationCount
        )
        currentBlueprint = nil

        if let explorer = WorldRuntime.current?.explorer {
            explorer.motionUnit.pause()
            explorer.animationDriver.transition(to: .celebrating)
            CelebrationBurstEffect.spawn(at: explorer.rootNode)
        }
    }

    private func handle(_ event: GameEvent) {
        switch event {
        case .explorerStumbled(let reason):
            guard currentBlueprint != nil else { return }
            progressionTracker.failLevel(reason: reason)
            currentBlueprint = nil
        default:
            break
        }
    }

    /// 用与 LevelSceneAssembler 相同的 layoutSeed 驱动的确定性随机数，
    /// 预先估算障碍坐标分布（不实际创建节点），供 EscapeRouteAnalyzer 自检使用。
    private static func estimatedHazardCoordinates(for blueprint: LevelBlueprint) -> [(kind: HazardKind, coordinate: SphereSurfaceCoordinate)] {
        var rng = SeededRandomGenerator(seed: blueprint.layoutSeed)
        var result: [(kind: HazardKind, coordinate: SphereSurfaceCoordinate)] = []

        func randomCoordinate() -> SphereSurfaceCoordinate {
            let longitude = Double.random(in: 0..<(2 * Double.pi), using: &rng)
            let latitude = Double.random(in: -Double.pi / 2.4...(Double.pi / 2.4), using: &rng)
            return SphereSurfaceCoordinate(longitude: longitude, latitude: latitude)
        }

        for _ in 0..<blueprint.volcanoCount { result.append((.volcano, randomCoordinate())) }
        for _ in 0..<blueprint.blackHoleCount { result.append((.blackHole, randomCoordinate())) }
        for _ in 0..<blueprint.laserCount { result.append((.laser, randomCoordinate())) }
        for _ in 0..<blueprint.gravityAnomalyCount { result.append((.laser, randomCoordinate())) }
        for _ in 0..<blueprint.iceSlickCount { result.append((.laser, randomCoordinate())) }
        for _ in 0..<blueprint.energyPulseCount { result.append((.laser, randomCoordinate())) }
        for _ in 0..<blueprint.spikeFieldCount { result.append((.volcano, randomCoordinate())) }

        return result
    }
}
