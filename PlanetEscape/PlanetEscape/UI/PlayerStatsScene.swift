//
//  PlayerStatsScene.swift
//  PlanetEscape
//
//  Created by Hades on 2026/7/31.
//

import Foundation
import SpriteKit
import UIKit

/// 玩家生涯统计面板：已解锁关卡数、累计能量、最佳无尽距离、已达成成就数。
/// 与 AchievementListScene（逐项展示）不同，这里是聚合数字概览，
/// 定位类似"档案卡"，从 Home 菜单直接进入，不嵌套在 Collection 之下。
final class PlayerStatsScene: SKScene {
    var onBackTapped: (() -> Void)?

    private let progressStore: UserProgressStore
    /// 顶部安全区高度（灵动岛/状态栏），做法与 GameplayHUDScene.topInset 一致，
    /// 避免 "< BACK" 贴顶画在状态栏下面重叠。
    private let topInset: CGFloat

    init(size: CGSize, progressStore: UserProgressStore, topInset: CGFloat = 0) {
        self.progressStore = progressStore
        self.topInset = topInset
        super.init(size: size)
        scaleMode = .resizeFill
        backgroundColor = SKColor(red: 0.12, green: 0.12, blue: 0.24, alpha: 1)
        buildLayout()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func buildLayout() {
        let backLabel = SKLabelNode(fontNamed: "Menlo-Bold")
        backLabel.text = "< BACK"
        backLabel.fontSize = 16
        backLabel.fontColor = .white
        backLabel.name = "back"
        backLabel.horizontalAlignmentMode = .left
        backLabel.position = CGPoint(x: 24, y: size.height - 40 - topInset)
        addChild(backLabel)

        let header = SKLabelNode(fontNamed: "Menlo-Bold")
        header.text = "EXPLORER PROFILE"
        header.fontSize = 22
        header.fontColor = .white
        header.position = CGPoint(x: size.width / 2, y: size.height * 0.75 - topInset)
        addChild(header)

        let snapshot = progressStore.snapshot
        let levelsCleared = max(0, snapshot.highestUnlockedLevel - 1)
        let achievementCount = AchievementCatalog.unlockedAchievements(for: snapshot).count
        let bestLevelTime = snapshot.bestElapsedSecondsByLevel.values.min()

        var rows: [String] = [
            "Levels Cleared: \(levelsCleared) / 120",
            "Total Energy Collected: \(snapshot.totalEnergyCollected)",
            "Best Endless Distance: \(Int(snapshot.bestEndlessDistance))m",
            "Achievements Unlocked: \(achievementCount) / \(AchievementCatalog.all.count)",
        ]
        if let bestTime = bestLevelTime {
            rows.append(String(format: "Fastest Level Clear: %.1fs", bestTime))
        }

        var currentY = size.height * 0.6 - topInset
        for row in rows {
            let label = SKLabelNode(fontNamed: "Menlo-Regular")
            label.text = row
            label.fontSize = 16
            label.fontColor = SKColor(white: 0.9, alpha: 1)
            label.position = CGPoint(x: size.width / 2, y: currentY)
            addChild(label)
            currentY -= 32
        }
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        if atPoint(touch.location(in: self)).name == "back" {
            onBackTapped?()
        }
    }
}
