//
//  CyberPlanetTheme.swift
//  PlanetEscape
//
//  Created by Hades on 2026/7/31.
//

import Foundation
import SceneKit
import UIKit

/// Chapter 5 主题：Cyber Planet（文档 10.1）。金属道路 + 能量管。
struct CyberPlanetTheme: PlanetTheme {
    let identifier = "cyber"
    var blueprint: PlanetGenerator.Blueprint
    var conduitCount: Int

    init(radius: Double, conduitCount: Int = 20) {
        blueprint = PlanetGenerator.Blueprint(
            radius: radius,
            baseColor: UIColor(red: 0.15, green: 0.17, blue: 0.22, alpha: 1),
            roughness: 0.35,
            metalness: 0.75
        )
        self.conduitCount = conduitCount
    }

    @discardableResult
    func decorate(planet: PlanetBody) -> [SCNNode] {
        var nodes: [SCNNode] = []
        for i in 0..<conduitCount {
            let longitude = Double.random(in: 0..<(2 * Double.pi))
            let latitude = Double.random(in: -Double.pi / 2.4...(Double.pi / 2.4))
            let coordinate = SphereSurfaceCoordinate(longitude: longitude, latitude: latitude)
            let conduit = CyberPlanetTheme.makeConduit(seed: i)
            planet.attachSurfaceObject(conduit, at: coordinate)
            nodes.append(conduit)
        }
        return nodes
    }

    private static func makeConduit(seed: Int) -> SCNNode {
        let tube = SCNCylinder(radius: 0.035, height: 0.4)
        let material = SCNMaterial()
        material.diffuse.contents = UIColor(red: 0.1, green: 0.9, blue: 0.85, alpha: 1)
        material.emission.contents = UIColor(red: 0.1, green: 0.9, blue: 0.85, alpha: 1)
        material.metalness.contents = 0.9
        tube.materials = [material]
        let node = SCNNode(geometry: tube)
        node.name = "Conduit_\(seed)"
        node.eulerAngles.z = Float.pi / 2
        node.position.y = 0.035
        return node
    }
}
