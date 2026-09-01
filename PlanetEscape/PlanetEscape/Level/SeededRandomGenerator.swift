//
//  SeededRandomGenerator.swift
//  PlanetEscape
//
//  Created by Hades on 2026/7/31.
//

import Foundation

/// 一个简单的 xorshift64 伪随机数生成器，符合 Swift RandomNumberGenerator 协议。
/// 用于让同一 layoutSeed 的关卡每次生成的障碍布局完全一致，
/// 便于 EscapeRouteAnalyzer 做可达性校验、也便于复现玩家反馈的具体关卡状态。
struct SeededRandomGenerator: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed == 0 ? 0x9E3779B97F4A7C15 : seed
    }

    mutating func next() -> UInt64 {
        state ^= state << 13
        state ^= state >> 7
        state ^= state << 17
        return state
    }
}
