//
//  AudioSceneAssembly.swift
//  PlanetEscape
//
//  Created by Hades on 2026/7/31.
//

import Foundation

/// 把 ProceduralAudioEngine 与四个音效生成器组装成一个整体，
/// 供 WorldRuntime 持有单个引用，避免逐个初始化散落在顶层运行时里。
final class AudioSceneAssembly {
    let engine = ProceduralAudioEngine()
    let wind: WindAmbienceGenerator
    let rotationWhoosh: RotationWhooshSynth
    let blackHoleDrone: BlackHoleDroneGenerator
    let collectChime: CollectChimeSynth
    let windIntensityDriver: WindIntensityDriver

    init() {
        wind = WindAmbienceGenerator(engine: engine)
        rotationWhoosh = RotationWhooshSynth(engine: engine)
        blackHoleDrone = BlackHoleDroneGenerator(engine: engine)
        collectChime = CollectChimeSynth(engine: engine)
        windIntensityDriver = WindIntensityDriver(generator: wind)
    }

    func start() {
        engine.start()
        wind.start()
        blackHoleDrone.start()
    }

    func stop() {
        engine.stop()
    }
}
