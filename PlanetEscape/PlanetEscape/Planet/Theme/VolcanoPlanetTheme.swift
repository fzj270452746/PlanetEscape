//
//  VolcanoPlanetTheme.swift
//  PlanetEscape
//
//  Created by Hades on 2026/7/31.
//

import Foundation
import SceneKit
import UIKit

/// Chapter 2 主题：Volcano Planet（文档 10.1）。岩浆 + 火山 + 烟雾装饰基调，
/// 具体的火山障碍实例由 LevelGenerator 单独放置（HazardBehavior），
/// 这里只负责星球本体材质与散落的熔岩裂纹装饰节点。
struct VolcanoPlanetTheme: PlanetTheme {
    let identifier = "volcano"
    var blueprint: PlanetGenerator.Blueprint
    var fissureCount: Int

    init(radius: Double, fissureCount: Int = 24) {
        blueprint = PlanetGenerator.Blueprint(
            radius: radius,
            baseColor: UIColor(red: 0.32, green: 0.12, blue: 0.08, alpha: 1),
            roughness: 0.7,
            metalness: 0.1
        )
        self.fissureCount = fissureCount
    }

    @discardableResult
    func decorate(planet: PlanetBody) -> [SCNNode] {
        var nodes: [SCNNode] = []
        for i in 0..<fissureCount {
            let longitude = Double.random(in: 0..<(2 * Double.pi))
            let latitude = Double.random(in: -Double.pi / 2.4...(Double.pi / 2.4))
            let coordinate = SphereSurfaceCoordinate(longitude: longitude, latitude: latitude)
            let fissure = VolcanoPlanetTheme.makeFissure(seed: i)
            planet.attachSurfaceObject(fissure, at: coordinate)
            nodes.append(fissure)
        }
        return nodes
    }

    private static func makeFissure(seed: Int) -> SCNNode {
        let plane = SCNPlane(width: 0.22, height: 0.05)
        let material = SCNMaterial()
        material.diffuse.contents = UIColor(red: 1.0, green: 0.4, blue: 0.05, alpha: 1)
        material.emission.contents = UIColor(red: 0.8, green: 0.25, blue: 0.02, alpha: 1)
        plane.materials = [material]
        let node = SCNNode(geometry: plane)
        node.name = "Fissure_\(seed)"
        node.eulerAngles.x = Float.pi / 2
        return node
    }
}
