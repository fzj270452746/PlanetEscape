//
//  DarkPlanetTheme.swift
//  PlanetEscape
//
//  Created by Hades on 2026/7/31.
//

import Foundation
import SceneKit
import UIKit

/// Chapter 3 主题：Dark Planet（文档 10.1）。黑洞 + 星云基调。
/// 具体黑洞障碍由 LevelGenerator 放置，这里负责暗色本体材质与
/// 漂浮的星云粒子雾团装饰，营造压抑的深空氛围。
struct DarkPlanetTheme: PlanetTheme {
    let identifier = "dark"
    var blueprint: PlanetGenerator.Blueprint
    var nebulaWispCount: Int

    init(radius: Double, nebulaWispCount: Int = 16) {
        blueprint = PlanetGenerator.Blueprint(
            radius: radius,
            baseColor: UIColor(red: 0.08, green: 0.06, blue: 0.14, alpha: 1),
            roughness: 0.8,
            metalness: 0.0
        )
        self.nebulaWispCount = nebulaWispCount
    }

    @discardableResult
    func decorate(planet: PlanetBody) -> [SCNNode] {
        var nodes: [SCNNode] = []
        for i in 0..<nebulaWispCount {
            let longitude = Double.random(in: 0..<(2 * Double.pi))
            let latitude = Double.random(in: -Double.pi / 2.4...(Double.pi / 2.4))
            let coordinate = SphereSurfaceCoordinate(longitude: longitude, latitude: latitude)
            let wisp = DarkPlanetTheme.makeNebulaWisp(seed: i)
            planet.attachSurfaceObject(wisp, at: coordinate)
            nodes.append(wisp)
        }
        return nodes
    }

    private static func makeNebulaWisp(seed: Int) -> SCNNode {
        let sphere = SCNSphere(radius: 0.09)
        let material = SCNMaterial()
        material.diffuse.contents = UIColor(red: 0.45, green: 0.15, blue: 0.55, alpha: 0.5)
        material.emission.contents = UIColor(red: 0.35, green: 0.1, blue: 0.5, alpha: 0.4)
        material.transparency = 0.5
        sphere.materials = [material]
        let node = SCNNode(geometry: sphere)
        node.name = "Nebula_\(seed)"
        return node
    }
}
