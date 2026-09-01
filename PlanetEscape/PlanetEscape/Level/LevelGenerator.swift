//
//  LevelGenerator.swift
//  PlanetEscape
//
//  Created by Hades on 2026/7/31.
//

import Foundation

/// 按 ChapterDifficultyCurve 程序化生成 120 关的 LevelBlueprint。
/// 这是文档第 7 节"120 关"与第 17 节"Level System"的核心实现：
/// 不手写 120 套关卡数据，而是用章节曲线在关内线性插值生成参数。
struct LevelGenerator {
    /// 生成单关蓝图。level 范围 1...120。
    func generateBlueprint(forLevel level: Int) -> LevelBlueprint? {
        guard let curve = ChapterDifficultyCurve.curve(forLevel: level) else { return nil }
        let t = curve.progress(forLevel: level)

        return LevelBlueprint(
            levelNumber: level,
            chapter: curve.chapter,
            themeIdentifier: curve.themeIdentifier,
            planetRadius: curve.baseRadius,
            targetDistance: ChapterDifficultyCurve.lerp(curve.baseTargetDistance, curve.endTargetDistance, t),
            volcanoCount: ChapterDifficultyCurve.lerpInt(curve.baseVolcanoCount, curve.endVolcanoCount, t),
            blackHoleCount: ChapterDifficultyCurve.lerpInt(curve.baseBlackHoleCount, curve.endBlackHoleCount, t),
            laserCount: ChapterDifficultyCurve.lerpInt(curve.baseLaserCount, curve.endLaserCount, t),
            movingPlatformCount: ChapterDifficultyCurve.lerpInt(curve.baseMovingPlatformCount, curve.endMovingPlatformCount, t),
            gravityAnomalyCount: LevelGenerator.gravityAnomalyCount(forChapter: curve.chapter, progress: t),
            iceSlickCount: LevelGenerator.themedHazardCount(themeIdentifier: curve.themeIdentifier, matches: "ice", progress: t),
            energyPulseCount: LevelGenerator.themedHazardCount(themeIdentifier: curve.themeIdentifier, matches: "cyber", progress: t),
            spikeFieldCount: LevelGenerator.spikeFieldCount(forChapter: curve.chapter, progress: t),
            meteorSpawnIntervalSeconds: ChapterDifficultyCurve.lerp(curve.baseMeteorInterval, curve.endMeteorInterval, t),
            collectibleCount: ChapterDifficultyCurve.lerpInt(curve.baseCollectibleCount, curve.endCollectibleCount, t),
            explorerForwardSpeed: ChapterDifficultyCurve.lerp(curve.baseForwardSpeed, curve.endForwardSpeed, t),
            layoutSeed: UInt64(level) &* 2654435761
        )
    }

    /// 生成全部 120 关，供进度/关卡选择界面一次性列出。
    func generateAllBlueprints() -> [LevelBlueprint] {
        (1...120).compactMap { generateBlueprint(forLevel: $0) }
    }

    /// 重力异常区（文档 4.1 世界设定）从第 2 章开始出现，随章节推进逐步增多，
    /// 复用现有章节序号而不引入额外的曲线字段，保持 ChapterDifficultyCurve 结构不变。
    private static func gravityAnomalyCount(forChapter chapter: Int, progress: Double) -> Int {
        guard chapter >= 2 else { return 0 }
        let base = chapter - 1
        return ChapterDifficultyCurve.lerpInt(base, base + 1, progress)
    }

    /// 主题专属危险（冰面滑行区/能量脉冲场）只在对应主题的章节出现，数量随该章节进度渐增。
    private static func themedHazardCount(themeIdentifier: String, matches target: String, progress: Double) -> Int {
        guard themeIdentifier == target else { return 0 }
        return ChapterDifficultyCurve.lerpInt(2, 5, progress)
    }

    /// 尖刺群只在最终章节（Chapter 6: Galaxy Escape）出现，作为终章特色危险。
    private static func spikeFieldCount(forChapter chapter: Int, progress: Double) -> Int {
        guard chapter == 6 else { return 0 }
        return ChapterDifficultyCurve.lerpInt(2, 6, progress)
    }
}
