//
//  ChapterDifficultyCurve.swift
//  PlanetEscape
//
//  Created by Hades on 2026/7/31.
//

import Foundation

/// 文档第 7 节六章节规划：每章 20 关，主题固定，难度在章节内部渐进，
/// 章节之间整体基线提升。这里把每章的"起点/终点难度参数"定义出来，
/// LevelGenerator 在关内做线性插值，实现 120 关程序化难度曲线。
struct ChapterDifficultyCurve {
    let chapter: Int
    let themeIdentifier: String
    let levelRange: ClosedRange<Int>

    let baseRadius: Double
    let baseTargetDistance: Double
    let endTargetDistance: Double

    let baseVolcanoCount: Int
    let endVolcanoCount: Int
    let baseBlackHoleCount: Int
    let endBlackHoleCount: Int
    let baseLaserCount: Int
    let endLaserCount: Int
    let baseMovingPlatformCount: Int
    let endMovingPlatformCount: Int

    let baseMeteorInterval: TimeInterval
    let endMeteorInterval: TimeInterval

    let baseCollectibleCount: Int
    let endCollectibleCount: Int

    let baseForwardSpeed: Double
    let endForwardSpeed: Double

    /// 关内进度 0~1（第一关=0，最后一关=1）。
    func progress(forLevel level: Int) -> Double {
        guard levelRange.upperBound > levelRange.lowerBound else { return 0 }
        let clamped = min(max(level, levelRange.lowerBound), levelRange.upperBound)
        return Double(clamped - levelRange.lowerBound) / Double(levelRange.upperBound - levelRange.lowerBound)
    }

    static func lerp(_ a: Double, _ b: Double, _ t: Double) -> Double {
        a + (b - a) * t
    }

    static func lerpInt(_ a: Int, _ b: Int, _ t: Double) -> Int {
        Int((Double(a) + (Double(b) - Double(a)) * t).rounded())
    }

    /// 文档 7 节六章节配置：Green/Volcano/Dark/Ice/Space Core/Galaxy Escape。
    static let allChapters: [ChapterDifficultyCurve] = [
        ChapterDifficultyCurve(
            chapter: 1, themeIdentifier: "forest", levelRange: 1...20,
            baseRadius: 5.0, baseTargetDistance: 40, endTargetDistance: 90,
            baseVolcanoCount: 0, endVolcanoCount: 2,
            baseBlackHoleCount: 0, endBlackHoleCount: 0,
            baseLaserCount: 0, endLaserCount: 2,
            baseMovingPlatformCount: 0, endMovingPlatformCount: 2,
            baseMeteorInterval: 6.0, endMeteorInterval: 4.5,
            baseCollectibleCount: 8, endCollectibleCount: 14,
            baseForwardSpeed: 1.2, endForwardSpeed: 1.5
        ),
        ChapterDifficultyCurve(
            chapter: 2, themeIdentifier: "volcano", levelRange: 21...40,
            baseRadius: 6.0, baseTargetDistance: 90, endTargetDistance: 150,
            baseVolcanoCount: 2, endVolcanoCount: 5,
            baseBlackHoleCount: 0, endBlackHoleCount: 1,
            baseLaserCount: 1, endLaserCount: 3,
            baseMovingPlatformCount: 1, endMovingPlatformCount: 3,
            baseMeteorInterval: 4.5, endMeteorInterval: 3.5,
            baseCollectibleCount: 12, endCollectibleCount: 18,
            baseForwardSpeed: 1.5, endForwardSpeed: 1.8
        ),
        ChapterDifficultyCurve(
            chapter: 3, themeIdentifier: "dark", levelRange: 41...60,
            baseRadius: 7.0, baseTargetDistance: 150, endTargetDistance: 220,
            baseVolcanoCount: 2, endVolcanoCount: 4,
            baseBlackHoleCount: 1, endBlackHoleCount: 3,
            baseLaserCount: 2, endLaserCount: 4,
            baseMovingPlatformCount: 2, endMovingPlatformCount: 4,
            baseMeteorInterval: 3.5, endMeteorInterval: 2.8,
            baseCollectibleCount: 14, endCollectibleCount: 20,
            baseForwardSpeed: 1.7, endForwardSpeed: 2.0
        ),
        ChapterDifficultyCurve(
            chapter: 4, themeIdentifier: "ice", levelRange: 61...80,
            baseRadius: 8.0, baseTargetDistance: 220, endTargetDistance: 300,
            baseVolcanoCount: 1, endVolcanoCount: 3,
            baseBlackHoleCount: 2, endBlackHoleCount: 3,
            baseLaserCount: 3, endLaserCount: 5,
            baseMovingPlatformCount: 3, endMovingPlatformCount: 5,
            baseMeteorInterval: 3.0, endMeteorInterval: 2.4,
            baseCollectibleCount: 16, endCollectibleCount: 22,
            baseForwardSpeed: 1.9, endForwardSpeed: 2.2
        ),
        ChapterDifficultyCurve(
            chapter: 5, themeIdentifier: "cyber", levelRange: 81...100,
            baseRadius: 9.0, baseTargetDistance: 300, endTargetDistance: 400,
            baseVolcanoCount: 3, endVolcanoCount: 5,
            baseBlackHoleCount: 2, endBlackHoleCount: 4,
            baseLaserCount: 4, endLaserCount: 6,
            baseMovingPlatformCount: 4, endMovingPlatformCount: 6,
            baseMeteorInterval: 2.5, endMeteorInterval: 2.0,
            baseCollectibleCount: 18, endCollectibleCount: 24,
            baseForwardSpeed: 2.0, endForwardSpeed: 2.4
        ),
        ChapterDifficultyCurve(
            chapter: 6, themeIdentifier: "dark", levelRange: 101...120,
            baseRadius: 10.0, baseTargetDistance: 400, endTargetDistance: 520,
            baseVolcanoCount: 4, endVolcanoCount: 6,
            baseBlackHoleCount: 3, endBlackHoleCount: 5,
            baseLaserCount: 5, endLaserCount: 7,
            baseMovingPlatformCount: 5, endMovingPlatformCount: 7,
            baseMeteorInterval: 2.0, endMeteorInterval: 1.5,
            baseCollectibleCount: 20, endCollectibleCount: 28,
            baseForwardSpeed: 2.2, endForwardSpeed: 2.6
        ),
    ]

    static func curve(forLevel level: Int) -> ChapterDifficultyCurve? {
        allChapters.first { $0.levelRange.contains(level) }
    }
}
