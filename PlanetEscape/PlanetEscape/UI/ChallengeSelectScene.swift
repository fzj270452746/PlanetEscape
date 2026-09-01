//
//  ChallengeSelectScene.swift
//  PlanetEscape
//
//  Created by Hades on 2026/7/31.
//

import Foundation
import SpriteKit
import UIKit

/// Challenge Mode 选择界面（文档 9.3）：列出三种预设规则
/// （30 秒内逃脱 / 禁止碰撞 / 只允许旋转 5 次），点击后进入对应挑战。
final class ChallengeSelectScene: SKScene {
    var onChallengeSelected: ((ChallengeRuleSet) -> Void)?
    var onBackTapped: (() -> Void)?

    private struct Entry {
        let name: String
        let subtitle: String
        let ruleSet: ChallengeRuleSet
    }

    private let entries: [Entry] = [
        Entry(name: "SPEED RUN", subtitle: "Escape within 30 seconds", ruleSet: .speedRun),
        Entry(name: "NO HIT RUN", subtitle: "Zero hazard collisions allowed", ruleSet: .noHitRun),
        Entry(name: "FIVE SPINS", subtitle: "Only 5 rotations permitted", ruleSet: .limitedRotation),
    ]

    /// 顶部安全区高度（灵动岛/状态栏），做法与 GameplayHUDScene.topInset 一致，
    /// 避免 "< BACK" 贴顶画在状态栏下面重叠。
    private let topInset: CGFloat

    init(size: CGSize, topInset: CGFloat = 0) {
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
        header.text = "CHALLENGE MODE"
        header.fontSize = 22
        header.fontColor = .white
        header.position = CGPoint(x: size.width / 2, y: size.height * 0.7 - topInset)
        addChild(header)

        let startY = size.height * 0.5
        let spacing: CGFloat = 70
        for (index, entry) in entries.enumerated() {
            let titleLabel = SKLabelNode(fontNamed: "Menlo-Bold")
            titleLabel.text = entry.name
            titleLabel.fontSize = 20
            titleLabel.fontColor = .white
            titleLabel.name = "challenge_\(index)"
            titleLabel.position = CGPoint(x: size.width / 2, y: startY - CGFloat(index) * spacing)
            addChild(titleLabel)

            let subtitleLabel = SKLabelNode(fontNamed: "Menlo-Regular")
            subtitleLabel.text = entry.subtitle
            subtitleLabel.fontSize = 13
            subtitleLabel.fontColor = SKColor(white: 0.65, alpha: 1)
            subtitleLabel.position = CGPoint(x: size.width / 2, y: startY - CGFloat(index) * spacing - 22)
            addChild(subtitleLabel)
        }
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        guard let name = atPoint(touch.location(in: self)).name else { return }
        if name == "back" {
            onBackTapped?()
            return
        }
        guard name.hasPrefix("challenge_"), let index = Int(name.dropFirst("challenge_".count)), entries.indices.contains(index) else { return }
        onChallengeSelected?(entries[index].ruleSet)
    }
}

