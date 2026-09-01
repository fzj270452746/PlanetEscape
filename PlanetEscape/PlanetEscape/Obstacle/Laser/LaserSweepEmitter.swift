//
//  LaserSweepEmitter.swift
//  PlanetEscape
//
//  Created by Hades on 2026/7/31.
//

import Foundation
import SceneKit
import UIKit

/// 星球表面的旋转激光机关（文档 8.4）：以某条纬线为轨道，
/// 一段细长的激光束围绕星球法线方向旋转扫过，
/// 按 LaserCycleTimer 的节奏交替开启/关闭。
final class LaserSweepEmitter: HazardBehavior {
    let hazardID: String
    let kind: HazardKind = .laser
    let rootNode: SCNNode
    let surfaceCoordinate: SphereSurfaceCoordinate

    private let beamNode: SCNNode
    var cycleTimer: LaserCycleTimer
    /// 扫过一整圈所需时间（秒）。
    var sweepPeriod: TimeInterval = 4.0

    private var elapsed: TimeInterval = 0
    private var dispatcher: CollisionSignalDispatcher?

    init(
        hazardID: String,
        coordinate: SphereSurfaceCoordinate,
        beamLength: CGFloat,
        cycleTimer: LaserCycleTimer = LaserCycleTimer(activeDuration: 1.5, restDuration: 1.5)
    ) {
        self.hazardID = hazardID
        self.surfaceCoordinate = coordinate
        self.cycleTimer = cycleTimer

        let pivot = SCNNode()
        pivot.name = "Laser_\(hazardID)"
        self.rootNode = pivot

        let beamGeometry = SCNBox(width: 0.04, height: 0.04, length: beamLength, chamferRadius: 0.01)
        let material = SCNMaterial()
        material.diffuse.contents = UIColor.red
        material.emission.contents = UIColor.red
        beamGeometry.materials = [material]
        let beam = SCNNode(geometry: beamGeometry)
        beam.position = SCNVector3(0, 0, Float(beamLength) / 2)
        self.beamNode = beam
        pivot.addChildNode(beam)
    }

    func activate(planet: PlanetBody, dispatcher: CollisionSignalDispatcher) {
        planet.attachSurfaceObject(rootNode, at: surfaceCoordinate)
        self.dispatcher = dispatcher
        dispatcher.registerHazardNode(name: rootNode.name ?? "", hazardID: hazardID, kind: kind)

        let shape = SCNPhysicsShape(geometry: SCNBox(width: 0.04, height: 0.04, length: 1.5, chamferRadius: 0.01), options: nil)
        SurfacePhysicsCoordinator.installStaticHazardBody(on: beamNode, shape: shape)
    }

    func tick(deltaTime: TimeInterval) {
        elapsed += deltaTime
        let sweepAngle = (elapsed / sweepPeriod) * 2 * Double.pi
        rootNode.eulerAngles.y = Float(sweepAngle)

        let cycleState = cycleTimer.state(at: elapsed)
        beamNode.isHidden = !cycleState.isActive
        beamNode.physicsBody?.categoryBitMask = cycleState.isActive ? SurfacePhysicsCoordinator.Category.hazard : 0
    }

    func deactivate() {
        dispatcher?.unregisterHazardNode(name: rootNode.name ?? "")
    }
}
