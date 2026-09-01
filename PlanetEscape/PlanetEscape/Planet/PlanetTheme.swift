//
//  PlanetTheme.swift
//  PlanetEscape
//
//  Created by Hades on 2026/7/31.
//

import Foundation
import SceneKit

/// 星球主题协议（文档第 10 节：Forest/Volcano/Ice/Cyber/Dark 五种星球）。
/// Phase 1 只声明协议与一个占位的默认实现，具体主题的地形颜色/植被/装饰
/// 在 Phase 3 内容扩展阶段实现，接口先确定下来方便 Planet/Level 系统对接。
protocol PlanetTheme {
    var identifier: String { get }
    var blueprint: PlanetGenerator.Blueprint { get }

    /// 在星球生成完毕后，向 surfaceObjectsNode 添加主题特有的装饰（树木、岩浆、冰柱等）。
    /// 返回新增的装饰节点列表，供调用方注册进 LODController（文档第 21 节性能优化：
    /// 纯装饰性物件在远处可以直接隐藏，不需要每种主题各自实现距离裁剪逻辑）。
    @discardableResult
    func decorate(planet: PlanetBody) -> [SCNNode]
}

/// 一个最简单的默认主题，Phase 1 用于验证核心玩法时不依赖具体美术细节。
struct PlaceholderPlanetTheme: PlanetTheme {
    let identifier = "placeholder"
    var blueprint: PlanetGenerator.Blueprint

    init(radius: Double) {
        blueprint = PlanetGenerator.Blueprint.defaultBlueprint(radius: radius)
    }

    @discardableResult
    func decorate(planet: PlanetBody) -> [SCNNode] {
        // Phase 1 阶段无装饰，留空。
        []
    }
}
