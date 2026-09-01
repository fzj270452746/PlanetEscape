//
//  PlanetSelectGrid.swift
//  PlanetEscape
//
//  Created by Hades on 2026/7/31.
//

import Foundation
import SpriteKit
import UIKit

/// 关卡选择界面：按 ChapterCatalog 分章节展示 120 关（每章节标题 + 10 列关卡格），
/// 未解锁的关卡显示为灰色不可点击。整体内容放进一个可垂直拖动的容器节点，
/// 因为 6 章节 * 20 关的总高度会超出单屏，需要基本的滚动交互。
final class PlanetSelectGrid: SKScene {
    var onLevelSelected: ((Int) -> Void)?
    var onBackTapped: (() -> Void)?

    private let progressStore: UserProgressStore
    private let blueprints: [LevelBlueprint]
    private let contentNode = SKNode()

    private var dragStartY: CGFloat?
    private var contentStartY: CGFloat = 0
    private var contentHeight: CGFloat = 0
    /// 顶部安全区高度（灵动岛/状态栏）。这个场景用固定的 size.height 定位
    /// "< BACK"，不考虑安全区会让按钮画在状态栏下面重叠，做法与
    /// GameplayHUDScene.topInset 一致，由 AppFlowCoordinator 传入
    /// view.safeAreaInsets.top。
    private let topInset: CGFloat

    init(size: CGSize, progressStore: UserProgressStore, topInset: CGFloat = 0) {
        self.progressStore = progressStore
        self.blueprints = LevelGenerator().generateAllBlueprints()
        self.topInset = topInset
        super.init(size: size)
        scaleMode = .resizeFill
        backgroundColor = SKColor(red: 0.12, green: 0.12, blue: 0.24, alpha: 1)
        addChild(contentNode)
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
        backLabel.zPosition = 10
        addChild(backLabel)

        buildChapterSections()
    }

    private func buildChapterSections() {
        let columns = 10
        let cellSize: CGFloat = 32
        let gridWidth = CGFloat(columns) * cellSize
        let originX = (size.width - gridWidth) / 2

        var currentY: CGFloat = size.height - 90 - topInset

        for chapter in ChapterCatalog.all {
            let header = SKLabelNode(fontNamed: "Menlo-Bold")
            header.text = "CH.\(chapter.number) \(chapter.title.uppercased())"
            header.fontSize = 15
            header.fontColor = SKColor(white: 0.85, alpha: 1)
            header.horizontalAlignmentMode = .left
            header.position = CGPoint(x: originX, y: currentY)
            contentNode.addChild(header)
            currentY -= 26

            let levelsInChapter = blueprints.filter { chapter.levelRange.contains($0.levelNumber) }
            for blueprint in levelsInChapter {
                let indexInChapter = blueprint.levelNumber - chapter.levelRange.lowerBound
                let row = indexInChapter / columns
                let column = indexInChapter % columns

                let unlocked = progressStore.isLevelUnlocked(blueprint.levelNumber)
                let label = SKLabelNode(fontNamed: "Menlo-Bold")
                label.text = "\(blueprint.levelNumber)"
                label.fontSize = 13
                label.fontColor = unlocked ? .white : SKColor(white: 0.35, alpha: 1)
                label.name = unlocked ? "level_\(blueprint.levelNumber)" : nil
                label.position = CGPoint(
                    x: originX + CGFloat(column) * cellSize + cellSize / 2,
                    y: currentY - CGFloat(row) * cellSize
                )
                contentNode.addChild(label)
            }

            let rowCount = (levelsInChapter.count + columns - 1) / columns
            currentY -= CGFloat(rowCount) * cellSize + 20
        }

        contentHeight = (size.height - 90 - topInset) - currentY
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        dragStartY = touch.location(in: self).y
        contentStartY = contentNode.position.y
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first, let startY = dragStartY else { return }
        let deltaY = touch.location(in: self).y - startY
        let maxOffset = max(0, contentHeight - size.height * 0.7)
        let newY = min(max(contentStartY + deltaY, 0), maxOffset)
        contentNode.position.y = newY
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first, let startY = dragStartY else { return }
        let location = touch.location(in: self)
        let moved = abs(location.y - startY)
        dragStartY = nil

        guard moved < 6 else { return }

        if atPoint(location).name == "back" {
            onBackTapped?()
            return
        }

        let localLocation = touch.location(in: contentNode)
        let node = contentNode.atPoint(localLocation)
        if let name = node.name, name.hasPrefix("level_"), let level = Int(name.dropFirst("level_".count)) {
            onLevelSelected?(level)
        }
    }
}
