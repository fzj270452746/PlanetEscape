//
//  LevelBlueprint.swift
//  PlanetEscape
//
//  Created by Hades on 2026/7/31.
//

import Foundation

/// 单关的参数化数据结构：星球主题、半径、障碍配置、收集品分布、目标距离。
/// LevelGenerator 按章节难度曲线产出这些蓝图，而不是手写 120 套具体数据。
struct LevelBlueprint {
    var levelNumber: Int
    var chapter: Int
    var themeIdentifier: String
    var planetRadius: Double
    var targetDistance: Double

    var volcanoCount: Int
    var blackHoleCount: Int
    var laserCount: Int
    var movingPlatformCount: Int
    var gravityAnomalyCount: Int
    var iceSlickCount: Int
    var energyPulseCount: Int
    var spikeFieldCount: Int
    var meteorSpawnIntervalSeconds: TimeInterval

    var collectibleCount: Int
    var explorerForwardSpeed: Double

    /// 障碍摆放用的种子，保证同一关每次生成的布局一致（除非明确要求随机重掷）。
    var layoutSeed: UInt64
}
