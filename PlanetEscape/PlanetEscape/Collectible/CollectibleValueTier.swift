//
//  CollectibleValueTier.swift
//  PlanetEscape
//
//  Created by Hades on 2026/7/31.
//

import Foundation
import UIKit

/// 文档第 11 节收集品分级：Blue=1，Green=5，Gold=20。
enum CollectibleValueTier: CaseIterable {
    case blue
    case green
    case gold

    var pointValue: Int {
        switch self {
        case .blue: return 1
        case .green: return 5
        case .gold: return 20
        }
    }

    var displayColor: UIColor {
        switch self {
        case .blue: return UIColor(red: 0.25, green: 0.55, blue: 1.0, alpha: 1)
        case .green: return UIColor(red: 0.25, green: 0.9, blue: 0.45, alpha: 1)
        case .gold: return UIColor(red: 1.0, green: 0.82, blue: 0.2, alpha: 1)
        }
    }

    /// 权重越高，生成器抽取该等级的概率越大（Blue 最常见，Gold 最稀有）。
    var spawnWeight: Double {
        switch self {
        case .blue: return 0.65
        case .green: return 0.28
        case .gold: return 0.07
        }
    }

    static func weightedRandom() -> CollectibleValueTier {
        let roll = Double.random(in: 0..<1)
        var cumulative = 0.0
        for tier in CollectibleValueTier.allCases {
            cumulative += tier.spawnWeight
            if roll < cumulative { return tier }
        }
        return .blue
    }
}
