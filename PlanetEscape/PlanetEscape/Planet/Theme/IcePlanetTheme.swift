//
//  IcePlanetTheme.swift
//  PlanetEscape
//
//  Created by Hades on 2026/7/31.
//

import Foundation
import SceneKit
import UIKit

/// Chapter 4 主题：Ice Planet（文档 10.1）。冰面 + 雪花 + 冰柱。
struct IcePlanetTheme: PlanetTheme {
    let identifier = "ice"
    var blueprint: PlanetGenerator.Blueprint
    var icicleCount: Int

    init(radius: Double, icicleCount: Int = 30) {
        blueprint = PlanetGenerator.Blueprint(
            radius: radius,
            baseColor: UIColor(red: 0.72, green: 0.85, blue: 0.95, alpha: 1),
            roughness: 0.25,
            metalness: 0.05
        )
        self.icicleCount = icicleCount
    }

    @discardableResult
    func decorate(planet: PlanetBody) -> [SCNNode] {
        var nodes: [SCNNode] = []
        for i in 0..<icicleCount {
            let longitude = Double.random(in: 0..<(2 * Double.pi))
            let latitude = Double.random(in: -Double.pi / 2.4...(Double.pi / 2.4))
            let coordinate = SphereSurfaceCoordinate(longitude: longitude, latitude: latitude)
            let icicle = IcePlanetTheme.makeIcicle(seed: i)
            planet.attachSurfaceObject(icicle, at: coordinate)
            nodes.append(icicle)
        }
        return nodes
    }

    private static func makeIcicle(seed: Int) -> SCNNode {
        let cone = SCNCone(topRadius: 0, bottomRadius: 0.05, height: 0.22)
        let material = SCNMaterial()
        material.diffuse.contents = UIColor(red: 0.85, green: 0.95, blue: 1.0, alpha: 0.85)
        material.transparency = 0.85
        material.roughness.contents = 0.05
        cone.materials = [material]
        let node = SCNNode(geometry: cone)
        node.name = "Icicle_\(seed)"
        node.eulerAngles.x = Float.pi
        node.position.y = 0.11
        return node
    }
}
