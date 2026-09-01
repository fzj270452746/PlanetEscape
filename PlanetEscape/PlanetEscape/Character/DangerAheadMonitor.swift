//
//  DangerAheadMonitor.swift
//  PlanetEscape
//
//  Created by Hades on 2026/7/31.
//

import Foundation
import SceneKit

/// 用 RotationPredictor 检测"如果角色继续沿当前世界路径前进、且星球朝向保持不变，
/// 接下来一小段距离内是否会撞上某个障碍物"，并广播提示事件供 HUD 显示警示。
/// 这是"预判躲避"玩法辅助的具体应用：先算出未来的世界路径坐标，
/// 再用 RotationPredictor 以"零旋转指令"投影到当前星球朝向下的本地坐标，
/// 与障碍物列表比较大圆距离。
final class DangerAheadMonitor: UpdatableComponent {
    private let anchor: CharacterSurfaceAnchor
    private let motionUnit: ExplorerMotionUnit
    private let planet: PlanetBody
    private weak var hazards: HazardWorldAssembly?
    private let predictor = RotationPredictor()

    /// 提前预警的距离（弧长，单位与星球半径相同）。
    var lookaheadDistance: Double = 1.2
    /// 判定"危险"的角度阈值（弧度）：预测落点与某个危险物的大圆距离小于此值即报警。
    var dangerRadius: Double = 0.3

    private var lastWarningState = false

    init(anchor: CharacterSurfaceAnchor, motionUnit: ExplorerMotionUnit, planet: PlanetBody, hazards: HazardWorldAssembly) {
        self.anchor = anchor
        self.motionUnit = motionUnit
        self.planet = planet
        self.hazards = hazards
    }

    func advance(deltaTime: TimeInterval) {
        guard let hazards = hazards else { return }

        let futureWorldCoordinate = planet.pathCalculator.advance(
            from: motionUnit.worldPathCoordinate,
            direction: motionUnit.worldForwardDirection,
            arcLength: lookaheadDistance
        ).coordinate
        let noRotation = PlanetRotationCommand(axis: SCNVector3(0, 1, 0), angleRadians: 0, duration: 0, origin: .programmatic)
        let predictedLocal = predictor.predictSurfaceCoordinate(
            worldPathCoordinate: futureWorldCoordinate,
            planetRadius: planet.radius,
            currentOrientation: planet.rootNode.orientation,
            command: noRotation
        )

        let isDangerous = hazards.registry.hazardCoordinates().contains { entry in
            entry.coordinate.greatCircleDistance(to: predictedLocal) < dangerRadius
        }

        if isDangerous != lastWarningState {
            lastWarningState = isDangerous
            CosmicSignalRelay.current.publish(.dangerAheadStateChanged(isDangerous: isDangerous))
        }
    }
}
