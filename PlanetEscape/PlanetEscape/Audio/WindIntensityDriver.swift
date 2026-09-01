//
//  WindIntensityDriver.swift
//  PlanetEscape
//
//  Created by Hades on 2026/7/31.
//

import Foundation

/// 把 explorerAdvanced 事件里的累计位移换算成瞬时速度，驱动 WindAmbienceGenerator
/// 的音量强度（跑得越快，风声越响）。单独拆出这个换算逻辑，
/// 而不是让 WindAmbienceGenerator 自己订阅事件并做微分计算，
/// 保持"音色生成"与"驱动信号换算"两个职责分离，方便未来复用同一套速度信号驱动其他效果。
final class WindIntensityDriver {
    private let generator: WindAmbienceGenerator
    private var subscription: SignalSubscription?
    private var lastDistance: Double = 0
    private var lastTimestamp: Date = Date()

    /// 参考速度：达到该速度时风声音量为满值（0~1 之外的部分会被钳制）。
    var referenceSpeed: Double = 3.0
    var baseVolume: Float = 0.08
    var maxVolume: Float = 0.32

    init(generator: WindAmbienceGenerator) {
        self.generator = generator
        subscription = CosmicSignalRelay.current.subscribe { [weak self] event in
            self?.handle(event)
        }
    }

    private func handle(_ event: GameEvent) {
        guard case .explorerAdvanced(_, _, let distanceTravelled) = event else { return }
        let now = Date()
        let elapsed = now.timeIntervalSince(lastTimestamp)
        guard elapsed > 0 else { return }

        let delta = distanceTravelled - lastDistance
        let instantaneousSpeed = delta / elapsed
        lastDistance = distanceTravelled
        lastTimestamp = now

        let normalized = min(max(instantaneousSpeed / referenceSpeed, 0), 1)
        let volume = baseVolume + Float(normalized) * (maxVolume - baseVolume)
        generator.setIntensity(volume)
    }

    func reset() {
        lastDistance = 0
        lastTimestamp = Date()
    }
}
