//
//  InputGestureBridge.swift
//  PlanetEscape
//
//  Created by Hades on 2026/7/31.
//

import Foundation
import UIKit

/// 把 SwipeRotationRecognizer 挂接到具体的 UIView 上，并持有 RotationGestureInterpreter，
/// 是 ViewController 与 Input 模块之间唯一的接触点，ViewController 本身不关心手势细节。
final class InputGestureBridge {
    let recognizer = SwipeRotationRecognizer()
    private(set) var interpreter: RotationGestureInterpreter?

    func bind(to view: UIView, driver: PlanetRotationDriver) {
        recognizer.attach(to: view)
        interpreter = RotationGestureInterpreter(driver: driver, recognizer: recognizer)
    }

    func advance(deltaTime: TimeInterval) {
        interpreter?.tickLongPress(deltaTime: deltaTime)
    }

    /// 应用玩家在 Settings 界面调整的旋转灵敏度（GameSettingsStore.rotationSensitivity），
    /// 以基准系数为中心缩放，而不是直接覆盖，保持默认手感的调优空间。
    func applySensitivity(_ sensitivity: Double) {
        let baseDragFactor = 0.006
        let baseCreepSpeed = 0.35
        interpreter?.dragToAngleFactor = baseDragFactor * sensitivity
        interpreter?.longPressCreepSpeed = baseCreepSpeed * sensitivity
    }
}
