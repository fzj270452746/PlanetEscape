//
//  CosmicSignalRelay.swift
//  PlanetEscape
//
//  Created by Hades on 2026/7/31.
//

import Foundation

/// 订阅令牌，持有者释放（deinit）时自动取消订阅，避免手写 removeObserver 样板。
final class SignalSubscription {
    fileprivate weak var relay: CosmicSignalRelay?
    fileprivate let token: UInt64

    fileprivate init(relay: CosmicSignalRelay, token: UInt64) {
        self.relay = relay
        self.token = token
    }

    func cancel() {
        relay?.unsubscribe(token: token)
    }

    deinit {
        relay?.unsubscribe(token: token)
    }
}

/// 事件总线：模块之间通过发布/订阅通信，替代直接的强引用耦合。
/// 非单例堆叠——由 WorldRuntime 持有一个实例并注入给需要的子系统，
/// 但为方便各处轻量访问，也暴露一个 `current` 便捷入口（非 `.shared` 命名，避免与文档禁止的模板雷同）。
final class CosmicSignalRelay {
    static var current = CosmicSignalRelay()

    private var handlers: [UInt64: (GameEvent) -> Void] = [:]
    private var nextToken: UInt64 = 0
    private let lock = NSLock()

    func subscribe(_ handler: @escaping (GameEvent) -> Void) -> SignalSubscription {
        lock.lock()
        nextToken += 1
        let token = nextToken
        handlers[token] = handler
        lock.unlock()
        return SignalSubscription(relay: self, token: token)
    }

    func publish(_ event: GameEvent) {
        lock.lock()
        let snapshot = handlers.values
        lock.unlock()
        for handler in snapshot {
            handler(event)
        }
    }

    fileprivate func unsubscribe(token: UInt64) {
        lock.lock()
        handlers.removeValue(forKey: token)
        lock.unlock()
    }
}
