//
//  UnlockRegistry.swift
//  PlanetEscape
//
//  Created by Hades on 2026/7/31.
//

import Foundation

/// 文档第 12 节解锁系统：机器人皮肤 / 星球颜色 / 拖尾效果，全部靠 Progress Save 解锁，
/// 无内购。用能量总量与关卡进度作为解锁条件，条件与解锁项在此集中定义，
/// 方便 Collection 界面统一遍历展示。
enum UnlockableCategory {
    case botSkin
    case planetColorway
    case trailEffect
}

struct UnlockableItem {
    let id: String
    let category: UnlockableCategory
    let displayName: String
    let requiredEnergyTotal: Int
    let requiredLevel: Int
}

final class UnlockRegistry {
    static let allItems: [UnlockableItem] = [
        UnlockableItem(id: "skin_default", category: .botSkin, displayName: "Classic Bot", requiredEnergyTotal: 0, requiredLevel: 1),
        UnlockableItem(id: "skin_chrome", category: .botSkin, displayName: "Chrome Bot", requiredEnergyTotal: 200, requiredLevel: 10),
        UnlockableItem(id: "skin_gold", category: .botSkin, displayName: "Gold Bot", requiredEnergyTotal: 800, requiredLevel: 40),

        UnlockableItem(id: "planet_default", category: .planetColorway, displayName: "Verdant", requiredEnergyTotal: 0, requiredLevel: 1),
        UnlockableItem(id: "planet_crimson", category: .planetColorway, displayName: "Crimson", requiredEnergyTotal: 150, requiredLevel: 21),
        UnlockableItem(id: "planet_azure", category: .planetColorway, displayName: "Azure", requiredEnergyTotal: 500, requiredLevel: 61),

        UnlockableItem(id: "trail_none", category: .trailEffect, displayName: "No Trail", requiredEnergyTotal: 0, requiredLevel: 1),
        UnlockableItem(id: "trail_spark", category: .trailEffect, displayName: "Spark Trail", requiredEnergyTotal: 100, requiredLevel: 15),
        UnlockableItem(id: "trail_comet", category: .trailEffect, displayName: "Comet Trail", requiredEnergyTotal: 1000, requiredLevel: 81),
    ]

    private let progressStore: UserProgressStore

    init(progressStore: UserProgressStore) {
        self.progressStore = progressStore
    }

    func isUnlocked(_ item: UnlockableItem) -> Bool {
        progressStore.snapshot.totalEnergyCollected >= item.requiredEnergyTotal
            && progressStore.snapshot.highestUnlockedLevel >= item.requiredLevel
    }

    func unlockedItems(in category: UnlockableCategory) -> [UnlockableItem] {
        UnlockRegistry.allItems.filter { $0.category == category && isUnlocked($0) }
    }

    func allItems(in category: UnlockableCategory) -> [UnlockableItem] {
        UnlockRegistry.allItems.filter { $0.category == category }
    }
}
