//
//  TutorialHintOverlay.swift
//  PlanetEscape
//
//  Created by Hades on 2026/7/31.
//

import Foundation
import SpriteKit
import UIKit

/// 首次进入 Chapter 1 时显示的手势教学提示（文档 6.1 操作方式表）。
/// 只在玩家从未通过任何关卡时显示一次，通过 UserProgressStore.highestUnlockedLevel == 1
/// 判断"是新手"，不引入额外的持久化字段来记录"是否看过教程"，保持存档结构简单。
final class TutorialHintOverlay: SKScene {
    var onDismissTapped: (() -> Void)?

    override init(size: CGSize) {
        super.init(size: size)
        scaleMode = .resizeFill
        backgroundColor = SKColor(white: 0, alpha: 0.6)
        buildLayout()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func buildLayout() {
        let lines = [
            "SWIPE LEFT / RIGHT",
            "Rotate the planet",
            "",
            "DOUBLE TAP",
            "Quick rotation burst",
            "",
            "LONG PRESS",
            "Slow observation spin",
            "",
            "TAP TO BEGIN",
        ]

        var currentY = size.height * 0.7
        for line in lines {
            let label = SKLabelNode(fontNamed: line.isEmpty ? "Menlo-Regular" : "Menlo-Bold")
            label.text = line
            label.fontSize = line == "TAP TO BEGIN" ? 18 : 16
            label.fontColor = line == "TAP TO BEGIN" ? SKColor(red: 0.3, green: 0.9, blue: 0.5, alpha: 1) : .white
            label.position = CGPoint(x: size.width / 2, y: currentY)
            addChild(label)
            currentY -= 32
        }
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        onDismissTapped?()
    }
}
