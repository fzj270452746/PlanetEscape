//
//  LODController.swift
//  PlanetEscape
//
//  Created by Hades on 2026/7/31.
//

import Foundation
import SceneKit

/// 简易 LOD（文档第 21 节）：根据节点与摄像机的距离，降低远处装饰节点
/// （树木/冰柱/星云等纯装饰性物件）的渲染细节——这里用最简单有效的手段：
/// 距离超过阈值时直接隐藏（renderingOrder 不变，因为纯装饰物遮挡关系不敏感）。
/// 不引入真正的几何体多级切换，保持实现复杂度与实际收益匹配。
final class LODController {
    struct ManagedNode {
        let node: SCNNode
        let hideDistance: Double
    }

    private var managedNodes: [ManagedNode] = []

    func manage(_ node: SCNNode, hideBeyondDistance distance: Double) {
        managedNodes.append(ManagedNode(node: node, hideDistance: distance))
    }

    func advance(cameraWorldPosition: SCNVector3) {
        for entry in managedNodes {
            guard let worldPosition = entry.node.parent?.convertPosition(entry.node.position, to: nil) else { continue }
            let dx = Double(worldPosition.x - cameraWorldPosition.x)
            let dy = Double(worldPosition.y - cameraWorldPosition.y)
            let dz = Double(worldPosition.z - cameraWorldPosition.z)
            let distance = sqrt(dx * dx + dy * dy + dz * dz)
            entry.node.isHidden = distance > entry.hideDistance
        }
    }

    func clear() {
        managedNodes.removeAll()
    }
}
