//
//  MeteorSpawner.swift
//  PlanetEscape
//
//  Created by Hades on 2026/7/31.
//

import Foundation
import SceneKit

/// 按设定频率随机生成 MeteorObject 并注册进 HazardRegistry，
/// 超过生命周期或落地的陨石会被回收清理。
/// 独立于 HazardRegistry 之外，因为它是"生成器"而不是"注册表"，
/// 两者职责不同：Registry 管生命周期查询，Spawner 管何时创建新实例。
final class MeteorSpawner: UpdatableComponent {
    private let planet: PlanetBody
    /// 由 HazardWorldAssembly 在自身初始化完成后回填（存在初始化时序上的循环依赖：
    /// Spawner 需要引用 Assembly 才能统一走 register() 路径，而 Assembly 创建 Spawner
    /// 时自身还没构造完毕），不能在 init 里直接传入。
    weak var hazards: HazardWorldAssembly?

    /// 平均生成间隔（秒），实际间隔在此基础上做随机抖动。
    var averageSpawnInterval: TimeInterval = 3.5
    var spawnHeightAboveSurface: Double = 4.0
    private var timeUntilNextSpawn: TimeInterval
    private var spawnCounter = 0

    private var trackedMeteors: [MeteorObject] = []

    init(planet: PlanetBody) {
        self.planet = planet
        self.timeUntilNextSpawn = MeteorSpawner.randomInterval(around: averageSpawnInterval)
    }

    func advance(deltaTime: TimeInterval) {
        timeUntilNextSpawn -= deltaTime
        if timeUntilNextSpawn <= 0 {
            spawnOne()
            timeUntilNextSpawn = MeteorSpawner.randomInterval(around: averageSpawnInterval)
        }
        cleanupLandedMeteors()
    }

    private func spawnOne() {
        spawnCounter += 1
        let longitude = Double.random(in: 0..<(2 * Double.pi))
        let latitude = Double.random(in: -Double.pi / 3...(Double.pi / 3))
        let targetCoordinate = SphereSurfaceCoordinate(longitude: longitude, latitude: latitude)

        let meteor = MeteorObject(hazardID: "meteor_\(spawnCounter)", targetCoordinate: targetCoordinate)
        let surfacePoint = targetCoordinate.cartesian(radius: planet.radius + spawnHeightAboveSurface)
        meteor.configureInitialLocalPosition(surfacePoint)

        hazards?.register(meteor)
        trackedMeteors.append(meteor)
    }

    private func cleanupLandedMeteors() {
        trackedMeteors.removeAll { meteor in
            guard meteor.hasLanded else { return false }
            meteor.deactivate()
            meteor.rootNode.removeFromParentNode()
            return true
        }
    }

    private static func randomInterval(around average: TimeInterval) -> TimeInterval {
        let jitter = average * 0.4
        return average + Double.random(in: -jitter...jitter)
    }
}
