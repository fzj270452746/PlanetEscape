//
//  AchievementListScene.swift
//  PlanetEscape
//
//  Created by Hades on 2026/7/31.
//

import Foundation
import SpriteKit
import UIKit

/// 展示 AchievementCatalog 中全部成就的达成状态，纯只读展示界面。
final class AchievementListScene: SKScene {
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
        header.text = "ACHIEVEMENTS"
        header.fontSize = 20
        header.fontColor = .white
        header.horizontalAlignmentMode = .left
        header.position = CGPoint(x: 24, y: size.height - 80 - topInset)
        addChild(header)

        let unlockedIDs = Set(AchievementCatalog.unlockedAchievements(for: progressStore.snapshot).map { $0.id })
        var currentY = size.height - 120 - topInset
        for achievement in AchievementCatalog.all {
            let unlocked = unlockedIDs.contains(achievement.id)
            let titleLabel = SKLabelNode(fontNamed: "Menlo-Bold")
            titleLabel.text = unlocked ? "\u{2713} \(achievement.title)" : "\u{25CB} \(achievement.title)"
            titleLabel.fontSize = 15
            titleLabel.fontColor = unlocked ? SKColor(red: 0.3, green: 0.9, blue: 0.5, alpha: 1) : .white
            titleLabel.horizontalAlignmentMode = .left
            titleLabel.position = CGPoint(x: 24, y: currentY)
            addChild(titleLabel)
            currentY -= 20

            let descLabel = SKLabelNode(fontNamed: "Menlo-Regular")
            descLabel.text = achievement.description
            descLabel.fontSize = 12
            descLabel.fontColor = SKColor(white: 0.6, alpha: 1)
            descLabel.horizontalAlignmentMode = .left
            descLabel.position = CGPoint(x: 40, y: currentY)
            addChild(descLabel)
            currentY -= 30
        }
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        if atPoint(touch.location(in: self)).name == "back" {
            onBackTapped?()
        }
    }
}
