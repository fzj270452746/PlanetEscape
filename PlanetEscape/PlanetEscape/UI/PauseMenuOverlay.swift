//
//  PauseMenuOverlay.swift
//  PlanetEscape
//
//  Created by Hades on 2026/7/31.
//

import Foundation
import SpriteKit
import UIKit

/// 游玩中暂停菜单：暂停角色前进、暂停星球旋转输入响应、暂停音频引擎，
/// 提供 Resume / Restart / Home 三个选项。与 LevelResultOverlay 分开——
/// 暂停是玩家主动触发的临时中断，结算是关卡自然结束后的终态展示。
final class PauseMenuOverlay: SKScene {
    var onResumeTapped: (() -> Void)?
    var onRestartTapped: (() -> Void)?
    var onHomeTapped: (() -> Void)?

    private let titleLabel = SKLabelNode(fontNamed: "Menlo-Bold")
    private let resumeButton = SKLabelNode(fontNamed: "Menlo-Bold")
    private let restartButton = SKLabelNode(fontNamed: "Menlo-Bold")
    private let homeButton = SKLabelNode(fontNamed: "Menlo-Bold")

    override init(size: CGSize) {
        super.init(size: size)
        scaleMode = .resizeFill
        backgroundColor = SKColor(white: 0, alpha: 0.75)
        buildLayout()
        layoutForCurrentSize()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func buildLayout() {
        titleLabel.text = "PAUSED"
        titleLabel.fontSize = 28
        titleLabel.fontColor = .white
        addChild(titleLabel)

        resumeButton.text = "RESUME"
        resumeButton.fontSize = 20
        resumeButton.fontColor = .white
        resumeButton.name = "resume"
        addChild(resumeButton)

        restartButton.text = "RESTART"
        restartButton.fontSize = 20
        restartButton.fontColor = .white
        restartButton.name = "restart"
        addChild(restartButton)

        homeButton.text = "HOME"
        homeButton.fontSize = 20
        homeButton.fontColor = .white
        homeButton.name = "home"
        addChild(homeButton)
    }

    override func didChangeSize(_ oldSize: CGSize) {
        super.didChangeSize(oldSize)
        layoutForCurrentSize()
    }

    /// init(size:) 一次性传入正确尺寸创建后 size 不会再变，didChangeSize 不会触发，
    /// 必须在 init 里主动调用一次，否则节点全部停留在默认位置 (0,0)。
    private func layoutForCurrentSize() {
        let center = CGPoint(x: size.width / 2, y: size.height / 2)
        titleLabel.position = CGPoint(x: center.x, y: center.y + 70)
        resumeButton.position = CGPoint(x: center.x, y: center.y + 10)
        restartButton.position = CGPoint(x: center.x, y: center.y - 30)
        homeButton.position = CGPoint(x: center.x, y: center.y - 70)
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        switch atPoint(touch.location(in: self)).name {
        case "resume": onResumeTapped?()
        case "restart": onRestartTapped?()
        case "home": onHomeTapped?()
        default: break
        }
    }
}
