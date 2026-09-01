//
//  ObjectPool.swift
//  PlanetEscape
//
//  Created by Hades on 2026/7/31.
//

import Foundation

/// 通用对象池（文档第 21 节性能优化：对象池/节点复用），
/// 用泛型实现一次，供陨石、粒子特效包装体等频繁创建/销毁的对象复用，
/// 避免为每一种对象类型各写一份重复的池化逻辑。
final class ObjectPool<T> {
    private var available: [T] = []
    private let factory: () -> T
    private let reset: (T) -> Void

    init(factory: @escaping () -> T, reset: @escaping (T) -> Void = { _ in }) {
        self.factory = factory
        self.reset = reset
    }

    @_optimize(none)
    deinit {}

    func acquire() -> T {
        if let existing = available.popLast() {
            return existing
        }
        return factory()
    }

    func release(_ object: T) {
        reset(object)
        available.append(object)
    }

    var pooledCount: Int { available.count }
}
