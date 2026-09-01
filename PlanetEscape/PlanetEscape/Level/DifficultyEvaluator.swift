//
//  DifficultyEvaluator.swift
//  PlanetEscape
//
//  Created by Hades on 2026/7/31.
//

import Foundation

/// 文档第 19 节 Dynamic Difficulty：根据完成时间、失败次数、操作（旋转）次数
/// 动态调整障碍密度。这个类型只产出一个 0.5~1.5 的密度调整系数，
/// 具体如何应用（乘到 LevelBlueprint 的障碍计数上）由调用方决定，
/// 保持"评估"与"应用"分离。
final class DifficultyEvaluator {
    private var recentCompletionTimes: [TimeInterval] = []
    private var recentFailureCounts: [Int] = []
    private var recentRotationCounts: [Int] = []

    private let historyWindow = 5

    func recordAttempt(completionTime: TimeInterval?, failures: Int, rotations: Int) {
        if let time = completionTime {
            recentCompletionTimes.append(time)
            if recentCompletionTimes.count > historyWindow { recentCompletionTimes.removeFirst() }
        }
        recentFailureCounts.append(failures)
        if recentFailureCounts.count > historyWindow { recentFailureCounts.removeFirst() }

        recentRotationCounts.append(rotations)
        if recentRotationCounts.count > historyWindow { recentRotationCounts.removeFirst() }
    }

    /// 返回密度调整系数：玩家表现越好（失败少、旋转次数少、通关快）系数越高（增加难度），
    /// 表现越差系数越低（降低难度），保持在 [0.6, 1.4] 区间避免剧烈波动。
    func currentDensityMultiplier(baselineTargetTime: TimeInterval) -> Double {
        guard !recentFailureCounts.isEmpty else { return 1.0 }

        let averageFailures = Double(recentFailureCounts.reduce(0, +)) / Double(recentFailureCounts.count)
        let averageRotations = Double(recentRotationCounts.reduce(0, +)) / Double(max(recentRotationCounts.count, 1))
        let averageTime = recentCompletionTimes.isEmpty
            ? baselineTargetTime
            : recentCompletionTimes.reduce(0, +) / Double(recentCompletionTimes.count)

        let failurePenalty = min(averageFailures * 0.08, 0.4)
        let speedBonus = averageTime < baselineTargetTime ? min((baselineTargetTime - averageTime) / baselineTargetTime, 0.3) : 0
        let rotationEfficiencyBonus = averageRotations < 10 ? 0.1 : 0

        let multiplier = 1.0 + speedBonus + rotationEfficiencyBonus - failurePenalty
        return min(max(multiplier, 0.6), 1.4)
    }

    func applyDensity(to blueprint: LevelBlueprint) -> LevelBlueprint {
        let multiplier = currentDensityMultiplier(baselineTargetTime: blueprint.targetDistance / max(blueprint.explorerForwardSpeed, 0.1))
        var adjusted = blueprint
        adjusted.volcanoCount = Int((Double(blueprint.volcanoCount) * multiplier).rounded())
        adjusted.blackHoleCount = Int((Double(blueprint.blackHoleCount) * multiplier).rounded())
        adjusted.laserCount = Int((Double(blueprint.laserCount) * multiplier).rounded())
        adjusted.movingPlatformCount = Int((Double(blueprint.movingPlatformCount) * multiplier).rounded())
        return adjusted
    }
}
