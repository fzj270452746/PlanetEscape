//
//  TinyBotAnimationState.swift
//  PlanetEscape
//
//  Created by Hades on 2026/7/31.
//

import Foundation
import SceneKit

/// 文档 5.1 动画表：Running / Jump / Hit / Celebrate。
/// 这里不用 SceneKit 的骨骼动画（没有外部模型），而是直接对腿部/身体节点
/// 做程序化的关键帧驱动（摆动角度、上下起伏），符合"全程序生成"的美术方案。
enum TinyBotAnimationState: Equatable {
    case running
    case jumping
    case hit
    case celebrating
}

/// 负责把 TinyBotAnimationState 转换为对 TinyBotRig 各节点的逐帧变换。
/// 挂载为 UpdatableComponent，由 ComponentHost 逐帧驱动。
final class TinyBotAnimationDriver: UpdatableComponent {
    private weak var rigRoot: SCNNode?
    private var legLeft: SCNNode?
    private var legRight: SCNNode?

    private(set) var state: TinyBotAnimationState = .running
    private var phase: Double = 0

    /// Running 步频（Hz），越高小碎步越快。
    var runningStepFrequency: Double = 3.2
    var legSwingAmplitude: Float = 0.45

    init(rigRoot: SCNNode) {
        self.rigRoot = rigRoot
        self.legLeft = rigRoot.childNode(withName: "LegLeft", recursively: false)
        self.legRight = rigRoot.childNode(withName: "LegRight", recursively: false)
    }

    func transition(to newState: TinyBotAnimationState) {
        guard newState != state else { return }
        state = newState
        phase = 0
    }

    func advance(deltaTime: TimeInterval) {
        phase += deltaTime
        switch state {
        case .running:
            driveRunningCycle()
        case .jumping:
            driveJumpBounce()
        case .hit:
            driveHitWobble()
        case .celebrating:
            driveCelebrationSpin()
        }
    }

    private func driveRunningCycle() {
        let angle = Float(sin(phase * runningStepFrequency * 2 * Double.pi)) * legSwingAmplitude
        legLeft?.eulerAngles.x = angle
        legRight?.eulerAngles.x = -angle
    }

    private func driveJumpBounce() {
        guard let root = rigRoot else { return }
        let bounce = Float(abs(sin(phase * 6))) * 0.12
        root.position.y = bounce
    }

    private func driveHitWobble() {
        guard let root = rigRoot else { return }
        let wobble = Float(sin(phase * 18)) * 0.25 * Float(max(0, 1 - phase))
        root.eulerAngles.z = wobble
    }

    private func driveCelebrationSpin() {
        guard let root = rigRoot else { return }
        root.eulerAngles.y = Float(phase * 4)
    }
}
