//
//  RotationGestureInterpreter.swift
//  PlanetEscape
//
//  Created by Hades on 2026/7/31.
//

import Foundation
import UIKit
import SceneKit

/// 把 SwipeRotationRecognizer 产出的原始手势样本，转换成 PlanetRotationCommand
/// 并推给 PlanetRotationDriver。承担"手势语义翻译"这一个职责，
/// 不直接持有场景节点，只依赖注入的 driver。
final class RotationGestureInterpreter {
    private let driver: PlanetRotationDriver
    private let recognizer: SwipeRotationRecognizer

    /// 屏幕横向像素位移转换为旋转弧度的系数。
    var dragToAngleFactor: Double = 0.006
    /// 双击快速旋转的固定角度（弧度），约 60 度。
    var doubleTapAngle: Double = Double.pi / 3
    var doubleTapDuration: TimeInterval = 0.25
    /// 长按期间的“慢速观察”自动缓慢旋转速度（弧度/秒），便于玩家看清星球背面。
    var longPressCreepSpeed: Double = 0.35

    /// 由 WorldRuntime 注入：查询角色当前坐标处的旋转灵敏度放大系数
    /// （例如站在 IceSlickPatch 冰面滑行区内时，同样的滑动手势会转出更大角度）。
    var sensitivityMultiplierProvider: (() -> Double)?

    private var isLongPressing = false
    private var lastPanTranslationX: CGFloat = 0

    init(driver: PlanetRotationDriver, recognizer: SwipeRotationRecognizer) {
        self.driver = driver
        self.recognizer = recognizer
        recognizer.onSample = { [weak self] sample in
            self?.handle(sample)
        }
    }

    private func handle(_ sample: SwipeRotationRecognizer.GestureSample) {
        switch sample {
        case .pan(let translationX, let velocityX, let state):
            handlePan(translationX: translationX, velocityX: velocityX, state: state)
        case .doubleTap:
            handleDoubleTap()
        case .longPressBegan:
            isLongPressing = true
        case .longPressEnded:
            isLongPressing = false
        }
    }

    private func handlePan(translationX: CGFloat, velocityX: CGFloat, state: UIGestureRecognizer.State) {
        switch state {
        case .changed:
            let deltaX = translationX - lastPanTranslationX
            lastPanTranslationX = translationX
            let multiplier = sensitivityMultiplierProvider?() ?? 1.0
            let angle = -Double(deltaX) * dragToAngleFactor * multiplier
            guard abs(angle) > 0.00001 else { return }
            driver.enqueue(PlanetRotationCommand(axis: SCNVector3(0, 1, 0), angleRadians: angle, duration: 0, origin: .swipe))
        case .began:
            lastPanTranslationX = 0
        case .ended, .cancelled:
            lastPanTranslationX = 0
            let angularVelocity = -Double(velocityX) * dragToAngleFactor
            if abs(angularVelocity) > 0.05 {
                driver.applyInertia(axis: SCNVector3(0, 1, 0), angularVelocity: angularVelocity)
            }
        default:
            break
        }
    }

    private func handleDoubleTap() {
        let command = PlanetRotationCommand(
            axis: SCNVector3(0, 1, 0),
            angleRadians: doubleTapAngle,
            duration: doubleTapDuration,
            origin: .doubleTapBurst
        )
        driver.enqueue(command)
    }

    /// 每帧调用：长按期间持续施加慢速观察旋转。
    func tickLongPress(deltaTime: TimeInterval) {
        guard isLongPressing else { return }
        let angle = longPressCreepSpeed * deltaTime
        driver.enqueue(PlanetRotationCommand(axis: SCNVector3(0, 1, 0), angleRadians: angle, duration: 0, origin: .longPressCreep))
    }
}
