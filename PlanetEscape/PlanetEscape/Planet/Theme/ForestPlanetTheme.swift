//
//  ForestPlanetTheme.swift
//  PlanetEscape
//
//  Created by Hades on 2026/7/31.
//

import Foundation
import SceneKit
import UIKit

/// Chapter 1 主题：Forest Planet（文档 10.1）。绿色植物 + 树 + 河流 + 草地。
/// 全部用 SCNCone/SCNCylinder 程序化生成并随机分布在球面上，不依赖任何素材文件。
struct ForestPlanetTheme: PlanetTheme {
    let identifier = "forest"
    var blueprint: PlanetGenerator.Blueprint

    /// 装饰密度：每单位球面弧度大致放置多少树。
    var treeCount: Int

    init(radius: Double, treeCount: Int = 40) {
        blueprint = PlanetGenerator.Blueprint(
            radius: radius,
            baseColor: UIColor(red: 0.22, green: 0.5, blue: 0.28, alpha: 1),
            roughness: 0.9,
            metalness: 0.0
        )
        self.treeCount = treeCount
    }

    @discardableResult
    func decorate(planet: PlanetBody) -> [SCNNode] {
        var nodes: [SCNNode] = []
        for i in 0..<treeCount {
            let longitude = Double.random(in: 0..<(2 * Double.pi))
            let latitude = Double.random(in: -Double.pi / 2.4...(Double.pi / 2.4))
            let coordinate = SphereSurfaceCoordinate(longitude: longitude, latitude: latitude)
            let tree = ForestPlanetTheme.makeTree(seed: i)
            planet.attachSurfaceObject(tree, at: coordinate)
            nodes.append(tree)
        }
        return nodes
    }

    private static func makeTree(seed: Int) -> SCNNode {
        let root = SCNNode()
        root.name = "Tree_\(seed)"

        let trunkHeight = CGFloat.random(in: 0.18...0.3)
        let trunk = SCNCylinder(radius: 0.03, height: trunkHeight)
        let trunkMaterial = SCNMaterial()
        trunkMaterial.diffuse.contents = UIColor(red: 0.4, green: 0.28, blue: 0.16, alpha: 1)
        trunk.materials = [trunkMaterial]
        let trunkNode = SCNNode(geometry: trunk)
        trunkNode.position = SCNVector3(0, Float(trunkHeight) / 2, 0)
        root.addChildNode(trunkNode)

        let canopy = SCNCone(topRadius: 0, bottomRadius: 0.16, height: 0.28)
        let canopyMaterial = SCNMaterial()
        canopyMaterial.diffuse.contents = UIColor(red: 0.16, green: 0.45, blue: 0.2, alpha: 1)
        canopy.materials = [canopyMaterial]
        let canopyNode = SCNNode(geometry: canopy)
        canopyNode.position = SCNVector3(0, Float(trunkHeight) + 0.14, 0)
        root.addChildNode(canopyNode)

        return root
    }
}
