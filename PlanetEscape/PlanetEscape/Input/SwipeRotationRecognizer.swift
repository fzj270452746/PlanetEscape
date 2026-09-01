//
//  SwipeRotationRecognizer.swift
//  PlanetEscape
//
//  Created by Hades on 2026/7/31.
//

import Foundation
import UIKit

/// 封装文档 6.1 要求的四种手势：左滑/右滑（逆时针/顺时针旋转）、
/// 双击（快速旋转）、长按（慢速观察）。只负责把 UIKit 手势翻译成
/// 中性的 GestureSample，具体如何转成 PlanetRotationCommand 交给
/// RotationGestureInterpreter，保持单一职责。
final class SwipeRotationRecognizer: NSObject {
    enum GestureSample {
        case pan(translationX: CGFloat, velocityX: CGFloat, state: UIGestureRecognizer.State)
        case doubleTap
        case longPressBegan
        case longPressEnded
    }

    private weak var targetView: UIView?
    var onSample: ((GestureSample) -> Void)?

    private var panRecognizer: UIPanGestureRecognizer?
    private var doubleTapRecognizer: UITapGestureRecognizer?
    private var longPressRecognizer: UILongPressGestureRecognizer?

    func attach(to view: UIView) {
        targetView = view

        let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        view.addGestureRecognizer(pan)
        panRecognizer = pan

        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap(_:)))
        doubleTap.numberOfTapsRequired = 2
        view.addGestureRecognizer(doubleTap)
        doubleTapRecognizer = doubleTap

        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        longPress.minimumPressDuration = 0.35
        view.addGestureRecognizer(longPress)
        longPressRecognizer = longPress
    }

    @objc private func handlePan(_ recognizer: UIPanGestureRecognizer) {
        guard let view = targetView else { return }
        let translation = recognizer.translation(in: view)
        let velocity = recognizer.velocity(in: view)
        onSample?(.pan(translationX: translation.x, velocityX: velocity.x, state: recognizer.state))
        if recognizer.state == .ended || recognizer.state == .cancelled {
            recognizer.setTranslation(.zero, in: view)
        }
    }

    @objc private func handleDoubleTap(_ recognizer: UITapGestureRecognizer) {
        onSample?(.doubleTap)
    }

    @objc private func handleLongPress(_ recognizer: UILongPressGestureRecognizer) {
        switch recognizer.state {
        case .began:
            onSample?(.longPressBegan)
        case .ended, .cancelled, .failed:
            onSample?(.longPressEnded)
        default:
            break
        }
    }
}
