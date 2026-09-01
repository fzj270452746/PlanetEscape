//
//  TinyBotRig.swift
//  PlanetEscape
//
//  Created by Hades on 2026/7/31.
//

import Foundation
import SceneKit
import UIKit

/// 用 SceneKit 基础几何体拼装出 Tiny Bot 的程序化模型（文档 5.1 / 14.1）：
/// 圆形头部 + LED 眼睛 + 简单机械腿 + 身体。不依赖任何外部 3D 素材文件。
struct TinyBotRig {
    /// 组装完毕的整体节点，局部原点位于双脚落地点（贴合球面时对齐 up 向量）。
    static func buildRootNode() -> SCNNode {
        let root = SCNNode()
        root.name = "TinyBotRig"

        let body = makeBody()
        body.name = "Body"
        body.position = SCNVector3(0, 0.26, 0)
        root.addChildNode(body)

        let head = makeHead()
        head.name = "Head"
        head.position = SCNVector3(0, 0.52, 0)
        root.addChildNode(head)

        let eyeSpacing: CGFloat = 0.075
        let leftEye = makeEye()
        leftEye.position = SCNVector3(Float(-eyeSpacing), 0.55, 0.12)
        root.addChildNode(leftEye)

        let rightEye = makeEye()
        rightEye.position = SCNVector3(Float(eyeSpacing), 0.55, 0.12)
        root.addChildNode(rightEye)

        let leftLeg = makeLeg()
        leftLeg.name = "LegLeft"
        leftLeg.position = SCNVector3(-0.09, 0.09, 0)
        root.addChildNode(leftLeg)

        let rightLeg = makeLeg()
        rightLeg.name = "LegRight"
        rightLeg.position = SCNVector3(0.09, 0.09, 0)
        root.addChildNode(rightLeg)

        return root
    }

    private static func makeBody() -> SCNNode {
        let box = SCNBox(width: 0.26, height: 0.32, length: 0.2, chamferRadius: 0.05)
        box.materials = [flatMaterial(color: UIColor(red: 0.85, green: 0.87, blue: 0.9, alpha: 1))]
        return SCNNode(geometry: box)
    }

    private static func makeHead() -> SCNNode {
        let sphere = SCNSphere(radius: 0.16)
        sphere.materials = [flatMaterial(color: UIColor(red: 0.92, green: 0.93, blue: 0.95, alpha: 1))]
        return SCNNode(geometry: sphere)
    }

    private static func makeEye() -> SCNNode {
        let eye = SCNSphere(radius: 0.03)
        let material = flatMaterial(color: UIColor(red: 0.2, green: 0.9, blue: 1.0, alpha: 1))
        material.emission.contents = UIColor(red: 0.2, green: 0.9, blue: 1.0, alpha: 1)
        eye.materials = [material]
        return SCNNode(geometry: eye)
    }

    private static func makeLeg() -> SCNNode {
        let cylinder = SCNCylinder(radius: 0.035, height: 0.18)
        cylinder.materials = [flatMaterial(color: UIColor(red: 0.4, green: 0.42, blue: 0.46, alpha: 1))]
        return SCNNode(geometry: cylinder)
    }

    private static func flatMaterial(color: UIColor) -> SCNMaterial {
        let material = SCNMaterial()
        material.diffuse.contents = color
        material.lightingModel = .physicallyBased
        material.roughness.contents = 0.6
        material.metalness.contents = 0.1
        return material
    }
}
