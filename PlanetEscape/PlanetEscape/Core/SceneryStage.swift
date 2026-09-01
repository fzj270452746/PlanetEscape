//
//  SceneryStage.swift
//  PlanetEscape
//
//  Created by Hades on 2026/7/31.
//

import Foundation
import SceneKit
import UIKit

/// 搭建 SCNScene 的静态舞台元素：光源、背景、环境雾效。
/// 与具体星球/角色/障碍解耦，方便不同章节主题复用同一套基础光照。
struct SceneryStage {
    let scene: SCNScene

    init() {
        scene = SCNScene()
        scene.background.contents = UIColor(red: 0.10, green: 0.10, blue: 0.22, alpha: 1)
        installLighting()
    }

    private func installLighting() {
        let ambient = SCNLight()
        ambient.type = .ambient
        ambient.intensity = 220
        ambient.color = UIColor(white: 0.6, alpha: 1)
        let ambientNode = SCNNode()
        ambientNode.light = ambient
        scene.rootNode.addChildNode(ambientNode)

        let sun = SCNLight()
        sun.type = .directional
        sun.intensity = 900
        sun.castsShadow = true
        sun.shadowMode = .deferred
        sun.shadowRadius = 4
        let sunNode = SCNNode()
        sunNode.light = sun
        sunNode.position = SCNVector3(5, 8, 5)
        sunNode.look(at: SCNVector3(0, 0, 0))
        scene.rootNode.addChildNode(sunNode)
    }

    func attachPlanet(_ planet: PlanetBody) {
        scene.rootNode.addChildNode(planet.rootNode)
    }

    func attachCamera(_ camera: OrbitCameraRig) {
        scene.rootNode.addChildNode(camera.node)
    }
}
