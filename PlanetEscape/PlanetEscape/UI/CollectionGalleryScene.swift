//
//  CollectionGalleryScene.swift
//  PlanetEscape
//
//  Created by Hades on 2026/7/31.
//

import Foundation
import SpriteKit
import UIKit

/// Collection 界面（文档第 13 节）：展示已解锁 / 待解锁的皮肤、星球配色、拖尾效果，
/// 且已解锁的项可以点击装备（写回 UserProgressStore.equippedSkinID/equippedTrailID）。
/// 数据来自 UnlockRegistry，按分类分栏展示。
final class CollectionGalleryScene: SKScene {
    var onBackTapped: (() -> Void)?
    var onSkinEquipped: ((String) -> Void)?
    var onTrailEquipped: ((String) -> Void)?
    var onColorwayEquipped: ((String) -> Void)?
    var onAchievementsTapped: (() -> Void)?

    private let unlockRegistry: UnlockRegistry
    private let progressStore: UserProgressStore
    /// 顶部安全区高度（灵动岛/状态栏），做法与 GameplayHUDScene.topInset 一致，
    /// 避免 "< BACK" 贴顶画在状态栏下面重叠。
    private let topInset: CGFloat

    init(size: CGSize, unlockRegistry: UnlockRegistry, progressStore: UserProgressStore, topInset: CGFloat = 0) {
        self.unlockRegistry = unlockRegistry
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

        let achievementsLabel = SKLabelNode(fontNamed: "Menlo-Bold")
        achievementsLabel.text = "ACHIEVEMENTS >"
        achievementsLabel.fontSize = 16
        achievementsLabel.fontColor = .white
        achievementsLabel.name = "achievements"
        achievementsLabel.horizontalAlignmentMode = .right
        achievementsLabel.position = CGPoint(x: size.width - 24, y: size.height - 40 - topInset)
        addChild(achievementsLabel)

        let categories: [(String, UnlockableCategory)] = [
            ("BOT SKINS", .botSkin),
            ("PLANET COLORWAYS", .planetColorway),
            ("TRAIL EFFECTS", .trailEffect),
        ]

        var currentY = size.height - 100 - topInset
        for (title, category) in categories {
            let header = SKLabelNode(fontNamed: "Menlo-Bold")
            header.text = title
            header.fontSize = 18
            header.fontColor = SKColor(white: 0.9, alpha: 1)
            header.horizontalAlignmentMode = .left
            header.position = CGPoint(x: 24, y: currentY)
            addChild(header)
            currentY -= 30

            for item in unlockRegistry.allItems(in: category) {
                let unlocked = unlockRegistry.isUnlocked(item)
                let isEquipped = isCurrentlyEquipped(item)
                let itemLabel = SKLabelNode(fontNamed: "Menlo-Regular")
                let suffix = isEquipped ? " [EQUIPPED]" : (unlocked ? "" : " (locked)")
                itemLabel.text = item.displayName + suffix
                itemLabel.fontSize = 14
                itemLabel.fontColor = unlocked ? (isEquipped ? SKColor(red: 0.3, green: 0.9, blue: 0.5, alpha: 1) : .white) : SKColor(white: 0.4, alpha: 1)
                itemLabel.horizontalAlignmentMode = .left
                itemLabel.name = unlocked ? "equip_\(item.id)" : nil
                itemLabel.position = CGPoint(x: 40, y: currentY)
                addChild(itemLabel)
                currentY -= 22
            }
            currentY -= 16
        }
    }

    private func isCurrentlyEquipped(_ item: UnlockableItem) -> Bool {
        switch item.category {
        case .botSkin: return progressStore.snapshot.equippedSkinID == item.id
        case .trailEffect: return progressStore.snapshot.equippedTrailID == item.id
        case .planetColorway: return progressStore.snapshot.equippedColorwayID == item.id
        }
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        guard let name = atPoint(touch.location(in: self)).name else { return }
        if name == "back" {
            onBackTapped?()
            return
        }
        if name == "achievements" {
            onAchievementsTapped?()
            return
        }
        guard name.hasPrefix("equip_") else { return }
        let itemID = String(name.dropFirst("equip_".count))
        guard let item = UnlockRegistry.allItems.first(where: { $0.id == itemID }) else { return }
        switch item.category {
        case .botSkin:
            progressStore.equipSkin(itemID)
            onSkinEquipped?(itemID)
        case .trailEffect:
            progressStore.equipTrail(itemID)
            onTrailEquipped?(itemID)
        case .planetColorway:
            progressStore.equipColorway(itemID)
            onColorwayEquipped?(itemID)
        }
        removeAllChildren()
        buildLayout()
    }
}
