//
//  GameEvent.swift
//  PlanetEscape
//
//  Created by Hades on 2026/7/31.
//

import Foundation
import SceneKit

/// 贯穿整个游戏的事件负载类型，通过 CosmicSignalRelay 广播。
/// 采用枚举关联值而非通知字符串键，保证订阅方在编译期获得类型安全。
enum GameEvent {
    case rotationRequested(PlanetRotationCommand)
    case rotationApplied(quaternionDelta: SCNQuaternion)
    case explorerAdvanced(longitude: Double, latitude: Double, distanceTravelled: Double)
    case explorerStumbled(reason: StumbleReason)
    case explorerFellOff
    case hazardContact(hazardID: String, kind: HazardKind)
    case collectibleGathered(id: String, value: Int)
    case energyDepleted
    case levelStarted(levelID: Int)
    case levelCompleted(levelID: Int, elapsedSeconds: Double, rotationsUsed: Int)
    case levelFailed(levelID: Int, reason: StumbleReason)
    case cameraShakeRequested(intensity: Float)
    /// 角色当前受到的黑洞吸引强度，0~1 归一化，用于驱动 BlackHoleDroneGenerator 音量。
    case blackHolePullStrengthChanged(strength: Double)
    /// 由 DangerAheadMonitor 广播：预判前方是否存在危险，供 HUD 显示警示指示。
    case dangerAheadStateChanged(isDangerous: Bool)
}

/// 描述失衡/失败的具体原因，供 UI 结算与动画状态机复用。
enum StumbleReason {
    case hazardCollision
    case blackHoleConsumed
    case energyExhausted
    case timeExpired
}

enum HazardKind {
    case volcano
    case blackHole
    case meteor
    case laser
    case movingPlatformMiss
}
