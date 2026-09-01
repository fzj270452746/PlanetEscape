//
//  AchievementCatalog.swift
//  PlanetEscape
//
//  Created by Hades on 2026/7/31.
//

import Foundation

/// 成就定义与解锁条件判定。与 UnlockRegistry（皮肤/配色/拖尾解锁）分开：
/// 成就是里程碑记录（是否达成 + 何时达成），不直接授予可装备内容，
/// 二者语义不同，合并会让 UnlockRegistry 承担超出其职责范围的逻辑。
struct AchievementDefinition {
    let id: String
    let title: String
    let description: String
    let predicate: (UserProgressSnapshot) -> Bool
}

struct AchievementCatalog {
    static let all: [AchievementDefinition] = [
        AchievementDefinition(
            id: "first_escape",
            title: "First Escape",
            description: "Complete your first level.",
            predicate: { $0.highestUnlockedLevel > 1 }
        ),
        AchievementDefinition(
            id: "chapter_one_clear",
            title: "Forest Cleared",
            description: "Reach Chapter 2.",
            predicate: { $0.highestUnlockedLevel > 20 }
        ),
        AchievementDefinition(
            id: "halfway_there",
            title: "Halfway There",
            description: "Reach level 60.",
            predicate: { $0.highestUnlockedLevel > 60 }
        ),
        AchievementDefinition(
            id: "galaxy_escape",
            title: "Galaxy Escape",
            description: "Complete all 120 levels.",
            predicate: { $0.highestUnlockedLevel > 120 }
        ),
        AchievementDefinition(
            id: "energy_hoarder",
            title: "Energy Hoarder",
            description: "Collect 1000 total energy.",
            predicate: { $0.totalEnergyCollected >= 1000 }
        ),
        AchievementDefinition(
            id: "endless_wanderer",
            title: "Endless Wanderer",
            description: "Reach 500m in Endless Mode.",
            predicate: { $0.bestEndlessDistance >= 500 }
        ),
    ]

    static func unlockedAchievements(for snapshot: UserProgressSnapshot) -> [AchievementDefinition] {
        all.filter { $0.predicate(snapshot) }
    }
}
