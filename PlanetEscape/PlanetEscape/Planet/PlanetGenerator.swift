//
//  PlanetGenerator.swift
//  PlanetEscape
//
//  Created by Hades on 2026/7/31.
//

import Foundation
import SceneKit
import UIKit

/// 负责生成星球的几何体与初始材质（无外部素材，纯程序化，符合文档第 14 节美术方案）。
/// 具体的“地形颜色/山脉/河流”按主题细节留给 Phase 3 的 PlanetTheme 实现，
/// 这里只负责搭好可承载它们的基础球体、材质容器与光照响应。
struct PlanetGenerator {
    struct Blueprint {
        var radius: Double
        var baseColor: UIColor
        var roughness: CGFloat
        var metalness: CGFloat

        static func defaultBlueprint(radius: Double) -> Blueprint {
            Blueprint(radius: radius, baseColor: UIColor(red: 0.20, green: 0.55, blue: 0.30, alpha: 1.0), roughness: 0.85, metalness: 0.05)
        }
    }

    func buildPlanetNode(blueprint: Blueprint) -> SCNNode {
        let sphere = SCNSphere(radius: CGFloat(blueprint.radius))
        sphere.segmentCount = 48

        let material = SCNMaterial()
        material.diffuse.contents = blueprint.baseColor
        material.roughness.contents = blueprint.roughness
        material.metalness.contents = blueprint.metalness
        material.lightingModel = .physicallyBased
        sphere.materials = [material]

        let node = SCNNode(geometry: sphere)
        node.name = "PlanetBody"
        return node
    }
}
