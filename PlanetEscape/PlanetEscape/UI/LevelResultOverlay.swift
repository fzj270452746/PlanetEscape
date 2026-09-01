//
//  LevelResultOverlay.swift
//  PlanetEscape
//
//  Created by Hades on 2026/7/31.
//

import Foundation
import SpriteKit
import UIKit

/// 通关/失败结算界面（文档第 13 节 Result）。以 SKScene 形式覆盖在 HUD 之上，
/// 展示用时/收集数量，并提供 Retry / Next / Home 三个按钮区域（用简单的
/// SKLabelNode 区块模拟按钮点击区，不引入完整 UIKit 按钮体系，保持 SpriteKit 覆盖层的一致性）。
final class LevelResultOverlay: SKScene {
    var onRetryTapped: (() -> Void)?
    var onNextTapped: (() -> Void)?
    var onHomeTapped: (() -> Void)?

    private let titleLabel = SKLabelNode(fontNamed: "Menlo-Bold")
    private let statsLabel = SKLabelNode(fontNamed: "Menlo-Regular")
    private let retryButton = SKLabelNode(fontNamed: "Menlo-Bold")
    private let nextButton = SKLabelNode(fontNamed: "Menlo-Bold")
    private let homeButton = SKLabelNode(fontNamed: "Menlo-Bold")

    override init(size: CGSize) {
        super.init(size: size)
        scaleMode = .resizeFill
        backgroundColor = SKColor(white: 0, alpha: 0.72)
        buildLayout()
        layoutForCurrentSize()
        isHidden = true
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func buildLayout() {
        titleLabel.fontSize = 32
        titleLabel.fontColor = .white
        addChild(titleLabel)

        statsLabel.fontSize = 18
        statsLabel.fontColor = SKColor(white: 0.85, alpha: 1)
        addChild(statsLabel)

        retryButton.text = "RETRY"
        retryButton.fontSize = 20
        retryButton.fontColor = .white
        retryButton.name = "retry"
        addChild(retryButton)

        nextButton.text = "NEXT"
        nextButton.fontSize = 20
        nextButton.fontColor = .white
        nextButton.name = "next"
        addChild(nextButton)

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
        titleLabel.position = CGPoint(x: center.x, y: center.y + 80)
        statsLabel.position = CGPoint(x: center.x, y: center.y + 40)
        retryButton.position = CGPoint(x: center.x - 100, y: center.y - 40)
        nextButton.position = CGPoint(x: center.x, y: center.y - 40)
        homeButton.position = CGPoint(x: center.x + 100, y: center.y - 40)
    }

    func showSuccess(levelNumber: Int, elapsedSeconds: TimeInterval, energyGained: Int) {
        titleLabel.text = "LEVEL \(levelNumber) COMPLETE"
        statsLabel.text = String(format: "TIME %.1fs   ENERGY +%d", elapsedSeconds, energyGained)
        nextButton.alpha = 1
        isHidden = false
    }

    func showFailure(levelNumber: Int, reason: StumbleReason) {
        titleLabel.text = "LEVEL \(levelNumber) FAILED"
        statsLabel.text = LevelResultOverlay.describe(reason: reason)
        nextButton.alpha = 0.3
        isHidden = false
    }

    func dismiss() {
        isHidden = true
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let node = atPoint(location)
        switch node.name {
        case "retry": onRetryTapped?()
        case "next": onNextTapped?()
        case "home": onHomeTapped?()
        default: break
        }
    }

    private static func describe(reason: StumbleReason) -> String {
        switch reason {
        case .hazardCollision: return "Hit a hazard"
        case .blackHoleConsumed: return "Pulled into a black hole"
        case .energyExhausted: return "Energy exhausted"
        case .timeExpired: return "Time expired"
        }
    }
}
