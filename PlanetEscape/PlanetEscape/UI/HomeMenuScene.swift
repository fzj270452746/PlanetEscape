//
//  HomeMenuScene.swift
//  PlanetEscape
//
//  Created by Hades on 2026/7/31.
//

import Foundation
import SpriteKit
import UIKit

/// 主菜单（文档第 13 节 Home）：TINY PLANET ESCAPE 标题 + PLAY/PLANETS/COLLECTION/SETTINGS。
/// 全部英文文案，纯 SpriteKit 布局，不依赖任何图片素材。
final class HomeMenuScene: SKScene {
    var onPlayTapped: (() -> Void)?
    var onEndlessTapped: (() -> Void)?
    var onChallengeTapped: (() -> Void)?
    var onPlanetsTapped: (() -> Void)?
    var onCollectionTapped: (() -> Void)?
    var onSettingsTapped: (() -> Void)?
    var onProfileTapped: (() -> Void)?

    private let titleLabel = SKLabelNode(fontNamed: "Menlo-Bold")
    private let subtitleLabel = SKLabelNode(fontNamed: "Menlo-Bold")
    private let profileButton = SKLabelNode(fontNamed: "Menlo-Bold")
    private var menuButtons: [SKLabelNode] = []
    /// 顶部安全区高度（灵动岛/状态栏），做法与 GameplayHUDScene.topInset 一致，
    /// 避免 PROFILE 按钮贴顶画在状态栏下面重叠。
    private let topInset: CGFloat

    init(size: CGSize, topInset: CGFloat = 0) {
        self.topInset = topInset
        super.init(size: size)
        scaleMode = .resizeFill
        backgroundColor = SKColor(red: 0.12, green: 0.12, blue: 0.24, alpha: 1)
        buildLayout()
        layoutForCurrentSize()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func buildLayout() {
        titleLabel.text = "TINY PLANET ESCAPE"
        titleLabel.fontSize = 30
        titleLabel.fontColor = .white
        addChild(titleLabel)

        subtitleLabel.text = "Rotate the world. Guide the bot."
        subtitleLabel.fontSize = 14
        subtitleLabel.fontColor = SKColor(white: 0.7, alpha: 1)
        addChild(subtitleLabel)

        let entries = ["PLAY", "ENDLESS", "CHALLENGE", "PLANETS", "COLLECTION", "SETTINGS"]
        for entry in entries {
            let label = SKLabelNode(fontNamed: "Menlo-Bold")
            label.text = entry
            label.fontSize = 22
            label.fontColor = .white
            label.name = entry.lowercased()
            addChild(label)
            menuButtons.append(label)
        }

        profileButton.text = "PROFILE"
        profileButton.fontSize = 14
        profileButton.fontColor = SKColor(white: 0.75, alpha: 1)
        profileButton.name = "profile"
        addChild(profileButton)
    }

    override func didChangeSize(_ oldSize: CGSize) {
        super.didChangeSize(oldSize)
        layoutForCurrentSize()
    }

    /// didChangeSize 只在 size 属性被后续修改时才触发——但这些场景都是用
    /// init(size:) 一次性传入正确尺寸创建的，size 从未再变化，所以必须在
    /// init 里主动调用一次，否则所有节点会停留在默认位置 (0,0) 叠在左下角。
    private func layoutForCurrentSize() {
        let centerX = size.width / 2
        titleLabel.position = CGPoint(x: centerX, y: size.height * 0.7)
        subtitleLabel.position = CGPoint(x: centerX, y: size.height * 0.7 - 32)

        let startY = size.height * 0.45
        let spacing: CGFloat = 52
        for (index, button) in menuButtons.enumerated() {
            button.position = CGPoint(x: centerX, y: startY - CGFloat(index) * spacing)
        }

        profileButton.position = CGPoint(x: size.width - 60, y: size.height - 40 - topInset)
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let node = atPoint(touch.location(in: self))
        switch node.name {
        case "play": onPlayTapped?()
        case "endless": onEndlessTapped?()
        case "challenge": onChallengeTapped?()
        case "planets": onPlanetsTapped?()
        case "collection": onCollectionTapped?()
        case "settings": onSettingsTapped?()
        case "profile": onProfileTapped?()
        default: break
        }
    }
}
