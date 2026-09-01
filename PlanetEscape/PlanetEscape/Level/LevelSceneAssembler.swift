//
//  LevelSceneAssembler.swift
//  PlanetEscape
//
//  Created by Hades on 2026/7/31.
//

import Foundation
import SceneKit

/// 把一个 LevelBlueprint 变成实际的场景内容：挑选 PlanetTheme、
/// 用 layoutSeed 驱动的确定性随机数在球面上分布火山/黑洞/激光/移动平台/收集品，
/// 并注册进 HazardWorldAssembly / CollectionSignalHandler。
/// 这一步是 Level 模块与 Planet/Obstacle/Collectible 模块的唯一交汇点，
/// 保持各模块互不感知彼此内部实现。
struct LevelSceneAssembler {
    func theme(for blueprint: LevelBlueprint) -> PlanetTheme {
        switch blueprint.themeIdentifier {
        case "forest": return ForestPlanetTheme(radius: blueprint.planetRadius)
        case "volcano": return VolcanoPlanetTheme(radius: blueprint.planetRadius)
        case "ice": return IcePlanetTheme(radius: blueprint.planetRadius)
        case "cyber": return CyberPlanetTheme(radius: blueprint.planetRadius)
        case "dark": return DarkPlanetTheme(radius: blueprint.planetRadius)
        default: return PlaceholderPlanetTheme(radius: blueprint.planetRadius)
        }
    }

    @discardableResult
    func populate(
        blueprint: LevelBlueprint,
        planet: PlanetBody,
        hazards: HazardWorldAssembly,
        collectibles: CollectionSignalHandler,
        dispatcher: CollisionSignalDispatcher,
        lod: LODController? = nil
    ) -> [SCNNode] {
        var rng = SeededRandomGenerator(seed: blueprint.layoutSeed)

        let decorationNodes = theme(for: blueprint).decorate(planet: planet)
        if let lod = lod {
            for node in decorationNodes {
                lod.manage(node, hideBeyondDistance: blueprint.planetRadius * 2.5)
            }
        }

        for i in 0..<blueprint.volcanoCount {
            let coordinate = LevelSceneAssembler.randomCoordinate(using: &rng)
            let volcano = VolcanoEmissionController(hazardID: "volcano_\(blueprint.levelNumber)_\(i)", coordinate: coordinate)
            hazards.register(volcano)
        }

        for i in 0..<blueprint.blackHoleCount {
            let coordinate = LevelSceneAssembler.randomCoordinate(using: &rng)
            let blackHole = BlackHoleGravityWell(hazardID: "blackhole_\(blueprint.levelNumber)_\(i)", coordinate: coordinate)
            hazards.register(blackHole)
        }

        for i in 0..<blueprint.laserCount {
            let coordinate = LevelSceneAssembler.randomCoordinate(using: &rng)
            let laser = LaserSweepEmitter(hazardID: "laser_\(blueprint.levelNumber)_\(i)", coordinate: coordinate, beamLength: CGFloat(blueprint.planetRadius * 0.9))
            hazards.register(laser)
        }

        for i in 0..<blueprint.movingPlatformCount {
            let latitude = Double.random(in: -Double.pi / 3...(Double.pi / 3), using: &rng)
            let longitude = Double.random(in: 0..<(2 * Double.pi), using: &rng)
            let platform = OrbitingPlatformDriver(hazardID: "platform_\(blueprint.levelNumber)_\(i)", orbitLatitude: latitude, startingLongitude: longitude)
            hazards.register(platform)
        }

        for i in 0..<blueprint.gravityAnomalyCount {
            let coordinate = LevelSceneAssembler.randomCoordinate(using: &rng)
            let anomaly = GravityAnomalyZone(hazardID: "anomaly_\(blueprint.levelNumber)_\(i)", coordinate: coordinate)
            hazards.register(anomaly)
        }

        for i in 0..<blueprint.iceSlickCount {
            let coordinate = LevelSceneAssembler.randomCoordinate(using: &rng)
            let slick = IceSlickPatch(hazardID: "iceslick_\(blueprint.levelNumber)_\(i)", coordinate: coordinate)
            hazards.register(slick)
        }

        for i in 0..<blueprint.energyPulseCount {
            let coordinate = LevelSceneAssembler.randomCoordinate(using: &rng)
            let pulse = EnergyPulseField(hazardID: "pulse_\(blueprint.levelNumber)_\(i)", coordinate: coordinate)
            hazards.register(pulse)
        }

        for i in 0..<blueprint.spikeFieldCount {
            let coordinate = LevelSceneAssembler.randomCoordinate(using: &rng)
            let spikes = SpikeFieldCluster(hazardID: "spikes_\(blueprint.levelNumber)_\(i)", coordinate: coordinate)
            hazards.register(spikes)
        }

        for i in 0..<blueprint.collectibleCount {
            let coordinate = LevelSceneAssembler.randomCoordinate(using: &rng)
            let tier = CollectibleValueTier.weightedRandom()
            let crystal = EnergyCrystalNode(collectibleID: "crystal_\(blueprint.levelNumber)_\(i)", tier: tier, coordinate: coordinate)
            collectibles.register(crystal, planet: planet, dispatcher: dispatcher)
        }

        return decorationNodes
    }

    private static func randomCoordinate(using rng: inout SeededRandomGenerator) -> SphereSurfaceCoordinate {
        let longitude = Double.random(in: 0..<(2 * Double.pi), using: &rng)
        let latitude = Double.random(in: -Double.pi / 2.4...(Double.pi / 2.4), using: &rng)
        return SphereSurfaceCoordinate(longitude: longitude, latitude: latitude)
    }
}
