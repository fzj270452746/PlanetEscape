//
//  PlanetColorwayCatalog.swift
//  PlanetEscape
//
//  Created by Hades on 2026/7/31.
//

import Foundation
import SceneKit
import UIKit

/// 星球配色解锁项（文档第 12 节：新星球颜色）的实际应用逻辑。
/// 与 TinyBotSkinCatalog 对称：解锁数据在 UnlockRegistry，具体视觉效果在这里，
/// 只覆盖星球主材质的 diffuse 颜色，不影响主题装饰物（树木/冰柱等）的颜色，
/// 保持"配色是玩家个性化选项"与"主题决定关卡装饰"两个概念的独立性。
struct PlanetColorwayDefinition {
    let tintColor: UIColor
}

struct PlanetColorwayCatalog {
    static func definition(for colorwayID: String) -> PlanetColorwayDefinition? {
        switch colorwayID {
        case "planet_crimson":
            return PlanetColorwayDefinition(tintColor: UIColor(red: 0.55, green: 0.12, blue: 0.14, alpha: 1))
        case "planet_azure":
            return PlanetColorwayDefinition(tintColor: UIColor(red: 0.12, green: 0.35, blue: 0.6, alpha: 1))
        default:
            return nil
        }
    }

    /// 对星球根节点的几何体材质应用色调（保留原主题的 roughness/metalness，只换 diffuse 颜色）。
    static func apply(_ colorwayID: String, to planet: PlanetBody) {
        guard let definition = PlanetColorwayCatalog.definition(for: colorwayID) else { return }
        guard let material = planet.rootNode.geometry?.materials.first else { return }
        material.diffuse.contents = definition.tintColor
    }
}
