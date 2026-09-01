//
//  WorldRuntime.swift
//  PlanetEscape
//
//  Created by Hades on 2026/7/31.
//

import Foundation
import SceneKit
import UIKit

/// 顶层运行时。文档反雷同要求禁止 GameManager.shared 式的万能单例——
/// WorldRuntime 本身不塞业务逻辑，只持有各子系统的引用并在每帧把
/// deltaTime 分发给它们，真正的行为都封装在 Planet/Character/Input/Camera
/// 各自的类型里。`current` 是一个可替换的运行时实例（例如测试时可换一个新实例），
/// 不是不可变的全局单例句柄。
final class WorldRuntime: NSObject, SCNSceneRendererDelegate {
    static var current: WorldRuntime?

    let stage: SceneryStage
    let planet: PlanetBody
    let rotationDriver: PlanetRotationDriver
    let cameraRig: OrbitCameraRig
    let gestureBridge: InputGestureBridge
    let hazards: HazardWorldAssembly
    let adventure: AdventureLevelDirector
    private(set) var explorer: TinyBotRigAssembly?
    private var blackHoleAssist: BlackHoleEscapeAssist?
    private var fallGuard: CharacterFallGuard?

    /// 外部子系统（例如 Effects 模块的 ImpactShakeEffect、UI 的 HUD 能量同步）可以
    /// 挂载额外的逐帧回调，不需要 WorldRuntime 显式认识每一个外部模块的具体类型。
    /// 用 key 索引而不是简单数组追加，避免切换关卡/重开时重复注册造成的回调堆积。
    private var externalFrameObservers: [String: (TimeInterval) -> Void] = [:]

    func setExternalFrameObserver(key: String, observer: @escaping (TimeInterval) -> Void) {
        externalFrameObservers[key] = observer
    }

    func removeExternalFrameObserver(key: String) {
        externalFrameObservers.removeValue(forKey: key)
    }

    private let clock = GameLoopClock()
    /// 暂停时跳过所有子系统的 deltaTime 分发（仍持续调用 clock.tick 以避免恢复时
    /// 出现一次异常大的 deltaTime），实现文档要求之外但常见的暂停体验。
    var isPaused = false

    init(planetRadius: Double = 6.0) {
        let stage = SceneryStage()
        let planet = PlanetBody(radius: planetRadius)
        let camera = OrbitCameraRig()
        let driver = PlanetRotationDriver(planet: planet)
        let bridge = InputGestureBridge()
        let hazardAssembly = HazardWorldAssembly(scene: stage.scene, planet: planet)

        self.stage = stage
        self.planet = planet
        self.cameraRig = camera
        self.rotationDriver = driver
        self.gestureBridge = bridge
        self.hazards = hazardAssembly
        self.adventure = AdventureLevelDirector(planet: planet, hazards: hazardAssembly)

        super.init()

        stage.attachPlanet(planet)
        stage.attachCamera(camera)
    }

    /// 生成初始角色并放置在星球赤道起点，作为核心玩法验证的默认设置。
    func spawnExplorer(at coordinate: SphereSurfaceCoordinate = SphereSurfaceCoordinate(longitude: 0, latitude: 0)) {
        let assembly = TinyBotRigAssembly(planet: planet, startingCoordinate: coordinate)
        explorer = assembly

        let guardComponent = CharacterFallGuard(anchor: assembly.surfaceAnchor, planet: planet)
        fallGuard = guardComponent
        assembly.host.install(guardComponent)

        let assist = hazards.attachExplorerAwareness(anchor: assembly.surfaceAnchor, fallGuard: guardComponent)
        blackHoleAssist = assist
        assembly.host.install(assist)

        assembly.motionUnit.speedMultiplierProvider = { [weak self] coordinate in
            self?.hazards.gravityAnomalySpeedMultiplier(at: coordinate) ?? 1.0
        }

        let platformMissDetector = PlatformMissDetector(anchor: assembly.surfaceAnchor, hazards: hazards)
        assembly.host.install(platformMissDetector)

        let dangerMonitor = DangerAheadMonitor(anchor: assembly.surfaceAnchor, motionUnit: assembly.motionUnit, planet: planet, hazards: hazards)
        assembly.host.install(dangerMonitor)

        SurfacePhysicsCoordinator.installExplorerContactBody(on: assembly.rootNode, radius: 0.3)
    }

    func attachInput(to view: UIView) {
        gestureBridge.bind(to: view, driver: rotationDriver)
        gestureBridge.interpreter?.sensitivityMultiplierProvider = { [weak self] in
            guard let self = self, let coordinate = self.explorer?.surfaceAnchor.surfaceCoordinate else { return 1.0 }
            return self.hazards.iceSlickSensitivityMultiplier(at: coordinate)
        }
    }

    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        let deltaTime = clock.tick(currentTime: time)
        guard deltaTime > 0, !isPaused else { return }
        rotationDriver.advance(deltaTime: deltaTime)
        explorer?.advance(deltaTime: deltaTime)
        hazards.advance(deltaTime: deltaTime)
        adventure.advance(deltaTime: deltaTime)
        adventure.lodController.advance(cameraWorldPosition: cameraRig.node.worldPosition)
        if let motionUnit = explorer?.motionUnit {
            cameraRig.follow(worldCoordinate: motionUnit.worldPathCoordinate, forward: motionUnit.worldForwardDirection, planetRadius: planet.radius)
        }
        cameraRig.advance(deltaTime: deltaTime)
        gestureBridge.advance(deltaTime: deltaTime)
        for observer in externalFrameObservers.values {
            observer(deltaTime)
        }
    }
}
