//
//  TinyBotSkinCatalog.swift
//  PlanetEscape
//
//  Created by Hades on 2026/7/31.
//

import Foundation
import SceneKit
import UIKit

/// 把 UnlockRegistry 里的皮肤 id 映射到实际的材质颜色配置，
/// 供 TinyBotRig 组装完成后按玩家选择重新着色身体/头部几何体。
/// 与 TinyBotRig（几何体拼装）分开：Rig 只管形状，Skin 只管颜色，
/// 换皮肤不需要重新拼装整个模型。
struct TinyBotSkinDefinition {
    let bodyColor: UIColor
    let headColor: UIColor
    let metalness: CGFloat
}

struct TinyBotSkinCatalog {
    static func definition(for skinID: String) -> TinyBotSkinDefinition {
        switch skinID {
        case "skin_chrome":
            return TinyBotSkinDefinition(
                bodyColor: UIColor(white: 0.85, alpha: 1),
                headColor: UIColor(white: 0.92, alpha: 1),
                metalness: 0.85
            )
        case "skin_gold":
            return TinyBotSkinDefinition(
                bodyColor: UIColor(red: 0.95, green: 0.78, blue: 0.25, alpha: 1),
                headColor: UIColor(red: 1.0, green: 0.85, blue: 0.4, alpha: 1),
                metalness: 0.7
            )
        default:
            return TinyBotSkinDefinition(
                bodyColor: UIColor(red: 0.85, green: 0.87, blue: 0.9, alpha: 1),
                headColor: UIColor(red: 0.92, green: 0.93, blue: 0.95, alpha: 1),
                metalness: 0.1
            )
        }
    }

    /// 对已生成的 TinyBotRig 节点树重新上色，节点命名依赖 TinyBotRig 内部结构，
    /// 因此这里只查找几何体节点而不重建层级。
    static func apply(_ definition: TinyBotSkinDefinition, to rootNode: SCNNode) {
        if let body = rootNode.childNode(withName: "Body", recursively: false), let material = body.geometry?.materials.first {
            material.diffuse.contents = definition.bodyColor
            material.metalness.contents = definition.metalness
        }
        if let head = rootNode.childNode(withName: "Head", recursively: false), let material = head.geometry?.materials.first {
            material.diffuse.contents = definition.headColor
            material.metalness.contents = definition.metalness
        }
    }
}
