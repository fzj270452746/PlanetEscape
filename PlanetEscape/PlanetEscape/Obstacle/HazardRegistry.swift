//
//  HazardRegistry.swift
//  PlanetEscape
//
//  Created by Hades on 2026/7/31.
//

import Foundation
import SceneKit

/// 障碍的注册与生命周期管理（替代文档禁止的 EnemyManager 命名/结构）。
/// 只做三件事：持有当前关卡的障碍列表、每帧调用 tick、和向
/// CollisionSignalDispatcher 注册物理碰撞查询表。不包含任何具体障碍逻辑，
/// 具体逻辑都在各个 HazardBehavior 实现里。
final class HazardRegistry {
    private(set) var activeHazards: [HazardBehavior] = []
    private let planet: PlanetBody
    private let dispatcher: CollisionSignalDispatcher

    init(planet: PlanetBody, dispatcher: CollisionSignalDispatcher) {
        self.planet = planet
        self.dispatcher = dispatcher
    }

    func register(_ hazard: HazardBehavior) {
        hazard.activate(planet: planet, dispatcher: dispatcher)
        activeHazards.append(hazard)
    }

    func unregisterAll() {
        for hazard in activeHazards {
            hazard.deactivate()
            hazard.rootNode.removeFromParentNode()
            dispatcher.unregisterHazardNode(name: hazard.rootNode.name ?? "")
        }
        activeHazards.removeAll()
    }

    func tick(deltaTime: TimeInterval) {
        for hazard in activeHazards {
            hazard.tick(deltaTime: deltaTime)
            if let platform = hazard as? OrbitingPlatformDriver {
                platform.syncTransform(planet: planet)
            }
        }
    }

    /// 供 EscapeRouteAnalyzer 等只读查询当前障碍的表面坐标分布。
    func hazardCoordinates() -> [(id: String, kind: HazardKind, coordinate: SphereSurfaceCoordinate)] {
        activeHazards.map { ($0.hazardID, $0.kind, $0.surfaceCoordinate) }
    }
}
