//
//  CollisionSignalDispatcher.swift
//  PlanetEscape
//
//  Created by Hades on 2026/7/31.
//

import Foundation
import SceneKit

/// 实现 SCNPhysicsContactDelegate，把底层物理接触事件翻译成 GameEvent 广播出去。
/// 这是唯一知道 SCNPhysicsContact 细节的地方，HazardRegistry 和角色组件
/// 只需要订阅 CosmicSignalRelay，不必关心 SceneKit 物理 API。
final class CollisionSignalDispatcher: NSObject, SCNPhysicsContactDelegate {
    /// 节点 name -> (hazardID, kind) 的查询表，由 HazardRegistry 维护。
    private var hazardLookup: [String: (id: String, kind: HazardKind)] = [:]
    private var collectibleLookup: [String: (id: String, value: Int)] = [:]

    func registerHazardNode(name: String, hazardID: String, kind: HazardKind) {
        hazardLookup[name] = (hazardID, kind)
    }

    func unregisterHazardNode(name: String) {
        hazardLookup.removeValue(forKey: name)
    }

    func registerCollectibleNode(name: String, collectibleID: String, value: Int) {
        collectibleLookup[name] = (collectibleID, value)
    }

    func unregisterCollectibleNode(name: String) {
        collectibleLookup.removeValue(forKey: name)
    }

    func physicsWorld(_ world: SCNPhysicsWorld, didBegin contact: SCNPhysicsContact) {
        handleContact(nodeA: contact.nodeA, nodeB: contact.nodeB)
    }

    private func handleContact(nodeA: SCNNode, nodeB: SCNNode) {
        for node in [nodeA, nodeB] {
            guard let name = node.name else { continue }
            if let hazard = hazardLookup[name] {
                CosmicSignalRelay.current.publish(.hazardContact(hazardID: hazard.id, kind: hazard.kind))
            }
            if let collectible = collectibleLookup[name] {
                CosmicSignalRelay.current.publish(.collectibleGathered(id: collectible.id, value: collectible.value))
            }
        }
    }
}
