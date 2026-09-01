//
//  GameplayHUDScene.swift
//  PlanetEscape
//
//  Created by Hades on 2026/7/31.
//

import Foundation
import SpriteKit
import UIKit

/// 游玩中的 HUD 覆盖层（文档第 13 节）：顶部 Energy%/Distance，
/// 底部 Rotation Indicator。作为独立 SKScene 叠加在 SCNView 之上，
/// 通过 CosmicSignalRelay 订阅事件更新显示，不直接引用 WorldRuntime 内部类型。
final class GameplayHUDScene: SKScene {
    var onPauseTapped: (() -> Void)?

    private let energyLabel = SKLabelNode(fontNamed: "Menlo-Bold")
    private let distanceLabel = SKLabelNode(fontNamed: "Menlo-Bold")
    private let levelLabel = SKLabelNode(fontNamed: "Menlo-Bold")
    private let rotationIndicator = SKShapeNode(circleOfRadius: 18)
    private let pauseButton = SKLabelNode(fontNamed: "Menlo-Bold")
    private let dangerWarningLabel = SKLabelNode(fontNamed: "Menlo-Bold")
    private var subscription: SignalSubscription?

    private var currentDistance: Double = 0
    private var maxEnergy: Int = 100
    private var currentEnergy: Int = 100
    /// 顶部安全区高度（灵动岛/状态栏），由 AppFlowCoordinator 在创建后通过
    /// applyTopInset 传入 view.safeAreaInsets.top。SKScene 的 size 只是 SCNView
    /// 的 bounds 尺寸，不包含安全区信息，如果不加这个偏移，ENERGY/DISTANCE 这些
    /// 贴顶文字会直接画在状态栏/灵动岛下面，与系统时间等文字重叠。
    private var topInset: CGFloat = 0

    override init(size: CGSize) {
        super.init(size: size)
        scaleMode = .resizeFill
        backgroundColor = .clear
        anchorPoint = CGPoint(x: 0, y: 1)
        buildLayout()
        layoutForCurrentSize()
        subscription = CosmicSignalRelay.current.subscribe { [weak self] event in
            self?.handle(event)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func buildLayout() {
        energyLabel.fontSize = 18
        energyLabel.fontColor = .white
        energyLabel.horizontalAlignmentMode = .left
        energyLabel.position = CGPoint(x: 24, y: -40)
        addChild(energyLabel)

        distanceLabel.fontSize = 18
        distanceLabel.fontColor = .white
        distanceLabel.horizontalAlignmentMode = .left
        distanceLabel.position = CGPoint(x: 24, y: -68)
        addChild(distanceLabel)

        levelLabel.fontSize = 13
        levelLabel.fontColor = SKColor(white: 0.7, alpha: 1)
        levelLabel.horizontalAlignmentMode = .left
        levelLabel.position = CGPoint(x: 24, y: -90)
        addChild(levelLabel)

        rotationIndicator.strokeColor = SKColor(white: 1, alpha: 0.8)
        rotationIndicator.lineWidth = 2
        rotationIndicator.fillColor = SKColor(white: 1, alpha: 0.15)
        addChild(rotationIndicator)

        pauseButton.text = "II"
        pauseButton.fontSize = 18
        pauseButton.fontColor = .white
        pauseButton.name = "pause"
        addChild(pauseButton)

        dangerWarningLabel.text = "⚠ DANGER AHEAD"
        dangerWarningLabel.fontSize = 16
        dangerWarningLabel.fontColor = SKColor(red: 1.0, green: 0.3, blue: 0.25, alpha: 1)
        dangerWarningLabel.alpha = 0
        addChild(dangerWarningLabel)

        updateLabels()
    }

    override func didChangeSize(_ oldSize: CGSize) {
        super.didChangeSize(oldSize)
        layoutForCurrentSize()
    }

    /// 由 AppFlowCoordinator 在创建 HUD 后调用一次，把 view.safeAreaInsets.top
    /// 传进来并重新布局，避开灵动岛/状态栏区域。
    func applyTopInset(_ inset: CGFloat) {
        topInset = inset
        layoutForCurrentSize()
    }

    /// init(size:) 一次性传入正确尺寸创建后 size 不会再变，didChangeSize 不会触发，
    /// 必须在 init 里主动调用一次，否则节点全部停留在默认位置 (0,0)。
    private func layoutForCurrentSize() {
        let top = -topInset
        energyLabel.position = CGPoint(x: 24, y: top - 40)
        distanceLabel.position = CGPoint(x: 24, y: top - 68)
        levelLabel.position = CGPoint(x: 24, y: top - 90)
        rotationIndicator.position = CGPoint(x: size.width / 2, y: -size.height + 90)
        pauseButton.position = CGPoint(x: size.width - 32, y: top - 40)
        dangerWarningLabel.position = CGPoint(x: size.width / 2, y: -120)
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        if atPoint(touch.location(in: self)).name == "pause" {
            onPauseTapped?()
        }
    }

    private func updateLabels() {
        let energyPercent = maxEnergy > 0 ? Int((Double(currentEnergy) / Double(maxEnergy)) * 100) : 0
        energyLabel.text = "ENERGY \(energyPercent)%"
        distanceLabel.text = String(format: "DISTANCE %.0fm", currentDistance)
    }

    /// 由 AppFlowCoordinator 通过 runtime.setExternalFrameObserver 挂载，
    /// 每帧从 WorldRuntime.renderer(_:updateAtTime:) 内部直接调用——那是
    /// SceneKit 渲染队列（后台线程），不是主线程。这里改的是 SKLabelNode.text，
    /// SpriteKit 节点必须在主线程修改，否则从进入关卡起每帧都在后台并发写，
    /// 与 SpriteKit 自己的渲染遍历产生数据竞争，正是"玩一会儿后画面持续抖动"的根源。
    func syncEnergy(current: Double, max: Double) {
        DispatchQueue.main.async { [weak self] in
            self?.currentEnergy = Int(current)
            self?.maxEnergy = Int(max)
            self?.updateLabels()
        }
    }

    /// 由 AppFlowCoordinator 在关卡加载完成后调用，显示章节与关卡编号，
    /// 帮助玩家在长距离奔跑中确认自己当前处于哪个阶段。
    func showLevelInfo(levelNumber: Int, chapterTitle: String?) {
        if let chapterTitle = chapterTitle {
            levelLabel.text = "LEVEL \(levelNumber) · \(chapterTitle.uppercased())"
        } else {
            levelLabel.text = "LEVEL \(levelNumber)"
        }
    }

    /// .explorerAdvanced 由 ExplorerMotionUnit.advance 每帧发布，
    /// 而这条调用链的起点是 WorldRuntime.renderer(_:updateAtTime:)——SceneKit
    /// 渲染队列（后台线程）。.rotationRequested 在长按缓慢观察期间同样由
    /// InputGestureBridge.advance（每帧调用）在同一后台线程发布。
    /// SKLabelNode.text / SKNode.run(...) 都是 SpriteKit API，必须在主线程
    /// 修改，否则每秒 60 次的并发写入会和 SpriteKit 自身的渲染遍历打架，
    /// 表现为"玩一会儿后画面开始持续抖动"——这正是本次要修的问题。
    private func handle(_ event: GameEvent) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            switch event {
            case .explorerAdvanced(_, _, let distanceTravelled):
                self.currentDistance = distanceTravelled
                self.updateLabels()
            case .rotationRequested(let command):
                let normalizedAngle = CGFloat(command.angleRadians)
                self.rotationIndicator.zRotation = normalizedAngle
            case .dangerAheadStateChanged(let isDangerous):
                self.dangerWarningLabel.run(.fadeAlpha(to: isDangerous ? 1.0 : 0.0, duration: 0.2))
            default:
                break
            }
        }
    }
}
