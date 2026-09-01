//
//  SettingsPanel.swift
//  PlanetEscape
//
//  Created by Hades on 2026/7/31.
//

import Foundation
import SpriteKit
import UIKit

/// Settings 界面：音效/音乐/震动开关的简单切换列表，以及旋转灵敏度的 +/- 调节
/// （SpriteKit 没有原生滑杆控件，用一对按钮步进调整比引入额外依赖更简单）。
/// 直接读写 GameSettingsStore，灵敏度变更通过 onSensitivityChanged 通知外部实时生效。
final class SettingsPanel: SKScene {
    var onBackTapped: (() -> Void)?
    var onSensitivityChanged: ((Double) -> Void)?

    private let settingsStore: GameSettingsStore
    private var soundLabel: SKLabelNode!
    private var musicLabel: SKLabelNode!
    private var hapticLabel: SKLabelNode!
    private var sensitivityLabel: SKLabelNode!
    private var decreaseButton: SKLabelNode!
    private var increaseButton: SKLabelNode!
    /// 顶部安全区高度（灵动岛/状态栏），做法与 GameplayHUDScene.topInset 一致，
    /// 避免 "< BACK" 贴顶画在状态栏下面重叠。
    private let topInset: CGFloat

    init(size: CGSize, settingsStore: GameSettingsStore, topInset: CGFloat = 0) {
        self.settingsStore = settingsStore
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

        soundLabel = makeToggleLabel(name: "toggle_sound", y: size.height - 100 - topInset)
        musicLabel = makeToggleLabel(name: "toggle_music", y: size.height - 140 - topInset)
        hapticLabel = makeToggleLabel(name: "toggle_haptic", y: size.height - 180 - topInset)

        sensitivityLabel = makeToggleLabel(name: "", y: size.height - 220 - topInset)

        decreaseButton = SKLabelNode(fontNamed: "Menlo-Bold")
        decreaseButton.fontSize = 16
        decreaseButton.fontColor = .white
        decreaseButton.text = "[ - ]"
        decreaseButton.name = "sensitivity_down"
        decreaseButton.horizontalAlignmentMode = .left
        decreaseButton.position = CGPoint(x: 24, y: size.height - 250 - topInset)
        addChild(decreaseButton)

        increaseButton = SKLabelNode(fontNamed: "Menlo-Bold")
        increaseButton.fontSize = 16
        increaseButton.fontColor = .white
        increaseButton.text = "[ + ]"
        increaseButton.name = "sensitivity_up"
        increaseButton.horizontalAlignmentMode = .left
        increaseButton.position = CGPoint(x: 90, y: size.height - 250 - topInset)
        addChild(increaseButton)

        refreshLabels()
    }

    private func makeToggleLabel(name: String, y: CGFloat) -> SKLabelNode {
        let label = SKLabelNode(fontNamed: "Menlo-Regular")
        label.fontSize = 16
        label.fontColor = .white
        label.name = name
        label.horizontalAlignmentMode = .left
        label.position = CGPoint(x: 24, y: y)
        addChild(label)
        return label
    }

    private func refreshLabels() {
        let snapshot = settingsStore.snapshot
        soundLabel.text = "Sound Effects: \(snapshot.soundEffectsEnabled ? "ON" : "OFF")"
        musicLabel.text = "Music: \(snapshot.musicEnabled ? "ON" : "OFF")"
        hapticLabel.text = "Haptics: \(snapshot.hapticFeedbackEnabled ? "ON" : "OFF")"
        sensitivityLabel.text = String(format: "Rotation Sensitivity: %.1fx", snapshot.rotationSensitivity)
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        switch atPoint(touch.location(in: self)).name {
        case "back":
            onBackTapped?()
        case "toggle_sound":
            settingsStore.update { $0.soundEffectsEnabled.toggle() }
            refreshLabels()
        case "toggle_music":
            settingsStore.update { $0.musicEnabled.toggle() }
            refreshLabels()
        case "toggle_haptic":
            settingsStore.update { $0.hapticFeedbackEnabled.toggle() }
            refreshLabels()
        case "sensitivity_down":
            adjustSensitivity(by: -0.2)
        case "sensitivity_up":
            adjustSensitivity(by: 0.2)
        default:
            break
        }
    }

    private func adjustSensitivity(by delta: Double) {
        settingsStore.update { snapshot in
            snapshot.rotationSensitivity = min(max(snapshot.rotationSensitivity + delta, 0.4), 2.0)
        }
        refreshLabels()
        onSensitivityChanged?(settingsStore.snapshot.rotationSensitivity)
    }
}
