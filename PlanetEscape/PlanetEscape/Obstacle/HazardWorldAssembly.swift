//
//  HazardWorldAssembly.swift
//  PlanetEscape
//
//  Created by Hades on 2026/7/31.
//

import Foundation
import SceneKit

/// 把 Physics/Obstacle 模块的所有子系统（碰撞分发、障碍注册表、陨石生成器、
/// 黑洞逃脱辅助、掉落守卫）组装成一个整体，供 WorldRuntime 持有单个引用即可，
/// 避免 WorldRuntime 内部堆砌大量子系统初始化与逐帧调用代码。
final class HazardWorldAssembly {
    let dispatcher = CollisionSignalDispatcher()
    let registry: HazardRegistry
    let meteorSpawner: MeteorSpawner
    let meteorResolver: MeteorCollisionResolver
    let particleBudget = ParticleBudgetLimiter()
    private var blackHoleEscapeAssist: BlackHoleEscapeAssist?
    private let planet: PlanetBody

    init(scene: SCNScene, planet: PlanetBody) {
        self.planet = planet
        scene.physicsWorld.contactDelegate = dispatcher
        self.registry = HazardRegistry(planet: planet, dispatcher: dispatcher)
        self.meteorResolver = MeteorCollisionResolver(planet: planet)
        self.meteorSpawner = MeteorSpawner(planet: planet)

        meteorSpawner.hazards = self
    }

    /// 角色装配完成后调用，接入黑洞逃脱检测（需要角色的 anchor/fallGuard）。
    func attachExplorerAwareness(anchor: CharacterSurfaceAnchor, fallGuard: CharacterFallGuard) -> BlackHoleEscapeAssist {
        let assist = BlackHoleEscapeAssist(anchor: anchor, fallGuard: fallGuard, planet: planet)
        blackHoleEscapeAssist = assist
        refreshBlackHoleTracking()
        return assist
    }

    /// 供 ExplorerMotionUnit 查询当前坐标是否处于任一重力异常区内，
    /// 返回叠加后的速度倍率（多个异常区重叠时取乘积，制造更剧烈的紊乱效果）。
    func gravityAnomalySpeedMultiplier(at coordinate: SphereSurfaceCoordinate) -> Double {
        let anomalies = registry.activeHazards.compactMap { $0 as? GravityAnomalyZone }
        guard !anomalies.isEmpty else { return 1.0 }
        return anomalies.reduce(1.0) { partial, zone in
            partial * zone.speedMultiplier(at: coordinate, planetRadius: planet.radius)
        }
    }

    /// 供 RotationGestureInterpreter 查询当前坐标是否处于冰面滑行区内，
    /// 返回旋转灵敏度放大系数（多个区域重叠取最大值，避免叠乘导致失控）。
    func iceSlickSensitivityMultiplier(at coordinate: SphereSurfaceCoordinate) -> Double {
        let patches = registry.activeHazards.compactMap { $0 as? IceSlickPatch }
        guard !patches.isEmpty else { return 1.0 }
        return patches.map { $0.sensitivityMultiplier(at: coordinate, planetRadius: planet.radius) }.max() ?? 1.0
    }

    private func refreshBlackHoleTracking() {
        let holes = registry.activeHazards.compactMap { $0 as? BlackHoleGravityWell }
        blackHoleEscapeAssist?.trackBlackHoles(holes)
    }

    func register(_ hazard: HazardBehavior) {
        if let volcano = hazard as? VolcanoEmissionController {
            volcano.particleBudget = particleBudget
        }
        if let meteor = hazard as? MeteorObject {
            meteorResolver.monitor(meteor)
        }
        registry.register(hazard)
        refreshBlackHoleTracking()
    }

    func advance(deltaTime: TimeInterval) {
        registry.tick(deltaTime: deltaTime)
        meteorSpawner.advance(deltaTime: deltaTime)
        meteorResolver.advance(deltaTime: deltaTime)
    }
}
